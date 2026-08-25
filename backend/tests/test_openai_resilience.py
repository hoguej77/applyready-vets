from __future__ import annotations

import json
from types import SimpleNamespace

import pytest

from app.models import EvidenceItem, JobAnalysis, ResumeMode
from app.providers.base import AIEdit, AIProposalEnvelope, PROMPT_VERSION, SYSTEM_INSTRUCTIONS
from app.providers.openai_provider import OpenAIProposalProvider, OpenAIProviderCircuitOpen


class FakeResponses:
    def __init__(self):
        self.calls: list[dict] = []
        self.result = None
        self.error: Exception | None = RuntimeError("temporary outage")

    def parse(self, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        return SimpleNamespace(output_parsed=self.result)


class FakeClient:
    def __init__(self):
        self.responses = FakeResponses()


def inputs() -> tuple[list[EvidenceItem], JobAnalysis]:
    evidence = [
        EvidenceItem(
            id="resume:001",
            source="resume",
            section="experience",
            text="Led 12 people.",
        )
    ]
    job = JobAnalysis(title="Operations Manager", keywords=["leadership"])
    return evidence, job


def test_provider_opens_bounded_circuit_and_recovers():
    clock = [100.0]
    client = FakeClient()
    provider = OpenAIProposalProvider(
        api_key="test-only",
        model="test-model",
        client=client,
        failure_threshold=2,
        cooldown_seconds=30,
        monotonic=lambda: clock[0],
    )
    evidence, job = inputs()

    with pytest.raises(RuntimeError, match="temporary outage"):
        provider.propose(evidence, job, "Required: leadership", ResumeMode.civilian)
    with pytest.raises(RuntimeError, match="temporary outage"):
        provider.propose(evidence, job, "Required: leadership", ResumeMode.civilian)
    assert len(client.responses.calls) == 2

    with pytest.raises(OpenAIProviderCircuitOpen):
        provider.propose(evidence, job, "Required: leadership", ResumeMode.civilian)
    assert len(client.responses.calls) == 2

    clock[0] += 31
    client.responses.error = None
    client.responses.result = AIProposalEnvelope(
        proposals=[
            AIEdit(
                section="experience",
                original_text="Led 12 people.",
                proposed_text="Led a 12-person team.",
                rationale="Clearer wording.",
                evidence_ids=["resume:001"],
                confidence=0.9,
            )
        ]
    )
    proposals = provider.propose(
        evidence,
        job,
        "Required: leadership",
        ResumeMode.civilian,
    )

    assert len(proposals) == 1
    assert provider.circuit_open is False
    assert client.responses.calls[-1]["store"] is False
    assert client.responses.calls[-1]["max_output_tokens"] == 4_000
    assert client.responses.calls[-1]["text_format"] is AIProposalEnvelope
    request_input = client.responses.calls[-1]["input"]
    assert request_input[0] == {"role": "system", "content": SYSTEM_INSTRUCTIONS}
    payload = json.loads(request_input[1]["content"])
    assert payload["prompt_version"] == PROMPT_VERSION
    assert payload["data_classification"] == "UNTRUSTED_CANDIDATE_AND_JOB_DATA"
