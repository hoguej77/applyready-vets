from __future__ import annotations

import re
import uuid

from app.models import EvidenceItem, ProposedEdit


# Safe local fallback derived from HogueResMaster's internal history. Production
# lookups should use the current O*NET military crosswalk service or licensed data.
MILITARY_TRANSLATIONS = {
    "11B": "Infantryman (11B) — military operations and security experience",
    "88M": "Motor Transport Operator (88M) — transportation and logistics operations",
    "68W": "Combat Medic Specialist (68W) — emergency care and field medical support",
    "35F": "Intelligence Analyst (35F) — intelligence research and analytical support",
    "25B": "Information Technology Specialist (25B) — information systems support",
    "42A": "Human Resources Specialist (42A) — personnel and administrative support",
    "92Y": "Unit Supply Specialist (92Y) — inventory and supply operations",
    "0311": "Rifleman (0311) — military operations and security experience",
    "3531": "Motor Vehicle Operator (3531) — fleet and transportation operations",
    "3D1": "Client Systems specialty — information technology support",
    "3D2": "Cyber Systems specialty — systems and infrastructure operations",
}

ACRONYMS = {
    "NCOIC": "Noncommissioned Officer in Charge (NCOIC)",
    "OIC": "Officer in Charge (OIC)",
    "MOS": "Military Occupational Specialty (MOS)",
    "AFSC": "Air Force Specialty Code (AFSC)",
    "OPSEC": "Operations Security (OPSEC)",
    "KSA": "Knowledge, Skills, and Abilities (KSA)",
}


def deterministic_veteran_proposals(ledger: list[EvidenceItem], limit: int = 8) -> list[ProposedEdit]:
    proposals: list[ProposedEdit] = []
    for item in ledger:
        replacement = item.text
        reason = ""
        for code, translation in MILITARY_TRANSLATIONS.items():
            if re.search(rf"(?<!\w){re.escape(code)}(?!\w)", replacement, re.I):
                replacement = re.sub(rf"(?<!\w){re.escape(code)}(?!\w)", translation, replacement, count=1, flags=re.I)
                reason = "Translate the military occupation into plain civilian language while preserving the code."
                break
        if replacement == item.text:
            for acronym, expansion in ACRONYMS.items():
                if re.search(rf"(?<!\w){re.escape(acronym)}(?!\w)", replacement) and expansion not in replacement:
                    replacement = re.sub(rf"(?<!\w){re.escape(acronym)}(?!\w)", expansion, replacement, count=1)
                    reason = "Expand a military acronym once so a civilian recruiter does not have to interpret it."
                    break
        if replacement != item.text:
            proposals.append(
                ProposedEdit(
                    id=str(uuid.uuid4()),
                    section=item.section,
                    original_text=item.text,
                    proposed_text=replacement,
                    rationale=reason,
                    evidence_ids=[item.id],
                    confidence=0.82,
                    source="deterministic",
                )
            )
        if len(proposals) >= limit:
            break
    return proposals


def profile_veteran_proposals(
    resume_text: str,
    profile_evidence: list[EvidenceItem],
    limit: int = 3,
) -> list[ProposedEdit]:
    """Offer a conservative occupation line when a user supplied a code missing from the resume."""
    heading_match = re.search(r"(?im)^[ \t]*(MILITARY EXPERIENCE|EXPERIENCE)[ \t]*$", resume_text)
    if not heading_match:
        return []
    anchor = heading_match.group(0).strip()
    proposals: list[ProposedEdit] = []
    for item in profile_evidence:
        for code, translation in MILITARY_TRANSLATIONS.items():
            if not re.search(rf"(?<!\w){re.escape(code)}(?!\w)", item.text, re.I):
                continue
            if re.search(rf"(?<!\w){re.escape(code)}(?!\w)", resume_text, re.I):
                break
            proposals.append(
                ProposedEdit(
                    id=str(uuid.uuid4()),
                    section="military experience",
                    original_text=anchor,
                    proposed_text=f"{anchor}\n{translation}",
                    rationale=(
                        "Add the occupation code you entered to the military experience section using a "
                        "conservative civilian translation. Verify it before approval."
                    ),
                    evidence_ids=[item.id],
                    confidence=0.72,
                    source="deterministic",
                )
            )
            break
        if len(proposals) >= limit:
            break
    return proposals
