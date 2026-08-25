from __future__ import annotations

import re

from app.core.safety import redact_for_ai, require_safe_for_public_output
from app.core.text import affirmed_tokens, normalized_lines
from app.models import ExportRequest, LinkedInProfileKit


NOISE = {
    "company", "title", "apply", "applicant", "candidate", "employment", "employer", "benefits",
    "salary", "location", "equal", "opportunity", "acme", "full-time", "part-time",
}
ACTION_PATTERN = re.compile(
    r"\b(?:led|managed|maintained|created|developed|improved|reduced|increased|trained|coordinated|"
    r"supervised|delivered|implemented|supported|analyzed|operated|planned|directed)\b",
    re.I,
)


def build_linkedin_kit(request: ExportRequest, final_resume_text: str) -> LinkedInProfileKit:
    require_safe_for_public_output(request.resume_text)
    require_safe_for_public_output(final_resume_text)
    job = request.response.job
    target = request.profile.target_role.strip() or job.title.strip() or "Your Target Role"
    verified_resume_tokens = set(affirmed_tokens(final_resume_text))
    matched = [
        token for token in job.keywords
        if (
            token.casefold() in verified_resume_tokens
            and token.casefold() not in NOISE
            and len(token) > 2
        )
    ]
    skills = [_display_skill(item) for item in matched[:15]]
    core = skills[:4]
    suffix = " | ".join(core)
    base_headline = f"{target} | {suffix}" if suffix else target

    # Veteran identity is a user-controlled public disclosure. Do not infer it
    # from free text (which could describe a spouse, family member, or employer).
    veteran = any(
        any(
            value.strip()
            for value in (
                service.branch,
                service.component,
                service.rank,
                service.pay_grade,
                service.occupation_code,
                service.occupation_title,
                service.service_start,
                service.service_end,
            )
        )
        for service in request.profile.military_service
    )
    headlines = [_limit(base_headline, 200)]
    if veteran:
        veteran_headline = f"Military Veteran | {target}"
        if suffix:
            veteran_headline += f" | {suffix}"
        headlines.append(_limit(veteran_headline, 200))
    if job.company:
        headlines.append(_limit(f"Exploring {target} Opportunities | {suffix}" if suffix else f"Exploring {target} Opportunities", 200))
    headlines = list(dict.fromkeys(headlines))

    skill_phrase = _human_list(core)
    identity = "military experience" if veteran else "professional experience"
    highlights = _experience_highlights(final_resume_text)
    about = f"I am a professional targeting {target} opportunities. My {identity}"
    if skill_phrase:
        about += f" includes evidence-backed work involving {skill_phrase}"
    about += "."
    if highlights:
        about += " Selected experience highlights include: " + " ".join(highlights[:2])

    featured = [
        "A sanitized work sample or project summary that demonstrates one verified skill",
        "A current certification or license already supported by your records",
        "A short post explaining a professional lesson without operational, medical, or clearance details",
    ]
    connection = f"Hello [Name], I’m transitioning toward {target} opportunities"
    if skill_phrase:
        connection += f" and bring experience with {skill_phrase}"
    connection += ". I’d value connecting and learning from your work."
    recruiter = f"Hello [Name], I’m interested in the {target} opportunity at [Company]."
    if skill_phrase:
        recruiter += f" My resume documents experience with {skill_phrase}."
    recruiter += " If the role is still active, I’d appreciate the chance to learn more."

    return LinkedInProfileKit(
        headline_options=headlines,
        about_text=about,
        skills=skills,
        experience_highlights=highlights,
        featured_ideas=featured,
        connection_message=connection,
        recruiter_message=recruiter,
        checklist=[
            "Choose whether you want to identify publicly as a veteran; it is optional.",
            "Use a professional photo and a simple background image you have rights to use.",
            "Verify dates, titles, credentials, numbers, and spelling before pasting anything.",
            "Add the strongest verified skills to both Skills and the related Experience entry.",
            "Request recommendations from people who directly observed your work.",
            "Review public-profile visibility and contact-information privacy settings.",
            "Never publish SSNs, medical/disability details, classified information, operation names, or sensitive clearance details.",
            "Refresh the profile after a promotion, certification, major project, or career change.",
        ],
        disclaimer=(
            "Copy-ready draft only. ApplyReady Vets does not sign in to, publish to, or claim affiliation with LinkedIn. "
            "Review every field before adding it to your profile."
        ),
    )


def linkedin_kit_text(kit: LinkedInProfileKit) -> str:
    sections = [
        "LINKEDIN PROFILE KIT",
        "",
        "HEADLINE OPTIONS",
        *[f"{index}. {value}" for index, value in enumerate(kit.headline_options, start=1)],
        "",
        "ABOUT",
        kit.about_text,
        "",
        "SKILLS",
        *[f"- {value}" for value in kit.skills],
        "",
        "EXPERIENCE HIGHLIGHTS",
        *[f"- {value}" for value in kit.experience_highlights],
        "",
        "FEATURED SECTION IDEAS",
        *[f"- {value}" for value in kit.featured_ideas],
        "",
        "CONNECTION MESSAGE",
        kit.connection_message,
        "",
        "RECRUITER MESSAGE",
        kit.recruiter_message,
        "",
        "PROFILE CHECKLIST",
        *[f"- {value}" for value in kit.checklist],
        "",
        kit.disclaimer,
    ]
    return "\n".join(sections).strip() + "\n"


def _experience_highlights(text: str) -> list[str]:
    lines = normalized_lines(text)
    likely = [
        line
        for line in lines
        if (ACTION_PATTERN.search(line) or re.search(r"\d", line))
        and not redact_for_ai(line)[1]
    ]
    return list(dict.fromkeys(likely))[:8]


def _display_skill(value: str) -> str:
    known = {"sql": "SQL", "it": "IT", "hr": "HR", "ai": "AI", "crm": "CRM"}
    return known.get(value.lower(), value.replace("-", " ").title())


def _human_list(items: list[str]) -> str:
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + f", and {items[-1]}"


def _limit(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1].rstrip(" |,") + "…"
