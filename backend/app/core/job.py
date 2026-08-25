from __future__ import annotations

import re

from app.core.text import affirmed_tokens, normalized_lines, ranked_keywords
from app.models import GapQuestion, JobAnalysis


SCAM_PATTERNS = {
    "upfront_fee": re.compile(r"(?:pay|payment).*(?:application|training|setup|before.*start)", re.I),
    "messaging_interview": re.compile(
        r"(?:(?:telegram|whatsapp).{0,30}(?:interview|chat|hr)|(?:interview|chat|hr).{0,30}(?:telegram|whatsapp))",
        re.I,
    ),
    "remote_access": re.compile(r"(?:install|download).*(?:anydesk|teamviewer|remote access)", re.I),
    "bank_or_ssn": re.compile(r"(?:ssn|social security|bank info|routing number|account number)", re.I),
    "gift_crypto_wire": re.compile(r"(?:gift card|bitcoin|crypto|wire transfer)", re.I),
}


def analyze_job(job_text: str, resume_text: str) -> JobAnalysis:
    lines = normalized_lines(job_text)
    company = _field(job_text, r"Company\s*[:\-]\s*([^\n]+)")
    title = _field(job_text, r"(?:Job\s*Title|Title)\s*[:\-]\s*([^\n]+)")
    if not title and lines:
        title = lines[0][:100]

    requirements = [
        line[:500]
        for line in lines
        if re.search(r"\b(?:required|requirements|must have|minimum qualification|specialized experience)\b", line, re.I)
    ][:12]
    keyword_lines = [
        line
        for line in lines
        if not re.match(r"^(?:company|job\s*title|title)\s*[:\-]", line, re.I)
        and not re.search(
            r"\b(?:open to veterans|veterans recruitment appointment|vra|veoa|veterans'? preference)\b",
            line,
            re.I,
        )
    ]
    keywords = ranked_keywords("\n".join(keyword_lines), 30)
    resume_tokens = set(affirmed_tokens(resume_text))
    missing = [token for token in keywords if token not in resume_tokens][:12]
    lower = job_text.lower()
    risks = [name for name, pattern in SCAM_PATTERNS.items() if pattern.search(job_text)]
    return JobAnalysis(
        company=company,
        title=title,
        keywords=keywords,
        required_qualifications=requirements,
        missing_keywords=missing,
        federal=any(term in lower for term in ("usajobs", "specialized experience", "gs-", "federal service")),
        open_to_veterans=any(term in lower for term in (
            "open to veterans", "veterans recruitment appointment", "vra", "veoa", "veterans' preference",
            "veterans preference", "30% or more disabled veteran",
        )),
        risk_flags=risks,
    )


def build_gap_questions(job: JobAnalysis, limit: int = 6) -> list[GapQuestion]:
    questions: list[GapQuestion] = []
    for index, term in enumerate(job.missing_keywords[:limit]):
        questions.append(
            GapQuestion(
                requirement=term,
                question=f"Do you have documented military, civilian, volunteer, or training experience with {term}?",
                priority="high" if index < 2 else "medium",
            )
        )
    return questions


def _field(text: str, pattern: str) -> str:
    match = re.search(pattern, text, re.I)
    return match.group(1).strip()[:120] if match else ""
