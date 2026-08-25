from __future__ import annotations

import re
from textwrap import dedent

from app.models import ExportRequest


def build_federal_career_packet(request: ExportRequest, final_resume_text: str) -> dict[str, str]:
    candidate = request.candidate_name or request.profile.full_name or "Applicant"
    company = request.response.job.company or "[Agency or employer]"
    title = request.response.job.title or request.profile.target_role or "[Target role]"
    return {
        "Federal_Career_Strategy.txt": _federal_strategy(candidate, company, title, request),
        "USAJOBS_Resume_Checklist.txt": _usajobs_checklist(candidate, title, final_resume_text),
        "Executive_Clearance_LinkedIn_Notes.txt": _executive_clearance_notes(candidate, title),
        "Federal_Executive_Source_Notes.txt": federal_source_notes(),
    }


def _federal_strategy(candidate: str, company: str, title: str, request: ExportRequest) -> str:
    federal_label = "Yes" if request.response.job.federal else "Not confirmed"
    veteran_label = "Yes" if request.response.job.open_to_veterans else "Not confirmed"
    missing = request.response.job.missing_keywords[:8]
    requirements = request.response.job.required_qualifications[:6]

    lines = [
        "APPLYREADY VETS FEDERAL CAREER STRATEGY",
        "",
        f"Candidate: {candidate}",
        f"Target: {title} at {company}",
        f"Federal signal detected: {federal_label}",
        f"Veteran hiring signal detected: {veteran_label}",
        "",
        "Use this file as a planning checklist before applying through USAJOBS, an agency site, or an employer site.",
        "",
        "Current federal-resume rule",
        "- Treat the current USAJOBS two-page limit as the controlling rule for USAJOBS resumes.",
        "- Older decks and guides may say federal resumes are longer. Do not follow that unless the live job",
        "  announcement or agency system clearly requires something different.",
        "- Tailor each resume to the announcement's duties, specialized experience, qualifications, and evaluation",
        "  factors. Federal reviewers are not supposed to infer missing qualifications.",
        "",
        "Recommended workflow",
        "1. Save the job announcement PDF or text before it closes.",
        "2. Copy the duties, qualifications, specialized experience, required documents, and questionnaire preview.",
        "3. Map each required qualification to evidence already in the resume, military profile, JST, training record,",
        "   certification, performance review, or civilian work history.",
        "4. Use exact required terms when truthful, especially technical systems, job series language, certifications,",
        "   grade/pay-plan history, and specialized-experience phrases.",
        "5. Keep every result claim evidence-backed. Do not invent numbers, awards, clearance details, or duties.",
        "6. Export the ATS/USAJOBS-safe resume and paste-check it before submission.",
        "",
        "Required qualification lines found in the job text",
    ]
    if requirements:
        lines.extend([f"- {item}" for item in requirements])
    else:
        lines.append("- None were clearly detected. Read the live announcement manually before applying.")

    lines.extend(["", "Keyword gaps to verify with evidence"])
    if missing:
        lines.extend([f"- {term}" for term in missing])
    else:
        lines.append("- No major keyword gaps were detected by the basic parser.")

    lines.extend([
        "",
        "Veteran-specific review",
        "- If claiming veterans' preference, verify eligibility and upload the required documentation.",
        "- If a special hiring authority such as VRA, VEOA, 30% or more disabled veteran, or Schedule A may apply,",
        "  confirm eligibility through official sources before using that language.",
        "- If the application asks for disability or protected-veteran self-identification, use the employer's normal",
        "  voluntary process. Do not put private medical details in the resume.",
    ])
    return "\n".join(lines).strip() + "\n"


def _usajobs_checklist(candidate: str, title: str, final_resume_text: str) -> str:
    page_warning = _page_estimate_warning(final_resume_text)
    privacy_warning = _privacy_warning(final_resume_text)
    return dedent(f"""
    USAJOBS RESUME BUILDER CHECKLIST

    Candidate: {candidate}
    Target role: {title}

    Current USAJOBS-safe resume requirements
    - Two pages or less for USAJOBS upload/build workflows.
    - 5 MB or less if uploaded.
    - Standard 8.5 x 11 inch page size.
    - Plain, readable font and simple formatting.
    - Tailored to the specific announcement.

    Include when relevant and true
    - Full name, email, and phone number.
    - Employer name, job title, start/end month and year, and hours worked per week for each relevant role.
    - Series and grade for federal jobs only.
    - Education, licenses, certifications, and transcripts only when required or useful for the announcement.
    - Volunteer, community, military, and training experience when it proves a qualification.
    - Results written with numbers, percentages, dollars, scope, or clear outcomes only when evidence supports them.

    Leave out
    - Social Security number.
    - Classified or government-sensitive information.
    - Photos.
    - Age, sex, religion, marital status, or unrelated personal information.
    - Digital signatures, encrypted documents, unsupported claims, or private medical details.

    Paste-builder preparation
    - Save a plain-text copy before pasting into USAJOBS Resume Builder.
    - Check bullets and special characters after pasting.
    - Preview before submission.
    - If the resume cannot be saved because of page length, cut unrelated history first.

    Automated review notes
    - {page_warning}
    - {privacy_warning}
    """).strip() + "\n"


def _executive_clearance_notes(candidate: str, title: str) -> str:
    return dedent(f"""
    EXECUTIVE, CLEARANCE-SAFE, AND LINKEDIN NOTES

    Candidate: {candidate}
    Target role: {title}

    Executive-resume pattern distilled from the uploaded executive-resume reference
    - Start with a focused title/profile, not a generic objective.
    - Make the first third of page one prove the strongest fit.
    - Use a hybrid structure: leadership profile, core strengths, selected achievements, then reverse chronology.
    - Convert duties into outcomes: scope, people, budget, risk, readiness, compliance, time, quality, or mission impact.
    - Keep claims honest, specific, and checkable.
    - Proofread aggressively. Resume errors create trust problems.

    ATS and recruiter review
    - Use the employer's real keywords only when the applicant has matching evidence.
    - Avoid tables, columns, text boxes, hidden text, graphics, and decorative templates for ATS copies.
    - Keep one polished human-readable version and one paste-safe version.
    - Track each application version so later interview answers match the submitted resume.

    LinkedIn builder guidance
    - The LinkedIn profile should reinforce the same target role, achievements, and evidence as the resume.
    - Use a headline that names the target function and value, not just the former military title.
    - Do not publish anything the veteran would not want recruiters, current employers, or the public to see.
    - ApplyReady Vets prepares copy-ready text only; it should not sign in, scrape, message, or post automatically.

    Clearance and intelligence-role safety
    - Include only clearance status or eligibility when accurate, current/recent enough to be relevant, and requested or useful.
    - Do not describe classified programs, operational details, mission names, customer names, locations, tools, or methods.
    - Use broad civilian language such as secure operations, compliance, incident response, watchstanding, analysis,
      mission support, documentation, and cross-functional coordination.
    - If unsure, remove the detail and ask a security officer, transition counselor, or cleared-career specialist.
    """).strip() + "\n"


def federal_source_notes() -> str:
    return dedent("""
    FEDERAL AND EXECUTIVE RESUME SOURCE NOTES

    Reviewed materials
    - Federal Careers deck supplied by the user:
      https://cdn.uconnectlabs.com/wp-content/uploads/sites/284/2025/07/Federal-Careers-PP-Autosaved.pptx.pdf
    - Uploaded local book reference:
      Top Secret Executive Resumes: Create the Perfect Resume for the Best Top-Level Positions.
      This app uses only high-level, summarized product guidance from that reference and does not reproduce its text.

    Official sources used to resolve conflicts and product rules
    - USAJOBS federal resume guidance:
      https://help.usajobs.gov/faq/application/documents/resume/what-to-include
    - USAJOBS resume upload/builder guidance:
      https://help.usajobs.gov/how-to/account/documents/resume
    - USAJOBS veterans hiring path:
      https://help.usajobs.gov/working-in-government/unique-hiring-paths/veterans
    - USAJOBS military service profile guidance:
      https://help.usajobs.gov/how-to/account/profile/experience/military
    - OPM Feds Hire Vets:
      https://www.opm.gov/fedshirevets/
    - OPM Schedule A/disability hiring:
      https://www.opm.gov/policy-data-oversight/disability-employment/hiring/
    - OPM Executive Core Qualifications:
      https://www.opm.gov/policy-data-oversight/senior-executive-service/executive-core-qualifications/
    - Presidential Management Fellows eligibility:
      https://www.pmf.gov/become-a-pmf/eligibility/

    Product boundary
    This is career-writing guidance, not legal advice, HR advice, benefits advice, security-clearance advice, or a
    guarantee of eligibility, referral, interview, selection, transfer credit, accommodation, or appointment.
    """).strip() + "\n"


def _page_estimate_warning(text: str) -> str:
    nonempty_lines = [line for line in text.splitlines() if line.strip()]
    words = re.findall(r"\b\w+\b", text)
    if len(words) > 950 or len(nonempty_lines) > 90:
        return "Length review: this may exceed two pages after formatting. Cut before uploading to USAJOBS."
    return "Length review: this appears plausibly within two pages, but preview the final PDF before applying."


def _privacy_warning(text: str) -> str:
    lowered = text.lower()
    if re.search(r"\b\d{3}-\d{2}-\d{4}\b", text):
        return "Privacy review: possible SSN detected. Remove it before applying."
    if any(term in lowered for term in ["classified", "special access program", "secret mission"]):
        return "OPSEC review: possible classified or sensitive detail detected. Remove it before applying."
    return "Privacy review: no SSN or obvious classified-detail pattern was detected by this basic scan."
