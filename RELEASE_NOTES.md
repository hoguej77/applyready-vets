# ApplyReady Vets release notes

The 0.7.0 section describes the current source. Older numbered sections are dated historical snapshots; their earlier
prices, operating-system targets, names, tip experiments, and feature gaps are preserved to explain the product's
evolution and are not current promises.

## 0.7.0 beta — build 18 — July 30, 2026

Validation update (August 2): the current Xcode 27 beta 4 clean iPhone 17 Pro Simulator pass is green—112 native tests
and 5 UI/accessibility tests passed in their complete suites, including the live Apple model quality gate, simulated
StoreKit lifecycle, all onboarding stages, maximum Dynamic Type, and the real Files Browse/Shared/Recents/Samples
workflow. The unsigned Release build passed. Strict App Store preflight passed every source-controlled check and
stopped only for the Apple Team ID plus live Support and Privacy URLs. Backend validation remains green at 44 tests.
This is local engineering validation, not a signed TestFlight or App Store release.

- Replaces the first-run situation picker with a four-stage protected onboarding flow: value, local profile, assistance
  choice, and review. It requests a preferred name and optional career context while explicitly avoiding sensitive
  government identifiers and medical information.
- Adds isolated household profiles with safe add, switch, edit, and remove behavior. Removing a person clears that
  person's protected in-app career work and preserves everyone else; Files exports remain user-managed. The final
  profile still requires the separate full local-data erase.
- Adds honest assistance levels: Private Core, Apple on-device, and external help by approval. The external choice is a
  reviewable preview and Apple Share Sheet—not a ChatGPT/Copilot login, embedded key, or automatically enabled service.
- Keeps the one free workspace installation-wide and documents that local profiles are not StoreKit Family Sharing or
  cross-device family sync.

- Enforces a 98% useful-output floor, a separate 50% bounded-model-yield floor, and perfect
  citation/safety/provenance floors with Apple's Evaluations framework. The 54-case synthetic veteran corpus contains
  50 expected-usefulness cases. The complete run measured 100% hybrid usefulness and 96% bounded model yield.
- Prewarms one clean on-device session, uses zero-randomness structured output, gives a rejected response one
  validator-guided repair, and falls back to an honestly labeled local repair that can only rearrange exact cited
  candidate wording.
- Keeps Truth Lock verification on by default while allowing a Settings-controlled unverified-draft view. Sensitive
  content is still blocked and employer-facing export can never bypass Truth Lock.
- Keeps deterministic O*NET crosswalk search separate from resume generation. A tool-calling prototype returned the
  correct lookup but failed the combined structured-generation reliability test in the iOS 27 beta runtime, so it is
  not in the launch path.
- Keeps the Today screen action-led after live visual review: the next step appears before due-soon items, with a more
  compact greeting and calmer spacing. Support and official-source links now fail safely if configuration is invalid.
- Uses an adaptive launch background in light and dark appearances, proves first-run actions and the independence
  notice remain reachable at the largest accessibility text size, and removes Xcode's temporary UI-test icon after
  Simulator runs. Repeat tests now perform a bounded, data-preserving Simulator reboot and clear stale app/test
  processes before the simulated StoreKit session.
- Makes the current-generation direction explicit: the app, Share extension, widget, unit tests, and UI tests require
  iOS 27 and use the iOS 27 Foundation Models and App Intents contracts.
- Simplifies the launch offer to one complete free workspace and one **$5.99 lifetime Complete purchase** in the U.S.
  storefront. There are no subscriptions, tips, credits, feature packs, ads, or repeated upsells.
- Resolves the StoreKit entitlement before a Siri/Shortcut workspace action is consumed, keeps existing work accessible,
  uses the storefront's localized display price, adds product-catalog retry, and disables conflicting restore/purchase
  actions while StoreKit work is active.
- Separates every tracked application's draft, analysis, Truth Lock decisions, LinkedIn kit, and export state into its
  own protected, recoverable workspace. Root state now commits before the per-application projection, and a lightweight
  revision check removes repeated full-resume hashing during typing and navigation.
- Expands privacy-safe deletion: active-application deletion clears its protected state and Apple projections while
  preserving reusable profile/base material; full local erase independently verifies each store, persists an
  interrupted-erase marker, retries before restoration, and reports incomplete cleanup.
- Makes Spotlight and widget privacy revocation durable. Spotlight remains off by default; widget details require a
  separate opt-in. Failed writes clear stale details, protected-data unavailability is not presented as “no
  applications,” and neither projection contains resume, evidence, notes, job-ad text, or files.
- Bounds the entire draft and every import path, including RTF/HTML source, extracted text, PDF/OCR accumulation,
  normalized URLs, O*NET search/results, tracker data, federal fields, required documents, packet versions, and edited
  proposals. HTML import remains text-only and cannot fetch remote resources.
- Creates matching employer-facing PDF, editable RTF, and parser-safe TXT files plus a separate private TXT review in
  the app's Files-visible Output directory. The app exposes its Documents folder through both Files integration keys,
  rejects unsafe file handoff paths, revalidates Truth Lock at export, and fails closed if a federal PDF exceeds two
  pages. If the files succeed but tracker persistence fails, the files remain available and the app reports that their
  version history still needs to be saved. PDF publication now uses a protected same-directory staging file,
  validates the document before publication, and atomically replaces the final file.
- Runs packet generation outside the main actor as one cancellable operation. If inputs or Truth Lock decisions change
  while files are being created, the stale files are removed instead of being attached to the application.
- Keeps job-link validation explicit: invalid edits stay visible and block saving, and an unsaved URL change must be
  saved and reanalyzed before export instead of silently reusing or erasing an earlier link.
- Keeps public employer artifacts separate from private candidate resources in the optional development service. The
  employer ZIP contains only explicitly requested employer files; readiness, evidence trace, safety/gap material,
  LinkedIn drafts, and other private planning files require a distinct private export.
- Keeps the optional backend disabled in Release by shipping no service endpoint, uses an ephemeral bounded network
  client for consented development calls, and records that the reviewed binary uses Apple operating-system networking
  and SHA-256 integrity checks rather than non-exempt custom encryption. Export-compliance answers must still be
  reconfirmed against the final archive. Release-facing Settings and privacy text state that no external-service token
  is stored; developer-server language is Debug-only.
- Updates navigation, multiline fields, handoff controls, packet-version sharing, trust information, status wording,
  contrast, and Dynamic Type behavior for narrower and accessibility-sized layouts. Automated coverage is expanded,
  but signed-device VoiceOver, Voice Control, Switch Control, large-text, dark-mode, rotation, keyboard, and iPad
  validation remain release gates.
- Makes release preflight mode explicit: release-candidate requires the single StoreKit boundary enabled, beta requires
  it disabled, and self-test exercises the bounded parser.

This is still a beta source milestone. App Store Connect product creation, signed StoreKit sandbox cases,
physical-device Apple Intelligence/App Group/accessibility tests, TestFlight, legal/privacy review, and App Review are
not complete.

## 0.6.0 beta — build 17 — July 29, 2026

This build turns ApplyReady Vets from a single guided form into a coherent career workspace. The redesigned app uses
four stable destinations—Today, Workspace, Applications, and Toolkit—so the product can be comprehensive without
making every screen feel like a crowded toolbox.

New in this build:

- a redesigned first launch based on whether the veteran found a job, has a resume, or needs to translate service;
- a quieter daily layout with one next action, compact pipeline, searchable toolkit, and no oversized logo header;
- a redesigned, branch-neutral icon and native visual system;
- a protected application tracker with supported job links, statuses, notes, deadlines, required documents, and
  numbered export history;
- one complete free tracked workspace and the then-planned **$24.99 lifetime Complete unlock** for unlimited
  workspaces, with no subscription, credits, feature packs, or price ladder;
- a test-only local Xcode StoreKit catalog plus verified StoreKit 2 purchase and restore logic; the catalog is excluded
  from the shipping app bundle;
- 12,921 official August 2024 O*NET military occupation mappings available offline across all six branches;
- a Federal mode with announcement/series/grade context and individual, dated USAJOBS readiness checks instead of a
  fake overall score;
- clean employer-facing and separate private-review files in the Files-visible Output directory (the original build 17
  implementation was text-focused; PDF/RTF/TXT were added in the later 0.7.0 source);
- expanded simulator validation for durability, recovery, entitlement boundaries, O*NET search, Files, UI, and
  accessibility.

Not in this dated build: the VA disability calculator, automatic job-site submission/login, scraped
LinkedIn/Indeed/Workday data, native DOCX, reminders, signed-device StoreKit/App Store Connect validation, or
TestFlight. PDF/RTF/TXT were added after this dated build and are described in the 0.7.0 section.

## 0.5.0 beta — build 16 — July 29, 2026

### Release outcome

Build 16 is the first genuinely local-first ApplyReady Vets beta. A veteran can import supported material, analyze a
target job, review evidence-linked wording, build LinkedIn copy, and export a verified application copy without an
account, network, AI model, OpenAI key, or Mac service.

The app still uses assistance where it adds value, but does not market “AI” on every screen. The required private rules
engine runs first. Eligible and consented Apple on-device assistance may improve wording. A separately consented
optional service is the last fallback. Failure never discards the private result.

### What changed

- Added the private `LocalCareerEngine`, explainable readiness checks, veteran/federal signals, scam and sensitive-data
  warnings, gap questions, conservative military translations, and native Truth Lock.
- Added private Vision OCR for images and scanned PDFs with page, confidence, performance, and verification safeguards.
- Added protected full-workspace autosave, last-known-good recovery, corrupt-file quarantine, and visible save failures.
- Added exact Apple proposal-to-evidence linkage and final Truth Lock validation of user-edited wording at export.
- Added a private LinkedIn drafting kit and accurate local verified-text export.
- Added Release endpoint enforcement, no default Release service, and separate service permission for upload, public
  page retrieval, and optional AI fallback.
- The optional service can no longer replace the phone's private evidence, safety findings, job analysis, gaps, or
  scores. Only bounded pending proposals tied to exact local resume evidence can pass the native service gate.
- Added a native Share action for saving a user-selected job URL or text from Safari and supported job apps. It does not
  scrape, sign in, or replace an existing posting without approval.
- Added bounded structured OpenAI handling, failure circuit breaking, and fake-client resilience tests; no live user
  account or API key was used.
- Added adversarial source-package scanning, per-file manifest verification, archive checksum verification, a complete
  local quality gate, and a generated-cache-only one-retry repair path.
- Added an automated accessibility UI audit for the welcome and import workflow screens, plus the contrast, tap-target,
  Dynamic Type, clipping, readable-label, and reduced-motion fixes it identified.
- Added restrained copy-confirmation haptics, a Haptic Touch application-handoff menu, and a documented privacy-first
  sequence for widgets, Home Screen quick actions, NFC tags, AirDrop, and Share Sheet behavior.
- Added a local release preflight that verifies the beta release contract and prints the Apple-account, StoreKit,
  physical-device, legal, and App Store work that still requires founder action.
- Expanded market research across the named high-volume resume apps and the smaller veteran-transition category. The
  product roadmap now separates completed Build 16 capability from unbuilt or partner-gated claims.
- Build 16's StoreKit storefront is explicitly disabled until delivered entitlement behavior and sandbox cases are
  ready; matching products cannot become purchasable accidentally.
- Final validation passed 41 backend tests plus 2 subtests, 13 shared-core tests, 21 live native iOS unit tests, 1
  automated accessibility UI test, generic Debug test compilation, embedded Share-extension validation, the local
  release preflight, and an unsigned arm64 Release build.

### What “self-healing” means here

Build 16 can recover a corrupt local workspace from a verified last-known-good copy, fall back safely when optional AI
or networking fails, regenerate the Xcode project, clear only allowlisted generated caches, rerun tests once, and refuse
to package private or unsafe files. It cannot and should not rewrite its own App Store executable, invent fixes, bypass
Apple review, approve veteran claims, or submit third-party applications without the veteran.

### Honest beta limits

- The local export is a protected verified text copy, not yet the rich ATS/DOCX/PDF/Workday/federal packet.
- Shared files, a Job Passport/application tracker, EventKit reminders, licensed O*NET crosswalk, and verified
  state/territory resource directory remain roadmap items.
- LinkedIn, Indeed, Workday, Handshake, VA, and applicant-account access require their authorization. This build uses
  user-selected links/text and safe handoff only.
- Foundation Models still needs quality, latency, refusal, thermal, language/region, and fallback validation on eligible
  physical iPhones.
- Apple signing, StoreKit sandbox products, physical assistive-technology/device testing, legal/privacy URLs,
  TestFlight, veteran beta testing, and App Review are still required before a public launch.

### Current identity and price posture

- App Store working name: `ApplyReady Vets`
- Subtitle: `Veteran Career Builder`
- Tagline: `From service to submitted.`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Developer display goal: `Jonathan Hogue Develops`
- Marketing version: `0.5.0`
- Build number: `16`

The recommended model remains a free download, one useful free packet, one transparent lifetime unlock, optional Apple
tips that unlock nothing, and organization licensing. Final launch price should be tested with veterans before it is
entered in App Store Connect.

## 0.4.0 beta - July 29, 2026

### Current beta identity

The working public product name is **ApplyReady Vets**.

The Xcode project, target, scheme, modules, app product, tests, package, and source folders use `ApplyReadyVets`.
`HogueResMaster` and `MusterForward` remain only in historical notes and beta-data compatibility migrations.

### Positioning

- App Store name: `ApplyReady Vets`
- Subtitle: `Veteran Career Builder`
- Tagline: `From service to submitted.`
- Paid unlock: `ApplyReady Vets Complete`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Developer display goal: `Jonathan Hogue Develops`
- Marketing version: `0.4.0`
- Build number: `15`

The product promise is simple: help veterans create honest, evidence-backed job packets without inventing experience,
exaggerating service, promising ATS results, or implying VA, DoD, USAJOBS, LinkedIn, Indeed, Workday, Apple, Microsoft,
OpenAI, or employer affiliation.

### Monetization

Recommended launch model:

- Free download.
- One useful free job packet.
- `ApplyReady Vets Complete` as one transparent lifetime unlock.
- Founding launch price: `$19.99`.
- Mature price target after reviews/proof: `$39.99` to `$59.99`.
- Optional Apple tips that do not unlock features.
- Organization licensing for colleges, workforce boards, veteran nonprofits, transition programs, and employers.

Do not promise “no refunds.” Apple controls App Store refund decisions. The app should support restore purchases, support
links, server notifications, and access updates after refunded transactions.

### AI and device posture

- Present the product as a veteran career tool; do not use AI as the brand or repeat AI language across the interface.
- Keep writing assistance quiet and contextual, with detailed device/provider status in Settings.
- Keep broad install support with deterministic/private analysis and backend AI.
- Use Apple Foundation Models only when Apple Intelligence device, OS, region, language, and runtime availability checks pass.
- Keep OpenAI keys on the backend only.
- Treat ChatGPT account linking and Microsoft Copilot/student-account integration as future roadmap items, not launch
  promises.

### iOS 26 interface and Siri

- Uses native SwiftUI structure and controls so iOS 26 applies its system design naturally.
- Uses Liquid Glass only for navigation, actions, and supporting surfaces; content remains the focus.
- Keeps an iOS 17 deployment target and supplies non-glass fallbacks on older devices.
- Adds App Shortcuts for starting an application, reviewing Truth Lock, opening the LinkedIn builder, and saving a job
  URL.
- Siri responses never repeat or expose resume, job, service, or profile content.
- Saves and recognizes major job-platform links, preserves the original source, and provides a user-controlled
  open/copy/share handoff without scraping or auto-submission.

### Integration and workforce audit

- Documents the remaining barriers from transition timing through credentialing, suitable pay, accessibility, and
  retention.
- Separates shippable job-site handoffs from partner-only account and submission APIs.
- Identifies USAJOBS as the first direct API priority, followed by read-only Greenhouse and Lever adapters.
- Adds actual availability-gated `LanguageModelSession` inference with a structured proposal schema on eligible iOS 26
  devices; every phone-generated proposal is revalidated by native Truth Lock.

### Competitor lesson

Generic resume apps win on speed, templates, and review count. ApplyReady Vets should win on trust: veteran translation,
Truth Lock, USAJOBS, clearance-safe guidance, Workday paste output, LinkedIn copy, and full application packets.

## 0.3.1 beta - July 28, 2026

### Decision

The working public product name at this stage was **MusterForward**.

`HogueResMaster` remained historical engineering lineage only. In 0.4.0 build 12, the public app identity moved from
MusterForward to ApplyReady Vets; build 13 then completed the internal Xcode project, target, scheme, module, package,
test, product, and source-folder rename.

MusterForward is the veteran-first flagship. The broader career engine should be kept reusable for a later non-veteran spin-off, but the first public product should stay focused on veterans because that creates clearer trust, differentiation, and partnership opportunities.

### Positioning

- App Store name: `MusterForward`
- Subtitle: `Veteran Career Builder`
- Tagline: `Your service. Your next move.`
- Paid unlock: `MusterForward Complete`
- Bundle ID: `com.jonathanhogue.musterforward`

The product promise is simple: help veterans create honest, evidence-backed job packets without inventing experience, exaggerating service, promising ATS results, or implying VA, DoD, USAJOBS, LinkedIn, Indeed, Workday, Apple, or employer affiliation.

### Naming shortlist

| Name | Recommendation | Notes |
| --- | --- | --- |
| MusterForward | Use for veteran flagship | Strongest fit for military transition, six-branches logo, and job-search momentum. |
| EarnedPath | Keep as backup | Broader and dignified, but preliminary searching found unrelated active usage. |
| OneMuster | Keep as backup | Good unity signal, less obvious as a career app. |
| ServiceForward | Keep as backup | Broad, but more generic and preliminary searching found existing social/service usage. |
| HogueResMaster | Internal only | Good origin story, not a market-ready app name. |
| MusterPath | Retire | Clear enough, but less active and memorable than MusterForward. |
| CareerProof | Avoid | Existing career AI usage appears active. |
| ProofPath | Avoid | Existing AI/proofing and other product usage appears active. |
| SkillBridge | Avoid | Too close to the official DoD SkillBridge program. |

Formal trademark, domain, social-handle, and App Store clearance is still required before public submission.

### Monetization

Use a free download with one transparent lifetime unlock.

- Free: one complete trusted job packet from import through export.
- Paid: `MusterForward Complete` at a recommended `$59.99` once.
- Launch promo: consider `$39.99` for a dated founding-member window.
- Optional tips: small Apple In-App Purchase tips that never unlock features.
- Organization licensing: sell sponsored access to colleges, workforce boards, nonprofits, transition programs, and employers.

Do not use ads, subscriptions, feature packs, credits, repeated upsells, or a personal Zelle number as the primary payment system. Digital app feature unlocks should use Apple's In-App Purchase system. Apple Pay donation support should only be revisited through an approved nonprofit relationship.

### Product standard

MusterForward should be built as a trusted career packet builder, not a generic resume generator.

The release standard:

- Every suggested bullet must trace to evidence.
- Every material change must be user-approved.
- Truth Lock must block unsupported claims before export.
- LinkedIn, Indeed, Workday, USAJOBS, and employer sites must be handled through permitted links, copy-ready text, and user-supplied content rather than scraping or unauthorized automation.
- The score should be an explainable readiness model, not a fake ATS promise.
- Cloud AI must be optional, redacted, and validated.
- Veterans must always be able to export, review, and delete their own local data.

### Path to the all-time version

The strongest product is a veteran career operating system:

- Resume and job evidence analysis.
- Job-link workspace for LinkedIn, Indeed, Workday, USAJOBS, and employer pages.
- Copy-ready LinkedIn profile builder.
- Federal resume mode.
- Interview and recruiter-message builder.
- O*NET military-to-civilian skills crosswalk.
- Application tracker with deadlines, contacts, versions, and reminders.
- Educational VA disability calculator with dated official rates and clear disclaimers.
- Military retirement education only after expert/legal review.
- Organization portal for sponsored cohorts and privacy-preserving outcome reporting.

### Launch metric

The main KPI is **completed trusted job packets**, not downloads.

A completed trusted job packet means the user imported or pasted resume and job text, reviewed evidence-linked suggestions, approved or edited output, and exported a usable artifact.

Initial operating targets:

- 100,000 verified installs.
- 50%+ onboarding completion.
- 35%+ first job analysis completion.
- 25%+ first export completion.
- 20%+ four-week return.
- 8% to 12% lifetime unlock conversion.
- 0 critical unsupported-claim escapes.

### Sources to preserve

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Pay nonprofit requirements: https://developer.apple.com/apple-pay/nonprofits/
- Apple Small Business Program: https://developer.apple.com/app-store/small-business-program/
- LinkedIn User Agreement: https://www.linkedin.com/legal/user-agreement
- O*NET Web Services: https://services.onetcenter.org/
- USAJOBS resume guidance: https://help.usajobs.gov/faq/application/documents/resume/what-to-include
- VA disability ratings: https://www.va.gov/disability/about-disability-ratings/
- VA compensation rates: https://www.va.gov/disability/compensation-rates/veteran-rates/
