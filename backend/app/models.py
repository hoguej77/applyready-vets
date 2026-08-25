from __future__ import annotations

from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field, model_validator


class ResumeMode(str, Enum):
    auto = "auto"
    civilian = "civilian"
    federal = "federal"
    healthcare = "healthcare"
    education = "education"


class ProposalStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    edited = "edited"


class Severity(str, Enum):
    info = "info"
    warning = "warning"
    critical = "critical"


class MilitaryService(BaseModel):
    branch: str = ""
    component: str = ""
    rank: str = ""
    pay_grade: str = ""
    occupation_code: str = ""
    occupation_title: str = ""
    service_start: str = ""
    service_end: str = ""


class CandidateProfile(BaseModel):
    full_name: str = ""
    email: str = ""
    phone: str = ""
    location: str = ""
    linkedin: str = ""
    target_role: str = ""
    military_service: list[MilitaryService] = Field(default_factory=list)
    military_spouse: bool = False


class EvidenceItem(BaseModel):
    id: str
    source: Literal["resume", "profile", "veteran_input"]
    section: str
    text: str
    redacted_for_ai: bool = False


class SafetyFinding(BaseModel):
    code: str
    severity: Severity
    title: str
    detail: str
    evidence_id: str | None = None


class ProposedEdit(BaseModel):
    id: str
    section: str
    original_text: str
    proposed_text: str
    rationale: str
    evidence_ids: list[str]
    confidence: float = Field(ge=0, le=1)
    status: ProposalStatus = ProposalStatus.pending
    edited_text: str | None = None
    source: Literal["deterministic", "openai", "apple"] = "deterministic"


class GapQuestion(BaseModel):
    requirement: str
    question: str
    priority: Literal["high", "medium", "low"] = "medium"


class JobAnalysis(BaseModel):
    company: str = ""
    title: str = ""
    keywords: list[str] = Field(default_factory=list)
    required_qualifications: list[str] = Field(default_factory=list)
    missing_keywords: list[str] = Field(default_factory=list)
    federal: bool = False
    open_to_veterans: bool = False
    risk_flags: list[str] = Field(default_factory=list)


class ReadinessScores(BaseModel):
    qualification_coverage: int = Field(ge=0, le=100)
    evidence_strength: int = Field(ge=0, le=100)
    acronym_clarity: int = Field(ge=0, le=100)
    application_readiness: int = Field(ge=0, le=100)
    disclaimer: str = "Readiness checks are guidance, not an ATS simulation or hiring prediction."


class TailorRequest(BaseModel):
    resume_text: str = Field(min_length=1, max_length=200_000)
    job_text: str = Field(min_length=1, max_length=200_000)
    profile: CandidateProfile = Field(default_factory=CandidateProfile)
    mode: ResumeMode = ResumeMode.auto
    use_ai: bool = False
    ai_consent: bool = False

    @model_validator(mode="after")
    def validate_ai_consent(self) -> "TailorRequest":
        if self.use_ai and not self.ai_consent:
            raise ValueError("ai_consent must be true before resume content is sent to the AI provider")
        return self


class TailorResponse(BaseModel):
    analysis_id: str
    engine: str
    evidence: list[EvidenceItem]
    job: JobAnalysis
    proposals: list[ProposedEdit]
    gap_questions: list[GapQuestion]
    safety_findings: list[SafetyFinding]
    integrity_warnings: list[str]
    scores: ReadinessScores


class DocumentExtraction(BaseModel):
    filename: str
    text: str
    warnings: list[str] = Field(default_factory=list)


class URLExtractionRequest(BaseModel):
    url: str = Field(min_length=8, max_length=2_000)


class ExportRequest(BaseModel):
    resume_text: str = Field(min_length=1, max_length=200_000)
    response: TailorResponse
    candidate_name: str = "Veteran"
    include_workday: bool = False
    include_employer_cover_letter: bool = False
    profile: CandidateProfile = Field(default_factory=CandidateProfile)


class PrivateExportRequest(ExportRequest):
    private_candidate_export: Literal[True]


class LinkedInProfileKit(BaseModel):
    headline_options: list[str]
    about_text: str
    skills: list[str]
    experience_highlights: list[str]
    featured_ideas: list[str]
    connection_message: str
    recruiter_message: str
    checklist: list[str]
    disclaimer: str
