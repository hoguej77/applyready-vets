from __future__ import annotations

from textwrap import dedent

from app.core.safety import redact_for_ai
from app.models import CandidateProfile, ExportRequest


BRANCH_POSITIONING: dict[str, tuple[str, list[str]]] = {
    "army": (
        "Army",
        [
            "ground operations, logistics, maintenance, safety, readiness, training, and mission execution",
            "team leadership, standard operating procedures, equipment accountability, and operational planning",
            "civilian language: operations coordinator, logistics lead, training supervisor, fleet/readiness specialist",
        ],
    ),
    "marine corps": (
        "Marine Corps",
        [
            "expeditionary operations, small-unit leadership, rapid execution, training, and readiness",
            "discipline under pressure, cross-functional coordination, risk control, and accountability",
            "civilian language: operations lead, program coordinator, security/field operations specialist",
        ],
    ),
    "marines": (
        "Marine Corps",
        [
            "expeditionary operations, small-unit leadership, rapid execution, training, and readiness",
            "discipline under pressure, cross-functional coordination, risk control, and accountability",
            "civilian language: operations lead, program coordinator, security/field operations specialist",
        ],
    ),
    "navy": (
        "Navy",
        [
            "shipboard or shore operations, technical systems, maintenance, watchstanding, safety, and compliance",
            "procedure-driven execution, training, documentation, and multi-team coordination",
            "civilian language: operations specialist, maintenance coordinator, compliance-focused team lead",
        ],
    ),
    "air force": (
        "Air Force",
        [
            "technical operations, aircraft or mission support, quality assurance, data, systems, and compliance",
            "readiness, inspection discipline, process improvement, documentation, and customer/stakeholder support",
            "civilian language: technical operations specialist, quality coordinator, systems support analyst",
        ],
    ),
    "space force": (
        "Space Force",
        [
            "space, cyber, intelligence, data, mission assurance, systems monitoring, and operational continuity",
            "technical risk control, secure processes, incident response, and cross-functional mission support",
            "civilian language: mission operations analyst, cyber/systems specialist, data-driven operations lead",
        ],
    ),
    "coast guard": (
        "Coast Guard",
        [
            "maritime safety, search and rescue, law enforcement support, emergency response, inspection, and compliance",
            "public-facing judgment, interagency coordination, safety discipline, and regulatory awareness",
            "civilian language: safety/compliance specialist, emergency operations coordinator, public-service operations lead",
        ],
    ),
}

COMPONENT_POSITIONING: dict[str, list[str]] = {
    "national guard": [
        "National Guard service can show dual mission experience: military readiness plus domestic support, emergency response, and community-facing operations.",
        "If relevant, translate state/federal activation experience into crisis response, logistics, public-service coordination, and schedule discipline.",
    ],
    "reserve": [
        "Reserve service can show long-term civilian/military balance, recurring training obligations, readiness discipline, and employer-compatible planning.",
        "If relevant, translate reserve leadership into part-time team leadership, training continuity, and operational reliability.",
    ],
}


def build_outreach_packet(request: ExportRequest, final_resume_text: str) -> dict[str, str]:
    profile = request.profile
    company = request.response.job.company or "[Employer]"
    title = request.response.job.title or profile.target_role or "[Target role]"
    identity = _applicant_identity(profile)
    candidate = request.candidate_name.strip() or profile.full_name.strip()
    if not candidate or (identity != "veteran" and candidate.casefold() in {"veteran", "veteran applicant"}):
        candidate = "Applicant"
    packet = {
        "Employer_Outreach_Letter.txt": _employer_letter(
            candidate,
            company,
            title,
            _service_summary(profile),
            identity,
        ),
        "College_Extension_Request.txt": _college_extension_request(candidate, identity),
        "JOFDAV_Job_Board_Strategy.txt": _jofdav_strategy(title),
        "Source_Notes.txt": source_notes(),
    }
    if identity == "veteran":
        packet.update({
            "Veteran_Promotion_Packet.txt": _promotion_packet(
                profile,
                candidate,
                company,
                title,
                final_resume_text,
            ),
            "Federal_Contractor_Veteran_Note.txt": _federal_contractor_note(candidate, company, title),
            "College_Credit_Review_Request.txt": _college_credit_request(candidate),
        })
    elif identity == "military_spouse":
        packet["Military_Spouse_Career_Packet.txt"] = _nonveteran_positioning_packet(
            candidate,
            company,
            title,
            final_resume_text,
            military_spouse=True,
        )
    else:
        packet["Career_Positioning_Packet.txt"] = _nonveteran_positioning_packet(
            candidate,
            company,
            title,
            final_resume_text,
            military_spouse=False,
        )
    return packet


def _has_service_history(profile: CandidateProfile) -> bool:
    return any(
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
        for service in profile.military_service
    )


def _applicant_identity(profile: CandidateProfile) -> str:
    if _has_service_history(profile):
        return "veteran"
    if profile.military_spouse:
        return "military_spouse"
    return "civilian"


def _service_summary(profile: CandidateProfile) -> str:
    parts: list[str] = []
    for service in profile.military_service:
        label = " ".join(
            item for item in [service.branch, service.component, service.rank, service.pay_grade, service.occupation_code]
            if item
        ).strip()
        if service.occupation_title:
            label = f"{label} — {service.occupation_title}" if label else service.occupation_title
        if label:
            parts.append(label)
    return "; ".join(parts) or "service information explicitly entered in my profile"


def _promotion_packet(
    profile: CandidateProfile,
    candidate: str,
    company: str,
    title: str,
    final_resume_text: str,
) -> str:
    detected = _detected_branches(profile)
    branch_sections = detected or ["branch-neutral"]
    lines = [
        "APPLYREADY VETS VETERAN PROMOTION PACKET",
        "",
        f"Candidate: {candidate}",
        f"Target: {title} at {company}",
        "",
        "Purpose",
        "This packet helps translate verified military experience into employer-ready language. It is not a VA, DoD, branch, or employer endorsement. Verify every claim before sending.",
        "",
        "Core positioning",
        "- Lead with outcomes, readiness, safety, compliance, training, logistics, communication, and mission execution.",
        "- Keep branch pride, but translate jargon into civilian business language.",
        "- Do not imply combat, clearance, classified, medical, disability, or credential details unless the veteran chooses to disclose and the resume evidence supports it.",
        "- Use exact numbers only when the same number appears in the source resume/profile evidence.",
        "",
        "Branch-specific translation angles",
    ]
    if "branch-neutral" in branch_sections:
        lines.extend([
            "- Branch not specified: use neutral language such as operations, training, logistics, leadership, safety, compliance, customer support, and project coordination.",
            "- Add branch, MOS/AFSC/rating, pay grade, component, and service dates in the profile when the veteran wants a more specific packet.",
        ])
    else:
        for branch in branch_sections:
            label, bullets = BRANCH_POSITIONING[branch]
            lines.append(f"- {label}:")
            lines.extend([f"  - {bullet}" for bullet in bullets])
    component_notes = _component_notes(profile)
    if component_notes:
        lines.extend(["", "Component notes"])
        for note in component_notes:
            lines.append(f"- {note}")
    evidence_lines = _best_evidence_lines(final_resume_text)
    if evidence_lines:
        lines.extend(["", "Evidence-backed talking points"])
        lines.extend([f"- {line}" for line in evidence_lines])
    lines.extend([
        "",
        "Employer-facing value proposition",
        f"For {candidate}'s application to {title}, connect only verified service evidence to the employer's "
        "stated requirements. Add accountability, communication, readiness, safety, or mission-focused "
        "problem solving only when a source record or resume example supports that specific point.",
    ])
    return "\n".join(lines).strip() + "\n"


def _nonveteran_positioning_packet(
    candidate: str,
    company: str,
    title: str,
    final_resume_text: str,
    *,
    military_spouse: bool,
) -> str:
    heading = (
        "APPLYREADY VETS MILITARY SPOUSE CAREER PACKET"
        if military_spouse
        else "APPLYREADY VETS CAREER POSITIONING PACKET"
    )
    identity_note = (
        "Military-spouse status is optional context. It does not establish personal military service, "
        "veteran status, protected-veteran status, or eligibility for a hiring preference."
        if military_spouse
        else
        "This packet makes no claim of military service, veteran status, protected-veteran status, "
        "or eligibility for a hiring preference."
    )
    lines = [
        heading,
        "",
        f"Candidate: {candidate}",
        f"Target: {title} at {company}",
        "",
        "Purpose",
        "Use verified professional evidence to prepare for an employer conversation.",
        identity_note,
        "",
        "Positioning guardrails",
        "- Use only duties, skills, credentials, and results supported by the resume or records.",
        "- Add numbers only when the same number appears in the source evidence.",
        "- Describe military-spouse context only when the applicant chooses to disclose it.",
    ]
    evidence_lines = _best_evidence_lines(final_resume_text)
    if evidence_lines:
        lines.extend(["", "Verified resume talking points"])
        lines.extend([f"- {line}" for line in evidence_lines])
    return "\n".join(lines).strip() + "\n"


def _employer_letter(
    candidate: str,
    company: str,
    title: str,
    service_summary: str,
    identity: str,
) -> str:
    if identity == "veteran":
        subject = f"Veteran candidate for {title}"
        background = (
            f"My background includes {service_summary}, and I am focused on translating that experience "
            "into measurable value for your team."
        )
        positioning = (
            "My attached resume provides the specific service examples I want considered. I will verify each "
            "duty, result, skill, and credential against my records before sending this letter."
        )
        context = "training, military transcript, certifications, or transition background"
    elif identity == "military_spouse":
        subject = f"Military spouse candidate for {title}"
        background = (
            "I identify as a military spouse. I am applying on the strength of my own verified professional "
            "experience and qualifications for this role."
        )
        positioning = (
            "My spouse status is context, not a claim of personal military service, veteran status, or a hiring "
            "preference. I welcome evaluation against the same stated role requirements."
        )
        context = "professional experience, training, certifications, or career transitions"
    else:
        subject = f"Candidate for {title}"
        background = (
            "I am focused on showing how my verified professional experience maps to the needs of your team."
        )
        positioning = (
            "I am especially interested in roles where disciplined execution, problem solving, communication, "
            "and dependable teamwork matter, and I will use only examples supported by my records."
        )
        context = "professional experience, training, or certifications"
    return dedent(f"""
    Subject: {subject}

    Dear Hiring Team,

    I am applying for the {title} role with {company}. {background}

    {positioning}

    I have attached an ATS-friendly resume and can provide additional context about my {context} if useful. I understand that hiring decisions must be based on the role requirements, and I welcome the opportunity to explain how my verified experience maps to this position.

    Respectfully,
    {candidate}
    """).strip() + "\n"


def _federal_contractor_note(candidate: str, company: str, title: str) -> str:
    return dedent(f"""
    Optional note for federal contractors or federal-adjacent employers

    Use this only when accurate and relevant. Do not claim protected-veteran status unless the veteran knows the category applies.

    Dear Hiring Team,

    I am applying for {title} with {company}. If your organization is a covered federal contractor or subcontractor, I understand that veteran hiring, nondiscrimination, and affirmative-action obligations may apply under VEVRAA for protected veterans. I am happy to provide any voluntary self-identification or documentation through your normal applicant process if requested and appropriate.

    My goal is straightforward: to be evaluated against the job requirements and to show how my verified experience can support the role.

    Respectfully,
    {candidate}
    """).strip() + "\n"


def _college_credit_request(candidate: str) -> str:
    name = candidate or "[Your name]"
    return dedent(f"""
    Subject: Request for military transcript / prior learning credit review

    Dear Registrar, Veterans Certifying Official, or Prior Learning Assessment Team,

    I am requesting a review of my military training and experience for possible transfer credit or prior learning credit toward my program.

    Please let me know the correct process for submitting my official Joint Services Transcript, Community College of the Air Force transcript, or other official military transcript/documentation, as applicable. I understand that each school determines how much credit it will accept and how that credit applies to a specific degree plan.

    I would also appreciate guidance on whether any military courses, occupations, certifications, or documented training may satisfy general education, elective, technical, or program-specific requirements.

    Respectfully,
    {name}
    """).strip() + "\n"


def _college_extension_request(candidate: str, identity: str) -> str:
    name = candidate or "[Your name]"
    if identity == "veteran":
        context = (
            "I am a service member or veteran. The specific, accurate circumstance affecting my timeline is: "
            "[describe the service, transition, health, family, or other documented circumstance]."
        )
    elif identity == "military_spouse":
        context = (
            "I am a military spouse. The specific, accurate military-family or other documented circumstance "
            "affecting my timeline is: [describe it here]. This does not claim personal military or veteran status."
        )
    else:
        context = (
            "The specific, accurate documented circumstance affecting my timeline is: [describe it here]."
        )
    return dedent(f"""
    Subject: Request for extension or academic support

    Dear Professor / Advisor / Student Support Office,

    I am requesting an extension or support option for my current coursework. {context}

    I am not asking to bypass academic standards. I am asking for the appropriate process, deadline, and documentation requirements so I can complete the work responsibly. Please direct me to the correct student-support, academic-advising, or formal extenuating-circumstances process.

    Proposed plan:
    - Course / assignment: [insert]
    - Current due date: [insert]
    - Requested new date or support option: [insert]
    - Documentation available if required: [insert]

    Respectfully,
    {name}
    """).strip() + "\n"


def _jofdav_strategy(title: str) -> str:
    return dedent(f"""
    JOFDAV job-board strategy

    JOFDAV.com is a job board focused on job openings for disabled veterans and disability employment. Use it as a discovery source, not as an automated-application target.

    Suggested workflow:
    1. Search JOFDAV for the target role, related titles, and location.
    2. Open promising postings and copy the job text or public URL into ApplyReady Vets.
    3. Use Truth Lock to tailor only evidence-backed resume language.
    4. Export the application packet.
    5. Apply through the employer's official process or the job board's normal application path.
    6. Track whether the employer is a federal contractor, veteran-friendly employer, government agency, college, healthcare employer, or private-sector company.

    Suggested searches for this packet:
    - "{title}"
    - "operations"
    - "logistics"
    - "program coordinator"
    - "analyst"
    - "customer success"
    - "administrative"
    - "information technology"

    Boundary:
    ApplyReady Vets should not scrape JOFDAV, sign in, create accounts, or submit applications without an approved integration and clear user consent.
    """).strip() + "\n"


def source_notes() -> str:
    return dedent("""
    Research/source notes for future production hardening

    - JOFDAV: disabled-veteran job board and disability-employment platform. Use as a job-discovery source; do not imply partnership.
      https://www.jofdav.com/
    - O*NET Military Crosswalk: official military occupational classification crosswalk covering Army MOS, Marine Corps MOS, Navy ratings, Air Force AFSC, and Coast Guard ratings.
      https://www.onetonline.org/crosswalk/MOC/
    - U.S. armed forces branches: Army, Marine Corps, Navy, Air Force, Space Force, and Coast Guard. Avoid official seals or endorsement language.
      https://www.war.gov/About/our-forces/
    - Department of Labor / OFCCP VEVRAA resources: protected-veteran nondiscrimination and affirmative-action context for covered federal contractors.
      https://www.dol.gov/agencies/ofccp/veterans/resources
    - EEOC ADA reasonable-accommodation guidance: employers may need to provide reasonable accommodation to qualified applicants/employees with disabilities unless undue hardship applies.
      https://www.eeoc.gov/laws/guidance/enforcement-guidance-reasonable-accommodation-and-undue-hardship-under-ada
    - VA military college credit guidance: schools decide how much military credit to accept after reviewing official transcripts.
      https://www.va.gov/resources/how-do-i-get-college-credits-for-my-military-service/
    - DANTES Joint Services Transcript guidance: JST is an official record with military experience, courses, and credit recommendations.
      https://www.dantes.mil/credit4training/

    Legal boundary:
    These notes are product guidance, not legal advice, benefits advice, accredited VA claims representation, or a guarantee of hiring, admission, transfer credit, accommodation, or eligibility.
    """).strip() + "\n"


def _detected_branches(profile: CandidateProfile) -> list[str]:
    branches: list[str] = []
    for service in profile.military_service:
        raw = service.branch.strip().lower()
        if raw in BRANCH_POSITIONING and raw not in branches:
            branches.append(raw)
    return branches


def _component_notes(profile: CandidateProfile) -> list[str]:
    notes: list[str] = []
    seen: set[str] = set()
    for service in profile.military_service:
        component = service.component.strip().lower()
        for key, values in COMPONENT_POSITIONING.items():
            if key in component and key not in seen:
                notes.extend(values)
                seen.add(key)
    return notes


def _best_evidence_lines(text: str, limit: int = 6) -> list[str]:
    candidates: list[str] = []
    for raw in text.splitlines():
        line = raw.strip().lstrip("-• ").strip()
        if not line or len(line) < 25 or redact_for_ai(line)[1]:
            continue
        lower = line.lower()
        if any(term in lower for term in ["led", "managed", "maintained", "improved", "trained", "coordinated", "supported", "built", "delivered"]):
            candidates.append(line)
        if len(candidates) >= limit:
            break
    return candidates
