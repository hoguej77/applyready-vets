# ApplyReady Vets

> **An iOS 27-native, local-first career workspace for veterans.**

ApplyReady Vets turns verified military and civilian experience into clearer application material while preventing
unsupported claims. Its normal iPhone workflow works without an account, network connection, external AI provider,
API key, or Mac service.

This repository contains the current SwiftUI product source, native iOS extensions, local career engine, privacy
controls, and release documentation. Earlier Hogue ResMaster Python releases are retained as historical lineage; the
active product is **ApplyReady Vets**.

The active identity is:

- Public product name: **ApplyReady Vets**
- Subtitle: `Veteran Career Builder`
- Tagline: `From service to submitted.`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Publisher: `Jonathan Hogue Develops`
- Marketing version: `0.7.0`
- Build number: `18`
- Platform: `iOS 27`
- Xcode source of truth: `ios/project.yml`

The Xcode project, scheme, app/test targets, Swift module, shared core package, product, and source folders all use
`ApplyReadyVets`. `HogueResMaster` and `MusterForward` remain only in historical records and compatibility migrations
for earlier beta data. ApplyReady Vets is a working name pending formal trademark, domain, and App Store clearance.

This folder is self-contained. ApplyReady Vets 0.7.0, build 18, is configured for Xcode 27 (`27A5228h`), Swift 6.4,
and the iOS 27 SDK. The product intentionally requires iOS 27; it does not carry an older-iOS compatibility target.
Generic iOS builds, test-target builds, and the core package suite are validated locally. Signed physical-device
testing, final accessibility review, and the non-beta Xcode accepted by App Store Connect remain release gates.

## Product and business decision

ApplyReady Vets is the veteran-first flagship. The career engine should remain reusable for a later civilian product
without diluting the veteran brand.

The consumer model is a free download with one complete free job packet and one **$5.99 lifetime unlock** in the U.S.
storefront for unlimited tracked workspaces. Complete is the only consumer purchase. Organization
licensing for colleges, workforce agencies, veteran nonprofits, transition programs, and employers is the strongest
second revenue path. Do not use ads, subscriptions, tips, credits, feature packs, repeated upsells, or a personal Zelle
number as the primary model.

The first real access boundary is implemented: one fully usable tracked application workspace is free, and
**ApplyReady Vets Complete** unlocks unlimited tracked workspaces through one lifetime StoreKit 2 purchase. A local
StoreKit configuration supports Xcode testing. The source-controlled Release-candidate configuration enables this
single storefront boundary, but that does not make the product purchasable: the matching App Store Connect product,
agreements, tax/banking setup, purchase/restore/refund scenarios, and signed-device behavior still require validation
before submission.

## What 0.7.0, build 18, actually does

### Native app shell and job workspace

- A focused four-section structure—Today, Workspace, Applications, and Toolkit—keeps the broad product organized
  around the veteran's real work. Today shows one next action, a compact pipeline, recent applications, and quick
  starts. Toolkit makes O*NET, civilian/federal, LinkedIn, official-source, and privacy tools searchable.
- A four-stage first launch explains the product's value, creates a protected local household profile, asks the person
  to choose Private Core, Apple on-device assistance, or external help by approval, and reviews those choices before
  opening the workspace. It asks for a preferred name and optional career context—not an SSN, DoD ID, VA claim number,
  birth date, or medical information.
- Multiple people can keep separate local profiles, application trackers, and workspaces on one device. Switching a
  profile refreshes the app's optional Spotlight and widget projections. Removing one person deletes that person's
  protected in-app tracker/workspace records while preserving other profiles; files already exported to Files remain
  under the device owner's control. The last profile can be removed only through the separate full local-data erase.
- The one-free-workspace boundary is global to the installation, not multiplied by adding household profiles. Local
  profiles are not online accounts or cross-device sync, and StoreKit Family Sharing remains a separate launch choice.
- The daily workspace no longer uses a large logo header or oversized nested metric cards. It uses native typography,
  stable tabs, compact rows, semantic colors, SF Symbols, and one primary action per section.
- The native Job Tracker stores LinkedIn, Indeed, Workday, USAJOBS, JOFDAV, Handshake, and employer links alongside
  employer, role, job ID, status, notes, deadline, required documents, numbered export history, and up to six private
  status screenshots or photos. A portal confirmation or interview invite can be reviewed or explicitly shared from
  the application detail; the image is not embedded in the tracker database or sent to a career service.
- Each tracked application has its own protected working snapshot for draft, analysis, Truth Lock decisions, active
  step, LinkedIn kit, and export state; switching jobs does not reuse another application's working material.
- Tracker data is local, file-protected, checksummed, atomically saved, and recoverable from a last-known-good copy.
- The redesigned original icon unifies service paths into one doorway/check/forward-arrow mark without copying a
  government seal, military insignia, or VA identity.

### Private core

- Native iPhone/iPad Import → Profile → Analysis → Truth Lock → Export workflow.
- Private `LocalCareerEngine` evidence ledger, job and keyword analysis, gap questions, safety review, veteran/federal
  signals, scam-risk patterns, explainable readiness estimates, and conservative military-language translations.
- Readiness is shown as separate qualification-coverage, evidence-strength, and acronym-clarity sub-scores, not a
  hiring probability or unexplained universal “ATS score.”
- Truth Lock rejects missing citations, invented numbers, copied target titles, sensitive details, mismatched Apple
  citations, and tampered user edits. User-edited wording is checked again immediately before export.
- Evidence-backed LinkedIn headlines, About copy, skills, highlights, networking messages, and checklist. The app does
  not log in, scrape, edit, or post to LinkedIn.
- Recognizes and preserves links from Indeed, Workday, LinkedIn, USAJOBS, Handshake, JOFDAV, and employer sites. It
  provides user-controlled open/copy/share handoff and never stores job-site passwords or submits applications.
- Includes a native **Save to ApplyReady Vets** Share Extension for user-selected web URLs and text. A bounded,
  file-protected App Group inbox rejects embedded URL credentials and asks before replacing existing job text or its
  source link; a new link cannot silently attach to an older posting.

### Private import and export

- Local TXT, Markdown, CSV/TSV, HTML, RTF, image, selectable-PDF, and scanned-PDF import.
- Apple Vision OCR is capped at 12 PDF pages to protect performance and battery life, reports lower-confidence text, and
  tells the veteran to verify names, dates, military codes, and numbers.
- Unsupported formats such as DOCX can use the optional development service only after separate service permission.
- Local protected export creates employer-facing PDF, editable RTF, and parser-safe TXT versions with identical
  candidate-reviewed wording in Files → On My iPhone or iPad → ApplyReady Vets → Output, plus a separate private TXT review
  containing readiness checks, questions, Truth Lock trace, safety review, and non-affiliation notice. Export
  automatically adds the filenames as a numbered version in the linked Job Tracker workspace.
- Federal mode adds announcement and target series/grade context plus requirement-specific, dated USAJOBS checks.
  It does not invent an overall federal score. Federal export rejects a PDF that renders beyond two pages, but the user
  must still inspect the final layout and verify the announcement requirements.
- The bundled, offline O*NET military crosswalk contains 12,921 mappings from the official August 2024 release
  across Army, Marine Corps, Navy, Air Force, Space Force, and Coast Guard service-code namespaces.
- Native DOCX, a field-by-field Workday paste lab, cover letters, and the broader application-packet family remain
  roadmap work. The optional development service retains an earlier richer ZIP route; that ZIP is not presented as the
  normal iPhone export.

### Resilience and privacy

- The complete workspace autosaves after a short debounce: draft, analysis, proposal decisions, active step, and
  LinkedIn kit.
- The authoritative root workspace commits before its per-application projection, preventing an older projection from
  overwriting newer edits after an interrupted save. A lightweight draft revision replaces repeated full-resume hashing
  during typing and navigation.
- Saves use an atomic, schema-versioned, SHA-256-checked envelope with iOS complete file protection, a last-known-good
  recovery copy, corrupt-primary quarantine, and visible save/recovery errors.
- Service tokens use atomic Keychain update-or-add behavior with when-unlocked, this-device-only access.
- Release has no default service address and no developer connection editor. The networking layer permits only HTTPS
  optional services in Release and blocks local-development, credential-bearing, query-bearing, or insecure remote
  endpoints.
- Resume/job character limits, upload/JSON/export response limits, and HTTP(S)-only job-link validation bound
  user-controlled and service-controlled inputs.
- Separate service permission is required before unsupported-file upload, public-page retrieval, or service AI fallback.
- Critical sensitive-information findings pause all generative assistance while leaving the private safety review ready.
- “Erase local data” independently verifies removal of protected workspaces, recovery copies, tracker data, Keychain
  tokens, app-managed exports, job-status images, Headshot Studio images, shared inbox data, widget snapshots, and
  Spotlight records. An incomplete erase is recorded and retried before saved work can be reopened.
- The privacy manifest declares no tracking, and the iOS target intentionally includes no third-party SDK.

### Quiet, bounded assistance

- The private rules engine works when AI is off, not consented, unavailable, or failing.
- Each profile records a clear assistance preference. Private Core disables generative and external help; Apple
  on-device permits eligible local Foundation Models; external help by approval only exposes a reviewable draft and
  the Apple Share Sheet. It does not link a ChatGPT or Copilot account, embed a provider key, or silently enable the
  optional development service.
- On eligible iOS 27 devices, Apple Foundation Models can add up to six structured wording proposals after explicit AI
  consent. The app uses an iOS 27 Dynamic Profile, a single-use prewarmed session, zero-randomness structured output,
  live context/token budgeting, and mode-specific instructions. Each proposal must cite its exact resume source.
- Headshot Studio uses Apple’s system Image Playground sheet, rather than an embedded third-party image provider, when
  the device reports that image creation is available. A person chooses a private source photo and career framing,
  reviews the system-generated result, and explicitly shares or deletes it. Unsupported devices get a shareable photo
  brief instead of a broken generation action.
- Truth Lock verification is on by default. If the person turns pre-display verification off, AI wording is visibly
  labeled as an unverified draft; sensitive-content blocking remains active and employer-facing export still requires
  Truth Lock validation.
- Failed model wording receives one bounded, validator-guided correction attempt. A final code-native repair may only
  rearrange the candidate's exact cited words and is labeled honestly instead of being presented as AI output.
- Apple Evaluations enforce a 98% usefulness floor, a 50% bounded-model-yield floor, and 100%
  citation/safety/provenance floors across 54 synthetic veteran scenarios. The complete August 1 M4 Simulator run
  measured 100% hybrid usefulness and 96% bounded Apple-model yield. See
  [AI_QUALITY_STANDARD.md](AI_QUALITY_STANDARD.md).
- If Apple assistance does not succeed, the optional service is considered only when AI permission and separate service
  permission are both on.
- A service response cannot replace the phone's evidence, safety findings, job analysis, gaps, or scores. It may add at
  most 12 bounded pending proposals, each linked to the phone's exact resume evidence and rechecked locally by Truth
  Lock.
- The optional OpenAI backend uses structured schema output, a provider-side no-storage request, bounded output,
  timeout/retry limits, and a circuit breaker. Provider failure preserves the completed private result.
- Siri and Shortcuts use the iOS 27 App Intents foreground-mode contract to start a workflow, open Truth Lock or
  LinkedIn drafting, and save a user-supplied job URL without speaking private career information. Entitlement
  resolution completes before a shortcut can consume a workspace action. Optional Spotlight indexing can open a
  matching tracked application and is off by default; it excludes resume text, notes, evidence, job-ad text, and files.
- A small/medium WidgetKit “Next Application” widget reads a minimal App Group snapshot containing active count, role,
  employer, status, and deadline—not resume or evidence content.
- Copy actions use restrained success haptics, and the final application handoff offers Haptic Touch open/copy/share
  actions. The system Share Sheet remains the supported path to AirDrop, Files, Mail, Messages, and receiving apps.
- The WidgetKit target and minimal next-application snapshot are implemented. Failed projection writes clear stale
  details, temporary protected-data unavailability is not misreported as an empty tracker, and privacy revocation is
  retried. Signed App Group behavior and physical-device privacy still require validation. Home Screen quick actions
  and any public-link NFC experiment remain roadmap items; NFC is not represented as phone-to-phone file transfer.

## Market and experience decision

The July 29 market refresh reviewed live App Store metadata for nine leading resume apps, public recent/helpful review
samples, competitor screenshot sets, Apple navigation/onboarding guidance, and VA veteran-centered content and
accessibility principles. The evidence, implemented information architecture, $5.99 pricing decision, and
$200,000 operating-contribution planning model are in
[MARKET_EXPERIENCE_AND_PRICING_DECISION.md](MARKET_EXPERIENCE_AND_PRICING_DECISION.md).
The competitor-price comparison, ChatGPT/Gemini boundary, prompt contract, cloud-cost limits, and beginner command
surface are in [VALUE_AI_AND_PRICING_STRATEGY.md](VALUE_AI_AND_PRICING_STRATEGY.md).

## Fastest start on this M4 Mac

Open the `scripts` folder in Finder and double-click:

1. `applyready.command`

That one command center can check the Mac, run the iPhone Simulator, open the live Files folders, test the entire
project, review release blockers, or open Xcode. In Terminal, the same actions are explicit:

```zsh
./scripts/applyready.command check
./scripts/applyready.command run
./scripts/applyready.command files
./scripts/applyready.command test
./scripts/applyready.command release
```
2. `setup.command`
3. `start-everything.command`

Those launchers verify the machine, create the optional Python environment, regenerate the Xcode project, start the
development service, boot an iPhone Simulator, build, install, and launch the app. The app's private core remains usable
even when the service is stopped. See [AUTOMATION.md](AUTOMATION.md).

The same actions work from Terminal:

```bash
cd "/Users/jonathanhogue/Documents/Codex/2026-07-13/files-mentioned-by-the-user-hogueresmaster/outputs/HogueResMasterApp"
make doctor
make setup
make start
make preflight
```

Open `ios/ApplyReadyVets.xcodeproj`, select the **ApplyReadyVets** scheme and an iPhone Simulator, then press Run. Choose
**Explore with safe demo data** for the quickest full-workflow check.

## Optional development service

The iPhone's normal private flow does not need this service. To test unsupported files, public-page retrieval, the
Mac's Apple model, OpenAI fallback, or the earlier rich development ZIP:

```bash
cd "/Users/jonathanhogue/Documents/Codex/2026-07-13/files-mentioned-by-the-user-hogueresmaster/outputs/HogueResMasterApp/backend"
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
cp .env.example .env
uvicorn app.main:app --reload --env-file .env --host 127.0.0.1 --port 8000
```

Visit `http://127.0.0.1:8000/docs` on the Mac. Debug builds classify localhost and trusted private-LAN addresses as
development endpoints. Release builds reject them.

No OpenAI key is required. The default optional-service route is:

```dotenv
HOGUE_AI_PROVIDER=auto
```

`auto` prefers the Apple system model on this M4 Mac, then an explicitly configured OpenAI provider, then safe
deterministic rules. To enable OpenAI, put the key only in `backend/.env`:

```dotenv
OPENAI_API_KEY=your_server_side_key
HOGUE_OPENAI_MODEL=gpt-5.6-sol
```

Never put that key in Swift, Xcode, the app bundle, source control, screenshots, or support messages. No real OpenAI call
was made during this build because no user key was supplied.

For local physical-iPhone development, the Mac and iPhone must be on the same trusted network and the service may bind
to the Mac's private address. Use a long random development token. Never expose the development server directly to the
internet.

## Validate and safely package

Run the bounded release-quality gate:

```bash
make quality
```

It checks shell automation, adversarial source-package policy, staged manifest and ZIP integrity, backend tests/lint,
generic iOS test compilation, the standalone Swift core, and an unsigned Release build. Add live Simulator execution:

```bash
HOGUE_QUALITY_RUN_SIMULATOR=1 make quality
```

Run the separate live Apple-model quality gate only on a validated eligible
iOS 27 runtime (and repeat it on the signed release device):

```bash
make ai-quality
```

Normal local and Simulator UI regressions skip that 54-scenario model test so
an Apple Intelligence runtime that reports available but stops responding
cannot block unrelated release checks. The in-app request itself has a
20-second local deadline and returns the completed private analysis when that
optional model path times out.

Other focused checks:

```bash
make test
make test-live
make source-policy
make package
```

`make repair` is deliberately not a self-modifying programmer. It may clear only four named generated-cache locations,
regenerate the Xcode project from `ios/project.yml`, and retry validation once. It never rewrites app code, changes
privacy decisions, edits `.env`, or deletes drafts, research, documents, or user data. A real code/policy failure stays
failed for review.

`make package` stages a clean source tree, excludes private/user/build material, scans for secrets and unsafe archive
members, creates `SOURCE_MANIFEST.sha256`, verifies the candidate and final ZIP, and publishes a companion archive
checksum only after every check passes.

## What Apple work remains

Build 18 is a strong engineering beta, not a submitted App Store product. The remaining Apple milestone is:

1. Connect the Xcode project to Jonathan's paid Apple Developer team and register the App ID.
2. Create the single lifetime Complete product, agreements, tax, and banking information in App Store Connect.
3. Test purchase, pending, cancellation, restore, and refund/access behavior in StoreKit sandbox.
4. Complete physical-device, VoiceOver, Dynamic Type, Voice Control, Reduce Motion, compact-iPhone, iPad, energy, and
   interruption testing with veterans.
5. Create the privacy policy/support URLs, final metadata, screenshots, age rating, privacy answers, and review notes.
6. Upload a signed archive to TestFlight, run a veteran beta, fix findings, then manually approve App Review submission.

Codex credits do not pay Apple's Developer Program membership, App Store business fees, legal/entity filings, hosting,
or OpenAI API usage. Signing contracts, entering tax/banking information, agreeing to Apple terms, and the final
submission must remain Jonathan's identity-authorized actions.

## Product work after the release foundation

The highest-value next builds are:

- Native DOCX, Workday field-by-field copy cards, cover letters, branch promotion outputs, and broader application
  packets with real parser and visual-regression fixtures. PDF/RTF/TXT and the federal two-page rejection gate already
  exist and need expanded visual fixtures rather than being described as future formats.
- Add local notifications and optional calendar reminders to the shipped tracker after permission and interruption
  testing; status, notes, deadlines, required documents, links, and packet versions are already present.
- Extend the current URL/text Share Extension to user-selected files, then add EventKit and local notifications.
- Add a dated state/territory veteran-resource manifest for all 50 states, DC, American Samoa, Guam, Northern Mariana
  Islands, Puerto Rico, and U.S. Virgin Islands. The attributed official offline O*NET crosswalk is already shipped.
- USAJOBS search first, then permitted read-only Greenhouse/Lever adapters. LinkedIn, Indeed, Workday, Handshake, and VA
  account actions require their approval; the app must never scrape, store their credentials, or claim submission.
- Independent security, privacy, veteran/OPSEC, career-counselor, accessibility, and legal review.
- Add a VA disability calculator only after its formulas and official rate tables have reproducible source-date tests,
  expert review, and prominent educational-estimate/non-affiliation language. It is deliberately not presented as
  implemented in build 18.

If a public optional service is later offered, it also needs HTTPS hosting, real user identity and authorization, rate
limits, abuse/cost controls, deletion and retention controls, content-minimal monitoring, incident response, and staging
evaluations. That service is not required for the private App Store core.

## Project records

- [`FOUNDER_LAUNCH_OPERATING_PLAN.md`](FOUNDER_LAUNCH_OPERATING_PLAN.md) is the controlling start-to-finish founder,
  company, Apple launch, TestFlight, App Review, growth, KPI, and 100,000-install/$200,000 target plan.
- [`APPLE_SIGNING_AND_ACCOUNT_WORKSHEET.md`](APPLE_SIGNING_AND_ACCOUNT_WORKSHEET.md) records every non-secret Apple
  organization, identifier, signing, StoreKit, and App Store Connect prerequisite.
- [`APP_STORE_PRIVACY_ANSWER_DRAFT.md`](APP_STORE_PRIVACY_ANSWER_DRAFT.md) derives the preliminary App Store privacy
  answers from the actual local-first Release configuration and defines the mandatory re-review if a service is enabled.
- [`BETA_TEST_PLAN.md`](BETA_TEST_PLAN.md) is the signed-device, accessibility, StoreKit, representative-user, severity,
  feedback-safety, and TestFlight exit-gate protocol.
- [`GROWTH_MEASUREMENT_AND_LAUNCH_PLAN.md`](GROWTH_MEASUREMENT_AND_LAUNCH_PLAN.md) defines the privacy-preserving KPI
  contract, scenario economics, product-page plan, six launch gates, and the evidence required before marketing scale.
- [`reports/growth-plan/report.html`](reports/growth-plan/report.html) is the self-contained founder decision report;
  its canonical source and reproducible scenario query are in
  [`reports/growth-plan/artifact.json`](reports/growth-plan/artifact.json).
- [`app-store-metadata.json`](app-store-metadata.json) is the machine-checked App Store Connect draft. Run
  `make metadata-draft-check` while preparing it. The combined `make app-store-release-check` must remain blocked until
  Apple signing, public URLs, owner contacts, version `1.0.0`, a new build number, and every final placeholder are real.
- [`launch-site/`](launch-site/) contains a deliberately blocked draft company, support, privacy, terms, and official-
  sources site. `make site-draft-check` validates its structure; `make site-release-check` must fail until every legal,
  company, contact, draft, and indexing placeholder is resolved.

- [CHANGELOG.md](CHANGELOG.md) and [HISTORICAL_CHANGELOG.md](HISTORICAL_CHANGELOG.md)
- [FULL_HISTORY_AND_REQUIREMENTS_AUDIT.md](FULL_HISTORY_AND_REQUIREMENTS_AUDIT.md) — reconciled
  available-history, founder-requirements, implementation-status, and next-build audit.
- [RELEASE_NOTES.md](RELEASE_NOTES.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md)
- [AI_DEVICE_AND_PROVIDER_STRATEGY.md](AI_DEVICE_AND_PROVIDER_STRATEGY.md)
- [AI_QUALITY_STANDARD.md](AI_QUALITY_STANDARD.md)
- [IOS_27_LAUNCH_READINESS.md](IOS_27_LAUNCH_READINESS.md)
- [AUTOMATION.md](AUTOMATION.md) and [TESTING.md](TESTING.md)
- [COMPETITOR_RESEARCH.md](COMPETITOR_RESEARCH.md)
- [VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md](VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md)
- [VETERAN_PACKET_RESEARCH.md](VETERAN_PACKET_RESEARCH.md)
- [FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md](FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md)
- [BUSINESS_AND_PRODUCT_ROADMAP.md](BUSINESS_AND_PRODUCT_ROADMAP.md)
- [LEGAL_AND_LAUNCH_MASTER_PLAN.md](LEGAL_AND_LAUNCH_MASTER_PLAN.md)
- [LLC_OPERATING_AGREEMENT_STARTER_TEMPLATE.md](LLC_OPERATING_AGREEMENT_STARTER_TEMPLATE.md)
- [APPLE_APP_STORE_SUBMISSION_GUIDE.md](APPLE_APP_STORE_SUBMISSION_GUIDE.md)
- [BRAND_NAME_REVIEW.md](BRAND_NAME_REVIEW.md)

ApplyReady Vets is independent and is not affiliated with or endorsed by the U.S. Department of Veterans Affairs,
Department of Defense, OPM, USAJOBS, Apple, OpenAI, Microsoft, LinkedIn, Indeed, Workday, or any employer or job platform.
