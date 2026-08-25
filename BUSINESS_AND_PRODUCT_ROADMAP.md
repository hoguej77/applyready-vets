# ApplyReady Vets business and product roadmap

Last reconciled with current source: July 30, 2026.

Status: planning document. Revenue, install, conversion, partnership, and launch figures are scenarios—not promises.

## Product decision

ApplyReady Vets should launch as a veteran-first application workspace, not as another generic AI resume maker. The
consumer promise is:

> Turn verified military and civilian experience into truthful, candidate-controlled application materials, organize
> each opportunity, and help the veteran move from service to submitted.

The reusable career engine can support a separately branded civilian product later. It should not dilute the veteran
launch or cause ApplyReady Vets to imply government affiliation.

Current working identity:

- Name: **ApplyReady Vets**
- Subtitle: `Veteran Career Builder`
- Tagline: `From service to submitted.`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Developer display goal: `Jonathan Hogue Develops`
- Current source version: `0.7.0` build `18`
- Minimum OS: iOS 27

The name, trademark, domains, social handles, and App Store availability still require formal clearance.

## Current source truth

Implemented in the native app:

- Today, Workspace, Applications, and Toolkit.
- One isolated protected workspace per tracked application.
- Resume/job import, deterministic evidence analysis, safety findings, gap questions, and Truth Lock.
- Separate qualification-coverage, evidence-strength, and acronym-clarity sub-scores.
- LinkedIn/Indeed/Workday/USAJOBS/JOFDAV/employer link handoff without account access or auto-apply.
- Tracker status, notes, deadline, required documents, due-soon view, and versioned output filenames.
- 12,921 active August 2024 O*NET military occupation mappings across all six branches.
- Federal fields, dated USAJOBS checks, and a two-page federal PDF rejection gate.
- Employer PDF, editable RTF, parser-safe TXT, and separate private TXT review.
- Optional iOS 27 Foundation Models proposals behind consent and runtime availability.
- App Intents, deep links, opt-in Spotlight metadata, a privacy-minimal widget, and URL/text Share extension.
- One full application free and a StoreKit 2 lifetime boundary for additional workspaces.

Not implemented or not validated for release:

- Native DOCX, Workday field-by-field paste lab, cover letters, interview/supplemental answers, promotion packets, and
  the full historical packet family.
- Job-site sign-in, auto-fill, auto-apply, account sync, or third-party application-status ingestion.
- USAJOBS search, Greenhouse/Lever adapters, EventKit, local notifications, and a 56-jurisdiction resource registry.
- VA disability or retirement estimates, VA claims, benefit eligibility, or government-record account integration.
- Production cloud service, production OpenAI route, accounts, organization portal, analytics, or cohort reporting.
- Signed App Group, StoreKit sandbox, physical-device Foundation Models/accessibility, TestFlight, or App Review.

## Consumer offer

Use one transparent consumer purchase:

- Free download.
- One completed tracked application from import through export at no charge.
- **ApplyReady Vets Complete: $5.99 once in the U.S. storefront.**
- Complete unlocks unlimited tracked application workspaces.
- Existing free work is never held hostage.
- Restore Purchase is available through StoreKit.
- No subscription, trial conversion, ads, consumer tips, donations, credits, feature packs, export fee, or price ladder.
- Apple controls storefront taxes, local-equivalent pricing, refunds, and purchase processing.

The Release-candidate source enables this single boundary. That is not proof the purchase is ready: the matching
non-consumable must be created in App Store Connect and signed purchase, pending, cancellation, restore,
refund/revocation, Ask to Buy, interruption, and offline behavior must pass.

Do not route digital feature payments through Zelle, Apple Pay, or an external checkout. Do not call tips “donations.”
If a future approved nonprofit relationship exists, fundraising must be designed separately under Apple's applicable
rules and must not unlock app features.

## Revenue strategy

At $5.99, consumer revenue can support reach and trust but is unlikely by itself to fund a large hosted AI service,
high-touch support, and a team. The stronger second revenue path is organization licensing:

- colleges and universities;
- workforce boards and state agencies;
- veteran nonprofits and transition programs;
- employers and military-friendly recruiting programs;
- sponsored Complete access for cohorts.

Organization pricing and data terms are not yet defined. Any organization product must preserve veteran ownership,
avoid surveillance, minimize data, prevent individual hiring decisions from hidden scores, and never reduce the
features purchased by an individual.

Illustrative consumer scenario:

| Assumption | Example |
| --- | ---: |
| Verified installs | 100,000 |
| Complete conversion | 12% |
| Purchases | 12,000 |
| Gross consumer sales at $5.99 | $71,880 |

Net proceeds depend on Apple's commission, taxes, refunds, regional pricing, chargebacks, and business expenses. This
scenario demonstrates why the $200,000–$1,000,000 ambition requires organization revenue or much greater consumer
scale. It is not a forecast.

## Why users would choose this over a general chatbot

A chatbot can rewrite text, but ApplyReady Vets should provide repeatable product controls:

- a persistent evidence ledger and exact source citations;
- deterministic private analysis even when all generative AI is off;
- Truth Lock before display and again before export;
- one protected workspace and version history per job;
- local O*NET military mapping with source metadata;
- federal announcement context and dated checks;
- consistent PDF/RTF/TXT handoff;
- tracker deadlines, required documents, and packet versions;
- platform-specific copy without pretending to control third-party accounts;
- accessibility, deletion, recovery, and privacy behavior that can be tested as one product.

AI should remain a quiet writing enhancement. It is not the brand, the score, or the source of truth.

## Market position

Generic resume builders are strongest at guided forms, templates, and fast PDF creation. Repeated category complaints
include recurring-price confusion, export paywalls, lost work, generic rewrites, rigid templates, sign-in failures,
unexplained ATS claims, and unclear data use.

ApplyReady Vets should win on:

1. Veteran-specific evidence and military translation.
2. Candidate truth and approval.
3. Local-first privacy and recovery.
4. Civilian and federal workflow in one app.
5. Per-job organization beyond the resume.
6. One simple lifetime consumer price.
7. Honest platform handoff and explicit limitations.

Competitor observations and dated App Store signals are preserved in
[COMPETITOR_RESEARCH.md](COMPETITOR_RESEARCH.md) and
[MARKET_EXPERIENCE_AND_PRICING_DECISION.md](MARKET_EXPERIENCE_AND_PRICING_DECISION.md).

## Product sequence

### Phase 0 — prove the current source

1. Run one clean integrated iOS unit/UI suite, backend/core gates, unsigned Release build, release-candidate preflight,
   and source-package validation.
2. Visually inspect normal and federal PDF/RTF/TXT files, including page count, margins, wrapping, fonts, order, and
   parser fixtures.
3. Complete compact-phone, iPad, dark mode, rotation, Dynamic Type, VoiceOver, Voice Control, Reduce Motion, keyboard,
   pointer, interruption, offline, and storage/recovery tests.
4. Sign the app, Share extension, widget, and App Group; validate Siri, Spotlight, widget privacy, Share intake, Files,
   Foundation Models, and StoreKit on physical iOS 27 devices.
5. Publish accurate privacy/support pages and complete independent privacy, security, accessibility, employment,
   benefits, and OPSEC review.

### Phase 1 — application packet depth

1. Native DOCX with visual and parser fixtures.
2. Workday field-by-field copy cards, plain-language field mapping, and no universal Workday login claim.
3. Evidence-backed cover letter, recruiter follow-up, interview stories, supplemental answers, confirmation sheet, and
   private evidence trace.
4. Resume redline and clear version comparison.
5. User-approved deadline/interview local notifications and optional EventKit editor.

### Phase 2 — veteran and federal depth

1. Read-only USAJOBS search/details/filters and official ApplyURI handoff through a backend-held API key.
2. Federal specialized-experience trace, document checklist, preference/eligibility education, and expanded layout
   fixtures without eligibility decisions.
3. Dated 56-jurisdiction official veteran/VSO/resource manifest with broken-link checks and last-verified dates.
4. State/occupation credential planner and 12–18 month transition plan.
5. Branch/rank/component promotion packet builders only after authoritative sourcing and expert review.

### Phase 3 — permitted integrations

1. Read-only Greenhouse and Lever public job adapters.
2. Partner-authorized LinkedIn, Indeed, Workday, Handshake, or employer ATS capabilities only after contracts,
   authorization, OAuth/security review, consent, and production certification.
3. Never add scraping, unattended applying, credential capture, or anti-automation bypasses.

### Phase 4 — separately gated education

An educational VA disability or military-retirement estimate may be considered only after:

- dated official formulas/rate tables;
- reproducible edge-case tests;
- strong estimate/non-affiliation language;
- accessible explanations;
- independent benefits/legal/subject-matter review;
- a design that never files a claim or represents the user.

## Launch sequence

1. Finish the integrated local validation and resolve all high-severity findings.
2. Form the legal entity and complete Apple Developer enrollment through founder-authorized actions.
3. Register identifiers/App Group and configure the one App Store Connect product.
4. Complete signed physical-device and StoreKit sandbox validation.
5. Create final icon, screenshots, product copy, age rating, privacy answers, accessibility labels, support URL, privacy
   URL, and review notes against the actual binary.
6. Upload a signed archive to TestFlight.
7. Run a moderated veteran/military-spouse beta and fix high-severity evidence, export, accessibility, privacy, purchase,
   or data-loss issues.
8. Submit manually through the owner's Apple account only after the release checklist passes.

No automation should file an LLC, accept Apple agreements, enter banking/tax data, purchase memberships, send legal
forms, publish a production service, or submit the app without the owner's explicit identity-authorized action.

## Success measures

Primary KPI: **completed trusted applications**, not raw downloads or AI generations.

Measure with consent and data minimization:

- onboarding-to-first-import completion;
- analysis-to-review completion;
- review-to-export completion;
- second-workspace intent and Complete conversion;
- export failure and recovery rate;
- correction/rejection rate for proposals;
- accessibility task completion;
- 4-week return;
- optional self-reported application, interview, offer, pay, fit, and retention outcomes.

Guardrails:

- zero known critical unsupported-claim escapes;
- zero known credential capture or unauthorized submission;
- no hidden or surprise consumer charge;
- no government/platform affiliation claim without a signed relationship;
- no employer or organization use of sensitive personal traits in an individual fit score.

## Non-affiliation

ApplyReady Vets is independent and is not affiliated with or endorsed by the Department of Veterans Affairs, Department
of Defense, OPM, USAJOBS, Apple, OpenAI, Microsoft, LinkedIn, Indeed, Workday, or any employer or job platform.
