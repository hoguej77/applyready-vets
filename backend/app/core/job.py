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

# These terms come from career-site chrome, legal copy, URLs, and general job-board
# boilerplate. They are not useful evidence gaps and should never become a question
# such as "Do you have experience with https?".
KEYWORD_NOISE = {
    "https", "http", "www", "com", "us", "benefits", "employment", "opportunity",
    "commitment", "united", "states", "professional", "other", "all", "companies",
    "equal", "protected", "required", "requirements", "qualifications", "responsibilities",
    "description", "overview", "apply", "application", "applicants", "career", "careers",
    "jobs", "privacy", "terms", "copyright", "rights", "reserved",
    # Generic prose and opaque query-string fragments are not a candidate's
    # experience gap. Keep concrete technical/domain terms instead.
    "information", "findings", "management", "into", "content", "appropriate", "knowledge",
    "strong", "ability", "id", "c0", "relevant", "synthesize", "maintain", "sources",
    "statements", "complex", "clear", "written", "support", "related", "technical",
}

ROLE_SECTION_STARTS = {"responsibilities", "qualifications", "what you will do", "what you'll do"}
ROLE_SECTION_ENDS = {
    "benefits", "the company", "industry recognition", "how to apply", "commitment equal opportunity",
    "accommodations", "equal opportunity employment", "faq",
}


def analyze_job(job_text: str, resume_text: str) -> JobAnalysis:
    lines = normalized_lines(job_text)
    company = _field(job_text, r"Company\s*[:\-]\s*([^\n]+)")
    title = _field(job_text, r"(?:Job\s*Title|Title)\s*[:\-]\s*([^\n]+)")
    if not title and lines:
        title = lines[0][:100]

    role_lines = _role_content(lines)
    requirements = [line[:500] for line in role_lines if _looks_like_requirement(line)][:12]
    excluded_tokens = KEYWORD_NOISE | set(clean_company_tokens(company)) | set(clean_company_tokens(title))
    keywords = [
        keyword
        for keyword in ranked_keywords("\n".join(role_lines), 60)
        if keyword not in excluded_tokens and not keyword.startswith(("http", "www")) and "." not in keyword
    ][:30]
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


def _role_content(lines: list[str]) -> list[str]:
    """Keep duties and qualifications while discarding careers-site boilerplate."""
    selected: list[str] = []
    in_role_section = False
    found_role_section = False
    for line in lines:
        normalized = line.casefold().rstrip(":")
        if normalized in ROLE_SECTION_STARTS:
            in_role_section = True
            found_role_section = True
            continue
        if in_role_section and any(normalized.startswith(marker) for marker in ROLE_SECTION_ENDS):
            break
        if in_role_section and not re.search(r"https?://|www\.", line, re.I):
            selected.append(line)

    if found_role_section:
        return selected

    # Small copied job posts often do not retain headings. In that case, still
    # reject headers, veteran-eligibility notices, and URL-heavy boilerplate.
    return [
        line
        for line in lines
        if not re.match(r"^(?:company|job\s*title|title)\s*[:\-]", line, re.I)
        and not re.search(r"\b(?:open to veterans|vra|veoa|veterans'? preference)\b", line, re.I)
        and not re.search(r"https?://|www\.", line, re.I)
    ]


def _looks_like_requirement(line: str) -> bool:
    return bool(re.search(
        r"^(?:\d+\+?\s+years?\b|strong\b|demonstrated\b|ability\b|experience\b|"
        r"familiarity\b|knowledge\b|u\.?s\.?\s+citizen\b|willing\b|must\b|minimum\b)",
        line,
        re.I,
    ))


def clean_company_tokens(value: str) -> list[str]:
    return [token for token in re.findall(r"[A-Za-z][A-Za-z0-9+#./-]{1,}", value.casefold())]


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
