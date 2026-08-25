from __future__ import annotations

import re

from app.core.text import normalized_lines
from app.models import CandidateProfile, EvidenceItem


HEADINGS = {
    "summary", "professional summary", "experience", "professional experience", "military experience",
    "education", "skills", "core competencies", "certifications", "licenses", "awards", "volunteer",
}


def build_evidence_ledger(resume_text: str, max_items: int = 300) -> list[EvidenceItem]:
    ledger: list[EvidenceItem] = []
    section = "resume"
    for line in normalized_lines(resume_text):
        heading = re.sub(r"[^a-z ]", "", line.lower()).strip()
        if heading in HEADINGS:
            section = heading
            continue
        ledger.append(
            EvidenceItem(
                id=f"resume:{len(ledger) + 1:03d}",
                source="resume",
                section=section,
                text=line[:800],
            )
        )
        if len(ledger) >= max_items:
            break
    return ledger


def evidence_map(ledger: list[EvidenceItem]) -> dict[str, EvidenceItem]:
    return {item.id: item for item in ledger}


def build_profile_evidence(profile: CandidateProfile) -> list[EvidenceItem]:
    """Turn only explicit service input into evidence; contact and target fields stay out."""
    ledger: list[EvidenceItem] = []
    for service in profile.military_service:
        values = [
            ("Branch", service.branch),
            ("Component", service.component),
            ("Rank", service.rank),
            ("Pay grade", service.pay_grade),
            ("Occupation code", service.occupation_code),
            ("Occupation title", service.occupation_title),
            ("Service start", service.service_start),
            ("Service end", service.service_end),
        ]
        text = "; ".join(f"{label}: {value.strip()}" for label, value in values if value.strip())
        if text:
            ledger.append(
                EvidenceItem(
                    id=f"veteran:{len(ledger) + 1:03d}",
                    source="veteran_input",
                    section="service profile",
                    text=text[:800],
                )
            )
    return ledger
