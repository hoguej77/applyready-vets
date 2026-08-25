# ApplyReady Vets workforce and integration gap audit

Last reconciled with the current iOS 27 source: July 30, 2026.

## Executive decision

ApplyReady Vets has not solved every veteran-workforce barrier or integrated directly with every job platform. The
defensible product is a **trusted veteran application companion**:

```text
capture a job
→ identify requirements
→ map requirements to veteran-confirmed evidence
→ expose gaps and required documents
→ create candidate-controlled files and copy
→ open the official application
→ let the veteran submit
→ track status, deadline, and exact packet version
```

Direct account access or submission stays out unless a platform offers an appropriate API, the required partnership or
employer authorization exists, security/privacy review passes, and the veteran gives informed consent. The current app
does not scrape, store job-site credentials, auto-fill third-party forms, post to LinkedIn, or auto-apply.

## Workforce barriers the product should address

| Barrier | Product response | Current boundary |
| --- | --- | --- |
| Transition begins too late | Future 12–18 month TAP/SkillBridge/education/credential plan | Not implemented; must not claim to replace TAP |
| Military experience is misunderstood | Offline O*NET military crosswalk plus evidence-confirmed translation | A crosswalk identifies related occupations; it does not prove qualification or licensure |
| Application quality is reduced to a fake “ATS score” | Separate qualification coverage, evidence strength, and acronym clarity, plus visible gaps | Heuristics do not predict ATS rank, interviews, or hiring |
| Federal hiring is announcement-specific | Federal fields, dated USAJOBS checks, required-document tracking, and a two-page PDF gate | No USAJOBS account access or submission; final requirements still require user review |
| Applications are fragmented | Local tracker with source URL, job ID, employer, role, status, deadline, notes, documents, workspace, and packet versions | No third-party status sync |
| Job quality and retention matter | Roadmap metrics include interviews, offers, wage, skill use, fit, and 90/180-day retention | Outcome collection and organization reporting are not implemented |
| Disability and accessibility affect participation | Native controls, automated accessibility tests, responsive layouts, private processing | Full physical-device assistive-technology testing and accommodation-copy safeguards remain |
| Licensing varies by state and occupation | Planned dated official-link credential planner | No eligibility determination or licensing advice |
| Job scams target service members | Current risk patterns and sensitive-data warnings; planned official-domain comparison | Never call a job “verified safe” |
| Guard/Reserve discrimination and employment rights | Planned factual official-source referrals | The app does not give legal advice |

Relevant official evidence:

- [GAO transition assistance](https://www.gao.gov/products/gao-24-107083)
- [DOL TAP impact study](https://www.dol.gov/resource-library/evaluation-transition-assistance-program-tap-impact-study-report)
- [BLS veteran employment, 2025](https://www.bls.gov/news.release/vet.nr0.htm)
- [Census Veteran Employment Outcomes](https://www.census.gov/library/stories/2025/01/veterans-employment-outcomes.html)
- [O*NET military crosswalks](https://www.onetcenter.org/crosswalks.html)
- [EEOC guidance for veterans with disabilities](https://www.eeoc.gov/publications/veterans)
- [USAJOBS required documents](https://help.usajobs.gov/faq/application/documents)
- [USAJOBS resume guidance](https://help.usajobs.gov/faq/application/documents/resume/what-to-include)
- [FTC job-seeking scam warning](https://consumer.ftc.gov/consumer-alerts/2025/06/job-seeking-servicemembers-avoid-scams-while-you-search)
- [DOL USERRA](https://www.dol.gov/agencies/vets/programs/userra/aboutuserra)

## Current source truth

| Capability | Current implementation | Honest limitation |
| --- | --- | --- |
| Private core | Deterministic evidence, requirements, gaps, safety findings, sub-scores, conservative proposals, and Truth Lock | Rules do not replace the veteran, a career counselor, recruiter, attorney, benefits adviser, or licensing authority |
| Per-job workspaces | Each tracked application has an isolated protected snapshot with checksum, atomic writes, backup, recovery, and migration | Physical-device storage pressure, interruption, upgrade, and migration testing remain |
| Import | Local text-family, RTF, HTML, image, selectable-PDF, and bounded scanned-PDF OCR; unsupported files may use the separately consented development service | DOCX is not converted locally; OCR must be manually checked |
| Military profile and mapping | Branch/component/rank/pay grade/code/title/dates plus 12,921 active August 2024 O*NET mappings across six branches | Mapping is dated and related-occupation evidence, not a qualification judgment |
| Job analysis | Requirements, gaps, risk patterns, federal/veteran signals, and three visible readiness sub-scores | No ATS certification or hiring probability |
| Local export | Employer PDF, editable RTF, parser-safe TXT, separate private TXT review, packet-version filenames, and direct file sharing | Native DOCX, cover letter, interview/supplemental packet, and Workday field lab remain |
| Federal mode | Announcement/series/grade context, requirement-specific source-dated checks, required documents, and rejection of PDFs over two pages | No USAJOBS search/account/submission; the final file and announcement must be reviewed |
| LinkedIn | Evidence-backed headline, About, skills, highlights, messages, featured ideas, and copy/share | No LinkedIn sign-in, editing, scraping, posting, or messaging automation |
| Job-site handoff | Recognizes/saves LinkedIn, Indeed, Workday, USAJOBS, Handshake, JOFDAV, and employer URLs; open/copy/share is user-controlled | No account integration or application submission |
| Tracker | Status, notes, deadline, required documents, due-soon view, workspace, and versioned output filenames | No partner sync, calendar, notification, contact, interview, offer, or retention tracking yet |
| Apple intelligence | Optional iOS 27 structured proposals after the local baseline, AI consent, runtime availability, and safety gate | Physical-device quality, latency, refusal, context, thermal, language/region, and model-update testing remain |
| Apple surfaces | App Intents, deep links, opt-in Spotlight metadata, privacy-minimal widget, and URL/text Share extension | Signed device/App Group/Siri/widget/Share validation remains |
| Optional service/OpenAI | Separate service consent, server-side key, structured bounded proposal route, and local revalidation | Release has no endpoint; no public identity, hosting, retention/deletion, rate/cost, monitoring, or incident system exists |
| Complete | One complete application free; unlimited workspaces through one $5.99 lifetime non-consumable | App Store Connect product and signed purchase/restore/refund lifecycle are not validated |

The source-controlled Release-candidate storefront is enabled, but the app is not purchasable until the matching App
Store Connect product, agreements, tax/banking, signing, and sandbox validation exist. There are no consumer tips,
subscriptions, ads, credits, or feature packs.

## Platform boundaries

| Platform | Safe current or near-term behavior | Requires approval/relationship | Never implement without authority |
| --- | --- | --- | --- |
| LinkedIn | User-selected URL, copy-ready profile content, system share, local tracking | Relevant LinkedIn partner product for expanded capabilities | Scraping, automated profile changes, messages, connections, or activity |
| Indeed | User-selected URL/text, local packet, official-page handoff | Approved Indeed/ATS partnership and OAuth for partner APIs | Password capture, scraping, browser bots, unattended applying |
| Workday/MyWorkdayJobs | Employer-specific link, local files, future field-by-field copy cards | Employer tenant authorization or Built on Workday approval | Treating all employers as one Workday account or injecting answers |
| USAJOBS | Current official handoff; planned read-only search/details/filters and closing reminders | Backend-held USAJOBS API credentials | Claiming submission or storing applicant credentials |
| Handshake | User-selected content and canonical handoff | Institution or Handshake relationship | Bulk collection or scraping |
| Greenhouse/Lever | Planned read-only public postings and hosted apply links | Employer authorization for private/application APIs | Shipping employer secrets in the app |
| Apple Calendar/Mail | Planned user-presented event editor, local notification, and user-edited share/mail sheets | Minimum Apple permission only | Reading the whole calendar or silently sending |

Official platform references:

- [LinkedIn open permissions](https://learn.microsoft.com/en-us/linkedin/shared/authentication/getting-access)
- [LinkedIn Apply Connect](https://learn.microsoft.com/en-us/linkedin/talent/apply-connect)
- [Indeed authentication](https://docs.indeed.com/authentication)
- [Indeed Developer Agreement](https://docs.indeed.com/legal-terms/developer-agreement)
- [Workday API overview](https://developer.workday.com/api-overview)
- [USAJOBS Search API](https://developer.usajobs.gov/api-reference/get-api-search)
- [Handshake EDU API](https://support.joinhandshake.com/hc/en-us/articles/31061076506391-Getting-Started-with-EDU-API)
- [Greenhouse Job Board API](https://developers.greenhouse.io/job-board)
- [Lever Postings API](https://github.com/lever/postings-api)

## Current iOS 27 SDK use

Implemented:

- SwiftUI navigation, forms, lists, search, semantic colors, Dynamic Type-aware layouts, and system share sheets.
- App Intents/App Shortcuts, app deep links, opt-in Core Spotlight, WidgetKit, and a URL/text Share extension.
- Foundation Models availability checks, dynamic profiles, structured output, live context/token budgeting, and native
  evidence validation.
- PDFKit/document APIs and bounded Vision OCR.
- Core Graphics/Core Text PDF generation, RTF/TXT generation, and Files-visible Output storage.
- CryptoKit checksum, atomic writes, complete file protection, Keychain, and protected App Group data.
- StoreKit 2 for one non-consumable lifetime purchase.
- Privacy manifest with no tracking and no third-party iOS SDK.

Not implemented or not release-validated:

- Share extension file attachments beyond URL/text.
- EventKit, local notifications, background partner refresh, approved OAuth connections, and Home Screen quick actions.
- Public-link NFC/QR. NFC is not a general iPhone-to-iPhone private file-transfer mechanism.
- Physical-device Apple Intelligence, accessibility, energy/thermal, App Group, widget, Siri, StoreKit, and interruption
  validation.

## Prioritized roadmap

### P0 — validate what already exists

1. Run the complete integrated unit/UI, Release, preflight, source-policy, backend, and Swift-core gates.
2. Inspect normal and federal PDF/RTF/TXT output with visual and parser fixtures.
3. Sign and test app/Share/widget App Group behavior, StoreKit, Foundation Models, Siri, Spotlight, Files, and
   accessibility on physical iOS 27 devices.
4. Complete privacy/support URLs, App Store disclosures, legal/privacy/accessibility/OPSEC review, and a veteran
   TestFlight beta.

### P1 — deepen the application packet

1. Native DOCX, Workday field-by-field copy cards, cover letters, interview stories, supplemental answers, recruiter
   follow-up, confirmation/evidence sheets, and redline.
2. User-approved local deadline/interview notifications and optional EventKit editors.
3. Scam-risk official-domain comparison and additional evidence/adversarial fixtures.
4. Read-only USAJOBS search followed by permitted Greenhouse/Lever adapters.

### P2 — veteran differentiation

1. Dated 56-jurisdiction veteran/VSO/resource manifest and state/occupation credential planner.
2. 12–18 month transition plan.
3. Branch/rank/component promotion packet builders only after authoritative source and expert review.
4. Consent-based interview, offer, wage, fit, and retention tracking.
5. Organization pilots and sponsored Complete access.

### P3 — separately gated

- Partner-authorized LinkedIn/Indeed/Workday/Handshake/employer ATS features.
- Educational VA disability and military-retirement estimates only after dated official formulas, reproducible tests,
  prominent non-affiliation/estimate language, and independent benefits/legal review.
- A public optional AI service only after production identity, authorization, security, privacy, cost, deletion,
  monitoring, and incident controls.

## Data useful for validation

Use public or de-identified data only:

- 5–10 public job URLs from each major platform.
- 25–50 de-identified resumes across branches/components, enlisted/officer paths, spouses, career fields, tables,
  columns, and scans.
- Redacted screenshots of failed parsing and synthetic application questions.
- Moderated testers including veterans with accessibility needs.
- Consent-based outcome labels such as packet completion, application, interview, offer, wage, fit, and retention.

Never supply passwords, SSNs, unredacted DD-214s, medical/disability records, classified or operational detail, banking
information, or production secrets.

## Claims the product must not make

- “Beats every ATS,” “ATS approved,” or “this score predicts an interview.”
- “Your MOS makes you qualified or licensed.”
- “Veterans' preference guarantees a federal job.”
- “This job or recruiter is verified safe.”
- “AI is unbiased.”
- “We automatically apply everywhere.”
- Legal, medical, disability-rating, retirement, employment, or benefits determinations.
- Government, Apple, AI-provider, job-platform, school, nonprofit, or employer endorsement without a signed
  relationship.

Recommended positioning:

> ApplyReady Vets turns verified military experience into truthful, candidate-controlled application materials and
> helps veterans organize the path from service to submitted.
