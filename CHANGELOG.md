# Changelog

## Unreleased — evidence and isolation hardening — 2026-11-14

- Made the optional Python service match the native product policy: it now returns separate document checks only and
  no composite application-readiness score. The keyword figure is explicitly described as job-keyword overlap, not a
  qualification decision, ATS simulation, or hiring prediction.
- Tightened both Truth Lock implementations so a source label cannot grant trust by itself. Backend proposals with
  uncited candidate-specific wording are rejected; native local-rule wording must exactly match an allowlisted
  military-code or acronym expansion at the supported resume heading. Claim checks preserve technical terms such as
  C++, C#, AI, and R and do not treat distinct leadership verbs as interchangeable. Native export now rebuilds its
  evidence ledger from the submitted resume and profile instead of trusting a saved response ledger.
- Made household recovery fail closed when its active-profile reference is missing or invalid. The app keeps all
  records hidden and clears the root draft until a surviving local profile is explicitly selected. It restores only
  the active profile's keyed snapshot, validates snapshot ownership, and blocks demo loading during recovery,
  preventing one household member's saved work from appearing under another person's session.
- Hardened optional-service extraction: blank documents and unreadable PDF/DOCX uploads return a clear validation
  error, and HTML extraction ignores hidden metadata/embedded content that could distort job-keyword analysis.
- Added regressions for uncited qualitative claims, forged local-rule provenance and placement, export-time evidence
  rebuilding, Jonathan/Denise restart isolation and corrupted snapshots, hidden HTML, blank/malformed imports, and
  truthfully scoped score wording.

## 0.7.0 protected-onboarding and household pass — 2026-08-02

- Replaced the earlier situation-picker welcome with a concise four-stage first launch: product value, protected local
  profile, explicit assistance level, and final review. The screen uses adaptive Apple system surfaces, typography,
  semantic VA-informed colors, one clear action, a visible independence/no-guarantee notice, and no government seal or
  implied VA affiliation.
- Added local household profiles for veterans, transitioning service members, Guard/Reserve members, spouses,
  caregivers, and civilian supporters. Each person receives isolated workspace and tracker state; switching profiles
  refreshes the optional Spotlight and widget projections without exposing another person's work.
- Kept identity collection intentionally small: preferred name plus optional branch/affiliation and career direction.
  Onboarding explicitly rejects the need for an SSN, DoD ID, VA claim number, date of birth, or medical information.
- Added profile-level Private Core, Apple on-device, and external-help-by-approval choices. Private Core disables
  generative/external paths; Apple assistance remains eligibility- and consent-gated; external help is a reviewable
  preview plus the Apple Share Sheet and never silently connects ChatGPT, Copilot, an API key, or the development
  service.
- Added protected profile removal with rollback on persistence failure. It deletes the person's in-app tracker and
  application workspaces, preserves other profiles, prevents deletion of the final profile outside full local erase,
  and accurately leaves previously exported Files copies for the device owner to manage.
- Preserved the one-free-workspace boundary across the whole installation so adding profiles cannot multiply the free
  entitlement. Local profiles remain distinct from StoreKit Family Sharing and are not described as cross-device sync.
- Fixed onboarding placeholder and disabled-control contrast, removed unsolicited keyboard focus, added stable UI-test
  identifiers that cannot collide with iOS system controls, and expanded automated coverage for every onboarding
  stage, largest accessibility text, Files import, Today, and the Complete boundary.
- Reproduced an iOS 27 beta SpringBoard/PosterUIFoundation snapshot crash with no ApplyReady Vets stack frames, then
  created a separate clean iPhone 17 Pro simulator without erasing the owner's existing simulator. The clean simulator
  completed all five current UI/accessibility scenarios successfully.
- Completed the August 2 regression in one clean pass: 112 of 112 native tests and 5 of 5 UI/accessibility tests
  passed, including the live Apple model evaluation and full simulated StoreKit lifecycle. The current unsigned Release
  build also passed. Strict App Store preflight accepted every local contract and reported only the missing Apple Team
  ID, live Support URL, and live Privacy URL.

## 0.7.0 founder operating-plan update — 2026-08-01

- Added `FOUNDER_LAUNCH_OPERATING_PLAN.md` as the single start-to-finish operating record from preliminary name
  clearance and California LLC formation through Apple organization enrollment, signing, TestFlight, App Review,
  launch, growth, and measurement.
- Recorded the August 1, 2026 preliminary USPTO exact-word knockout results while preserving the required
  confusing-similarity, common-law, App Store, domain, state, and attorney clearance steps.
- Reconciled the $5.99 lifetime offer with a scenario model: at 100,000 installs and 12% conversion, estimated proceeds
  after a 15% Apple commission are about $61,098 before other costs; the $200,000 goal therefore needs substantially
  more consumer scale, organization revenue, or both.
- Defined a 36-month planning horizon, staged install gates, founder/Codex ownership boundary, initial KPI contract,
  and the exact three source settings still blocking strict App Store preflight.
- Added a local accessible launch-site package with company, support, privacy, terms, and official-source pages derived
  from the shipping data flow. Every page is intentionally `noindex` and visibly draft until legal/company/contact
  values are approved.
- Added a two-mode launch-site validator: draft mode proves the local page structure; release mode rejects draft banners,
  placeholders, `noindex`, and missing monitored domain email before publication.
- Added Apple signing/account, App Store privacy-answer, and signed TestFlight beta worksheets covering the exact bundle
  IDs, App Group, StoreKit product, physical-device matrix, representative cohorts, sensitive-data limits, severity,
  and release exit gates.
- Added a canonical `app-store-metadata.json` draft and two-mode validator. Draft mode enforces Apple's current text
  limits, the exact StoreKit product/price, and public-claim controls; release mode also blocks owner placeholders,
  non-HTTPS URLs, unfinished contacts, beta version/build identifiers, and an unreviewed privacy state.
- Added `make app-store-draft-check` and `make app-store-release-check` so the source preflight, launch site, and App
  Store metadata are checked as one operating gate.
- Added `GROWTH_MEASUREMENT_AND_LAUNCH_PLAN.md` with a privacy-preserving north star, primary KPIs, drivers, guardrails,
  $5.99 revenue scenarios, product-page strategy, weekly review, and six scale gates. Added a self-contained founder
  decision report generated from a validated canonical artifact and reproducible SQLite scenario query.

The newest version section describes the current source. Older versioned entries are dated historical snapshots; older
iOS targets, storefront states, prices, names, and feature gaps are retained as history and are not current
configuration.

## 0.7.0 — July 30, 2026 — build 18

- Began the App Review cleanup pass: simplified consumer purchase copy to the one feature actually sold, removed
  future licensing/fundraising language from the purchase screen, added safe configurable public Support and Privacy
  links, and added an `--app-store` preflight that fails until a paid Apple team and valid public HTTPS URLs are set.

- Raised the veteran AI release floor to 98% useful output, 50% bounded Apple-model yield before local fallback, and
  100% for Truth Lock, exact citations, trusted provenance, unsupported-claim exclusion, sensitive-content exclusion,
  required pauses, and proposal limits. Added a 54-case Apple Evaluations corpus with 50 expected-usefulness cases
  across all six branches and varied occupations plus federal-grade, credential, prompt-injection, clearance, and
  sensitive-data boundaries. The final integrated run measured 100% hybrid usefulness and 96% bounded model yield.
- Added single-use model prewarming, zero-randomness generation, Apple error-specific safe fallback messages, rejection
  diagnostics, one bounded validator-guided self-correction pass, and an honestly labeled verified local repair that
  can only rearrange exact cited candidate words.
- Made pre-display Truth Lock verification a persistent Settings control that defaults on. When off, exact-cited AI
  output appears only as an unverified draft; sensitive-content blocking and final export verification remain active.
- Evaluated Foundation Models tool calling against the bundled O*NET crosswalk. Exact branch/code lookup worked, but
  the combined tool-plus-structured-resume session reproducibly failed in the iOS 27 beta model runtime. Kept O*NET
  deterministic and separate, kept model tools disabled for resume generation, and strengthened the evaluation gate
  so all 54 fixtures must record outcomes instead of silently dropping failed subjects.
- Completed the final local Xcode 27 beta 4 validation pass on August 1: 44 backend tests, 107 native XCTest cases,
  and 4 UI/accessibility tests passed on the iPhone 17 Pro iOS 27 Simulator. The Files test exercised Browse, Shared,
  Recents, On My iPhone, the app folder, Samples, and actual sample-resume intake; it did not substitute a picker-open
  check for the full user flow. Release preflight also passed. Apple signing, App Store Connect, and signed-device
  checks remain external launch gates.
- Added an adaptive light/dark launch background so cold Simulator/device startup transitions into the app without a
  harsh white flash. Added maximum-accessibility-text onboarding coverage that proves both start actions and the legal
  independence notice remain reachable.
- Hardened repeatable Simulator testing with a bounded, data-preserving reboot before StoreKit sessions, stale app
  termination, and removal of Xcode's temporary Home Screen test app even after failures. This resets the Xcode 27 beta
  storefront service that app termination alone cannot clear, prevents an empty simulated product catalog, and keeps
  the test icon from looking like a second installed product.
- Tightened the Today hierarchy after a live Simulator visual review: the single next action now stays ahead of
  due-soon cards, the greeting and section rhythm use less vertical space, and supporting pipeline information remains
  visible without competing with the primary task.
- Removed remaining forced URL construction from user-facing support, source, and license links. Invalid configuration
  now degrades to unavailable text instead of creating a launch-time crash path.

- Made a deliberate current-generation product break: every application, extension, widget, and test target now requires
  iOS 27. Removed the older-OS Foundation Models session branch and made the iOS 27 Dynamic Profile route authoritative.
- Upgraded Apple on-device assistance to use a versioned, prompt-injection-resistant, career-mode-specific instruction
  contract; deterministic evidence relevance ranking; exact model token counting; live context-size budgeting; explicit
  temperature and response-token limits; and the existing exact-citation plus Truth Lock acceptance gate.
- Added privacy-controlled Core Spotlight application discovery and deep links. Indexing is off by default and excludes
  resume text, notes, evidence, job-ad text, and files.
- Added the first WidgetKit extension: a small/medium next-application widget backed by a minimal App Group snapshot
  containing only active count, role, employer, status, and deadline.
- Migrated the Share extension to the iOS 27 object-loading API instead of retaining a newly deprecated attachment API.
- Added iOS 27 platform-contract tests for safe Spotlight identifiers, relevant evidence ranking, and the untrusted-input
  prompt boundary, plus [IOS_27_LAUNCH_READINESS.md](IOS_27_LAUNCH_READINESS.md) with official-source research,
  intentional non-claims, and release-candidate/TestFlight gates.
- Consolidated launch monetization to one consumer product: one complete workspace free and **ApplyReady Vets
  Complete at $5.99 once** in the U.S. storefront. Removed the optional tip catalog and purchase surface so the App
  Store offer has one price, no subscription, no credits, and no tip ladder.
- Reframed the revenue plan around realistic $5.99 unit economics: consumer purchases support reach, while
  organization licensing and sponsored access must carry material hosted-service and support costs.
- Added a versioned outcome-first assistance prompt with an explicit untrusted-data/prompt-injection boundary,
  candidate-control and Truth Lock invariants, empty-result stop behavior, and structured-output-only instructions.
- Added prompt-contract regression tests and prompt-version metadata to both optional Apple and OpenAI provider inputs.
- Added one beginner command center for Mac/Xcode checks, Simulator launch, live Files folders, tests, release review,
  bounded repair, packaging, and Xcode opening.
- Added [VALUE_AI_AND_PRICING_STRATEGY.md](VALUE_AI_AND_PRICING_STRATEGY.md) to document the current competitor-price
  comparison, honest ChatGPT/Gemini differentiation, $5.99 unit economics, and hosted-AI cost boundary.
- Moved tracked working material into isolated per-application, checksummed, atomically written, file-protected
  workspaces with recovery copies and a migration away from the prior embedded-workspace dictionary.
- Added local employer-facing PDF, editable RTF, and parser-safe TXT export with identical reviewed wording, kept the
  private review in a separate TXT file, and made tracker packet-version rows share files that still exist.
- Added a fail-closed federal export gate that removes the incomplete bundle when its rendered PDF exceeds two pages.
- Bounded resume, job, profile, military-service, federal, tracker, required-document, packet-version, and edited
  proposal inputs before persistence or analysis.
- Hardened the optional iOS client with an ephemeral URL session, no persistent cache/cookies/credentials, same-origin
  redirect enforcement, downgrade/user-information rejection, bounded request and streamed response sizes, task
  cancellation, multipart limits, and redacted length-bounded error messages.
- Added explicit release-preflight modes: `--release-candidate`, `--beta`, and `--self-test`. Release-candidate is now
  the default and requires the one-product Release storefront to be enabled; the self-test validates a bounded parser
  against normal, mismatched, duplicate, and 25,000-line fixtures.
- Improved Today with a due-soon view and active-workspace context, and made application rows, profile fields, summary
  metrics, and file handoff adapt more safely to accessibility text sizes and narrow widths.
- Added scene-transition saving and prevented underlying controls from remaining interactive or exposed to
  accessibility while a global work overlay is active.
- Replaced the deprecated iOS 27 App Intent launch flag with the foreground `supportedModes` contract and made Siri
  dialogs describe a handoff rather than promise that a destination completed. Initial StoreKit entitlement resolution
  now finishes before RootView consumes any pending shortcut that could create a workspace.
- Completed the one-product StoreKit lifecycle for this source milestone: localized storefront price, initial
  entitlement resolution, verified purchase/restore/refund-revocation handling, transaction listening, catalog reload
  after failure, and disabled conflicting controls while StoreKit is busy. The real product remains gated on App Store
  Connect and signed sandbox validation.
- Made the root workspace the authoritative first commit and treated the per-application file as a rebuildable
  projection, preventing stale projection data from overwriting newer edits after an interrupted save. Replaced
  view-facing full-resume hashing with a cheap draft revision so typing and navigation do not repeatedly hash the
  bounded résumé.
- Hardened active-application deletion and full local erase. Application deletion clears its tracker state, protected
  snapshot, matching quarantine files, widget projection, and Spotlight record while preserving reusable profile/base
  material. Full erase independently verifies every local store and Keychain item, persists an interrupted-erase
  marker, retries before restoring saved work, and surfaces incomplete cleanup immediately.
- Made Spotlight/widget privacy changes durable: opt-out writes a persistent deletion marker before asynchronous
  cleanup; stale widget details are cleared after any failed projection write; missing and temporarily protected data
  are distinguished; and newer projection generations supersede older callbacks without clearing a pending revocation.
- Extended input policy to the complete `WorkspaceDraft` and all persistence/analysis entry points. Added explicit
  source and extracted-text ceilings for RTF/HTML, bounded PDF/OCR accumulators, text-only HTML import with no external
  resource retrieval, a 2,048-character normalized URL ceiling, and bounded O*NET queries/results.
- Restored intentional Files integration with both `UIFileSharingEnabled` and
  `LSSupportsOpeningDocumentsInPlace`. Local employer PDF/RTF/TXT outputs and the separate private review use protected
  app-managed storage, validate handoff paths, re-run Truth Lock, attach existing filenames to tracker history, and
  remove an incomplete federal bundle if its PDF exceeds two pages.
- Separated the optional service's employer-facing ATS application archive from the explicitly requested private
  candidate-resources archive. Public output no longer silently includes readiness, safety/gap, evidence-trace,
  LinkedIn, college, federal-planning, or outreach material.
- Moved local-network development metadata into the Debug-only Info.plist and kept the Release plist free of the
  developer LAN exception. Recorded `ITSAppUsesNonExemptEncryption = false` for the reviewed source because it uses
  Apple operating-system networking and SHA-256 integrity checks rather than non-exempt custom encryption; final
  export-compliance answers still require review against the submitted binary.
- Improved narrow-width and accessibility-size behavior across welcome trust content, import handoff actions,
  application copy/share controls, tracker packet versions, multiline notes/documents, and readiness/status labels.
  Removed grouped accessibility semantics that collapsed distinct share actions and adjusted brand surfaces/semantic
  text for stronger contrast without claiming signed-device assistive-technology completion.
- Corrected release-facing truthfulness: “ready to export” is distinct from a completed packet, LinkedIn sharing names
  only the copy it includes, Release saves a job link without implying hidden page retrieval, O*NET metadata is dated
  rather than called live, and purchase/legal copy uses StoreKit's localized product information.
- Made local export report partial success honestly: valid files remain available when tracker persistence fails, but
  the UI no longer claims their packet version was saved and instead tells the user to retry the application save.
- Moved PDF/RTF/TXT/private-review generation out of the main actor into one cancellable, single-flight task. Draft and
  review revisions discard stale results, while tracker and UI commits remain main-actor isolated.
- Hardened PDF publication with a same-directory, complete-protection staging file, structural/page validation, federal
  page-limit enforcement before publication, and atomic replacement. A rejected replacement preserves the prior
  bundle and removes its hidden staging file.
- Replaced silent job-link fallback/coercion with visible validation. Invalid edits remain on screen and block saving;
  tracker-only identity changes preserve valid analysis, while an unsaved URL change blocks export until it is saved
  and reanalyzed.
- Aligned the shipping Settings and in-app privacy policy with the Release binary: external-service tokens and
  developer-server wording appear only in Debug, while Release states that its core is local/on-device. Pre-release
  support placeholders are also excluded from the Release UI.
- Removed third-party product names from the App Store keyword draft while retaining accurate service-handoff
  descriptions elsewhere in the listing.

## 0.6.0 — July 29, 2026 — build 17

- Replaced the rejected Home/Build/Jobs layout with four stable top-level destinations: Today, Workspace,
  Applications, and Toolkit. The new Today screen centers one next action, a compact application pipeline, recent
  opportunities, and a direct first-application action; Toolkit makes the military crosswalk, civilian/federal modes, LinkedIn handoff,
  official sources, and privacy help searchable.
- Rebuilt first launch around three real starting states—job found, resume ready, or service translation needed—while
  keeping the full workflow optional and preserving the safe demo path.
- Removed the oversized daily logo header, nested marketing cards, vague dashboard emphasis, and decorative gradient.
  Adopted a quieter native information hierarchy using system typography, SF Symbols, semantic surfaces, compact rows,
  stable navigation, and one prominent action per section.
- Refreshed the market audit using live App Store metadata for nine resume leaders, public recent/helpful review
  samples, and six screenshot sets. Documented the strongest positive patterns and repeated complaints without copying
  proprietary designs, content, code, templates, or workflows.
- Set the then-current consumer decision to one complete free application workspace plus **ApplyReady Vets Complete at $24.99
  once**. Removed the earlier founding-price/mature-price ladder and documented the 100,000-install, 12% conversion,
  $200,000 operating-contribution planning model.
- Made unsigned Simulator launches quietly tolerate the expected absence of a signed App Group container so visual and
  accessibility testing is not interrupted before a share action occurs.
- Replaced the earlier icon with an original branch-neutral doorway/check/forward-arrow mark. Production asset-catalog
  files are opaque, correctly sized, and do not reproduce a VA/DoD seal, service insignia, rank, eagle, or flag.
- Added the protected Job Tracker for LinkedIn, Indeed, Workday, USAJOBS, Handshake, JOFDAV, and employer links,
  including employer, role, job ID, status, notes, deadline, required documents, and numbered packet history.
- Added a separate checksummed, atomically written, file-protected tracker ledger with a last-known-good backup,
  corrupt-primary quarantine, recovery messaging, and delete support.
- Implemented the first real access boundary: one complete tracked workspace is free; ApplyReady Vets Complete unlocks
  unlimited tracked workspaces as one non-consumable StoreKit 2 purchase. Existing work is never locked. Added purchase,
  verified entitlement, revocation, restore, pending/cancel handling, and a local Xcode StoreKit configuration.
- Kept that StoreKit catalog test-only: Xcode's Run scheme and unit-test bundle can load it, while Release builds
  explicitly exclude it. Synchronized the optional service package to 0.6.0 and made both conditions preflight checks.
- Added a deterministic offline O*NET military crosswalk generated from the official August 2024 downloadable source:
  12,921 active mapped records across all six branches, exact/prefix/title search, O*NET links, source release,
  attribution, licensing link, source checksum, and explicit evidence/qualification limits.
- Added Federal mode fields for announcement number and target series/grade plus requirement-specific readiness checks
  based on the current USAJOBS two-page guidance. Federal readiness intentionally has no vague overall score and leaves
  final PDF page count for human verification.
- Corrected local export to use the app's Files-visible `Output` directory, keep the employer resume separate from the
  private review, use federal-specific naming/content, and attach each successful packet to tracker version history.
- Added simulator tests for tracker durability/recovery, one-free-versus-Complete access, federal checks, crosswalk
  title/code ranking, official bundled data, the real Apple Files picker, the paywall boundary, and accessibility of the
  redesigned welcome, import, and Today screens.
- Added adaptive large-text layouts for the Today action panel, pipeline, section controls, and empty application state;
  the strict Xcode accessibility audit now passes contrast, hit-target, clipping, and Dynamic Type checks across
  Welcome, Import, and Today.
- Kept the VA disability calculator explicitly out of this build. It remains an educational-estimate roadmap item
  pending dated official rate/formula fixtures, strong disclaimers, and independent expert review.

## 0.5.0 — July 29, 2026 — build 16

- Added restrained copy-confirmation haptics and a Haptic Touch context menu for opening, copying, and sharing from the
  final application handoff.
- Added automated Xcode accessibility audits for the welcome and import workflow screens; fixed tap-target, contrast,
  Dynamic Type, clipping, reduced-motion, and filename-label issues surfaced by the audit.
- Added a local release preflight that checks identity/version parity, bundle IDs, App Group alignment, privacy
  declarations, disabled beta storefront, empty Release service endpoint, StoreKit identifier consistency, App Intents,
  and accessibility-test registration while reporting founder-controlled public-release blockers separately.
- Added [APPLE_PLATFORM_INTEGRATION_PLAN.md](APPLE_PLATFORM_INTEGRATION_PLAN.md) with the current Siri/Share/Haptic Touch
  implementation, a privacy-safe widget sequence, the NFC tag-versus-file-transfer boundary, and Home Screen
  quick-action release criteria.
- Replaced the service-dependent execution path with a required private `LocalCareerEngine` baseline that runs without
  an account, network, AI model, OpenAI key, or Mac service.
- Added deterministic evidence-ledger construction, job/keyword analysis, missing-term questions, federal/veteran
  signals, scam-risk patterns, sensitive-information review, explainable readiness estimates, conservative
  veteran-language proposals, and local Truth Lock validation.
- Added a private LinkedIn kit with evidence-backed headlines, About copy, skills, highlights, networking messages,
  featured-content guidance, and a no-posting/no-affiliation disclaimer.
- Added private TXT/Markdown/CSV/TSV, RTF, HTML, image, selectable-PDF, and scanned-PDF import. Vision OCR is limited to
  the first 12 PDF pages, reports lower confidence, and requires manual verification of names, dates, codes, and numbers.
- Added local protected text export containing the verified resume, readiness context, open questions, Truth Lock trace,
  safety review, and non-affiliation notice. Corrected the interface and documentation so it no longer describes the
  optional service's richer ZIP as the normal offline export.
- Added a final export-time Truth Lock pass that rejects user edits adding unsupported numbers, sensitive material,
  copied target titles, missing citations, or source text that is no longer present.
- Strengthened Apple Foundation Models proposals so every cited evidence ID must include the exact claimed original
  resume line before the proposal can appear.
- Added a versioned, checksummed, atomic, file-protected workspace containing the complete draft, analysis, proposal
  decisions, workflow step, and LinkedIn kit.
- Added last-known-good recovery, corrupt-primary quarantine, verified restore, legacy-draft migration only after a
  successful save, 450 ms autosave, and visible save/recovery failures.
- Changed Keychain token writes to atomic update-or-add behavior and surfaced secure-save errors.
- Split optional assistance into AI consent and separate service consent. The service is now gated for unsupported-file
  conversion, public job-page retrieval, and fallback AI.
- Added fail-closed endpoint enforcement: Debug accepts local/private development addresses and secure HTTPS; Release
  rejects localhost/private-development, credential-bearing, query-bearing, and insecure remote endpoints and ships
  with no default service URL. Manual and Shortcut job links are restricted to normal HTTP(S) URLs.
- Added an embedded `Save to ApplyReady Vets` Share Extension for user-selected web URLs and text, backed by an App
  Group inbox with URL credential rejection, text/file-size limits, a 20-item ceiling, atomic protected writes,
  corrupt-item quarantine, explicit acknowledgment, deletion support, and confirmation before replacing current job
  text or its source link. Shared text and URL remain paired so a new link cannot silently attach to an older posting.
  Choosing “Decide later” now dismisses cleanly and reoffers the pending choice after a later app activation.
- Changed analysis routing to private baseline → eligible/consented Apple on-device enhancement → separately
  consented optional service fallback. A critical safety finding pauses both generative paths, and any failure preserves
  the private result.
- Changed optional-service handling so it can no longer replace local evidence, safety findings, job analysis, gaps, or
  scores. It may contribute at most 12 bounded pending proposals; every one must cite an exact local resume line and
  pass native Truth Lock. Added upload, input, JSON-response, and export-response limits.
- Added bounded OpenAI Responses structured-output handling with `store=False`, configurable timeout/retry/output caps,
  a persistent circuit breaker, cooldown recovery, and fake-client resilience tests. No live OpenAI request was made.
- Added adversarial source-package policy, secret/path/archive scanning, staged and ZIP manifest verification, final ZIP
  checksum publication, and explicit exclusion of `.env`, documents, logs, caches, credentials, databases, provisioning
  files, archives, and build products.
- Added a complete quality gate covering automation syntax, source-policy self-tests, validation-only packaging, backend
  tests/lint, iOS test compilation, Swift core tests, and unsigned Release build.
- Added bounded repair-and-validate automation with at most two total validation attempts and an allowlist limited to
  generated caches and Xcode-project regeneration. It cannot edit source or delete private/user files.
- Added a fail-closed production-service authentication check and disabled the Build 16 StoreKit storefront behind an
  explicit release flag so an accidental product setup cannot sell unvalidated or undelivered entitlement behavior.
- Expanded native regression coverage for workspace round-trip, corrupt-primary recovery, old-draft decoding, endpoint
  classification, exact Apple evidence linkage, export-time edited-text rejection, and safe Share-inbox behavior.
- Completed the live iOS 27 iPhone 17 Pro Simulator suite with 17 tests and 0 failures, plus a full demo walkthrough
  through private analysis, Truth Lock approvals, LinkedIn preparation, and export.
- Expanded backend coverage to 28 passing tests and the shared Swift core to 6 passing tests.
- Updated the competitor audit with current generic and veteran-focused products, review/pricing/privacy signals,
  defensible differentiation, and an honest current-versus-roadmap matrix.
- Added the 56-jurisdiction veteran-resource manifest plan covering all states, DC, and the five inhabited U.S.
  territories while keeping VA/ID.me/Login.gov credentials outside the app.
- Reconciled the README, architecture, AI strategy, privacy/security design, roadmap, test record, automation guide, and
  release notes with the actual Build 16 code and remaining App Store gates.

## 0.4.0 — July 29, 2026

- Adopted **ApplyReady Vets** as the public and internal working name for the veteran-first app.
- Renamed the Xcode project, scheme, app target, test target, app product, Swift modules, core package, tests, resource
  groups, source folders, and automation paths from `MusterForward` to `ApplyReadyVets`.
- Preserved the earlier MusterForward keychain service and draft filename only as compatibility migrations so beta users
  do not lose saved data.
- Updated the app display name, bundle ID, StoreKit product IDs, app icon asset, backend API title, AI prompt identity, export filenames, keychain service, local draft filename, and user-facing copy.
- Set Apple-style versioning to marketing version `0.4.0`; the completed internal rename advanced the build number to `13`.
- Advanced to build `14` for the iOS 26 interface and platform-integration pass.
- Advanced to build `15` for the evidence-backed workforce and application-integration pass.
- Added persistent job-link context, strict platform recognition for Indeed, Workday, LinkedIn, USAJOBS, Handshake,
  JOFDAV, and employer sites, and a user-controlled application handoff with open, copy, and share actions.
- Added a privacy-safe `Save a Job Link` App Intent and registered updated App Shortcut parameters at app launch.
- Replaced the LinkedIn builder's conspicuous magic-wand language with a natural evidence-review action.
- Corrected the iOS 26 visual hierarchy by reserving Liquid Glass for the primary action instead of applying glass to
  every content card.
- Corrected Settings and consent language so Foundation Models availability is not described as completed on-phone
  inference, and tightened the API-token Keychain item to when-unlocked, this-device-only access.
- Added real, availability-gated `LanguageModelSession` inference on eligible iOS 26 devices using a structured
  `@Generable` proposal schema; every phone-generated proposal must cite evidence, match original resume text, and pass
  native Truth Lock before it appears.
- Added [VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md](VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md) with official
  veteran-workforce evidence, platform API boundaries, the current iOS SDK audit, data needs, prohibited claims, and a
  prioritized integration roadmap.
- Reworked the welcome screen around the veteran, verified evidence, and application outcomes; removed prominent AI
  marketing so writing assistance feels optional, natural, and honest.
- Added native iOS 26 Liquid Glass treatment with iOS 17–25 fallbacks, a more compact workflow progress header,
  adaptive career-path cards, a persistent primary action, and production-safe hiding of development connection fields.
- Added real Apple Foundation Models availability checks so the app distinguishes eligible, disabled, downloading, and
  unsupported on-device model states without blocking the core workflow.
- Added privacy-safe App Intents for starting an application, reviewing Truth Lock, and opening the LinkedIn builder
  through Siri, Spotlight, Shortcuts, and supported system surfaces without putting resume text in the spoken response.
- Incorporated the July 13, 2026 `HogueResMaster_REVIEW_AND_IOS_ROADMAP.md` into the evidence-based history and current
  release gates, preserving its v11 safety findings, v12 validation record, native-iOS architecture decisions, OCR and
  document-fixture requirements, proposal provenance model, deletion controls, and visual-regression obligations.
- Added [APPLYREADY_VETS_PRODUCT_DECISION.md](APPLYREADY_VETS_PRODUCT_DECISION.md) to summarize the new brand, developer display goal, LLC path, pricing stance, and deferred work.
- Added [AI_DEVICE_AND_PROVIDER_STRATEGY.md](AI_DEVICE_AND_PROVIDER_STRATEGY.md) to document iOS/device requirements, Apple Foundation Models availability gating, OpenAI backend routing, ChatGPT boundaries, and Microsoft Copilot roadmap status.
- Added [COMPETITOR_RESEARCH.md](COMPETITOR_RESEARCH.md) after reviewing current App Store resume-builder competitors and documenting the veteran-specific differentiation strategy.
- Updated the business roadmap, App Store submission guide, legal launch plan, README, and AI strategy for ApplyReady Vets.
- Replaced the active App Store icon asset with a new ApplyReady Vets abstract unified-branches mark that avoids VA/DoD seals and official insignia.

## 0.3.2 — July 29, 2026

- Added [HISTORICAL_CHANGELOG.md](HISTORICAL_CHANGELOG.md), a reconstructed product-lineage changelog from the earliest surviving `v2.7` Python artifact through the current ApplyReady Vets iOS app.
- Documented the unrecovered v1.x through v2.6 gap instead of inventing history.
- Added a larger 30-name candidate set to the brand review so naming decisions are tracked in one place.
- Added veteran-packet exports: branch promotion packet, employer outreach letter, federal-contractor veteran note, college credit review request, college extension request, JOFDAV job-board strategy, and source notes.
- Added [VETERAN_PACKET_RESEARCH.md](VETERAN_PACKET_RESEARCH.md) to track JOFDAV, O*NET military crosswalk, six-branch coverage, VEVRAA/ADA boundaries, and college-credit source direction.
- Added [FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md](FEDERAL_CAREERS_AND_EXECUTIVE_RESUME_RESEARCH.md) after reviewing the supplied Federal Careers deck and local executive-resume PDF.
- Added federal-career export files: USAJOBS checklist, federal strategy, executive/LinkedIn notes, clearance-safe guidance, and federal/executive source notes.
- Updated iOS source links and export screen language for USAJOBS, veteran hiring paths, OPM ECQs, and clearance-statement verification.

## 0.3.1 — July 28, 2026

- Selected **MusterForward** as the working public product name for the veteran-first app and renamed the Xcode project, scheme, app target, test target, app product, and local Swift core package to match.
- Added a double-clickable `link-xcode-beta.command` helper to make `/Applications/Xcode-beta.app` the global command-line Xcode when Apple asks for a supported Xcode version.
- Updated the visible iOS display name, local-network usage text, backend API title, AI prompt identity, LinkedIn disclaimer, ZIP export filename, and StoreKit product IDs from the temporary MusterPath label to MusterForward.
- Changed the app bundle identifier to `com.jonathanhogue.musterforward` for the next generated Xcode project.
- Added a transparent StoreKit lifetime-unlock surface for `MusterForward Complete` with restore-purchase handling and separate optional Apple tips.
- Embedded the monetization decision in the roadmap: free download, one lifetime unlock, optional tips, Apple offer-code distribution, and organization licensing.
- Added launch operating goals centered on completed trusted job packets, paid conversion, retention, and Truth Lock failure prevention.
- Added release positioning for a future non-veteran spin-off so the evidence-first career engine can expand without weakening the veteran flagship.
- Added a legal and launch master plan covering California LLC formation, EIN, D-U-N-S, Apple Developer organization enrollment, App Store upload, App Review compliance, and public legal-document needs.
- Added an LLC operating agreement starter template for attorney review.
- Added a dedicated App Store submission guide with metadata draft, IAP product setup, TestFlight steps, and App Review note draft.
- Added a brand name review that keeps MusterForward as the flagship recommendation and tracks backup names, rejected names, company-name strategy, and future spin-off naming.
- Revalidated with Xcode 27 beta 4: iPhone build succeeded and live iOS Simulator tests passed with 3 tests and 0 failures.

## 0.2.0 — July 28, 2026

- Installed and first-launched Xcode 27 beta 4 with the matching iOS 27 beta 4 platform and Simulator runtime.
- Completed a real unsigned arm64 iPhone build with Xcode 27 beta 4, Swift 6.4, and the iPhoneOS 27.0 SDK while preserving an iOS 17 deployment target.
- Added automatic Xcode 27 macro-compatible build routing to all one-click automation.
- Added Xcode 27 Device Hub launch support and a one-click live Simulator test command.
- Fixed Xcode 27's generated Info.plist requirement for the XCTest target; 2 live Simulator tests pass.
- Added M4-first hybrid AI routing: Apple Foundation Models on-device, optional OpenAI cloud fallback, and deterministic fallback in every configuration.
- Added structured local-model output, compact prompt budgeting, timeouts, provider health reporting, and Apple-provider test coverage.
- Updated app consent and engine labels so veterans can distinguish on-device processing from redacted cloud processing.
- Expanded backend validation to 23 passing tests with Ruff clean.
- Installed the official OpenAI developer-documentation connector for Codex; one Codex restart is required before it becomes available to this task.

## 0.1.1 — July 26, 2026

- Added beginner-friendly local automation for setup, health checks, backend startup, native iOS builds, combined validation, clean source packaging, and one-command Simulator launch.
- Changed the Xcode target to compile the shared HogueResCore sources directly, avoiding nested Swift Package sandbox failures while preserving the reusable Swift package.
- Completed a real unsigned arm64 generic-iPhone build with Xcode 26.6 and the iPhoneOS 26.5 SDK.
- Compiled and linked the XCTest bundle successfully with Xcode.
- Revalidated all 19 backend tests and Ruff checks.
- Diagnosed the remaining launch blocker as macOS 27 beta running the macOS 26-only Xcode 26.6 release plus a CoreSimulator 1051.50/1051.55 mismatch; added automatic preference for the matching `Xcode-beta.app`.

## 0.1.0 — July 13, 2026

- Built native SwiftUI iPhone/iPad workflow and generated Xcode project.
- Added protected draft storage, Keychain token, privacy manifest, accessible components, and demo mode.
- Built FastAPI service with document extraction, public job URL retrieval, evidence ledger, readiness analysis, gap questions, veteran/federal signals, and suspicious-job warnings.
- Added optional server-side OpenAI Responses API integration with structured output and explicit consent.
- Added deterministic fallback and conservative starter military code translations.
- Added Truth Lock with citation, number, sensitive-content, approval, and server-side export validation.
- Added ATS text, Workday text, DOCX, trace, readiness, safety/gap, and ZIP export.
- Added special LinkedIn Profile Builder with copy/share UI and kit files in the ZIP.
- Added 19 passing backend tests, Swift package/XCTest sources, XcodeGen generation, parser validation, and linting.
- Documented internal HogueResMaster version lineage, official research, architecture, privacy/security, beta metrics, setup, and App Store gaps.
