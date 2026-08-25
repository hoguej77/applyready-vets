# ApplyReady Vets / HogueResMaster historical changelog

Last updated: July 30, 2026

This is the product-lineage changelog reconstructed from the HogueResMaster Python files found on this Mac and the
current ApplyReady Vets iOS project. The Xcode project, scheme, targets, modules, package, tests, product, and source
folders now use `ApplyReadyVets`. Earlier names remain only as history and beta-data compatibility migrations. This
changelog is intentionally evidence-based: if a version file was not found, the gap is called out instead of invented.

## Source evidence reviewed

| Source artifact | File date | Role in history |
| --- | --- | --- |
| `/Users/jonathanhogue/Library/Mobile Documents/com~apple~CloudDocs/HogueResMaster_v2.7_2025-08-15.py` | 2025-08-15 | Earliest surviving full Python artifact found. |
| `/Users/jonathanhogue/Library/Mobile Documents/com~apple~CloudDocs/HogueResMaster_v7.6.py` | 2025-08-15 | Contains the condensed internal history for v7.4, v7.5, and v7.6. |
| `/Users/jonathanhogue/Downloads/Paperwork /Denise Resume /HogueResMaster_v11_cards.py` | 2025-08-16 | Cards-only v11 chat UX branch. |
| `/Users/jonathanhogue/Documents/Jonathan's Personal PaperWork/DL/HogueResMaster_v11_final.py` | 2025-09-04 | v11 final branch preserving cards, style packs, federal/healthcare helpers, and ZIP packaging. |
| `/Users/jonathanhogue/Documents/Jonathan's Personal PaperWork/DL/HogueResMaster_v11_ASCII.py` | 2025-09-04 | ASCII terminal UI shell branch. |
| `/Users/jonathanhogue/Documents/Jonathan's Personal PaperWork/DL/HogueResMaster_v11_ASCII_patched.py` | 2025-09-11 | Patched ASCII shell branch with payload-oriented additions. |
| `/Users/jonathanhogue/Library/Mobile Documents/com~apple~CloudDocs/HogueResMaster_v11_FIXED 2.py` | 2025-10-13 | Larger v11 fixed branch with cards-only UX, style packs, federal/healthcare helpers, ZIP packaging, and in-code roadmap. |
| `/Users/jonathanhogue/Library/Mobile Documents/com~apple~CloudDocs/HogueResMaster_FINAL.py` | 2026-01-17 | FINAL branch focused on extraction-first, ATS linting, Office hardening, and confirmation artifacts. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_v11_FIXED_Executable.py` | 2026-04-20 | Clean runnable executable rewrite of a broken v11 branch. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_v11_FIXED_OPTIMIZED_2026-04-21.py` | 2026-04-21 | Targeted procurement/Honeywell optimization branch. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_v11_procurement_bundle_2026-04-21.zip` | 2026-04-21 | Generated procurement deliverables bundle proving the output set. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_vNext_Workday.py` | 2026-04-21 | Workday-first export branch. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_v11_BASE_IMPROVED.py` | 2026-04-21 | Clean improved base branch. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_v13_BASE_PLUS.py` | 2026-04-21 | Base-plus branch; file header still says v11 base, but body adds self-test and acronym expansion. |
| `/Users/jonathanhogue/Documents/Codex/2026-07-13/files-mentioned-by-the-user-hogueresmaster/outputs/HogueResMaster_v12_HARDENED.py` | 2026-07-13 | Hardened Python successor used as a bridge toward the iOS product. |
| `/Users/jonathanhogue/Downloads/HogueResMaster_REVIEW_AND_IOS_ROADMAP.md` | 2026-07-13 | Contemporary v11 safety review, v12 validation record, and the first explicit native-iOS architecture roadmap. |
| `outputs/HogueResMasterApp` | 2026-07-13 onward | Native iOS/FastAPI product line, now publicly renamed ApplyReady Vets. |
| /Users/jonathanhogue/Library/Mobile Documents/com~apple~CloudDocs/Jonathan_Hogue_Senior_Office_Specialist_FINAL_v5_HogueResMaster_Packet.zip | 2026-06-09 | Preserved 21-artifact candidate/output packet demonstrating the mature document family that later iOS work must restore safely. |

## Known gaps

- No `v1.x`, `v2.0`–`v2.6`, `v3`, `v4`, `v5`, or `v6` source files were found in the searched Documents, Downloads, iCloud Drive, or Codex project paths.
- The v7.6 source states a condensed history for v7.4, v7.5, and v7.6. That is reliable as an internal note, but separate v7.4/v7.5 files were not found.
- Several v11 files are branches, not a clean straight line. The changelog treats them as branches where the file history shows parallel experimentation.
- Some historical branches are useful as design evidence but do not parse as runnable Python. They are not release-quality implementation sources.

## Product lineage summary

The product started as a Python-based resume and job-application packet generator. It evolved through:

1. ATS-safe document generation.
2. Veteran translation and MOS/AFSC/rating crosswalk concepts.
3. Batch job matching and silent search orchestration.
4. Chat-native cards-only UX.
5. Federal, healthcare, and Workday-specific outputs.
6. Safer extraction-first writing with confirmation artifacts.
7. Hardened evidence-preserving logic.
8. Native SwiftUI iOS app with a FastAPI service, Truth Lock, LinkedIn kit, Workday text, AI consent, and M4-first AI routing.
9. Public rebrand from HogueResMaster to MusterForward, then to ApplyReady Vets.

## Surviving historical releases and branches

### Unrecovered v1.x through v2.6 — before August 15, 2025

Status: not found.

What can be said safely:

- These versions likely preceded the consolidated `v2.7` master build.
- No code artifact was found, so no feature claims should be made beyond “pre-v2.7 internal work.”
- If older files are located later, this section should be replaced with file-backed entries.

### v2.7 — August 15, 2025

Source: `HogueResMaster_v2.7_2025-08-15.py`

Major changes:

- Consolidated multiple ideas into one ChatGPT Advanced Data Analysis-compatible Python file.
- Added veteran crosswalk concepts and starter mappings for codes such as 88M, 35F, 68W, 3D1/3D2, and additional military examples.
- Added batch mode through CSV job lists.
- Added silent search orchestration: if no jobs JSON existed, the script asked ChatGPT to fetch job results and save them silently, while Python itself made no external web calls.
- Added TF-IDF ranking and job deduplication.
- Added optional mileage filtering through `--miles` and `--latlon`.
- Added formatting controls for fonts, spacing, margins, headings, and default filenames.
- Added output packet generation: resume DOCX, cover letter DOCX, study guide HTML, redline diff DOCX, preflight JSON, and optional job tracker CSV.
- Added scoring concepts for match, requirements, ATS health, and overall grade.

Product significance:

- This is the earliest surviving complete product ancestor.
- It established the idea that the tool should generate a full job packet, not just a resume.
- It introduced veteran translation as a core differentiator.

### v7.4 — recorded in v7.6 internal notes

Source: `HogueResMaster_v7.6.py`

Recorded changes:

- Added print options.
- Added the “WOW mission” framing.
- Consolidated beta build.

Product significance:

- This is where the product mission became explicit: a career accelerator providing fast, ATS-ready, polished job materials.

### v7.5 — recorded in v7.6 internal notes

Source: `HogueResMaster_v7.6.py`

Recorded changes:

- Added auto-extraction of the candidate name from the resume.

Product significance:

- Reduced setup friction and moved the product toward “upload and run” behavior.

### v7.6 — August 15, 2025

Source: `HogueResMaster_v7.6.py`

Major changes:

- Added no-flags mode: auto-detect resume, job posting, company, and job title.
- Generated resume, cover letter, interview guide, ATS text, redline, and matches JSON.
- Added healthcare-specific enhancements and medical keyword/certification packs.
- Added scam/risk checks for suspicious job postings.
- Added veteran crosswalk support for common military codes.
- Added match, ATS, hire-likelihood, and letter-grade scoring.
- Supported auto mode and manual CLI mode.

Product significance:

- This was the first surviving version that strongly resembles the later “upload both files and I’ll handle the packet” user experience.
- It also established job-safety scanning as part of the product.

### Planned v7.7 — roadmap only

Source: `HogueResMaster_v7.6.py`

Planned but not confirmed as shipped in the found files:

- One-Tap ReRun for applying to the next job.
- Batch Mode UI with Next / Back / Print / Email-to-self.
- Salary bands per location.
- Expanded MOS/AFSC crosswalk and healthcare templates.

Product significance:

- These ideas later reappear conceptually in the iOS roadmap: reusable job packets, repeat workflows, salary intelligence, and expanded military translation.

### v11 cards-only branch — August 16, 2025

Source: `HogueResMaster_v11_cards.py`

Major changes:

- Shifted the UX toward a cards-only chat experience.
- Stayed quiet by default until both resume and job posting were present.
- Auto-ran once both required inputs were detected.
- Showed one friendly instruction card when input was missing.
- Showed one emoji summary card on success instead of debug chatter.
- Supported DOCX output with RTF fallback.
- Added safe error handling so raw tracebacks did not show to end users.
- Produced resume, cover letter, interview guide, ATS-safe text, and redline diff.

Product significance:

- This branch is the ancestor of the current onboarding philosophy: ask for only what is missing and avoid overwhelming users.

### v11 final / full cards branch — September 4, 2025

Source: `HogueResMaster_v11_final.py`

Major changes:

- Preserved the cards-only UX.
- Added or retained style packs: Classic, Hybrid, Technical, Executive, Healthcare, Federal, and CV.
- Added healthcare skill enrichment and federal formatting helpers.
- Added scam/risk heuristics.
- Added Deliverables.zip packaging for mobile users.
- Added roadmap notes for OCR, researcher tools, federal/USAJobs KSA expansion, LinkedIn/Profile support, and guided help.

Product significance:

- This branch shows the product broadening from “resume generator” to “career packet engine.”

### v11 ASCII TUI shell — September 4, 2025

Source: `HogueResMaster_v11_ASCII.py`

Major changes:

- Added a terminal UI shell with ASCII frames, tables, progress bars, log panels, error panels, and success panels.
- Added theme and width controls.
- Enforced a strict greeting policy: greet by name only after both resume and job posting were uploaded.
- Added an actions menu and router for parse inputs, build resume, cover letter, ATS text, interview guide, and ZIP packaging.
- Kept the shell safe for ChatGPT’s Python sandbox with no external dependencies.

Product significance:

- This branch experimented with a guided workflow UI before the later SwiftUI app.
- Some handlers were stubs, so it should be treated as a UX shell rather than the primary resume engine.

### v11 ASCII patched branch — September 11, 2025

Status: historical UI/payload experiment only; the surviving source has a syntax error and is not a safe runnable baseline.

Source: `HogueResMaster_v11_ASCII_patched.py`

Major changes:

- Continued the ASCII shell direction.
- Added JSON/payload-oriented helpers.
- Cleaned the interaction flow around upload status, greeting, dashboard, and action routing.

Product significance:

- This branch reinforced the idea of a structured session state and a guided sequence—concepts now present in the iOS Import → Profile → Analysis → Truth Lock → Export flow.

### v11 fixed branch — October 13, 2025

Status: historical feature inventory only; the surviving source has syntax-breaking content and must not be treated as a runnable release.

Source: `HogueResMaster_v11_FIXED 2.py`

Major changes:

- Documented itself as `HogueResMaster_v11.py` with filename fixed by request.
- Added cards-only UX, style packs, federal/healthcare helpers, and ZIP packaging.
- Added instruction-first behavior until both resume and job were present.
- Added single emoji summary card on completion.
- Added DOCX output with RTF fallback.
- Added federal checklist helper and healthcare skill enrichment.
- Added scam/risk heuristics.
- Added in-code roadmap notes for:
  - OCR for scanned PDFs.
  - Style-preserving DOCX export with safe fallback.
  - Golden test suite.
  - Passive-voice detection.
  - Duplicate bullet deduping.
  - Impact metric suggestions.
  - USAJobs KSA support.
  - Specialized Experience detection.
  - Clearance normalization.
  - Expanded domain packs.
  - LinkedIn/profile JSON support.
  - Guided onboarding and help modes.

Product significance:

- This is the strongest surviving v11 “feature-breadth” branch.
- It directly foreshadows many current app goals: OCR, federal mode, LinkedIn kit, safer evidence handling, and guided UX.

### FINAL branch — January 17, 2026

Source: `HogueResMaster_FINAL.py`

Release notes embedded in source:

- v11 → FINAL:
  1. Resume extraction-first: build output from the user’s resume text when possible.
  2. Keyword injection disabled by default; keyword alignment became evidence-based.
  3. Office hardening: run-level font enforcement in DOCX output.
  4. Strict ATS lint option; always writes ATS report.
  5. `CONFIRM_THESE_ITEMS` artifact to reduce back-and-forth.
  6. Removed duplicate function definitions and consolidated flow.

Additional changes:

- Added Office compatibility rules for Word desktop and iOS.
- Avoided templates and generated documents from scratch.
- Required ATS-safe headings, linear reading order, no tables/columns/images/headers/footers, and common fonts.
- Added a prompt packet for constrained AI rewriting.
- Documented future PyInstaller packaging and watch-folder automation.

Product significance:

- This branch is where the product philosophy shifted from “optimize aggressively” toward “do not invent; confirm what is missing.”
- It is the conceptual predecessor of the current Truth Lock system.

### v11 fixed executable branch — April 20, 2026

Source: `HogueResMaster_v11_FIXED_Executable.py`

Major changes:

- Cleaned a broken v11 source into a runnable executable Python script.
- Fixed syntax-breaking fragments such as broken try/except indentation, malformed function signatures, duplicate argparse blocks, and invalid placeholder sections.
- Generated executive ATS-safe resume and cover letter DOCX.
- Added consistent professional header formatting.
- Added a small sanity-check report to ensure incorrect/old contact details were not present.
- Supported JSON payload input and direct contact-field overrides.

Product significance:

- This was a repair branch focused on runnability and document quality.
- It was narrower than the full product vision but important because it proved the pipeline could be cleaned into executable shape.

### v11 procurement optimized branch — April 21, 2026

Sources:

- `HogueResMaster_v11_FIXED_OPTIMIZED_2026-04-21.py`
- `HogueResMaster_v11_procurement_bundle_2026-04-21.zip`

Major changes:

- Created a targeted Honeywell Procurement Buyer I packet.
- Added procurement keyword handling and procurement-aligned tailoring.
- Reframed account/customer-success experience toward forecasting, cross-functional coordination, escalation, risk monitoring, compliance-minded execution, and supplier/vendor-adjacent language.
- Generated resume DOCX, cover DOCX, ATS TXT, payload JSON, summary JSON, redline TXT, guide HTML, and deliverables ZIP.
- Explicitly avoided unsupported FAR/DFAR, SAP, or purchase-order ownership claims.

Product significance:

- This branch is important because it shows the product’s best direction: role-specific translation without overstating experience.
- It also exposed a problem: the generated summary reported a low coverage score, showing why future versions needed better scoring methodology and evidence logic.

### June 2026 preserved candidate packet — June 9, 2026

Source: Jonathan_Hogue_Senior_Office_Specialist_FINAL_v5_HogueResMaster_Packet.zip

Status: output evidence only. The generator source was not included, so this is not a separate source release.

Confirmed deliverables:

- Master and job-targeted resume/cover-letter documents.
- ATS text and an ATS evidence report.
- Confirmation-items sheet, supplemental application answers, redline, interview guide, and constrained prompt packet.
- DOCX/PDF artifacts and a nested deliverables ZIP.

Product significance:

- This is the clearest preserved evidence that the product evolved into a multi-artifact candidate packet, not just a resume writer.
- The native app should restore this document family only through local evidence, Truth Lock, privacy boundaries, and visual regression tests.

### vNext.1 Workday-first branch — April 21, 2026

Source: `HogueResMaster_vNext_Workday.py`

Major changes:

- Focused on Workday upload-safe exports rather than browser autofill.
- Generated two document families:
  - ATS/recruiter DOCX with approved formatting.
  - Workday DOCX, Workday PDF, and Workday TXT with parser-first formatting.
- Added Workday field map for copy/paste verification.
- Added structured `resume_payload.json`.
- Added lint report to flag formatting likely to break Workday parsing.
- Added template families such as Account Manager, Procurement Buyer, and General.
- Extracted salary mentions from job descriptions.
- Explicitly stated it does not log into any site or auto-submit applications.

Product significance:

- This branch became the basis for the current app’s Workday paste/export idea.
- It correctly avoided risky automation of third-party job sites.

### v11 base improved branch — April 21, 2026

Source: `HogueResMaster_v11_BASE_IMPROVED.py`

Major changes:

- Rebuilt the v11 base into a cleaner runtime foundation.
- Preserved chat-native cards-only workflow.
- Added explicit flow state: welcome, waiting for resume, waiting for job, ready to build, reviewing risk, done, and error.
- Added dataclass models for profile and experience.
- Added mode support: auto, classic, education, military, federal, healthcare.
- Added ATS/recruiter export, Workday-safe export, ZIP packaging, job-risk scan, document extraction, and payload loading.
- Explicitly avoided website form/browser automation.

Product significance:

- This branch is the first clear “application architecture” version rather than a single-purpose script.
- It is a direct ancestor of the current service/app architecture.

### v13 base-plus branch — April 21, 2026

Source: `HogueResMaster_v13_BASE_PLUS.py`

Important note:

- The file is named v13, but its header still says `HogueResMaster_v11_BASE_IMPROVED.py`. Treat it as a base-plus branch, not a perfectly labeled release.

Major changes:

- Added acronym expansion for terms such as ATS, MOS, KSA, and HIPAA.
- Added post-processing for acronym expansion across generated files.
- Added `--selftest` smoke-test mode.
- Added mode-help output.
- Kept Workday-safe export, ZIP packaging, risk checks, mode handling, and profile dataclasses.

Product significance:

- This branch improved testability and beginner readability.
- It points toward app-store-grade onboarding, where acronyms must be explained for nontechnical users.

### v12 hardened branch — July 13, 2026

Source: `HogueResMaster_v12_HARDENED.py`

Major changes:

- Rebuilt the improved base into a hardened successor.
- Added dependency error capture for optional document/PDF/network libraries.
- Added pypdf first with PyPDF2 fallback.
- Added ReportLab PDF writing support.
- Added HTML-to-text parsing for imported job pages.
- Added safer profile bootstrapping from resume text.
- Changed metric-shell behavior into a no-op so exports do not contain invented metrics.
- Added integrity warnings for unsupported or suspicious profile content.
- Added safer output stems and unique output names.
- Added Workday DOCX/PDF/TXT pack, Workday lint, ATS outputs, cover letter, interview guide, redline, and ZIP packaging.
- Preserved the no-browser-automation boundary.

Product significance:

- This is the immediate Python bridge to the iOS app work.
- It hardened the product around a key rule: never fabricate resume claims.

### v11 safety review and first iOS roadmap — July 13, 2026

Source: `HogueResMaster_REVIEW_AND_IOS_ROADMAP.md`

This report is not a separate app release. It is a contemporary audit of v11, a validation record for the hardened v12
branch, and the earliest surviving explicit architecture plan for the iOS product.

Findings preserved from the report:

- Earlier healthcare, education, federal, keyword-injection, metric, profile, and cover-letter paths could transform job
  requirements or generic defaults into unsupported candidate claims.
- Job HTML needed to be converted to visible text and escaped before appearing in an exported guide.
- Missing, unreadable, empty, or malformed inputs needed to stop with a clear error instead of producing a
  plausible-looking generic resume.
- ZIP behavior, repeated-run filenames, optional-dependency failures, and resume/job file selection needed to be
  explicit rather than silent.
- “ATS Scan” and “Hire Likelihood” overstated what simple heuristics could know. The review recommended descriptive,
  non-predictive scoring and a clear disclaimer.
- Every proposed edit should carry an ID, before/after text, reason, supporting source excerpt, confidence, and approval
  state; only approved edits should be exportable.

The report recorded 15 passing v12 regression tests and a successful integration run producing ATS, Workday, cover
letter, interview, redline, metadata, PDF, and ZIP outputs. It also correctly warned that lexical matching was not
semantic proof.

Architecture direction adopted by the current product:

- A native SwiftUI client rather than embedding the monolithic Python script in iOS.
- A versioned Python service boundary for ingestion, profile facts, job analysis, proposed tailoring, rendering, and
  export.
- A guided Import → Profile → Analysis → approval → Export experience.
- Evidence-linked proposals, candidate control, protected local drafts, minimal server retention, and explicit
  deletion as product requirements.

Still-open obligations carried into the current release gates:

- OCR for scanned PDFs.
- Fixture-based parsing tests across real, de-identified document layouts.
- Production authentication, upload limits, content-type verification, cleanup guarantees, retention controls, and
  one-tap deletion.
- Visual regression testing for DOCX and PDF output.
- Full accessibility, offline/error-state, security, privacy, and localization hardening.

Product significance:

- This audit supplied the safety and architecture bridge between the experimental Python generations and ApplyReady
  Vets.
- Truth Lock is the current implementation of its central rule: job requirements may guide questions and proposals,
  but they never become veteran claims without source evidence and approval.

### Native iOS prototype 0.1.0 — July 13, 2026

Source: `outputs/HogueResMasterApp`

Major changes:

- Built native SwiftUI iPhone/iPad workflow.
- Added Import → Profile → Analysis → Truth Lock → Export flow.
- Added FastAPI service for extraction, analysis, LinkedIn kit, and export.
- Added document extraction for TXT, Markdown, HTML, RTF, DOCX, and PDF.
- Added evidence ledger assigning source IDs to resume lines.
- Added deterministic veteran translation and job-readiness analysis.
- Added optional OpenAI structured-output integration with explicit consent.
- Added Truth Lock:
  - evidence citations required,
  - unsupported new numbers rejected,
  - sensitive patterns blocked,
  - accepted edits revalidated on export.
- Added ATS text, Workday text, DOCX, trace, readiness, safety/gap, and ZIP export.
- Added LinkedIn Profile Builder with copy/share UI and kit files.
- Added privacy manifest, protected local draft storage, Keychain token storage, demo mode, backend tests, and Swift tests.

Product significance:

- This was the leap from Python script to actual mobile-app architecture.
- The product stopped being just a generator and became an evidence-first career workflow.

### Native iOS prototype 0.1.1 — July 26, 2026

Major changes:

- Added beginner-friendly Mac automation scripts.
- Added setup, health check, backend startup, iOS build, validation, packaging, and Simulator launch commands.
- Fixed Swift/Xcode build issues.
- Completed real unsigned arm64 iPhone build with Xcode 26.6.
- Revalidated backend and lint checks.
- Diagnosed the macOS 27 beta / Xcode 26.6 compatibility issue and added preference for Xcode beta.

Product significance:

- This made the project runnable on your Mac instead of only existing as source code.

### Native iOS prototype 0.2.0 — July 28, 2026

Major changes:

- Installed and validated Xcode 27 beta 4 and iOS 27 beta 4 simulator runtime.
- Added Xcode 27 macro-compatible automation.
- Added Xcode 27 Device Hub launch support.
- Added M4-first hybrid AI routing:
  - Apple on-device model first,
  - optional OpenAI fallback,
  - deterministic fallback always available.
- Added provider health reporting, timeouts, schema-bounded local-model output, and provider fallback tests.
- Updated app consent labels to distinguish local AI from cloud AI.

Product significance:

- This aligned the project with your M4 Mac and the Apple Intelligence direction.

### Native iOS prototype 0.3.1 — July 28, 2026

Major changes:

- Selected MusterForward as the working public app name.
- Renamed the actual Xcode project, scheme, app target, test target, product, bundle ID, and local Swift package to MusterForward.
- Added `link-xcode-beta.command` to fix global Xcode command-line selection when Apple tooling points at Command Line Tools.
- Added StoreKit lifetime unlock surface for MusterForward Complete.
- Added optional Apple tips with restore-purchase handling.
- Added monetization docs: free core, one transparent lifetime unlock, optional tips, and organization licensing.
- Added legal and launch docs for California LLC, EIN, D-U-N-S, Apple Developer enrollment, App Store submission, privacy/support docs, and App Review notes.
- Revalidated:
  - backend tests: 25 passed,
  - lint: clean,
  - iOS build: passed,
  - live Simulator tests: 3 passed, 0 failures.

Product significance:

- This turned the HogueResMaster working title into a real app identity.
- This name was later superseded publicly by ApplyReady Vets in 0.4.0.

### Native iOS prototype 0.4.0 — July 29, 2026

Major changes:

- Adopted ApplyReady Vets as the veteran-first public working name.
- Build 12 initially kept the internal Xcode project, scheme, target, and source folder name as MusterForward while the
  public rebrand was validated.
- Build 13 completed the internal rename to ApplyReadyVets across the project, scheme, targets, modules, product, tests,
  core package, resource groups, source folders, and automation.
- Retained only the earlier keychain service and draft filename as data-migration identifiers.
- Updated the app display name, bundle ID, backend API identity, AI system prompt identity, ZIP export filename, StoreKit product IDs, legal/support copy, Settings metadata, README, changelog, release notes, App Store guide, business roadmap, AI strategy, and product-decision docs.
- Added a new original branch-unity app icon for ApplyReady Vets without VA, DoD, military-service, or U.S. government seals.
- Documented the AI/device plan:
  - deterministic/private analysis available broadly,
  - Apple Foundation Models only when Apple Intelligence availability checks pass,
  - OpenAI through a backend service with server-side keys only,
  - Microsoft Copilot/student-account integration treated as a later roadmap item.
- Documented competitor research and the core product standard: win on veteran trust, evidence-backed writing, complete packets, LinkedIn/Workday copy, Truth Lock, and transparent pricing.

Product significance:

- This is the current public app direction.
- `HogueResMaster` remains historical lineage only.
- `MusterForward` is retired from the active build and remains only in historical records and compatibility migrations.

### Native iOS beta 0.5.0 — build 16 — July 29, 2026

Status: dated historical baseline, not current configuration.

Major changes:

- Replaced the service-dependent normal path with a deterministic local career engine.
- Added local evidence, gap, safety, veteran/federal, readiness, Truth Lock, LinkedIn, supported import, and protected
  text-export flows.
- Added protected workspace recovery, a user-selected URL/text Share extension, stricter endpoint policy, bounded
  optional-service proposals, and adversarial packaging checks.
- Added Apple Foundation Models proposals behind runtime availability and consent.
- Kept the Release StoreKit storefront disabled while entitlement behavior was still being developed.

Product significance:

- This was the first native beta whose core workflow did not require the Mac service, an AI provider, or a network.
- Later entries supersede its text-only export, disabled-storefront state, and iOS 26-era implementation details.

### Native iOS beta 0.6.0 — build 17 — July 29, 2026

Status: versioned beta baseline. Current Unreleased work builds on it.

Major changes:

- Reorganized the product into Today, Workspace, Applications, and Toolkit.
- Added the protected job tracker with platform/employer links, status, notes, deadlines, required documents, and
  packet-version history.
- Added one complete free application workspace and a non-consumable Complete boundary for additional workspaces.
- Bundled the official August 2024 O*NET military crosswalk with 12,921 active mappings across all six branches.
- Added federal application fields and dated requirement-specific USAJOBS checks without a hiring-style overall score.
- Added the iOS 27-only target, updated Apple Foundation Models route, opt-in Spotlight metadata, and a privacy-minimal
  widget target.

Product significance:

- This shifted the app from one guided resume form toward a local veteran application workspace.
- The version's earlier $24.99 price discussion was superseded by the current $5.99 one-time decision.

### Unreleased iOS 27 hardening — July 30, 2026

Status: current source under validation; not an App Store release.

Major changes:

- Isolated each tracked application's draft, analysis, Truth Lock decisions, and export state in its own protected,
  checksummed, recoverable workspace.
- Added employer-facing PDF, editable RTF, and parser-safe TXT export plus a separate private TXT review.
- Added a fail-closed federal two-page PDF gate.
- Bounded resume, job, profile, military, federal, tracker, required-document, packet-version, and edited-proposal input.
- Hardened optional networking with ephemeral storage, same-origin redirects, request/response ceilings, cancellation,
  and redacted bounded errors.
- Set the current consumer decision to one completed application free and unlimited workspaces through one $5.99
  lifetime non-consumable. Tips, subscriptions, credits, ads, and feature packs are not current products.
- Made release preflight behavior explicit through release-candidate, beta, and parser self-test modes.

Product significance:

- The current native app now covers the trustworthy local core, per-job organization, O*NET mapping, federal review,
  readiness sub-scores, LinkedIn copy, and multi-format export.
- It still lacks signed-device/App Store Connect validation, TestFlight, a native DOCX/Workday field lab, the broader
  historical packet family, production cloud-service controls, and independent expert review.

## Major ideas that survived into ApplyReady Vets

- Upload resume + job, then guide the user through only what is missing.
- Generate a complete application packet, not just a resume.
- Keep ATS-safe and Workday-safe outputs separate.
- Avoid automated logins or auto-submission to third-party job sites.
- Support veterans, federal applicants, healthcare roles, education roles, and later civilian spin-offs.
- Warn about suspicious job postings.
- Translate military experience conservatively.
- Use evidence-backed writing rather than unsupported keyword stuffing.
- Require user review and approval before export.
- Preserve an audit trail.
- Keep AI behind consent, redaction, schema limits, and deterministic fallback.

## Product lessons from the history

1. The product is strongest when it is evidence-first, not keyword-stuffing-first.
2. Veterans need translation, not exaggeration.
3. Workday/ATS parsing needs its own export format.
4. LinkedIn support should be copy-ready guidance, not credential-based automation.
5. AI should be built in as an assistant, not as an unchecked fact generator.
6. The best business path is a trusted career packet platform, not a one-off resume script.
7. The app should eventually support veterans first, then spin off a general-public career tool later.
8. AI should feel quiet and optional in the interface; the veteran's evidence and next action should remain visually
   primary.
