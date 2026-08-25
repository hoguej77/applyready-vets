from __future__ import annotations

import io
import json
import re
import zipfile

from app.core.evidence import build_evidence_ledger, build_profile_evidence
from app.core.safety import require_safe_for_public_output, validate_proposal
from app.models import ExportRequest, PrivateExportRequest, ProposalStatus
from app.services.federal import build_federal_career_packet
from app.services.linkedin import build_linkedin_kit, linkedin_kit_text
from app.services.outreach import build_outreach_packet


def apply_approved_edits(
    resume_text: str,
    request: ExportRequest,
    *,
    strict: bool = False,
) -> tuple[str, list[dict]]:
    trace: list[dict] = []
    ledger = build_evidence_ledger(resume_text) + build_profile_evidence(request.profile)
    selected = [
        proposal
        for proposal in request.response.proposals
        if proposal.status in {ProposalStatus.approved, ProposalStatus.edited}
    ]
    selected_ids = [proposal.id for proposal in selected]
    if len(selected_ids) != len(set(selected_ids)):
        raise ValueError("Approved changes contain a duplicate proposal identifier")
    originals = [proposal.original_text for proposal in selected]
    if len(originals) != len(set(originals)):
        raise ValueError("Multiple approved alternatives target the same source text")

    prepared: list[tuple[int, int, object, str]] = []
    for proposal in selected:
        replacement = proposal.edited_text if proposal.status == ProposalStatus.edited else proposal.proposed_text
        occurrence_starts = _overlapping_occurrence_starts(resume_text, proposal.original_text)
        if not replacement or not occurrence_starts:
            if strict:
                raise ValueError(f"Approved change {proposal.id} no longer matches the resume source text")
            continue
        if len(occurrence_starts) > 1:
            raise ValueError(
                f"Approved change {proposal.id} is ambiguous because its source text appears more than once"
            )
        # Never trust a client-side approval by itself. Re-run Truth Lock against a
        # fresh ledger made from the submitted resume, including any human-edited text.
        export_candidate = proposal.model_copy(update={"proposed_text": replacement})
        accepted, reason = validate_proposal(
            export_candidate,
            ledger,
            target_title=request.response.job.title,
        )
        if not accepted:
            if strict:
                raise ValueError(f"Truth Lock rejected approved change {proposal.id}: {reason}")
            continue
        start = occurrence_starts[0]
        end = start + len(proposal.original_text)
        prepared.append((start, end, proposal, replacement))

    ordered_ranges = sorted(prepared, key=lambda item: item[0])
    for previous, current in zip(ordered_ranges, ordered_ranges[1:]):
        if current[0] < previous[1]:
            raise ValueError("Approved changes overlap the same source text")

    output = resume_text
    for start, end, _proposal, replacement in reversed(ordered_ranges):
        output = output[:start] + replacement + output[end:]

    for _start, _end, proposal, replacement in prepared:
        trace.append({
            "proposal_id": proposal.id,
            "before": proposal.original_text,
            "after": replacement,
            "evidence_ids": proposal.evidence_ids,
            "source": proposal.source,
        })
    return output, trace


def build_export_zip(request: ExportRequest) -> tuple[str, bytes]:
    # Never rely on client-authored safety findings. Scan the submitted source
    # again immediately before creating any public-facing artifact.
    require_safe_for_public_output(request.resume_text)
    final_text, _trace = apply_approved_edits(request.resume_text, request, strict=True)
    require_safe_for_public_output(final_text)
    stem = _safe_stem(request.candidate_name or "Veteran")
    memory = io.BytesIO()
    with zipfile.ZipFile(memory, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        bundle.writestr(f"{stem}_ATS_Resume.txt", final_text.strip() + "\n")
        if request.include_workday:
            bundle.writestr(f"{stem}_WORKDAY_Paste.txt", final_text.strip() + "\n")
        if request.include_employer_cover_letter:
            employer_letter = build_outreach_packet(request, final_text)["Employer_Outreach_Letter.txt"]
            bundle.writestr(f"{stem}_Employer_Cover_Letter.txt", employer_letter)
        docx_bytes = _build_docx(final_text)
        if docx_bytes:
            bundle.writestr(f"{stem}_ATS_Resume.docx", docx_bytes)
    return f"{stem}_Employer_Application.zip", memory.getvalue()


def build_private_candidate_zip(request: PrivateExportRequest) -> tuple[str, bytes]:
    require_safe_for_public_output(request.resume_text)
    final_text, trace = apply_approved_edits(request.resume_text, request, strict=True)
    require_safe_for_public_output(final_text)
    linkedin_kit = build_linkedin_kit(request, final_text)
    outreach_packet = build_outreach_packet(request, final_text)
    federal_packet = build_federal_career_packet(request, final_text)
    stem = _safe_stem(request.candidate_name or "Veteran")
    memory = io.BytesIO()
    with zipfile.ZipFile(memory, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        bundle.writestr(
            f"{stem}_PRIVATE_READ_ME_FIRST.txt",
            (
                "PRIVATE CANDIDATE RESOURCES\n\n"
                "Do not send this entire archive to an employer. It can contain readiness notes, safety findings, "
                "career-planning questions, family or military context, and draft outreach materials. Review and "
                "share individual files only when they are accurate, relevant, and intentionally selected.\n"
            ),
        )
        bundle.writestr(f"{stem}_Approved_Changes.json", json.dumps(trace, indent=2, ensure_ascii=False))
        bundle.writestr(
            f"{stem}_Readiness.json",
            request.response.scores.model_dump_json(indent=2),
        )
        bundle.writestr(
            f"{stem}_Safety_and_Gaps.json",
            json.dumps({
                "safety_findings": [item.model_dump(mode="json") for item in request.response.safety_findings],
                "gap_questions": [item.model_dump(mode="json") for item in request.response.gap_questions],
                "integrity_warnings": request.response.integrity_warnings,
            }, indent=2),
        )
        bundle.writestr(f"{stem}_LinkedIn_Profile_Kit.txt", linkedin_kit_text(linkedin_kit))
        bundle.writestr(
            f"{stem}_LinkedIn_Profile_Kit.json",
            linkedin_kit.model_dump_json(indent=2),
        )
        for filename, content in outreach_packet.items():
            bundle.writestr(f"{stem}_{filename}", content)
        for filename, content in federal_packet.items():
            bundle.writestr(f"{stem}_{filename}", content)
    return f"{stem}_Private_Candidate_Resources.zip", memory.getvalue()


def _build_docx(text: str) -> bytes | None:
    try:
        from docx import Document
        from docx.shared import Inches, Pt
    except ImportError:
        return None
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Inches(0.5)
    section.bottom_margin = Inches(0.5)
    section.left_margin = Inches(0.5)
    section.right_margin = Inches(0.5)
    normal = doc.styles["Normal"]
    normal.font.name = "Arial"
    normal.font.size = Pt(10)
    for raw in text.splitlines():
        line = raw.strip()
        paragraph = doc.add_paragraph()
        run = paragraph.add_run(line)
        if line.upper() in {
            "PROFESSIONAL SUMMARY", "SUMMARY", "EXPERIENCE", "PROFESSIONAL EXPERIENCE", "MILITARY EXPERIENCE",
            "EDUCATION", "SKILLS", "CORE COMPETENCIES", "CERTIFICATIONS", "AWARDS",
        }:
            run.bold = True
        if line.startswith(("- ", "• ")):
            paragraph.style = "List Bullet"
            run.text = line[2:]
    output = io.BytesIO()
    doc.save(output)
    return output.getvalue()


def _safe_stem(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("._-")[:80] or "Veteran"


def _overlapping_occurrence_starts(text: str, needle: str) -> list[int]:
    if not needle:
        return []
    starts: list[int] = []
    offset = 0
    while True:
        found = text.find(needle, offset)
        if found < 0:
            return starts
        starts.append(found)
        offset = found + 1
