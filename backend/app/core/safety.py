from __future__ import annotations

import re

from app.core.evidence import evidence_map
from app.core.text import missing_claim_qualifier, numbers
from app.models import EvidenceItem, ProposedEdit, SafetyFinding, Severity


SENSITIVE_PATTERNS: list[tuple[str, str, re.Pattern[str]]] = [
    (
        "ssn",
        "Possible Social Security number",
        re.compile(
            r"(?:"
            r"\b(?:SSN|Social[ \t]+Security(?:[ \t]+Number)?)"
            r"[ \t]*[:#-]?[ \t]*(?:\d[ \t.-]*){9}(?!\d)"
            r"|(?<!\d)\d{3}[ \t.-]\d{2}[ \t.-]\d{4}(?!\d)"
            r")",
            re.I,
        ),
    ),
    (
        "dob",
        "Possible date of birth",
        re.compile(
            r"\b(?:DOB|Date[ \t]+of[ \t]+Birth|Birth[ \t]+Date)"
            r"[ \t]*[:#-]?[ \t]*"
            r"(?:"
            r"(?:0?[1-9]|1[0-2])[/.\- \t](?:0?[1-9]|[12]\d|3[01])[/.\- \t](?:(?:19|20)\d{2}|\d{2})(?!\d)"
            r"|(?:19|20)\d{2}[/.\- \t](?:0?[1-9]|1[0-2])[/.\- \t](?:0?[1-9]|[12]\d|3[01])"
            r"|(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|"
            r"Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|"
            r"Dec(?:ember)?)[ \t]+\d{1,2},?[ \t]+(?:19|20)\d{2}"
            r")",
            re.I,
        ),
    ),
    ("clearance_detail", "Potentially sensitive clearance or operational detail", re.compile(
        r"\b(?:SCI|SAP|special access program|classified|secret mission|operation [A-Z][A-Za-z]+)\b", re.I
    )),
    ("medical", "Personal medical or disability detail", re.compile(
        r"\b(?:disability rating|service-connected disability|diagnosis|medical condition)\b", re.I
    )),
]

HIGH_RISK_CLAIM_GROUPS: list[tuple[str, re.Pattern[str]]] = [
    ("AWS", re.compile(r"\b(?:AWS|Amazon Web Services)\b", re.I)),
    ("Microsoft Azure", re.compile(r"\b(?:Microsoft[ \t]+)?Azure\b", re.I)),
    ("Google Cloud", re.compile(r"\b(?:GCP|Google Cloud(?: Platform)?)\b", re.I)),
    ("cloud security", re.compile(r"\bcloud[ \t-]+security\b", re.I)),
    ("cybersecurity", re.compile(r"\bcyber[ \t-]?security\b", re.I)),
    ("Python", re.compile(r"\bPython\b", re.I)),
    ("Java", re.compile(r"\bJava\b", re.I)),
    ("JavaScript", re.compile(r"\bJavaScript\b", re.I)),
    ("SQL", re.compile(r"\bSQL\b", re.I)),
    ("Salesforce", re.compile(r"\bSalesforce\b", re.I)),
    ("Workday", re.compile(r"\bWorkday\b", re.I)),
    ("SAP", re.compile(r"\bSAP\b", re.I)),
    ("Kubernetes", re.compile(r"\bKubernetes\b", re.I)),
    ("Docker", re.compile(r"\bDocker\b", re.I)),
    ("PMP", re.compile(r"\b(?:PMP|Project Management Professional)\b", re.I)),
    ("CISSP", re.compile(r"\bCISSP\b", re.I)),
    ("CompTIA certification", re.compile(r"\b(?:CompTIA|Security\+|Network\+|A\+)\b", re.I)),
    ("clearance", re.compile(r"\b(?:security[ \t]+clearance|clearance|TS/SCI|top secret)\b", re.I)),
    ("professional certification", re.compile(r"\b(?:certified|certification)\b", re.I)),
    ("professional license", re.compile(r"\b(?:licensed|licensure)\b", re.I)),
    (
        "academic degree",
        re.compile(
            r"\b(?:associate(?:'s)?|bachelor(?:'s)?|master(?:'s)?|doctorate|Ph\.?D\.?|MBA)"
            r"(?:[ \t]+degree)?\b",
            re.I,
        ),
    ),
    ("language fluency", re.compile(r"\b(?:bilingual|fluent(?:ly)?)\b", re.I)),
    ("expert claim", re.compile(r"\b(?:expert|expertise|mastery)\b", re.I)),
    ("proven claim", re.compile(r"\bproven\b", re.I)),
    (
        "superlative claim",
        re.compile(r"\b(?:exceptional|award-winning|top-performing|highly skilled)\b", re.I),
    ),
    ("advanced proficiency", re.compile(r"\b(?:advanced proficiency|extensive experience)\b", re.I)),
]


def scan_resume_safety(
    ledger: list[EvidenceItem],
    *,
    full_text: str | None = None,
) -> list[SafetyFinding]:
    findings: list[SafetyFinding] = []
    for item in ledger:
        for code, title, pattern in SENSITIVE_PATTERNS:
            if pattern.search(item.text):
                findings.append(
                    SafetyFinding(
                        code=code,
                        severity=Severity.critical if code in {"ssn", "clearance_detail"} else Severity.warning,
                        title=title,
                        detail="Review and remove this information before sharing the resume or sending it to AI.",
                        evidence_id=item.id,
                    )
                )
    if full_text is not None:
        existing_codes = {finding.code for finding in findings}
        for finding in scan_text_safety(full_text):
            if finding.code not in existing_codes:
                findings.append(finding)
                existing_codes.add(finding.code)
    return findings


def scan_text_safety(text: str) -> list[SafetyFinding]:
    """Scan the complete text, independent of the bounded evidence ledger."""
    findings: list[SafetyFinding] = []
    seen_codes: set[str] = set()
    for code, title, pattern in SENSITIVE_PATTERNS:
        if code in seen_codes or not pattern.search(text):
            continue
        findings.append(
            SafetyFinding(
                code=code,
                severity=Severity.critical if code in {"ssn", "clearance_detail"} else Severity.warning,
                title=title,
                detail="Review and remove this information before sharing the resume or sending it to AI.",
                evidence_id=None,
            )
        )
        seen_codes.add(code)
    return findings


def require_safe_for_public_output(text: str) -> None:
    critical = [finding for finding in scan_text_safety(text) if finding.severity == Severity.critical]
    if critical:
        labels = ", ".join(dict.fromkeys(finding.title for finding in critical))
        raise ValueError(
            f"Export blocked by critical privacy or OPSEC finding: {labels}. "
            "Remove the sensitive content and run analysis again."
        )


def contains_sensitive_content(text: str) -> bool:
    return any(pattern.search(text) for _code, _title, pattern in SENSITIVE_PATTERNS)


def redact_for_ai(text: str) -> tuple[str, bool]:
    redacted = text
    changed = False
    for code, _title, pattern in SENSITIVE_PATTERNS:
        replacement = f"[REDACTED_{code.upper()}]"
        redacted, count = pattern.subn(replacement, redacted)
        changed = changed or count > 0
    redacted, count = re.subn(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b", "[REDACTED_EMAIL]", redacted)
    changed = changed or count > 0
    redacted, count = re.subn(r"\b(?:\+?1[-. ]?)?\(?\d{3}\)?[-. ]\d{3}[-. ]\d{4}\b", "[REDACTED_PHONE]", redacted)
    return redacted, changed or count > 0


def redacted_ledger(ledger: list[EvidenceItem]) -> list[EvidenceItem]:
    output: list[EvidenceItem] = []
    for item in ledger:
        text, changed = redact_for_ai(item.text)
        output.append(item.model_copy(update={"text": text, "redacted_for_ai": changed}))
    return output


def validate_proposal(
    proposal: ProposedEdit,
    ledger: list[EvidenceItem],
    *,
    target_title: str = "",
) -> tuple[bool, str]:
    lookup = evidence_map(ledger)
    if not proposal.evidence_ids:
        return False, "No source evidence was cited."
    if any(item_id not in lookup for item_id in proposal.evidence_ids):
        return False, "An evidence citation does not exist."
    if not proposal.proposed_text.strip() or proposal.proposed_text.strip() == proposal.original_text.strip():
        return False, "The proposal is empty or unchanged."

    cited_text = " ".join(lookup[item_id].text for item_id in proposal.evidence_ids)
    cited_items = [lookup[item_id] for item_id in proposal.evidence_ids]
    cited_resume_lines = [item.text for item in cited_items if item.source == "resume"]
    if cited_resume_lines:
        if len(cited_items) != 1:
            return False, "A resume rewrite must cite exactly one source line and may not recombine claims."
        if not any(_normalized_phrase(proposal.original_text) == _normalized_phrase(line) for line in cited_resume_lines):
            return False, "The proposal does not cite the resume line it would replace."
    else:
        if len(cited_items) != 1:
            return False, "A profile-backed insertion must cite exactly one explicit service record."
        if not proposal.proposed_text.startswith(f"{proposal.original_text}\n"):
            return False, "A profile-backed proposal may only insert text after its existing resume anchor."

    missing_qualifier = missing_claim_qualifier(proposal.original_text, proposal.proposed_text)
    if missing_qualifier:
        return False, f"Proposal drops a source qualifier ({missing_qualifier})."

    normalized_title = _normalized_phrase(target_title)
    normalized_proposal = _normalized_phrase(proposal.proposed_text)
    normalized_evidence = _normalized_phrase(cited_text)
    if normalized_title and normalized_title in normalized_proposal and normalized_title not in normalized_evidence:
        return False, "Proposal copies the target job title without supporting evidence."

    unsupported_numbers = numbers(proposal.proposed_text) - numbers(cited_text)
    if unsupported_numbers:
        return False, f"Unsupported numeric claim: {', '.join(sorted(unsupported_numbers))}."

    for label, pattern in HIGH_RISK_CLAIM_GROUPS:
        if pattern.search(proposal.proposed_text) and not pattern.search(cited_text):
            return False, f"Unsupported high-risk qualitative claim: {label}."

    for code, _title, pattern in SENSITIVE_PATTERNS:
        if pattern.search(proposal.proposed_text):
            return False, f"Proposal contains sensitive information ({code})."
    return True, ""


def _normalized_phrase(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().casefold()
