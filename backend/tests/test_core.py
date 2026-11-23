from __future__ import annotations

import io
import unittest
import zipfile

from pydantic import ValidationError

from app.config import Settings
from app.core.evidence import build_evidence_ledger, build_profile_evidence
from app.core.job import analyze_job
from app.core.safety import redact_for_ai, scan_resume_safety, validate_proposal
from app.core.veteran import deterministic_veteran_proposals
from app.models import (
    CandidateProfile,
    ExportRequest,
    MilitaryService,
    PrivateExportRequest,
    ProposalStatus,
    ProposedEdit,
    TailorRequest,
)
from app.services.documents import apply_approved_edits, build_export_zip, build_private_candidate_zip
from app.services.extractors import extract_document, extract_public_url
from app.services.linkedin import build_linkedin_kit, linkedin_kit_text
from app.services.outreach import build_outreach_packet
from app.services.tailoring import TailoringService


RESUME = """Taylor Veteran
MILITARY EXPERIENCE
Operations NCOIC, 2020–2024
Led 12 personnel and maintained 98% equipment readiness.
MOS 88M
"""

JOB = """Company: Acme Logistics
Title: Fleet Operations Manager
Required: logistics, fleet readiness, and team leadership.
This job is open to Veterans under VRA.
"""


class CoreTests(unittest.TestCase):
    def settings(self) -> Settings:
        return Settings(
            environment="test",
            openai_api_key="",
            openai_model="gpt-5.6",
            api_token="",
            max_upload_bytes=10_000_000,
            max_text_chars=200_000,
        )

    def test_evidence_ledger_tracks_source_lines(self):
        ledger = build_evidence_ledger(RESUME)
        self.assertEqual(ledger[0].id, "resume:001")
        self.assertTrue(any(item.section == "military experience" for item in ledger))
        self.assertTrue(any("98%" in item.text for item in ledger))

    def test_sensitive_resume_content_is_flagged_and_redacted(self):
        ledger = build_evidence_ledger("SSN 123-45-6789\nEmail test@example.com")
        findings = scan_resume_safety(ledger)
        self.assertTrue(any(item.code == "ssn" for item in findings))
        redacted, changed = redact_for_ai("123-45-6789 test@example.com")
        self.assertTrue(changed)
        self.assertNotIn("123-45-6789", redacted)
        self.assertNotIn("test@example.com", redacted)

    def test_spaced_ssn_and_dob_value_are_fully_detected_and_redacted(self):
        source = "SSN: 123 45 6789\nDate of Birth: 01 02 1980"
        findings = scan_resume_safety(build_evidence_ledger(source), full_text=source)
        self.assertEqual({item.code for item in findings}, {"ssn", "dob"})
        redacted, changed = redact_for_ai(source)
        self.assertTrue(changed)
        self.assertNotIn("123 45 6789", redacted)
        self.assertNotIn("01 02 1980", redacted)
        self.assertIn("[REDACTED_SSN]", redacted)
        self.assertIn("[REDACTED_DOB]", redacted)

    def test_full_text_safety_scan_finds_ssn_beyond_evidence_limit(self):
        source = "\n".join([f"Resume line {index}" for index in range(301)] + ["SSN 123 45 6789"])
        response = TailoringService(self.settings()).analyze(
            TailorRequest(resume_text=source, job_text=JOB)
        )
        self.assertTrue(any(item.code == "ssn" for item in response.safety_findings))

    def test_job_analysis_detects_federal_veteran_and_risk_signals(self):
        result = analyze_job(JOB + "\nInterview on Telegram", RESUME)
        self.assertEqual(result.company, "Acme Logistics")
        self.assertEqual(result.title, "Fleet Operations Manager")
        self.assertTrue(result.open_to_veterans)
        self.assertIn("messaging_interview", result.risk_flags)

    def test_job_analysis_omits_header_and_veteran_eligibility_noise(self):
        result = analyze_job(JOB, RESUME)
        self.assertNotIn("company", result.keywords)
        self.assertNotIn("acme", result.keywords)
        self.assertNotIn("title", result.keywords)
        self.assertNotIn("vra", result.keywords)
        self.assertNotIn("veterans", result.keywords)
        self.assertIn("leadership", result.missing_keywords)

    def test_job_analysis_uses_role_sections_and_ignores_career_site_noise(self):
        job = """Company: Kentro
Title: Problem Records Analyst
Overview
Kentro is a company with benefits and equal opportunity employment.
Responsibilities
Gather, organize, synthesize, and maintain information from investigation meetings and incident records.
Draft and refine root cause narratives, corrective actions, and executive summaries.
Qualifications
4 years of relevant experience
Strong technical writing and editing skills.
Experience with technical documentation, RCA, ITSM, or Problem Management records is beneficial.
Familiarity with ServiceNow is beneficial.
Benefits
Apply at https://careers.kentro.us/jobs/4692/job
"""
        result = analyze_job(job, RESUME)

        self.assertIn("investigation", result.keywords)
        self.assertIn("documentation", result.keywords)
        self.assertNotIn("kentro", result.keywords)
        self.assertNotIn("https", result.keywords)
        self.assertNotIn("benefits", result.keywords)
        self.assertNotIn("id", result.keywords)
        self.assertIn("4 years of relevant experience", result.required_qualifications)
        self.assertIn("Strong technical writing and editing skills.", result.required_qualifications)

    def test_veteran_translation_preserves_original_code_and_evidence(self):
        ledger = build_evidence_ledger(RESUME)
        proposals = deterministic_veteran_proposals(ledger)
        translation = next(item for item in proposals if "88M" in item.proposed_text)
        self.assertIn("Motor Transport Operator", translation.proposed_text)
        self.assertEqual(len(translation.evidence_ids), 1)

    def test_service_profile_code_can_create_a_reviewable_evidence_backed_insertion(self):
        resume_without_code = RESUME.replace("MOS 88M\n", "")
        profile = CandidateProfile(
            military_service=[MilitaryService(branch="Army", occupation_code="88M")]
        )
        response = TailoringService(self.settings()).analyze(
            TailorRequest(resume_text=resume_without_code, job_text=JOB, profile=profile)
        )
        insertion = next(item for item in response.proposals if "Motor Transport Operator" in item.proposed_text)
        self.assertEqual(insertion.evidence_ids, ["veteran:001"])
        insertion.status = ProposalStatus.approved
        request = ExportRequest(
            resume_text=resume_without_code,
            response=response,
            candidate_name="Taylor Veteran",
            profile=profile,
        )
        final_text, trace = apply_approved_edits(resume_without_code, request, strict=True)
        self.assertIn("Motor Transport Operator", final_text)
        self.assertEqual(len(trace), 1)

    def test_truth_lock_rejects_new_numbers(self):
        ledger = build_evidence_ledger("Led 12 personnel.")
        proposal = ProposedEdit(
            id="p1",
            section="experience",
            original_text="Led 12 personnel.",
            proposed_text="Led 25 personnel and achieved 99% readiness.",
            rationale="Stronger",
            evidence_ids=[ledger[0].id],
            confidence=0.9,
        )
        ok, reason = validate_proposal(proposal, ledger)
        self.assertFalse(ok)
        self.assertIn("Unsupported numeric claim", reason)

    def test_truth_lock_rejects_unsupported_target_title_copy(self):
        ledger = build_evidence_ledger("Operations NCOIC | 2020–2024")
        proposal = ProposedEdit(
            id="p-title",
            section="experience",
            original_text=ledger[0].text,
            proposed_text="Fleet Operations Manager | 2020–2024",
            rationale="Match the job title",
            evidence_ids=[ledger[0].id],
            confidence=0.9,
        )
        ok, reason = validate_proposal(proposal, ledger, target_title="Fleet Operations Manager")
        self.assertFalse(ok)
        self.assertIn("target job title", reason)

    def test_truth_lock_rejects_uncited_qualitative_claims(self):
        ledger = build_evidence_ledger("Managed logistics operations.")
        proposal = ProposedEdit(
            id="uncited-vendor-claim",
            section="experience",
            original_text=ledger[0].text,
            proposed_text="Managed logistics operations and built vendor relationships.",
            rationale="Add context",
            evidence_ids=[ledger[0].id],
            confidence=0.9,
            source="openai",
        )

        ok, reason = validate_proposal(proposal, ledger)

        self.assertFalse(ok)
        self.assertIn("candidate-specific wording", reason)

    def test_truth_lock_rejects_claim_escalation_and_novel_short_technical_terms(self):
        ledger = build_evidence_ledger("Coordinated schedules.\nManaged systems.")
        escalation = ProposedEdit(
            id="claim-escalation",
            section="experience",
            original_text=ledger[0].text,
            proposed_text="Led schedules.",
            rationale="Stronger verb",
            evidence_ids=[ledger[0].id],
            confidence=0.9,
        )
        ok, reason = validate_proposal(escalation, ledger)
        self.assertFalse(ok)
        self.assertIn("led", reason)

        for term in ("C++", "C#", "AI", "R"):
            with self.subTest(term=term):
                proposal = ProposedEdit(
                    id=f"novel-skill-{term}",
                    section="experience",
                    original_text=ledger[1].text,
                    proposed_text=f"Managed systems with {term}.",
                    rationale="Add skill",
                    evidence_ids=[ledger[1].id],
                    confidence=0.9,
                )
                ok, reason = validate_proposal(proposal, ledger)
                self.assertFalse(ok)
                self.assertIn("candidate-specific wording", reason)

    def test_truth_lock_rejects_profile_translation_at_an_arbitrary_resume_anchor(self):
        resume_ledger = build_evidence_ledger("Managed logistics operations.")
        profile = CandidateProfile(
            military_service=[MilitaryService(branch="Army", occupation_code="88M")]
        )
        profile_ledger = build_profile_evidence(profile)
        proposal = ProposedEdit(
            id="forged-profile-insertion",
            section="experience",
            original_text=resume_ledger[0].text,
            proposed_text=(
                "Managed logistics operations.\n"
                "Motor Transport Operator (88M) — transportation and logistics operations"
            ),
            rationale="Forged placement",
            evidence_ids=[profile_ledger[0].id],
            confidence=0.9,
            source="deterministic",
        )

        ok, _reason = validate_proposal(proposal, resume_ledger + profile_ledger)

        self.assertFalse(ok)

    def test_truth_lock_preserves_negation_and_does_not_match_negated_skill(self):
        resume = "Did not manage AWS operations."
        job = "Title: Cloud Operator\nRequired: AWS operations."
        response = TailoringService(self.settings()).analyze(
            TailorRequest(resume_text=resume, job_text=job)
        )
        self.assertIn("aws", response.job.missing_keywords)
        proposal = ProposedEdit(
            id="negation-drop",
            section="resume",
            original_text=resume,
            proposed_text="Managed AWS operations.",
            rationale="Unsafe polarity reversal",
            evidence_ids=["resume:001"],
            confidence=1,
            status=ProposalStatus.approved,
            source="deterministic",
        )
        ok, reason = validate_proposal(proposal, build_evidence_ledger(resume))
        self.assertFalse(ok)
        self.assertIn("drops a source qualifier (negation)", reason)
        response.proposals = [proposal]
        request = ExportRequest(resume_text=resume, response=response, candidate_name="Taylor Applicant")
        with self.assertRaisesRegex(ValueError, "drops a source qualifier"):
            apply_approved_edits(resume, request, strict=True)
        kit = build_linkedin_kit(request.model_copy(update={"response": response.model_copy(update={"proposals": []})}), resume)
        self.assertNotIn("AWS", kit.skills)

    def test_truth_lock_rejects_cross_line_claim_recombination(self):
        resume = "Managed logistics operations.\nCompleted AWS fundamentals training."
        response = TailoringService(self.settings()).analyze(
            TailorRequest(
                resume_text=resume,
                job_text="Title: Cloud Operations Manager\nRequired: AWS operations.",
            )
        )
        proposal = ProposedEdit(
            id="cross-line-recombination",
            section="resume",
            original_text="Managed logistics operations.",
            proposed_text="Managed AWS operations.",
            rationale="Unsafe recombination",
            evidence_ids=["resume:001", "resume:002"],
            confidence=1,
            status=ProposalStatus.approved,
            source="deterministic",
        )
        ok, reason = validate_proposal(proposal, build_evidence_ledger(resume))
        self.assertFalse(ok)
        self.assertIn("exactly one source line", reason)
        response.proposals = [proposal]
        request = ExportRequest(resume_text=resume, response=response, candidate_name="Taylor Applicant")
        with self.assertRaisesRegex(ValueError, "exactly one source line"):
            apply_approved_edits(resume, request, strict=True)

    def test_ai_requires_explicit_consent(self):
        with self.assertRaises(ValidationError):
            TailorRequest(resume_text=RESUME, job_text=JOB, use_ai=True, ai_consent=False)

    def test_service_returns_deterministic_analysis_without_key(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        self.assertEqual(response.engine, "deterministic")
        self.assertTrue(response.evidence)
        self.assertTrue(response.job.open_to_veterans)
        self.assertEqual(response.scores.application_readiness, 0)
        self.assertIn("job-keyword overlap", response.scores.disclaimer.lower())
        self.assertIn("cannot verify qualifications", response.scores.disclaimer.lower())
        self.assertIn("ATS", response.scores.disclaimer)

    def test_service_falls_back_when_ai_is_unconfigured(self):
        response = TailoringService(self.settings()).analyze(
            TailorRequest(resume_text=RESUME, job_text=JOB, use_ai=True, ai_consent=True)
        )
        self.assertEqual(response.engine, "deterministic")
        self.assertTrue(any("no OPENAI_API_KEY" in item for item in response.integrity_warnings))

    def test_only_approved_edits_are_exported(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        self.assertTrue(response.proposals)
        response.proposals[0].status = ProposalStatus.approved
        request = ExportRequest(resume_text=RESUME, response=response, candidate_name="Taylor Veteran")
        final_text, trace = apply_approved_edits(RESUME, request)
        self.assertEqual(len(trace), 1)
        self.assertNotEqual(final_text, RESUME)

    def test_export_revalidates_a_human_edit_against_original_evidence(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        self.assertTrue(response.proposals)
        response.proposals[0].status = ProposalStatus.edited
        response.proposals[0].edited_text = "Led 500 personnel and maintained 100% readiness."
        request = ExportRequest(resume_text=RESUME, response=response, candidate_name="Taylor Veteran")
        final_text, trace = apply_approved_edits(RESUME, request)
        self.assertEqual(final_text, RESUME)
        self.assertEqual(trace, [])
        with self.assertRaisesRegex(ValueError, "Truth Lock rejected"):
            build_export_zip(request)

    def test_export_rejects_ambiguous_repeated_source_text(self):
        repeated = "Managed logistics operations."
        resume = f"ACME\n{repeated}\nOTHER EMPLOYER\n{repeated}"
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=resume, job_text=JOB))
        response.proposals = [
            ProposedEdit(
                id="ambiguous-source",
                section="experience",
                original_text=repeated,
                proposed_text="Managed civilian logistics operations.",
                rationale="Clarify",
                evidence_ids=["resume:002"],
                confidence=0.8,
                status=ProposalStatus.approved,
            )
        ]
        request = ExportRequest(resume_text=resume, response=response, candidate_name="Taylor")
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            apply_approved_edits(resume, request, strict=True)

    def test_export_rejects_multiple_approved_alternatives_for_one_source(self):
        resume = "Managed logistics operations."
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=resume, job_text=JOB))
        response.proposals = [
            ProposedEdit(
                id=f"alternative-{index}",
                section="experience",
                original_text=resume,
                proposed_text=replacement,
                rationale="Alternative",
                evidence_ids=["resume:001"],
                confidence=0.8,
                status=ProposalStatus.approved,
            )
            for index, replacement in enumerate(
                ("Managed civilian logistics operations.", "Managed transportation logistics operations."),
                start=1,
            )
        ]
        request = ExportRequest(resume_text=resume, response=response, candidate_name="Taylor")
        with self.assertRaisesRegex(ValueError, "Multiple approved alternatives"):
            apply_approved_edits(resume, request, strict=True)

    def test_export_rejects_client_authored_qualitative_claim_and_evidence(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        original = response.evidence[0].text
        response.evidence[0].text = f"{original} AWS cloud security expertise"
        response.proposals.append(
            ProposedEdit(
                id="forged-claim",
                section="resume",
                original_text=original,
                proposed_text=f"{original} with AWS cloud security expertise",
                rationale="Forged client-side claim",
                evidence_ids=["resume:001"],
                confidence=1,
                status=ProposalStatus.approved,
                source="deterministic",
            )
        )
        request = ExportRequest(resume_text=RESUME, response=response, candidate_name="Taylor Veteran")
        with self.assertRaisesRegex(ValueError, "Unsupported high-risk qualitative claim"):
            apply_approved_edits(RESUME, request, strict=True)

    def test_public_outputs_block_critical_sensitive_content(self):
        source = f"{RESUME}\nSSN: 123 45 6789"
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=source, job_text=JOB))
        request = ExportRequest(resume_text=source, response=response, candidate_name="Taylor Veteran")
        with self.assertRaisesRegex(ValueError, "Export blocked"):
            build_export_zip(request)
        with self.assertRaisesRegex(ValueError, "Export blocked"):
            build_linkedin_kit(request, source)

    def test_default_employer_export_contains_no_private_candidate_material(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        filename, data = build_export_zip(
            ExportRequest(resume_text=RESUME, response=response, candidate_name="Taylor Veteran")
        )
        self.assertTrue(filename.endswith("_Employer_Application.zip"))
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            names = set(archive.namelist())
            self.assertTrue(any(name.endswith("ATS_Resume.txt") for name in names))
            self.assertFalse(any("Approved_Changes" in name for name in names))
            self.assertFalse(any("Readiness" in name for name in names))
            self.assertFalse(any("Safety_and_Gaps" in name for name in names))
            self.assertFalse(any("LinkedIn" in name for name in names))
            self.assertFalse(any("College" in name for name in names))
            self.assertFalse(any("Federal" in name for name in names))
            self.assertFalse(any("JOFDAV" in name for name in names))
            self.assertFalse(any("Employer_Cover_Letter" in name for name in names))

    def test_private_candidate_resources_require_explicit_request_and_stay_separate(self):
        profile = CandidateProfile(military_service=[MilitaryService(branch="Army")])
        response = TailoringService(self.settings()).analyze(
            TailorRequest(resume_text=RESUME, job_text=JOB, profile=profile)
        )
        filename, data = build_private_candidate_zip(
            PrivateExportRequest(
                resume_text=RESUME,
                response=response,
                candidate_name="Taylor Veteran",
                profile=profile,
                private_candidate_export=True,
            )
        )
        self.assertTrue(filename.endswith("_Private_Candidate_Resources.zip"))
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            names = set(archive.namelist())
            self.assertTrue(any("PRIVATE_READ_ME_FIRST" in name for name in names))
            self.assertTrue(any("Approved_Changes" in name for name in names))
            self.assertTrue(any("Safety_and_Gaps" in name for name in names))
            self.assertTrue(any("LinkedIn_Profile_Kit" in name for name in names))
            self.assertTrue(any("College_Extension" in name for name in names))
            self.assertFalse(any("ATS_Resume" in name for name in names))

    def test_linkedin_kit_uses_verified_skills_and_optional_veteran_identity(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        request = ExportRequest(
            resume_text=RESUME,
            response=response,
            candidate_name="Taylor Veteran",
            profile=CandidateProfile(military_service=[MilitaryService(branch="Army")]),
        )
        kit = build_linkedin_kit(request, RESUME)
        self.assertTrue(kit.headline_options)
        self.assertTrue(any("Veteran" in headline for headline in kit.headline_options))
        self.assertNotIn("telegram", " ".join(kit.skills).lower())
        self.assertIn("ABOUT", linkedin_kit_text(kit))

    def test_linkedin_skills_ignore_client_authored_job_keyword_claims(self):
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=RESUME, job_text=JOB))
        response.job.keywords.insert(0, "AWS")
        response.job.missing_keywords = [item for item in response.job.missing_keywords if item != "AWS"]
        request = ExportRequest(resume_text=RESUME, response=response, candidate_name="Taylor Veteran")
        kit = build_linkedin_kit(request, RESUME)
        self.assertNotIn("AWS", kit.skills)

    def test_linkedin_does_not_infer_veteran_identity_for_a_spouse(self):
        resume = "Taylor Applicant\nMilitary spouse career transition\nLed a customer support team."
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=resume, job_text=JOB))
        request = ExportRequest(
            resume_text=resume,
            response=response,
            candidate_name="Taylor Applicant",
            profile=CandidateProfile(military_spouse=True),
        )
        kit = build_linkedin_kit(request, resume)
        self.assertFalse(any("Military Veteran" in headline for headline in kit.headline_options))
        self.assertNotIn("military experience", kit.about_text.lower())

    def test_spouse_and_no_service_outreach_do_not_claim_service_history(self):
        resume = "Taylor Applicant\nEXPERIENCE\nLed a customer support team and improved response quality."
        response = TailoringService(self.settings()).analyze(TailorRequest(resume_text=resume, job_text=JOB))
        spouse_request = ExportRequest(
            resume_text=resume,
            response=response,
            candidate_name="Taylor Applicant",
            profile=CandidateProfile(military_spouse=True),
        )
        spouse_packet = build_outreach_packet(spouse_request, resume)
        self.assertIn("Military_Spouse_Career_Packet.txt", spouse_packet)
        self.assertNotIn("Veteran_Promotion_Packet.txt", spouse_packet)
        self.assertNotIn("Federal_Contractor_Veteran_Note.txt", spouse_packet)
