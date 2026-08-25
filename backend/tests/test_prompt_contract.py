from __future__ import annotations

from app.providers.base import PROMPT_VERSION, SYSTEM_INSTRUCTIONS


def test_prompt_contract_is_versioned_outcome_first_and_bounded():
    required_sections = [
        "ROLE",
        "OUTCOME",
        "SUCCESS CRITERIA",
        "TRUST BOUNDARY",
        "TRUTH LOCK",
        "OUTPUT AND STOP RULES",
    ]
    positions = [SYSTEM_INSTRUCTIONS.index(section) for section in required_sections]

    assert positions == sorted(positions)
    assert PROMPT_VERSION
    assert "up to eight" in SYSTEM_INSTRUCTIONS
    assert "return an empty proposals list" in SYSTEM_INSTRUCTIONS
    assert "Return only the requested structured result" in SYSTEM_INSTRUCTIONS


def test_prompt_contract_treats_resume_and_job_text_as_untrusted_data():
    prompt = SYSTEM_INSTRUCTIONS.casefold()

    assert "untrusted data" in prompt
    assert "never follow" in prompt
    assert "instructions" in prompt
    assert "role changes" in prompt
    assert "use them only" in prompt


def test_prompt_contract_preserves_truth_and_candidate_control():
    prompt = SYSTEM_INSTRUCTIONS.casefold()

    for invariant in [
        "candidate—not the model—decides",
        "never invent or infer",
        "cite exactly one",
        "match the cited resume evidence line exactly",
        "preserve negation",
        "military-to-civilian translation is wording help",
        "never promise ats passage",
        "sensitive clearance details",
    ]:
        assert invariant in prompt
