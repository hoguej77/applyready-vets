from __future__ import annotations

import re

from app.core.text import affirmed_tokens, clean_tokens
from app.models import EvidenceItem, JobAnalysis, ReadinessScores, SafetyFinding


ACTION_VERBS = {
    "led", "managed", "trained", "planned", "delivered", "improved", "reduced", "increased", "built",
    "maintained", "coordinated", "supervised", "analyzed", "implemented", "operated", "developed",
}


def readiness_scores(
    resume_text: str,
    job: JobAnalysis,
    ledger: list[EvidenceItem],
    safety_findings: list[SafetyFinding],
) -> ReadinessScores:
    resume_tokens = set(affirmed_tokens(resume_text))
    job_tokens = set(job.keywords)
    coverage = round(100 * len(resume_tokens & job_tokens) / max(1, len(job_tokens)))

    strong_lines = 0
    for item in ledger:
        line_tokens = set(clean_tokens(item.text))
        if line_tokens & ACTION_VERBS and re.search(r"\d|%|\$", item.text):
            strong_lines += 1
    evidence_strength = min(100, round(100 * strong_lines / max(1, min(8, len(ledger)))))

    all_caps = re.findall(r"\b[A-Z][A-Z0-9/+-]{2,}\b", resume_text)
    explained = sum(1 for acronym in all_caps if re.search(rf"[A-Za-z ]+\({re.escape(acronym)}\)", resume_text))
    acronym_clarity = 100 if not all_caps else round(100 * explained / len(all_caps))

    penalty = min(40, len(safety_findings) * 10)
    readiness = max(0, round((coverage + evidence_strength + acronym_clarity) / 3) - penalty)
    return ReadinessScores(
        qualification_coverage=coverage,
        evidence_strength=evidence_strength,
        acronym_clarity=acronym_clarity,
        application_readiness=readiness,
    )
