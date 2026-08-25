# Veteran packet research and implementation notes

Last updated: July 29, 2026

## What was added

ApplyReady Vets exports now include additional veteran-support materials:

- Veteran promotion packet.
- Employer outreach letter.
- Federal-contractor veteran note.
- College credit review request.
- College extension / extenuating-circumstances request.
- JOFDAV job-board strategy.
- Source notes and legal/product boundaries.

These outputs are copy-ready drafts. They do not submit applications, log in to third-party sites, scrape job boards, claim partnership, provide legal advice, or guarantee hiring/admission/credit/accommodation.

Federal application, USAJOBS, executive-resume, and clearance-safe research is tracked separately in
[FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md](FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md).

## JOFDAV

JOFDAV is a disabled-veteran job-board and disability-employment platform. The app should treat it as a discovery source:

1. The veteran searches JOFDAV manually.
2. The veteran copies a public job URL or job description into ApplyReady Vets.
3. ApplyReady Vets analyzes and exports a packet.
4. The veteran applies through the employer or job board process.

No scraping, auto-apply, account creation, or credential storage should be added without an explicit integration review.

Source: [JOFDAV](https://www.jofdav.com/)

## Branch coverage

The app should support the six U.S. armed forces:

- Army
- Marine Corps
- Navy
- Air Force
- Space Force
- Coast Guard

National Guard and Reserve should be treated as component/context notes rather than separate armed-service branches.

Source: [U.S. Department of War — Our Forces](https://www.war.gov/About/our-forces/)

## Military occupation translation

For production, branch-specific promotion packets should use official/licensed occupation data rather than hard-coded guesses.

Primary source direction:

- [O*NET Military Crosswalk](https://www.onetonline.org/crosswalk/MOC/)
- [O*NET Resource Center crosswalk files](https://www.onetcenter.org/crosswalks.html)

The current implementation uses conservative branch-level positioning only. It does not yet claim complete MOS/AFSC/rating coverage.

## Employer/legal context

The employer letters should stay careful:

- Do not claim protected-veteran status unless the veteran knows it applies.
- Do not imply federal-contractor obligations apply to every employer.
- Do not disclose disability, medical, VA rating, clearance, or classified details unless the veteran intentionally chooses to disclose them.
- Include “not legal advice” boundaries.

Useful official sources:

- [DOL OFCCP Veteran Resources / VEVRAA](https://www.dol.gov/agencies/ofccp/veterans/resources)
- [EEOC ADA reasonable accommodation guidance](https://www.eeoc.gov/laws/guidance/enforcement-guidance-reasonable-accommodation-and-undue-hardship-under-ada)
- [DOL Veterans’ Preference Advisor](https://webapps.dol.gov/elaws/vetspref.htm)

## College letters

The college credit review request should ask the school to review official military transcripts and prior learning. It must not promise credit. Each school decides what to accept and how it applies to a degree plan.

Useful official sources:

- [VA — College credits for military service](https://www.va.gov/resources/how-do-i-get-college-credits-for-my-military-service/)
- [DANTES — College Credit for Military Training](https://www.dantes.mil/credit4training/)

The college extension template is intentionally generic and tells the user to route disability-related requests through the correct campus office when appropriate.

## Future implementation roadmap

1. Add a visible “Veteran Packet Builder” section in the iOS app after Export.
2. Let users choose which letters to include.
3. Add branch-specific form fields for MOS/AFSC/rating, pay grade, component, clearance disclosure preference, disability-disclosure preference, and education goal.
4. Integrate official O*NET crosswalk files and cite version/date.
5. Add a “do not disclose” privacy guard for medical, disability, VA rating, classified, clearance, and operation-name content.
6. Add a reviewed employer-facing one-page PDF.
7. Add school-specific packet variants for admissions, registrar, veterans certifying official, disability services, and professor extension requests.
8. Add organization-license templates for veteran nonprofits, colleges, workforce agencies, and employers.
