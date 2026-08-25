# Research and product specification

Research refreshed July 13, 2026 using primary/official sources; implementation status reconciled July 30, 2026.

## Product promise

**ApplyReady Vets helps veterans convert verified service experience into application-ready career materials while keeping the veteran—not the AI—in control.**

The product should feel like a careful transition coach, resume editor, and application organizer. It must not act like an automatic claims generator.

## Core user journeys

1. Import or paste an existing resume and a target job.
2. Add optional branch, rank, occupation code, target role, and military-spouse context.
3. Choose civilian, federal, healthcare, education, or automatic mode.
4. Choose private deterministic analysis or explicitly consent to redacted AI processing.
5. Review readiness checks, missing requirements, privacy/OPSEC issues, and suspicious-job signals.
6. Approve, edit, or reject each evidence-linked suggestion.
7. Export employer-facing PDF, editable RTF, parser-safe TXT, and a separate private TXT review; copy approved LinkedIn
   material separately.

## Research-backed requirements

### Federal applications

Current USAJOBS guidance says a federal resume should be no more than two pages and include month/year dates, hours per week, and relevant qualifications. USAJOBS also warns applicants not to include sensitive information such as Social Security numbers or photos. The app therefore detects federal language, produces a warning/checklist, and avoids pretending a civilian resume is automatically federal-ready.

- [USAJOBS: What to include in your resume](https://help.usajobs.gov/faq/application/documents/resume/what-to-include)
- [USAJOBS resume guidance](https://help.usajobs.gov/how-to/account/documents/resume)
- [USAJOBS veterans hiring path](https://help.usajobs.gov/working-in-government/unique-hiring-paths/veterans)
- [OPM veteran hiring authorities](https://www.opm.gov/fedshirevets/hiring-officials/strategic-recruitment-and-hiring/veterans/)

The app must never decide whether someone qualifies for veterans’ preference or a special hiring authority. It can identify announcement language and direct the user to the official source.

### Military-to-civilian translation

The Department of Labor’s Transition Assistance Program includes employment preparation, and O*NET maintains a military occupational classification crosswalk covering Army, Navy, Air Force, Marine Corps, Coast Guard, and Space Force data. The production roadmap uses this official crosswalk rather than inventing a proprietary equivalence system.

- [DOL Transition Assistance Program](https://www.dol.gov/agencies/vets/programs/tap)
- [DOL Veterans’ Employment and Training Service](https://www.dol.gov/agencies/vets/veterans/veterans-employment-services)
- [O*NET military crosswalk reference](https://services.onetcenter.org/reference/online/crosswalk/moc)
- [O*NET crosswalk downloads](https://www.onetcenter.org/crosswalks.html)

The current app bundles the official August 2024 O*NET military crosswalk with 12,921 active mappings across all six
branches. It preserves source metadata and uses related occupations as a discovery aid, not proof of qualification,
licensure, or work actually performed.

### LinkedIn profile builder

LinkedIn’s current help materials describe the headline as separate from the current position and list profile sections including About, Experience, Education, licenses/certifications, Skills, Recommendations, Projects, honors, and volunteer experience. LinkedIn recommends a short one- or two-paragraph About section and says military self-identification is not required.

- [LinkedIn: Your profile](https://www.linkedin.com/help/linkedin/answer/a564064/your-linkedin-profile-overview)
- [LinkedIn: Create a good profile](https://www.linkedin.com/help/linkedin/answer/a554351/how-do-i-create-a-good-linkedin-profile-)
- [LinkedIn: Add profile sections](https://www.linkedin.com/help/linkedin/answer/a540837/add-sections-to-your-profile)
- [LinkedIn military community FAQ](https://www.linkedin.com/help/linkedin/answer/a518653/linkedin-for-veterans-free-premium-career-subscription-and-eligibility)
- [LinkedIn: Edit your headline](https://www.linkedin.com/help/linkedin/answer/a542926/edit-your-headline)

The builder generates copy-ready fields and instructions. It intentionally does not collect LinkedIn credentials, scrape profiles, impersonate the user, auto-connect, auto-message, or publish. A veteran-identified headline is one option, never the forced default.

### iOS privacy, security, and accessibility

Apple requires privacy disclosures, accurate data handling, and declared reasons for covered APIs. UserDefaults is declared in the privacy manifest under the approved app-only reason. The app uses the system document picker and share sheet, Keychain for the service token, file protection for the draft, Dynamic Type-compatible layouts, and accessibility labels.

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Apple SwiftUI accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
- [Apple SwiftUI file importer](https://developer.apple.com/documentation/swiftui/view/fileimporter%28ispresented%3Aallowedcontenttypes%3Aallowsmultipleselection%3Aoncompletion%3Aoncancellation%3A%29)

### Built-in AI

OpenAI’s official guidance says API keys must stay secret and be loaded server-side, not embedded in apps. The current implementation uses the Responses API with a Pydantic structured-output schema and disables response storage with `store=False`.

- [OpenAI structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [OpenAI text generation / Responses API](https://developers.openai.com/api/docs/guides/text?api-mode=responses)
- [OpenAI production best practices](https://developers.openai.com/api/docs/guides/production-best-practices)

The provider receives a redacted evidence ledger, job posting, and job analysis only after explicit consent. All output is treated as untrusted and revalidated.

## Success measures for a veteran beta

- At least 90% of accepted suggestions are judged fully supported by source material.
- Zero invented numbers, credentials, clearances, dates, ranks, or eligibility claims in controlled red-team testing.
- At least 80% of testers complete a first export without facilitator help.
- Median time from import to reviewed packet under 15 minutes.
- VoiceOver completion of the core workflow with no blocker.
- Veterans report that translations preserve meaning and do not exaggerate responsibility.
- Users understand the difference between readiness guidance and an ATS/hiring prediction.

## Next product increments

1. Validate and refresh the bundled O*NET release process, integrity metadata, branch searches, and source display.
2. Add an evidence editor so users can answer gap questions with verified new facts, then rerun analysis.
3. Expand the implemented federal fields/checks/two-page gate with specialized-experience trace and representative
   layout fixtures.
4. Add user-approved reminders, contacts, interview/offer/retention fields to the implemented tracker and isolated
   per-job workspaces.
5. Add native DOCX and a Workday field-by-field copy lab, then restore the broader historical packet family through
   evidence and visual/parser fixtures.
6. Add salary range normalization from trusted job text without compensation promises.
7. Add multilingual plain-language coaching and physical-device screen-reader usability testing.
8. Add production authentication, authorization, deletion/retention, rate/cost controls, and safety operations only if
   the optional service is enabled publicly.
