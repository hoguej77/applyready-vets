# Product lineage from the internal HogueResMaster files

Historical sources reviewed July 13, 2026; current decisions reconciled July 30, 2026. The inspected release notes were
embedded in HogueResMaster Python headers rather than stored in one standalone changelog. Unrelated personal documents
were deliberately excluded. No v1.x through v2.6 source was recovered; v2.7 is the earliest recoverable full source.

| Observed version | Strong ideas found | Decision in iOS build |
|---|---|---|
| `v2.7_2025-08-15` | TF-IDF job ranking, veteran crosswalk, batch mode, mileage filter, tracker CSV | Kept job/resume comparison and veteran translation. The native tracker now organizes per-job workspaces; batch/radius search remain deferred. |
| `v7.6` | Mission/release notes; planned one-tap rerun, batch UI, salary bands, expanded MOS/AFSC and healthcare | Preserved rerunnable analysis and multiple resume modes. The official dated O*NET military crosswalk is now bundled; salary normalization and batch search remain deferred. |
| `FINAL` | Extraction-first design, evidence-based keyword alignment, ATS lint, confirmation items; planned schema-bound optional LLM and packaging | This became the core architecture: deterministic first, schema-bound optional AI, evidence ledger, gap questions, and human confirmation. |
| `vNext_Workday` | Workday-first no-table output, ATS versus Workday paths, lint, salary extraction, field maps/template families | Native iOS now exports PDF/RTF/TXT. DOCX and field-by-field Workday assistance remain later workflows. |
| `v11_BASE_IMPROVED` | The current user-supplied baseline and its resume generation workflow | Reviewed and hardened separately as v12; its mission and useful extraction/export behavior informed this app. |
| `v11_FIXED_OPTIMIZED`, `v11_FIXED_Executable`, ASCII/procurement variants | Packaging and compatibility experiments, including broken experimental branches | Retained useful packet ideas, but rejected malformed/unrunnable branches as release baselines and replaced desktop packaging with native SwiftUI plus an optional service boundary. |
| June 2026 preserved output packet | 21-artifact candidate packet with resume/cover, ATS report, confirmation items, supplemental answers, redline, interview guidance, prompt material, and DOCX/PDF | Treat as output evidence, not recovered generator source. Restore the document family only with evidence, privacy, and visual/parser fixtures. |
| `v13_BASE_PLUS` | Broader healthcare/military enrichment, acronym expansion, self-test/help modes | Kept acronym clarity, healthcare mode, help text, and testing intent. Rejected generic inserted achievements and corrupted boundary patterns because they can fabricate or mis-detect evidence. |

## Principles preserved

- Help veterans tell the strongest truthful story supported by their record.
- Extract first; do not force a fragile template before understanding the source.
- Translate military language conservatively.
- Keep ATS-friendly and Workday-friendly deliverables.
- Make AI optional and schema-bound.
- Ask confirmation questions when evidence is missing.
- Keep a deterministic mode so the app remains useful without a vendor or network.

## New protections added

- Truth Lock evidence IDs and server-side export revalidation.
- Exact-number preservation.
- SSN, medical/disability, clearance/OPSEC, and contact-data redaction before AI.
- Explicit third-party AI consent.
- Suspicious job-posting warnings.
- Keychain token storage, iOS file-protected workspaces, privacy manifest, safe URL retrieval, upload limits, and safe
  filenames.
- Honest readiness labels rather than fake ATS or hiring predictions.
- LinkedIn Profile Builder that uses verified skills and makes veteran self-identification optional.

## Deliberately deferred

- Automated job applications, LinkedIn login/publishing, Workday browser automation, or employer messaging.
- Claims of ATS scoring accuracy, eligibility, veteran preference, salary entitlement, or hiring probability.
- O*NET refresh automation and validation beyond the currently bundled, attributed August 2024 release.
- Batch job search or partner status synchronization until source terms, authorization, consent, rate limits, and user
  data retention are designed. Local user-entered tracking is already implemented.
