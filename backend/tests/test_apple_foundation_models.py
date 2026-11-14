from __future__ import annotations

import json
import os
import subprocess
import unittest
from unittest.mock import patch

from app.config import Settings
from app.models import EvidenceItem, JobAnalysis, ResumeMode
from app.providers.base import PROMPT_VERSION
from app.providers.apple_foundation_models import AppleFoundationModelProvider


class AppleFoundationModelsTests(unittest.TestCase):
    def setUp(self) -> None:
        # app.main can initialize a tailoring service during test collection,
        # which otherwise leaves the platform-availability result cached.
        AppleFoundationModelProvider.is_available.cache_clear()

    def tearDown(self) -> None:
        AppleFoundationModelProvider.is_available.cache_clear()

    @patch("app.providers.apple_foundation_models.subprocess.run")
    @patch("app.providers.apple_foundation_models.APPLE_FM_EXECUTABLE")
    def test_availability_accepts_system_model_when_pcc_is_unavailable(self, executable, run):
        executable.is_file.return_value = True
        executable.__str__.return_value = "/usr/bin/fm"
        run.return_value = subprocess.CompletedProcess(
            args=["fm", "available"],
            returncode=1,
            stdout="System model available\n",
            stderr="Private Cloud Compute is not available in this context.",
        )

        self.assertTrue(AppleFoundationModelProvider.is_available())

    @patch("app.providers.apple_foundation_models.subprocess.run")
    def test_structured_result_becomes_truth_lock_candidate(self, run):
        output = {
            "proposals": [
                {
                    "section": "experience",
                    "original_text": "Led 12 personnel.",
                    "proposed_text": "Led a 12-person operations team.",
                    "rationale": "Uses civilian leadership language.",
                    "evidence_ids": ["resume:001"],
                    "confidence": 0.86,
                }
            ]
        }
        run.return_value = subprocess.CompletedProcess(
            args=["fm", "respond"],
            returncode=0,
            stdout=json.dumps(output),
            stderr="",
        )
        provider = AppleFoundationModelProvider()
        proposals = provider.propose(
            evidence=[
                EvidenceItem(
                    id="resume:001",
                    source="resume",
                    section="experience",
                    text="Led 12 personnel.",
                )
            ],
            job=JobAnalysis(title="Operations Manager"),
            job_text="Operations Manager",
            mode=ResumeMode.civilian,
        )

        self.assertEqual(len(proposals), 1)
        self.assertEqual(proposals[0].source, "apple")
        self.assertEqual(proposals[0].evidence_ids, ["resume:001"])
        self.assertNotIn("Led 12 personnel.", run.call_args.args[0])
        self.assertIn("resume:001", run.call_args.kwargs["input"])
        prompt_payload = json.loads(run.call_args.kwargs["input"])
        self.assertEqual(prompt_payload["prompt_version"], PROMPT_VERSION)
        self.assertEqual(
            prompt_payload["data_classification"],
            "UNTRUSTED_CANDIDATE_AND_JOB_DATA",
        )

    def test_compact_payload_respects_local_context_budget(self):
        provider = AppleFoundationModelProvider(max_prompt_chars=450)
        evidence = [
            EvidenceItem(
                id=f"resume:{index:03}",
                source="resume",
                section="experience",
                text="A" * 220,
            )
            for index in range(1, 10)
        ]
        payload = provider._compact_payload(
            evidence=evidence,
            job=JobAnalysis(title="Operations Manager"),
            mode=ResumeMode.civilian,
        )

        self.assertLess(len(payload["candidate_evidence"]), len(evidence))

    def test_unknown_provider_value_falls_back_to_auto(self):
        with patch.dict(os.environ, {"HOGUE_AI_PROVIDER": "not-a-provider"}):
            self.assertEqual(Settings.from_environment().ai_provider, "auto")


if __name__ == "__main__":
    unittest.main()
