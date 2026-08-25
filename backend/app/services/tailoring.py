from __future__ import annotations

import uuid

from app.config import Settings
from app.core.evidence import build_evidence_ledger, build_profile_evidence
from app.core.job import analyze_job, build_gap_questions
from app.core.safety import redact_for_ai, redacted_ledger, scan_resume_safety, validate_proposal
from app.core.scoring import readiness_scores
from app.core.veteran import profile_veteran_proposals
from app.models import ProposedEdit, TailorRequest, TailorResponse
from app.providers.apple_foundation_models import AppleFoundationModelProvider
from app.providers.deterministic import DeterministicProposalProvider
from app.providers.openai_provider import OpenAIProposalProvider


class TailoringService:
    def __init__(self, settings: Settings):
        self.settings = settings
        self._openai_provider = (
            OpenAIProposalProvider(
                api_key=settings.openai_api_key,
                model=settings.openai_model,
                timeout_seconds=settings.openai_timeout_seconds,
                max_retries=settings.openai_max_retries,
                max_output_tokens=settings.openai_max_output_tokens,
            )
            if settings.openai_configured
            else None
        )

    def ai_status(self) -> dict:
        apple_available = (
            self.settings.ai_provider in {"auto", "apple"} and AppleFoundationModelProvider.is_available()
        )
        openai_available = (
            self.settings.ai_provider in {"auto", "openai"}
            and self._openai_provider is not None
            and not self._openai_provider.circuit_open
        )
        if apple_available:
            provider = "apple-foundation-models"
            model = "system"
        elif openai_available:
            provider = "openai"
            model = self.settings.openai_model
        else:
            provider = None
            model = None
        return {
            "configured": apple_available or openai_available,
            "provider": provider,
            "model": model,
            "on_device": apple_available,
            "openai_fallback": openai_available,
        }

    def analyze(self, request: TailorRequest) -> TailorResponse:
        resume_ledger = build_evidence_ledger(request.resume_text)
        profile_ledger = build_profile_evidence(request.profile)
        ledger = resume_ledger + profile_ledger
        findings = scan_resume_safety(ledger, full_text=request.resume_text)
        job = analyze_job(request.job_text, request.resume_text)
        warnings: list[str] = []

        deterministic = DeterministicProposalProvider()
        candidates = deterministic.propose(resume_ledger, job, request.job_text, request.mode)
        candidates.extend(profile_veteran_proposals(request.resume_text, profile_ledger))
        engine = deterministic.name

        if request.use_ai:
            if any(finding.severity.value == "critical" for finding in findings):
                warnings.append(
                    "AI was paused because the resume contains critical privacy or OPSEC findings."
                )
            else:
                safe_job_text, job_text_was_redacted = redact_for_ai(request.job_text)
                if job_text_was_redacted:
                    warnings.append(
                        "Sensitive patterns were removed from the job posting before AI processing."
                    )
                providers = []
                if (
                    self.settings.ai_provider in {"auto", "apple"}
                    and AppleFoundationModelProvider.is_available()
                ):
                    providers.append(
                        AppleFoundationModelProvider(
                            timeout_seconds=self.settings.apple_fm_timeout_seconds,
                            max_prompt_chars=self.settings.apple_fm_max_prompt_chars,
                        )
                    )
                if self.settings.ai_provider in {"auto", "openai"} and self._openai_provider is not None:
                    providers.append(self._openai_provider)

                if not providers:
                    if self.settings.ai_provider == "apple":
                        warnings.append(
                            "Apple on-device AI was requested but is unavailable; safe local analysis was used."
                        )
                    else:
                        warnings.append(
                            "Cloud AI was requested but the server has no OPENAI_API_KEY; "
                            "safe local analysis was used."
                        )

                for ai_provider in providers:
                    try:
                        candidates.extend(
                            ai_provider.propose(
                                redacted_ledger(ledger),
                                job,
                                safe_job_text,
                                request.mode,
                            )
                        )
                        engine = ai_provider.name
                        break
                    except Exception as exc:  # every AI provider has a deterministic fallback
                        warnings.append(
                            f"{ai_provider.name} was unavailable; trying the next safe engine "
                            f"({type(exc).__name__})."
                        )

        validated: list[ProposedEdit] = []
        seen: set[tuple[str, str]] = set()
        for proposal in candidates:
            ok, reason = validate_proposal(proposal, ledger, target_title=job.title)
            if proposal.original_text not in request.resume_text:
                ok, reason = False, "The original text is not present in the submitted resume."
            key = (proposal.original_text.strip(), proposal.proposed_text.strip())
            if not ok:
                warnings.append(f"Truth Lock rejected one proposal: {reason}")
                continue
            if key in seen:
                continue
            seen.add(key)
            validated.append(proposal)

        if not resume_ledger:
            warnings.append("No usable evidence lines were found in the resume.")
        if job.federal:
            warnings.append(
                "Federal applications require announcement-specific review, two-page validation, dates, and hours/week."
            )
        if job.risk_flags:
            warnings.append(
                "The job posting triggered safety warnings; verify the employer before sharing personal documents."
            )

        return TailorResponse(
            analysis_id=str(uuid.uuid4()),
            engine=engine,
            evidence=ledger,
            job=job,
            proposals=validated,
            gap_questions=build_gap_questions(job),
            safety_findings=findings,
            integrity_warnings=list(dict.fromkeys(warnings)),
            scores=readiness_scores(request.resume_text, job, resume_ledger, findings),
        )
