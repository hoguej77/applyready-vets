from __future__ import annotations

import json
import threading
import time
import uuid
from typing import Any, Callable

from app.models import EvidenceItem, JobAnalysis, ProposedEdit, ResumeMode
from app.providers.base import AIProposalEnvelope, PROMPT_VERSION, SYSTEM_INSTRUCTIONS


class OpenAIProposalProvider:
    def __init__(
        self,
        api_key: str,
        model: str,
        *,
        timeout_seconds: float = 30.0,
        max_retries: int = 2,
        max_output_tokens: int = 4_000,
        failure_threshold: int = 3,
        cooldown_seconds: float = 60.0,
        client: Any | None = None,
        monotonic: Callable[[], float] = time.monotonic,
    ):
        if client is None:
            try:
                from openai import OpenAI
            except ImportError as exc:  # pragma: no cover - dependency is installed in production
                raise RuntimeError("The openai package is not installed") from exc
            client = OpenAI(
                api_key=api_key,
                timeout=max(5.0, min(60.0, timeout_seconds)),
                max_retries=max(0, min(3, max_retries)),
            )
        self._client = client
        self._model = model
        self._max_output_tokens = max(500, min(8_000, max_output_tokens))
        self._failure_threshold = max(1, min(5, failure_threshold))
        self._cooldown_seconds = max(10.0, min(300.0, cooldown_seconds))
        self._monotonic = monotonic
        self._consecutive_failures = 0
        self._circuit_open_until = 0.0
        self._lock = threading.Lock()
        self.name = f"openai:{model}"

    @property
    def circuit_open(self) -> bool:
        with self._lock:
            return self._monotonic() < self._circuit_open_until

    def propose(
        self,
        evidence: list[EvidenceItem],
        job: JobAnalysis,
        job_text: str,
        mode: ResumeMode,
    ) -> list[ProposedEdit]:
        with self._lock:
            if self._monotonic() < self._circuit_open_until:
                raise OpenAIProviderCircuitOpen(
                    "OpenAI fallback is cooling down after repeated transient failures"
                )

        payload = {
            "prompt_version": PROMPT_VERSION,
            "data_classification": "UNTRUSTED_CANDIDATE_AND_JOB_DATA",
            "mode": mode.value,
            "job_analysis": job.model_dump(),
            "job_posting": job_text[:60_000],
            "candidate_evidence": [item.model_dump() for item in evidence],
        }
        try:
            response = self._client.responses.parse(
                model=self._model,
                store=False,
                max_output_tokens=self._max_output_tokens,
                reasoning={"effort": "low"},
                input=[
                    {"role": "system", "content": SYSTEM_INSTRUCTIONS},
                    {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
                ],
                text_format=AIProposalEnvelope,
            )
        except Exception:
            with self._lock:
                self._consecutive_failures += 1
                if self._consecutive_failures >= self._failure_threshold:
                    self._circuit_open_until = self._monotonic() + self._cooldown_seconds
            raise

        with self._lock:
            self._consecutive_failures = 0
            self._circuit_open_until = 0.0
        envelope = response.output_parsed
        if envelope is None:
            return []
        return [
            ProposedEdit(
                id=str(uuid.uuid4()),
                section=item.section,
                original_text=item.original_text,
                proposed_text=item.proposed_text,
                rationale=item.rationale,
                evidence_ids=item.evidence_ids,
                confidence=item.confidence,
                source="openai",
            )
            for item in envelope.proposals[:8]
        ]


class OpenAIProviderCircuitOpen(RuntimeError):
    """Raised before a paid request while the bounded provider circuit is cooling down."""
