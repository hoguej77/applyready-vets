# Competitor research: resume apps, veteran career tools, and ApplyReady Vets positioning

Market evidence captured July 29, 2026; current-product section reconciled July 30, 2026.

This document records visible US App Store and official-site research. It is product research, not a plan to copy
competitor designs, text, data, or protected workflows. Ratings, review counts, prices, and listings can change; the
signals below were visible on July 29, 2026. App Store privacy labels are developer-reported and are not an independent
privacy audit.

## Executive conclusion

The crowded resume category is good at guided forms, templates, and quick PDF export. It is repeatedly weak at pricing
clarity, draft reliability, explainable ATS claims, privacy, and veteran-specific evidence. Veteran transition apps cover
resources, timelines, benefits, or career exploration, but the audited products do not combine a veteran-controlled
application workspace, evidence-linked language, Truth Lock, federal and civilian packets, copy-ready platform handoffs,
and local-first privacy.

ApplyReady Vets should therefore compete as a **trusted veteran application command center**, not as another generic
“AI resume builder.” Its defensible promise is: preserve the veteran's truth, translate it carefully, show what remains
unproven, and help the user carry approved material into the systems where applications actually happen.

## What the current source does—and what it does not

The current source is ApplyReady Vets 0.7.0, build 18 with the iOS 27 hardening incorporated. It is a beta source tree, not a
submitted product.

### Current capabilities

- iOS 27-only SwiftUI Today, Workspace, Applications, and Toolkit structure.
- Isolated protected per-application workspaces and a local tracker with supported URLs, job ID, status, notes,
  deadline, required documents, due-soon context, and numbered packet files.
- Deterministic evidence, safety, gap, military-language, and readiness analysis. The UI shows qualification coverage,
  evidence strength, and acronym clarity instead of one opaque “ATS score.”
- Native Truth Lock before proposals appear and again before export; the candidate decides every material change.
- Optional iOS 27 Apple Foundation Models proposals after runtime availability and consent. Optional service/OpenAI
  fallback requires separate service consent, and Release ships with no endpoint.
- Local text-family, RTF, HTML, image, selectable-PDF, and bounded scanned-PDF import.
- Employer-facing PDF, editable RTF, and parser-safe TXT plus a separate private TXT review. Federal export rejects PDFs
  over two pages.
- Bundled August 2024 O*NET military crosswalk with 12,921 active mappings across all six branches.
- Federal announcement/series/grade fields and dated requirement-specific USAJOBS checks without a hiring score.
- Evidence-backed LinkedIn copy, a URL/text Share extension, user-controlled open/copy/share, App Intents, opt-in
  Spotlight metadata, and a privacy-minimal next-application widget.
- One complete application free and unlimited workspaces through one $5.99 lifetime StoreKit non-consumable. The
  Release-candidate source enables the boundary, but App Store Connect and signed sandbox validation remain open.

### Not built or not production-verified

- No sign-in, submission, or status synchronization with LinkedIn, Indeed, Workday, USAJOBS, or an employer ATS.
- No auto-apply, scraping, password collection, or background manipulation of another platform.
- No native USAJOBS search, Greenhouse/Lever adapter, or employer-authorized Workday integration.
- No native DOCX, Workday field lab, cover letter, interview/supplemental packet, branch promotion workflow, or full
  historical packet family.
- No VA API production integration, VA credential handling, claims filing, disability estimate, or benefits decision.
- No 56-jurisdiction resource manifest, EventKit/reminders, production accounts/service, or production analytics.
- No physical-device Foundation Models, App Group, Siri/widget, StoreKit, accessibility, or export-fixture completion.
- No promise that a resume will pass every ATS, receive an interview, or produce a hiring outcome.
- No App Store readiness claim until Apple signing, sandbox, device, accessibility, privacy, security, TestFlight, and
  independent review gates pass.

## Generic resume and career-app audit

| Product | Current visible US App Store signal | Strengths observed | Review or product friction observed |
| --- | --- | --- | --- |
| [Resume Builder⁺](https://apps.apple.com/us/app/resume-builder/id1047522998) | 4.8/5, 74K ratings | Guided steps, templates, duplicate versions, PDF/email/cloud export, AI cover-letter positioning | Weekly pricing is a recurring complaint; current IAPs include roughly $4.99–$6.99 weekly, $9.99 monthly, and $19.99 semester products |
| [Resume Builder Pro with AI](https://apps.apple.com/us/app/resume-builder-pro-with-ai/id1457411537) | 4.8/5, 39K ratings | More than 100 templates, offline use, guided creation, AI suggestions and review | Reviews show billing and cancellation anxiety around recurring products; visible IAPs include $14.99 monthly and $29.99 for three months |
| [Kickresume](https://apps.apple.com/us/app/kickresume-ai-resume-builder/id1523618695) | 4.7/5, about 4K ratings | More than 40 templates, web/mobile continuity, tailoring, checker, samples, interview tools, AI, optional human proofreading | Reviews mention rigid layouts, lost edits, bugs, ATS parsing regressions, and a second access/payment layer around some proofreading; visible products include $9.95 monthly, $24.95 yearly, and $27.99 proofreading |
| [Resume.com by Indeed](https://apps.apple.com/us/app/resume-builder-pdf-resume-app/id1527659872) | 4.8/5, 14K ratings | Free, no subscription or ads in the listing, 125+ templates/examples, guided PDF creation, strong job-board adjacency | Reviews mention sign-in loops, white screens, unsaved progress, and recent iPhone crashes; promoted AI capability is stronger on the desktop web experience |
| [Resume Star](https://apps.apple.com/us/app/resume-star-pro-cv-maker/id730643547) | 4.9/5, 17K ratings | Simple targeted resume and cover-letter PDFs, unlimited resumes, unusually clear honor-system “pay when interview” trust hook | Limited modern career intelligence; visible one-time IAPs include $7.99, $14.99, and $34.99 |
| [Got Resume Builder](https://apps.apple.com/us/app/got-resume-builder/id1505217304) | 4.7/5, 1.2K ratings | Free guided three-step flow, multiple versions, PDF/email output, online resume | Reviews mention failed save/email export and repeated contact entry; last visible update was January 2, 2025 |
| [CV Maker – AI Resume Builder](https://apps.apple.com/us/app/cv-maker-ai-resume-builder/id1608333252) | 4.6/5, 365 ratings | More than 50 templates, 36 languages, LinkedIn import, ATS checker, AI letters and translation | Weekly/monthly/yearly/lifetime tiers plus AI credit packs create pricing complexity; the privacy label includes tracking identifiers and advertising data |
| [Resume AI – Intelligent CV App](https://apps.apple.com/us/app/resume-ai-intelligent-cv-app/id1473493711) | 4.5/5, 1.6K ratings | Resume import, interview simulator, PDF/DOCX, job listings, courses, and video tools | Numerous IAP price points complicate the offer; the privacy label includes tracking and identity-linked contact and user-content categories |
| [Resume Builder Pro by Cosey](https://apps.apple.com/us/app/resume-builder-pro/id583018751) | 5.0/5, 2 ratings | $39.99 lifetime purchase and a no-data-collected privacy label | Very small rating base; the near-identical product name demonstrates App Store naming and brand-confusion risk |

Relevant developer privacy policies:

- [Resume Builder⁺ privacy policy](https://roundingsquares.com/privacy/)
- [Resume Builder Pro with AI privacy policy](https://www.uncaught.app/privacy/)
- [Kickresume privacy policy](https://www.kickresume.com/privacy/)

Kickresume's July 22, 2026 policy describes AI-provider processing and document-use conditions for product improvement.
That does not prove misuse, but it shows why ApplyReady Vets should make processing destination, retention, redaction,
and model-training choices understandable before sensitive career content leaves the device.

## Veteran-specific app audit

| Product | Current visible US App Store signal | Strengths observed | Opening for ApplyReady Vets |
| --- | --- | --- | --- |
| [Vet Launcher](https://apps.apple.com/us/app/vet-launcher-ai-career-coach/id6761058036) | Not enough ratings for a summary score | Closest direct competitor: all six branches; MOS/AFSC/rating input; O*NET and BLS context; transition timeline; benefits checklist; skill-gap roadmap; voice interview tools and widgets; $4.99/month or $49.99/year | Does not replace the need for a user-controlled evidence ledger, Truth Lock, multi-platform application packet, and transparent lifetime consumer option |
| [Project Trailhead](https://apps.apple.com/us/app/project-trailhead/id6751343349) | Not enough ratings for a summary score; free | Short 5–10 minute “missions,” transition and benefit resources, spouse content, gamification, and a strong one-next-action model | Resource navigation is useful, but it is not the same as completing and exporting a verified civilian/federal application packet |
| [Prize](https://apps.apple.com/us/app/prize/id6476713243) | 5.0/5 from 1 rating after its July 2026 rebuild | Vetted local/national resource discovery, user-controlled sharing, and identity/document connection claims | Earlier reviews reported setup and ZIP-code failures; the privacy label includes sensitive information, location, search, and user content. ApplyReady Vets can keep career-document processing narrower and more explicit |
| [MYTT365](https://apps.apple.com/us/app/mytt365/id1662888621) | 5.0/5, 2 ratings; free | Focused transition timing and planning | Narrower than an evidence-backed job-application workflow |
| [Salute to Suit](https://apps.apple.com/us/app/salute-to-suit/id6743656630) | 4.7/5, 15 ratings | Transition, compensation, and retirement modeling | Useful planning focus, but not an end-to-end civilian/federal application workspace |

Vet Launcher's published privacy policy names Firebase, Google Analytics, RevenueCat, and aggregated AI-improvement uses:
[Vet Launcher privacy policy](https://vetlauncher.com/privacy/). That reinforces the need for precise ApplyReady Vets
language rather than a vague claim that all AI is automatically private.

## What the market consistently gets right

- A guided first-run flow with one clear next action.
- Automatic formatting and a readable preview.
- Multiple tailored versions for different opportunities.
- Editable phrasing help instead of a blank page.
- Fast, transparent export.
- Reliable save and resume-later behavior.
- Clear progress and a finished artifact, not endless analysis.

## Repeated complaints and unmet veteran needs

### Category-wide complaints

- Surprise export paywalls, weekly subscriptions, unclear renewals, and additional AI-credit purchases.
- Lost drafts, crashes, sign-in failures, broken exports, and unreliable device-to-web continuity.
- Rigid templates that make the user fight the format.
- ATS scores or claims that are not explained and can conflict with actual parser results.
- Broad tracking or document-use policies that are difficult to understand.
- Generic AI wording that can sound inflated, repetitive, or untrue.

### Workforce hurdles the product should address

- Military duties, ranks, systems, and impact are hard to translate without losing accuracy or context.
- Veterans must prove civilian relevance while protecting classified, controlled, medical, and personally identifying
  information.
- Civilian, federal, contractor, college, and networking workflows ask for different documents and vocabulary.
- USAJOBS veteran preference, Schedule A, transcripts, DD214-related proof, and other required documents are fragmented
  across official sites.
- Job information is scattered across LinkedIn, Indeed, Workday, USAJOBS, employer ATSs, email, calendars, and notes.
- Accessibility, service-connected disability, employment gaps, and accommodation questions need respectful,
  user-controlled guidance—not automated disclosure.
- Local state and territory resources change, links decay, and users cannot easily tell whether guidance is current or
  official.
- Veterans may need a qualified human, accredited representative, career counselor, or transition professional; an app
  should help the user reach the right person without pretending to replace them.

Most audited App Store listings do not declare Apple accessibility features. ApplyReady Vets can differentiate by
testing and accurately declaring VoiceOver, Dynamic Type, sufficient contrast, reduced-motion behavior, and keyboard or
switch access where supported. Accessibility claims must be verified on devices before App Store submission.

## Prioritized differentiation

1. **Never lose the veteran's work.** Keep the existing protected draft foundation, then add autosave checkpoints,
   version history, crash recovery, and export regression tests.
2. **Use transparent one-time pricing.** Provide one complete evaluation workflow and one lifetime unlock; never ambush
   the user at export and never resell “AI credits” inside a purchased core feature.
3. **Make assistance evidence-backed.** Keep Truth Lock, show source evidence beside material changes, and make
   generated language a proposal the veteran approves.
4. **Build an honest ATS lab.** Report explainable sub-scores and formatting/parser risks against representative fixtures;
   never promise one universal ATS result or guaranteed interview.
5. **Create one application command center.** Save the job, source link, approved resume, cover letter, LinkedIn text,
   federal documents, contacts, dates, and next action without pretending external accounts are directly connected.
6. **Add verified official-resource and document readiness.** Use dated, refreshable official links and checklists for all
   56 US jurisdictions, federal hiring, records, and accredited help.
7. **Treat privacy as a product feature.** Prefer on-device processing, no ads, no credentials for other services, no
   content training by default, granular cloud consent, redaction, deletion, and plain-language processing receipts.
8. **Support safe human handoff.** Let the veteran choose which packet or evidence to share with a counselor, VSO,
   workforce office, college, or employer and clearly identify what is not being shared.

Items 1–5 build on parts of the current beta but still require production hardening. Items 6–8 are roadmap work except
for the current official-source notes, export controls, and non-affiliation language.

## Platform integration strategy

The safest useful integration is **user-controlled handoff**, followed by official public APIs and employer-authorized
connections where terms permit. The app must not collect a user's LinkedIn, Indeed, Workday, USAJOBS, ID.me, Login.gov,
or VA.gov credentials.

| Platform | Current source behavior | Recommended next step | Boundary |
| --- | --- | --- | --- |
| LinkedIn | Save/open link, accept user-shared text/URL, and generate copy-ready profile sections | Extend sharing to safe files and add section-by-section copy confirmation | No scraping, publishing, connection requests, or account creation |
| Indeed | Save/open job link, accept user-shared text/URL, and maintain verified material | Improve shared-text cleanup; monitor official consumer API options | Indeed partner APIs are mainly employer/ATS-facing; do not imply a consumer account sync |
| Workday | Save/open job link, accept user-shared text/URL, and provide parser-safe TXT plus PDF/RTF files | Add reliable field-by-field paste cards and native DOCX; pursue a connection only for an authorized employer tenant | No universal Workday login or cross-tenant consumer API promise |
| USAJOBS | Save/open/share a link, track requirements, create evidence/readiness guidance, and reject federal PDFs beyond two pages | Evaluate official search API integration and expand announcement/layout fixtures | Do not submit, certify eligibility, or claim federal endorsement |
| Employer ATS | Preserve the source URL and PDF/RTF/TXT packet version | Add real parser fixtures and the wider native packet; later evaluate Greenhouse/Lever public job adapters | Do not auto-apply or bypass employer controls |
| Calendar/reminders | Not integrated | Add user-approved EventKit deadlines and interview reminders | Never create calendar events without explicit permission |

Official platform references:

- [Indeed Partner API guides](https://docs.indeed.com/api-guides/)
- [Workday Developer Platform](https://developer.workday.com/)
- [LinkedIn User Agreement](https://www.linkedin.com/legal/user-agreement)
- [USAJOBS API](https://developer.usajobs.gov/)
- [O*NET Web Services](https://services.onetcenter.org/)

## Proposed 56-jurisdiction official-resource manifest

This is a **roadmap design, not a current feature**. Cover the 50 states, District of Columbia, American Samoa,
Guam, Northern Mariana Islands, Puerto Rico, and US Virgin Islands.

Each versioned record should contain:

- jurisdiction and audience;
- topic and plain-language purpose;
- official agency name;
- canonical URL and upstream source;
- effective date, last-verified timestamp, and replacement URL when retired;
- offline last-known-good copy metadata;
- review status and a visible “verify on official site” action.

The manifest should be signed, versioned, bundled with a last-known-good offline set, refreshed on a schedule, checked
for broken or redirected links, and display the verification date to the user. A failed refresh must not silently erase
working resources.

Primary official source set:

- [VA State Veterans Affairs Offices open dataset](https://www.data.va.gov/dataset/State-Veterans-Affairs-Offices/ezwx-6yyp)
  (OData; visible dataset update June 19, 2026).
- [National Association of State Directors of Veterans Affairs](https://nasdva.us/) directory.
- [VBA regional offices](https://www.benefits.va.gov/benefits/offices.asp?lv=true).
- [VA locations](https://www.va.gov/landing2_locations.htm).

### Accredited help and document readiness

At launch, deep-link to official sources:

- [Find a VA-accredited representative or VSO](https://www.va.gov/get-help-from-accredited-representative).
- [VA Office of General Counsel accreditation search and downloadable lists](https://www.va.gov/ogc/apps/accreditation/index.asp?lv=true).
- [Download VA benefit letters](https://www.va.gov/records/download-va-letters/).
- [Request military service records and DD214 information](https://www.va.gov/records/get-military-service-records/).
- [USAJOBS required documents](https://help.usajobs.gov/faq/application/documents).
- [SF-15](https://www.opm.gov/forms/pdf_fill/SF15.pdf).
- [OPM Schedule A hiring authority](https://www.opm.gov/policy-data-oversight/disability-employment/hiring/tabs/schedule-a-hiring-authority/).
- [USAJOBS Schedule A guidance](https://help.usajobs.gov/working-in-government/unique-hiring-paths/individuals-with-disabilities).
- [OPM veteran and family-member hiring information](https://piv.opm.gov/fedshirevets/veteran-job-seekers/veteran-family-members/).
- [USAJOBS unique hiring paths](https://help.usajobs.gov/working-in-government/unique-hiring-paths).

The [VA Letter Generator API](https://developer.va.gov/explore/api/va-letter-generator) has a sandbox, but production
access is restricted and generally requires VA participation or an agreement. Treat it as a partner-gated roadmap item,
not a launch dependency. Never request or store VA.gov, ID.me, or Login.gov passwords.

The app may explain requirements, organize a checklist, and help the user prepare user-approved career documents. It
must not determine legal eligibility, file a VA claim, act as a VSO or accredited representative, or send sensitive
records to an employer or model without a separate explicit user action.

## July 29, 2026 layout and review refresh

A second pass reviewed live App Store metadata for nine major resume apps, publicly accessible recent/helpful review
samples, and screenshot sets for six representative leaders. The dominant positive themes were guided steps, fast
formatting, editable examples, attractive previews, and reliable export. The dominant complaints were surprise weekly
paywalls, lost work, login failures, export crashes, paid plans with hidden AI limits, generic rewrites, rigid
templates, and vague ATS promises.

The resulting interface decision is documented in
[`MARKET_EXPERIENCE_AND_PRICING_DECISION.md`](MARKET_EXPERIENCE_AND_PRICING_DECISION.md). The app now uses four stable
destinations—Today, Workspace, Applications, and Toolkit—removes the large brand treatment from daily work, replaces
the marketing-heavy home screen with one next action and a visible pipeline, and makes the toolbox searchable.

## App Store positioning and pricing implication

Recommended primary category: **Business**. Recommended secondary category: **Productivity**. The likely rating is
**4+** if the submitted product remains a private career-writing utility without public user content, medical advice, or
benefits decisions; App Store Connect answers must reflect the actual release.

- [Apple App Store categories](https://developer.apple.com/app-store/categories/)
- [Apple product-page guidance](https://developer.apple.com/app-store/product-page/)
- [Apple age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)

The market strongly favors free download or free evaluation over paid-up-front acquisition. Recommended consumer offer:

- One real, exportable job-packet evaluation.
- One non-consumable `ApplyReady Vets Complete` lifetime unlock.
- $5.99 once in the U.S. storefront, with no founding-price or later mature-price ladder.
- No consumer tip ladder; Complete is the only consumer purchase.
- No subscription, ads, weekly billing, feature packs, or AI-credit ladder.

Paid-up-front at $8.99–$9.99 could filter casual users, but it would likely reduce install velocity, testing volume, and
review growth relative to the 100,000-install goal.

## Product-research guardrails

Do not copy competitor wording, templates, interfaces, or proprietary data. Do not use:

- “AI will get you hired” or equivalent outcome promises;
- unsupported ATS guarantees;
- fake direct-integration language;
- manipulative subscription or export gates;
- automatic disability, veteran-preference, benefit, or qualification decisions;
- auto-apply, credential collection, scraping, or unauthorized platform automation.

The release should be judged on completed trusted job packets, retained user work, verified accessibility, transparent
processing, reliable exports, and evidence that real veterans can finish the workflow—not on the number of AI labels or
the length of the feature list.
