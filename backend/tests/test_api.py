from __future__ import annotations

import os
import unittest
import zipfile
from dataclasses import replace
from io import BytesIO
from unittest.mock import patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

import app.main as main_module
from app.main import app


RESUME = """Taylor Veteran
MILITARY EXPERIENCE
Operations NCOIC, 2020–2024
Led 12 personnel and maintained 98% equipment readiness.
MOS 88M
"""

JOB = """Company: Acme Logistics
Title: Fleet Operations Manager
Required: logistics, fleet readiness, and team leadership.
This job is open to Veterans under VRA.
"""


class APITests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_token = os.environ["HOGUE_TEST_API_TOKEN"]
        cls.client = TestClient(app, headers={"Authorization": f"Bearer {test_token}"})

    def analyze_payload(self) -> dict:
        response = self.client.post(
            "/v1/analyze",
            json={
                "resume_text": RESUME,
                "job_text": JOB,
                "profile": {"full_name": "Taylor Veteran", "target_role": "Fleet Operations Manager"},
                "mode": "auto",
                "use_ai": False,
                "ai_consent": False,
            },
        )
        self.assertEqual(response.status_code, 200, response.text)
        return response.json()

    def export_payload(self, analysis: dict) -> dict:
        return {
            "resume_text": RESUME,
            "response": analysis,
            "candidate_name": "Taylor Veteran",
            "include_workday": True,
            "profile": {"full_name": "Taylor Veteran", "target_role": "Fleet Operations Manager"},
        }

    def test_health_contract(self):
        response = self.client.get("/v1/health")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["truth_lock"])

    def test_production_service_fails_closed_without_authentication_secret(self):
        production_without_token = replace(
            main_module.settings,
            environment="production",
            api_token="",
        )
        with patch.object(main_module, "settings", production_without_token):
            with self.assertRaises(HTTPException) as raised:
                main_module.authorize(None)
        self.assertEqual(raised.exception.status_code, 503)

    def test_analyze_and_linkedin_contract(self):
        analysis = self.analyze_payload()
        self.assertEqual(analysis["engine"], "deterministic")
        response = self.client.post("/v1/linkedin", json=self.export_payload(analysis))
        self.assertEqual(response.status_code, 200, response.text)
        kit = response.json()
        self.assertTrue(kit["headline_options"])
        self.assertGreater(len(kit["about_text"]), 40)
        self.assertTrue(kit["skills"])
        self.assertIn("does not sign in", kit["disclaimer"])

    def test_extract_upload_contract(self):
        response = self.client.post(
            "/v1/extract",
            files={"file": ("resume.txt", RESUME.encode("utf-8"), "text/plain")},
        )
        self.assertEqual(response.status_code, 200, response.text)
        self.assertIn("Led 12 personnel", response.json()["text"])

    def test_export_rejects_tampered_approved_edit(self):
        analysis = self.analyze_payload()
        self.assertTrue(analysis["proposals"])
        analysis["proposals"][0]["status"] = "edited"
        analysis["proposals"][0]["edited_text"] = "Led 500 people with 100% success."
        response = self.client.post("/v1/export", json=self.export_payload(analysis))
        self.assertEqual(response.status_code, 422, response.text)
        self.assertIn("Truth Lock rejected", response.json()["detail"])

    def test_export_includes_veteran_outreach_packet(self):
        analysis = self.analyze_payload()
        payload = self.export_payload(analysis)
        payload["profile"]["military_service"] = [{
            "branch": "Army",
            "component": "National Guard",
            "rank": "Sergeant",
            "pay_grade": "E-5",
            "occupation_code": "88M",
            "occupation_title": "Motor Transport Operator",
        }]
        # Planning materials are deliberately separated from the employer-facing
        # application ZIP. Request the explicit private archive rather than
        # risking college, veteran-status, or strategy material being sent to an
        # employer with the resume.
        payload["private_candidate_export"] = True
        response = self.client.post("/v1/export/private", json=payload)
        self.assertEqual(response.status_code, 200, response.text)
        with zipfile.ZipFile(BytesIO(response.content)) as archive:
            names = set(archive.namelist())
            self.assertIn("Taylor_Veteran_Veteran_Promotion_Packet.txt", names)
            self.assertIn("Taylor_Veteran_Employer_Outreach_Letter.txt", names)
            self.assertIn("Taylor_Veteran_College_Credit_Review_Request.txt", names)
            self.assertIn("Taylor_Veteran_College_Extension_Request.txt", names)
            self.assertIn("Taylor_Veteran_JOFDAV_Job_Board_Strategy.txt", names)
            self.assertIn("Taylor_Veteran_Federal_Career_Strategy.txt", names)
            self.assertIn("Taylor_Veteran_USAJOBS_Resume_Checklist.txt", names)
            self.assertIn("Taylor_Veteran_Executive_Clearance_LinkedIn_Notes.txt", names)
            packet = archive.read("Taylor_Veteran_Veteran_Promotion_Packet.txt").decode("utf-8")
            self.assertIn("Army", packet)
            self.assertIn("National Guard", packet)
            self.assertIn("operations", packet.lower())
            usajobs = archive.read("Taylor_Veteran_USAJOBS_Resume_Checklist.txt").decode("utf-8")
            self.assertIn("Two pages or less", usajobs)
            self.assertIn("Social Security number", usajobs)


if __name__ == "__main__":
    unittest.main()
