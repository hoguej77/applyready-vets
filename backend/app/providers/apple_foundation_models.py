from __future__ import annotations

import json
import subprocess
import uuid
from functools import lru_cache
from pathlib import Path

from app.models import EvidenceItem, JobAnalysis, ProposedEdit, ResumeMode
from app.providers.base import AIProposalEnvelope, PROMPT_VERSION, SYSTEM_INSTRUCTIONS


APPLE_FM_EXECUTABLE = Path("/usr/bin/fm")
APPLE_FM_SCHEMA = Path(__file__).with_name("apple_fm_schema.json")


class AppleFoundationModelProvider:
    """Use the Apple Intelligence system model locally on macOS 27."""

    name = "apple-foundation-models:system"

    def __init__(self, timeout_seconds: int = 90, max_prompt_chars: int = 12_000):
        self.timeout_seconds = timeout_seconds
        self.max_prompt_chars = max_prompt_chars

    @staticmethod
    @lru_cache(maxsize=1)
    def is_available() -> bool:
        if not APPLE_FM_EXECUTABLE.is_file():
            return False
        try:
            result = subprocess.run(
                [str(APPLE_FM_EXECUTABLE), "available"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            return False
        return "System model available" in f"{result.stdout}\n{result.stderr}"

    def propose(
        self,
        evidence: list[EvidenceItem],
        job: JobAnalysis,
        job_text: str,
        mode: ResumeMode,
    ) -> list[ProposedEdit]:
        del job_text  # The compact job analysis keeps the on-device prompt within its smaller context window.
        payload = self._compact_payload(evidence, job, mode)
        result = subprocess.run(
            [
                str(APPLE_FM_EXECUTABLE),
                "respond",
                "--no-stream",
                "--greedy",
                "--guardrails",
                "permissive-content-transformations",
                "--schema",
                str(APPLE_FM_SCHEMA),
                "--instructions",
                SYSTEM_INSTRUCTIONS,
            ],
            input=json.dumps(payload, ensure_ascii=False),
            capture_output=True,
            text=True,
            timeout=self.timeout_seconds,
            check=False,
        )
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()
            raise RuntimeError(f"Apple Foundation Models failed: {detail[-500:]}")

        envelope = AIProposalEnvelope.model_validate_json(self._json_object(result.stdout))
        return [
            ProposedEdit(
                id=str(uuid.uuid4()),
                section=item.section,
                original_text=item.original_text,
                proposed_text=item.proposed_text,
                rationale=item.rationale,
                evidence_ids=item.evidence_ids,
                confidence=item.confidence,
                source="apple",
            )
            for item in envelope.proposals[:8]
        ]

    def _compact_payload(
        self,
        evidence: list[EvidenceItem],
        job: JobAnalysis,
        mode: ResumeMode,
    ) -> dict:
        payload = {
            "prompt_version": PROMPT_VERSION,
            "data_classification": "UNTRUSTED_CANDIDATE_AND_JOB_DATA",
            "mode": mode.value,
            "job_analysis": {
                "company": job.company,
                "title": job.title,
                "keywords": job.keywords[:24],
                "required_qualifications": job.required_qualifications[:16],
                "missing_keywords": job.missing_keywords[:16],
                "federal": job.federal,
            },
            "candidate_evidence": [],
        }
        used = len(json.dumps(payload, ensure_ascii=False))
        for item in evidence:
            candidate = {
                "id": item.id,
                "source": item.source,
                "section": item.section,
                "text": item.text,
            }
            size = len(json.dumps(candidate, ensure_ascii=False))
            if used + size > self.max_prompt_chars:
                break
            payload["candidate_evidence"].append(candidate)
            used += size
        return payload

    @staticmethod
    def _json_object(output: str) -> str:
        start = output.find("{")
        end = output.rfind("}")
        if start == -1 or end <= start:
            raise ValueError("Apple Foundation Models returned no structured JSON object")
        return output[start : end + 1]
