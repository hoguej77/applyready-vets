# ApplyReady Vets full available-history and requirements audit

Last updated: July 30, 2026
Status: evidence-based working audit. It does not claim that unrecovered files were reviewed.
Current source snapshot: ApplyReady Vets 0.7.0, build 18.

## Why this document exists

The original product was developed across many Python files, experimental branches, local
deliverable archives, research documents, and a later native iOS rewrite. The founder's
requirements also grew beyond a resume generator: a veteran-first career platform, honest AI
assistance, private document handling, lawful job-platform handoffs, federal and promotion
support, a future civilian product, a transparent business model, and a real Apple launch path.

This document separates four things that must not be blurred together:

1. **Verified implementation**: code that exists in the active iOS/backend project.
2. **Verified historical capability**: a feature found in an accessible old source file or output archive.
3. **Documented roadmap**: a desired feature that is not yet implemented or release-validated.
4. **Unrecoverable history**: versions or artifacts that were not found and must not be reconstructed as facts.

## Available historical evidence

| Period | Evidence | Important contribution |
| --- | --- | --- |
| Before August 15, 2025 | No v1.x through v2.6 source was found | Do not invent a detailed pre-v2.7 history. |
| August 15, 2025 | v2.7 and v7.6 source | Veteran crosswalk concept, TF-IDF ranking, batch CSV, mileage filtering, tracker CSV, input discovery, risk checks, and packet outputs. |
| August–October 2025 | v11 cards, final, ASCII, patched ASCII, and fixed branches | Quiet cards-first flow, guided input state, style packs, ZIP packaging, federal/healthcare experiments, and terminal UI experiments. |
| January 2026 | FINAL source | Extraction-first pipeline, ATS lint, confirmation sheet, evidence-aware alignment, and safer document structure. |
| April 2026 | executable, procurement, Workday, Base Improved, and Base Plus branches | Runnable document generation, truthful procurement translation, Workday-safe formats, field-map concept, acronym expansion, and self-test/help modes. |
| June 2026 | Senior Office Specialist final packet archive | Evidence of a rich packet: resume, cover letter, ATS text/report, confirmation sheet, supplemental answers, redline, interview guide, prompt packet, targeted packet, and PDFs. |
| July 13, 2026 | v11 review/iOS roadmap and v12 hardened source/tests | Safety bridge: removal of unsupported claim injection, safer HTML/input behavior, no fabricated metrics, and the native-iOS architecture direction. |
| July 13–30, 2026 | active ApplyReady Vets project | Native iOS 27 SwiftUI app, local career engine, Truth Lock, protected per-application workspaces, tracker, O*NET, federal mode, multi-format local export, optional Apple assistance, and development service. |

The exact source paths and detailed chronology are preserved in
[HISTORICAL_CHANGELOG.md](HISTORICAL_CHANGELOG.md). The older v1–v6 work remains an explicit
evidence gap.

### Important historical corrections

- The first recoverable full source is v2.7. v7.4 and v7.5 are self-reported by v7.6; they are not
  separate recovered source releases.
- The patched ASCII and v11 fixed source branches include syntax-breaking defects. They are historical
  UX experiments, not safe runnable release baselines.
- The Base Plus branch contains malformed word-boundary characters and an always-on ZIP condition.
- The June 2026 rich output packet is output evidence, not proof of a recovered generator release. It is now represented
  in the historical changelog as a 21-artifact packet containing resume/cover material, ATS text/report, confirmation
  items, supplemental answers, redline, interview guidance, prompt material, and DOCX/PDF output.

## Research evidence reviewed

- The supplied executive-resume book is useful as a historical executive-career reference for inventory,
  impact, clarity, design, networking, and cover-letter workflow. It is not a current source of federal
  rules or Apple requirements.
- The supplied Federal Careers presentation is useful for USAJOBS workflow, saved searches, special
  hiring pathways, and application tracking. Its two-to-four-page/SSN resume advice conflicts with
  current USAJOBS rules; current official USAJOBS guidance controls.
- JOFDAV is a job-discovery source for disabled veterans, not an approved target for automated account
  actions, scraping, credential collection, or auto-submission.
- Official Apple, USAJOBS, VA, OPM, and O*NET sources remain controlling sources for launch,
  payment, privacy, hiring-path, and benefits-related behavior.

## Founder requirements collected from the available thread

1. A best-in-category, veteran-first career application platform, not a generic template maker.
2. A later civilian product built from a reusable, safe career engine.
3. A natural interface that does not shout “AI,” but uses helpful AI with consent and availability checks.
4. Evidence-backed military-to-civilian translation that never fabricates qualifications, metrics,
   clearance, disability, medical, or service claims.
5. Resume, LinkedIn, Workday, USAJOBS/federal, employer, college, networking, and promotion support.
6. User-controlled handoff to LinkedIn, Indeed, Workday, USAJOBS, JOFDAV, and employer sites; no
   credential capture, scraping, automated posting, or auto-apply.
7. Support for all branches/components, with full official crosswalk coverage only when licensed,
   attributed, tested, and current.
8. National/state veteran resources, VSO/accredited-help navigation, record/document checklists, and
   Schedule A guidance; no claims filing, benefit determination, or representative impersonation.
9. Future VA disability educational estimate and military-retirement education only after rate, legal,
   and subject-matter validation.
10. A VA-inspired civic visual system without VA marks, branch insignia, or implied affiliation.
11. A new brand, original logo, clear non-affiliation language, and trademark/domain/App Store clearance.
12. A transparent business model: one completed application free, one $5.99 lifetime unlock, and possible organization
    licensing; no consumer tips, subscription maze, credits, ads, feature packs, or public personal Zelle number.
13. M4/Xcode-beta automation for build, test, packaging, diagnostics, and recovery; never silent
    self-rewriting code, Apple-review bypasses, or autonomous external submissions.
14. Complete README, changelog, release notes, roadmap, legal-launch path, and audit trail.
15. Beginner-friendly LLC, Apple enrollment, TestFlight, App Review, and revenue guidance, while
    retaining founder-controlled legal, tax, banking, signing, and submission actions.

## Current implementation against requirements

| Requirement | Current status | Evidence / honest boundary |
| --- | --- | --- |
| Native veteran-first iPhone/iPad workflow | **Verified** | SwiftUI Import → Profile → Analysis → Truth Lock → Export flow. |
| Local-first privacy and recovery | **Verified** | Protected workspace, backup recovery, Keychain token, and no required account/network for the core flow. |
| Evidence-based wording and Truth Lock | **Verified** | Local evidence ledger, user review, export-time revalidation, and sensitive-content checks. |
| Quiet Apple on-device assistance | **Code verified, device-gated** | Foundation Models path is availability- and consent-gated on iOS 27. Private rules remain available; physical-device quality remains unverified. |
| Optional OpenAI/service fallback | **Development-only foundation** | Consent/service gates exist. Release ships with no endpoint; no public host, user account, or deletion operation exists. |
| LinkedIn builder | **Verified, handoff only** | Copy-ready profile sections/messages and system copy/share. No login, publishing, scraping, or sync. |
| Indeed/Workday/USAJOBS/JOFDAV links | **Verified, handoff only** | Recognizes/saves user-selected URL/text and opens/copies/shares material. No platform integration or auto-apply. |
| Share Extension | **Code/simulator verified** | Bounded URL/text inbox and replacement confirmation; physical signed-device validation remains. |
| Siri / Shortcuts | **Code/build verified** | Four privacy-safe App Intents and App Shortcuts; Release metadata extraction succeeds. Physical Siri/Action button testing remains. |
| Share Sheet / AirDrop | **Code verified** | Native ShareLink handoff for exports and LinkedIn material. AirDrop/receiving-app behavior requires signed physical-device tests. |
| Haptic Touch / haptics | **Code verified** | Final handoff context menu and restrained copy-confirmation feedback; modern Haptic Touch is used instead of a 3D Touch-only design. |
| Widgets | **Code/build verified** | Small/medium next-application widget uses a minimal protected snapshot. Application details are separately opt-in; signed App Group and locked-device testing remain. |
| NFC | **Not a file-transfer feature** | Future use, if any, is limited to public universal-link tags; no resume, VA, clearance, or credential payloads. |
| Rich application packet | **Partial** | Native iPhone export creates employer PDF/RTF/TXT plus a separate private TXT review. Native DOCX, cover letter, interview/supplemental material, Workday field lab, and the wider historical packet remain. |
| Federal/USAJOBS | **Partial** | Federal fields, requirement-specific checks, source dates, specialized output text, and a two-page PDF rejection gate exist. No production USAJOBS search or full document/layout fixture suite exists. |
| All-branch promotion packets | **Partial** | Branch-level positioning and service packet exist. Full branch/rank/component promotion workflow requires source validation and dedicated UX. |
| Full O*NET crosswalk | **Implemented from a dated source** | Bundled August 2024 official crosswalk contains 12,921 mappings and attribution. It must be refreshed and integrity-tested when O*NET updates. |
| Job Passport/tracker/reminders | **Tracker implemented; reminders partial** | Links, employer, role, job ID, status, notes, deadline, required documents, packet versions, due-soon views, and isolated per-job workspaces exist. Notifications/EventKit and contacts remain roadmap. |
| State/VSO/resource navigator | **Not built** | Official-link research exists; no signed, dated 56-jurisdiction manifest in the app. |
| VA disability or retirement calculators | **Not built by design** | Must be educational, dated, source-backed, and independently reviewed before implementation. |
| VA-inspired original design/non-affiliation | **Partial** | Original civic palette and disclaimers exist. The current abstract logo has not received founder design approval and is not final. |
| Name/brand/legal clearance | **Working choice only** | ApplyReady Vets is a working name; clearance remains. |
| Lifetime IAP | **Source boundary implemented; external validation open** | One free application and the $5.99 lifetime Complete product are implemented; Release-candidate source enables the boundary. App Store Connect product setup, signed sandbox behavior, tax/banking, and review remain. There are no consumer tips. |
| LLC/Apple launch plan | **Documented, not executed** | Formation/app-submission documents exist. Filing, enrollment, signing, and legal documents are founder-authorized actions. |
| Automated build/test/repair | **Verified, bounded** | Xcode-beta-aware doctor/setup/start/test/quality/package scripts exist. Repair clears only named generated caches and regenerates project files. |

## Historical features worth restoring safely

1. **Candidate artifact system**: local ATS DOCX/PDF, Workday DOCX/PDF/TXT, cover letter, redline,
   interview guide, confirmation sheet, and a deliberately separate private evidence packet.
2. **Workday paste lab**: field-by-field copy cards, parser/lint checks, output preview, and no universal
   Workday login claim.
3. **Job Passport completion**: the current app already has link, employer, job ID, deadline, status, notes, required
   documents, per-job workspace, and exact packet versions. Restore contacts, interviews/offers, next actions,
   user-approved reminders, and optional retention outcomes.
4. **Federal workspace completion**: current announcement fields, checks, documents, and two-page rejection exist.
   Restore a stronger specialized-experience trace and expand announcement/layout fixtures.
5. **Supplemental-answer builder**: draft only from verified evidence, with answer-specific sources and
   candidate approval.
6. **Crosswalk/resource registry**: keep the bundled August 2024 O*NET data refreshable and add a dated, signed
   56-jurisdiction veteran resource manifest with visible verification dates.
7. **Document quality lab**: representative import/export fixtures, visual regression checks, layout tests,
   accessibility testing, and actual parser tests—not a generic ATS guarantee.

## Historical patterns that must not return

- Keyword injection from the job posting into a candidate resume.
- Generic healthcare, education, federal, or military claims inserted without source evidence.
- Placeholder metrics in employer materials.
- ATS score, hire-likelihood, or guaranteed-interview language.
- External job-site automation, credential capture, screen scraping, or unauthorized browser control.
- Monolithic self-modifying automation that hides failures instead of making them visible.
- Candidate-specific legacy templates treated as generic product features without privacy-safe fixtures and
  evidence controls.

## Documentation and code inconsistencies to correct

1. Some historical documents describe a broad packet or text-only native output. Current native output is exactly
   employer PDF/RTF/TXT plus a separate private TXT review. The optional development ZIP and unbuilt native
   DOCX/cover/interview/Workday packet must remain labeled separately.
2. Backend scoring still contains an application-readiness calculation even though the native local
   engine/UI intentionally removed the overall hiring-style score. Align the backend contract before
   it is exposed to users.
3. The prior testing report predates current repairs. Test totals and the quality-gate statement must be
   refreshed only after the complete current gate passes again.
4. The Release-candidate StoreKit boundary is enabled in source but cannot be called purchasable or launch-ready until
   the matching App Store Connect product and signed sandbox lifecycle tests pass.
5. The current logo is an original abstract mark, not a final founder-approved six-branch identity. It
   needs a deliberate visual brief and selection process.

## Correct build order

1. Finish the current automated quality gate and resolve every compile, test, or policy failure.
2. Align code and all release documents to the actual next-build boundary.
3. Validate the current PDF/RTF/TXT and federal two-page output with visual/parser fixtures, then add native DOCX and
   the broader evidence-backed packet family.
4. Validate the implemented tracker/per-job workspace and add user-approved reminders.
5. Add dated official-resource navigation, then USAJOBS search and federal depth; keep the bundled O*NET release dated
   and refreshable.
6. Conduct physical-device, accessibility, veteran usability, privacy/security, and StoreKit validation.
7. Complete entity/Apple authorization, TestFlight, public URLs, and App Review work only after the app
   behaves as described.

## Current truth statement

ApplyReady Vets 0.7.0, build 18, is a real iOS 27 beta source with a local deterministic core, protected per-job
workspaces, readiness sub-scores, O*NET mapping, federal checks, LinkedIn copy, and PDF/RTF/TXT export. It is not the finished all-in-one
veteran career platform and is not App Store-ready. The largest product gap is not “more AI”: it is validating the
current app on signed physical devices and restoring the broader historical packet family without weakening evidence,
privacy, accessibility, platform-compliance, or candidate-control rules.
