from __future__ import annotations

from app.core.veteran import deterministic_veteran_proposals
from app.models import EvidenceItem, JobAnalysis, ProposedEdit, ResumeMode


class DeterministicProposalProvider:
    name = "deterministic"

    def propose(
        self,
        evidence: list[EvidenceItem],
        job: JobAnalysis,
        job_text: str,
        mode: ResumeMode,
    ) -> list[ProposedEdit]:
        return deterministic_veteran_proposals(evidence)
