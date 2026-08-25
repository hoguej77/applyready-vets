# Federal Careers and Executive Resume Research

Last updated: July 29, 2026

This note summarizes the user-supplied federal-careers deck, the local executive-resume PDF, and current official
federal hiring sources. It is intended to guide ApplyReady Vets product behavior. It is not legal advice, HR advice,
benefits advice, security-clearance advice, or a guarantee of hiring, referral, interview, selection, credit, or
appointment.

## Materials reviewed

- Federal Careers deck supplied by the user:
  <https://cdn.uconnectlabs.com/wp-content/uploads/sites/284/2025/07/Federal-Careers-PP-Autosaved.pptx.pdf>
- Local uploaded reference:
  `/Users/jonathanhogue/Documents/Jonathan's Personal PaperWork/goals/TO DO/Intel Job/Top Secret Executive Resumes - Create the Perfect Resume for  the Best Top-Level Positions.pdf`
- Official USAJOBS federal resume guidance:
  <https://help.usajobs.gov/faq/application/documents/resume/what-to-include>
- Official USAJOBS resume builder guidance:
  <https://help.usajobs.gov/how-to/account/documents/resume>
- Official USAJOBS veterans hiring path:
  <https://help.usajobs.gov/working-in-government/unique-hiring-paths/veterans>
- Official USAJOBS military service profile guidance:
  <https://help.usajobs.gov/how-to/account/profile/experience/military>
- OPM Feds Hire Vets:
  <https://www.opm.gov/fedshirevets/>
- OPM disability/Schedule A hiring guidance:
  <https://www.opm.gov/policy-data-oversight/disability-employment/hiring/>
- OPM Executive Core Qualifications:
  <https://www.opm.gov/policy-data-oversight/senior-executive-service/executive-core-qualifications/>
- Presidential Management Fellows eligibility:
  <https://www.pmf.gov/become-a-pmf/eligibility/>

## Federal Careers deck: useful takeaways

The deck is useful as an introductory federal-career workflow. It covers:

- Why federal employment can appeal to applicants.
- Setting up a USAJOBS account and profile.
- Applications, saved jobs, and saved searches.
- Searching by job title, agency, location, and job-code/career-family concepts.
- Internship pathways, including Pathways, Recent Graduates, PMF, and agency-specific internships.
- USAJOBS Resume Builder.
- Federal resume differences, veteran preference, Schedule A, special populations, and federal events.
- Intelligence-community internship timing and clearance lead-time cautions.

Product implication: ApplyReady Vets should not only generate a resume. It should generate a federal application packet:
job-announcement checklist, resume-builder paste copy, veterans preference/document reminder, Schedule A reminder when
user-selected, and a saved-search/application tracker.

## Important correction: older federal resume advice conflicts with current USAJOBS

The deck includes older-style advice that federal resumes are longer and asks for SSN. Current USAJOBS guidance should
control app behavior instead:

- USAJOBS now says federal resumes must be two pages or less.
- USAJOBS says to include hours worked per week and series/grade for federal jobs only.
- USAJOBS says to leave out SSN, classified/government-sensitive information, photos, and unrelated personal details.
- USAJOBS recommends simple formatting and a PDF upload when preserving layout matters.

Product rule: ApplyReady Vets should treat two pages as the default federal-resume limit, warn on possible SSNs, and block
or warn on classified/sensitive details before export or AI processing.

## Executive-resume PDF: high-level usable patterns

The uploaded 316-page executive-resume book was used for high-level patterns only. The app should not reproduce its
examples or copyrighted text. The relevant product lessons are:

- Strong executive resumes start with a focused title/profile and a fast first-page value proposition.
- A hybrid structure works well for senior candidates: profile, selected strengths, selected achievements, then reverse
  chronology.
- Duties should be converted into outcomes: scope, people led, budget, risk, readiness, compliance, quality, time, and
  mission impact.
- Honesty and proof are central. Unsupported numbers, invented leadership scope, or inflated titles create risk.
- ATS-friendly versions still matter for executive applicants.
- LinkedIn should reinforce the same career target and evidence-backed achievements as the resume.
- Cover letters should be targeted and tracked by employer/job, not generic.

Product implication: ApplyReady Vets should support a separate executive mode with achievement inventory prompts,
first-page proof review, LinkedIn alignment, cover-letter tracking, and interview-message consistency checks.

## Clearance-safe and intelligence-role guidance

For intelligence, defense, federal contractor, and cleared roles, the app should separate three concepts:

1. Clearance status or eligibility, if accurate and relevant.
2. Transferable secure-work skills.
3. Classified/sensitive details that should not be disclosed.

Safe phrasing should prefer broad language such as secure operations, compliance, incident response, watchstanding,
analysis, mission support, documentation, risk control, and cross-functional coordination. The app should warn users not
to disclose classified programs, customer names, mission names, locations, tools, methods, or operational details.

## Veteran and special-hiring guidance

Official USAJOBS guidance says veterans may be eligible for veterans' preference or other veteran-specific hiring
options, but those do not guarantee a job. Applicants claiming preference may need DD-214, SF-15, or VA documentation.
Military profile data and disability rating information, when entered, may be sent to hiring agencies through USAJOBS.

OPM Schedule A guidance confirms non-competitive hiring can apply for persons with disabilities, but documentation is
required and eligibility does not guarantee selection.

Product rule: ApplyReady Vets should never tell a user they are eligible. It should say “verify eligibility,” “if
applicable,” and “upload required documentation through the official process.”

## Executive Core Qualifications update risk

OPM's Executive Core Qualifications page is current source-of-truth for SES positioning. The app should not hard-code an
old ECQ list without checking current OPM guidance. Current product behavior should link to OPM and provide a generic SES
leadership evidence inventory unless the app includes a maintained ECQ data file.

## Implemented in this codebase

- Added export files:
  - `Federal_Career_Strategy.txt`
  - `USAJOBS_Resume_Checklist.txt`
  - `Executive_Clearance_LinkedIn_Notes.txt`
  - `Federal_Executive_Source_Notes.txt`
- Added health feature flags:
  - `usajobs_resume_checklist`
  - `executive_clearance_notes`
- Updated the iOS export screen to show the federal career packet.
- Updated the iOS legal/source screen with USAJOBS veterans and OPM ECQ links.

## Roadmap recommendations

### Near-term

- Add a “Federal / USAJOBS” mode with two-page validation and a resume-builder paste preview.
- Add a job-announcement parser that extracts duties, qualifications, specialized experience, required documents, and
  questionnaire-preview links.
- Add a “Do not include” privacy gate for SSN, DOB, photos, medical details, and classified/sensitive details.
- Add a veteran preference document checklist with DD-214, SF-15, and VA letter reminders.
- Add a cleared-role safety checklist.

### Mid-term

- Add saved USAJOBS search planning and application tracker fields.
- Add PMF/Pathways/Recent Graduates checklists.
- Add Schedule A letter/documentation guidance without making eligibility claims.
- Add executive mode with achievement-inventory prompts and first-page value review.
- Add LinkedIn/resume consistency scoring.

### Later

- Maintain an official-source update job that checks USAJOBS/OPM guidance changes before releases.
- Add agency-specific variants for FBI, DHS, VA, DoD, intelligence community, healthcare, and contracting roles.
- Add a federal contractor packet that distinguishes VEVRAA, private-sector contractor hiring, and direct federal jobs.
- Add organization dashboards for veteran nonprofits, colleges, workforce boards, and transition programs.
