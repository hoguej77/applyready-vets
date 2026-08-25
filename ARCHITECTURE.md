# Architecture

Current source identity: ApplyReady Vets 0.7.0, build 18. The app, Share extension, widget, unit tests, and UI tests have
an iOS 27 minimum deployment target.

This document describes the source tree, not an App Store release. Signing, App Group registration, App Store Connect
configuration, StoreKit sandbox validation, physical-device validation, TestFlight, and App Review remain open gates.

## System shape

```text
ApplyReady Vets (SwiftUI, iOS 27)
  ├─ Today
  │    ├─ next action and due-soon applications
  │    └─ application pipeline and recent work
  ├─ Workspace
  │    └─ Import → Profile → Analysis → Truth Lock → Export
  ├─ Applications
  │    ├─ LinkedIn / Indeed / Workday / USAJOBS / JOFDAV / employer links
  │    ├─ status, notes, deadline, required documents, and packet versions
  │    └─ one isolated protected workspace per tracked application
  ├─ Toolkit
  │    ├─ offline O*NET military occupation crosswalk
  │    ├─ federal mode and dated USAJOBS checks
  │    ├─ evidence-backed LinkedIn copy
  │    └─ official sources, privacy, and support
  ├─ local deterministic career engine
  │    ├─ evidence ledger and requirement analysis
  │    ├─ qualification coverage, evidence strength, and acronym clarity
  │    ├─ gap questions and sensitive-content review
  │    └─ Truth Lock before verified display and again before export; optional unverified drafts stay labeled
  ├─ local document pipeline
  │    ├─ text, RTF, HTML, image, selectable-PDF, and bounded OCR import
  │    ├─ employer PDF + editable RTF + parser-safe TXT
  │    └─ separate private TXT review
  ├─ optional Apple Foundation Models enhancement
  │    └─ supported device + runtime availability + explicit AI consent
  ├─ Apple platform surfaces
  │    ├─ privacy-safe App Intents and deep links
  │    ├─ opt-in Core Spotlight application metadata
  │    ├─ small/medium next-application widget
  │    └─ URL/text Share extension
  ├─ StoreKit 2 boundary
  │    └─ one free completed application; $5.99 lifetime Complete unlock
  └─ optional development service
       ├─ unsupported document extraction
       ├─ user-requested public-page retrieval
       └─ optional writing proposals through Mac Apple models or server-side OpenAI
```

The optional service is not the app's execution engine. The iPhone creates a deterministic result first. A missing
network, unavailable Apple model, absent OpenAI key, denied consent, or failed optional service does not prevent the
supported local workflow.

## Local contracts

| Operation | Current source behavior | Network required |
| --- | --- | ---: |
| Workspace persistence | Schema-versioned, checksummed, atomic, completely file-protected primary and recovery files | No |
| Application isolation | Each tracked application has its own protected workspace snapshot and recovery copy | No |
| Document import | Local TXT/Markdown/CSV/TSV, RTF, HTML, image, selectable PDF, and OCR for up to 12 PDF pages | No for supported formats |
| Job capture | Paste text, type a URL, or accept a user-selected URL/text Share Extension item | No |
| Tracker | Employer, role, platform, job ID, URL, status, notes, deadline, required documents, and packet versions | No |
| Military mapping | Bundled August 2024 O*NET military crosswalk with 12,921 active mappings across all six branches | No |
| Federal mode | Announcement/series/grade context and requirement-specific checks with a visible source-review date | No |
| Readiness | Separate qualification-coverage, evidence-strength, and acronym-clarity sub-scores; no hiring probability | No |
| LinkedIn kit | Candidate-controlled copy derived from verified material; no login, publishing, scraping, or messaging automation | No |
| Export | Candidate PDF, RTF, and TXT plus a separate private TXT review; federal PDF export fails when it renders beyond two pages | No |
| Complete | One tracked application remains free; a verified non-consumable unlock permits unlimited workspaces | Apple purchase services |

DOCX, a structured Workday field lab, cover letters, promotion packets, and the wider historical packet family are not
part of the current native export. The optional service's development ZIP must not be marketed as the normal iPhone
output.

## Evidence and assistance route

```text
resume + job + profile
  → bounded-input validation
  → LocalCareerEngine evidence, requirements, gaps, safety findings, and sub-scores
  → deterministic proposals
  → native Truth Lock
  → optional Apple model only when enabled, consented, safe, and available
  → optional service only when separately consented and Apple assistance did not succeed
  → exact-evidence and Truth Lock validation of every accepted proposal
  → candidate decision
  → final export-time revalidation
```

Apple Foundation Models use an iOS 27 Dynamic Profile, a versioned instruction contract, relevance-ranked evidence,
live context/token budgeting, structured output, and a six-proposal ceiling. The optional service may add no more than
12 pending proposals. Neither path may replace local evidence, safety findings, job analysis, gaps, or scores, and
neither path can approve content or submit an application.

The local rules and scores are application-readiness heuristics. They are not ATS certification, hiring probability,
eligibility advice, legal advice, benefits advice, or proof that user-entered facts are true.

## Persistence and Files behavior

- The root workspace autosaves after a short debounce and on scene transitions.
- Tracked applications use separate per-application snapshots instead of embedding every workspace in one root file.
- Saves use atomic replacement, complete file protection, a SHA-256 corruption check, a last-known-good copy, and
  corrupt-primary quarantine.
- The SHA-256 value detects accidental corruption; it is not a keyed authenticity proof or end-to-end encryption.
- The Files-visible Output directory contains user-created export copies. The tracker stores filenames, not hidden
  duplicate documents, and reports when a referenced file has been removed.
- “Delete local workspace” removes root/per-application workspace state, tracker/recovery/quarantine data, the Share
  inbox, managed Samples/Output files, temporary exports, saved service token, and legacy migration data. Files the
  user originally selected elsewhere and copies shared to another app or location are outside ApplyReady Vets' control.

## Optional-service and network boundary

- Debug defaults to the owner's local Mac service. Release has no default service URL and no service editor.
- Release accepts only a configured HTTPS origin and rejects credentials, query-bearing base URLs, loopback, `.local`,
  private-network, malformed, and insecure addresses.
- The client uses an ephemeral URL session without persistent caches, cookies, or credential storage.
- Redirects are same-origin only. Cross-origin redirects, HTTPS downgrades, and URLs containing user information are
  rejected.
- JSON responses are capped at 2 MiB, rich development export responses at 50 MiB, and JSON requests at 8 MiB.
  Multipart names and overhead are bounded, and cancellation propagates to the request.
- Server error text is length-bounded, control-stripped, and redacted before display.
- A production public service still requires real user identity and authorization, rate/cost limits, secure secrets,
  retention/deletion operations, minimal-content monitoring, incident response, and an independent security review.

Release source deliberately has no service endpoint, so the optional backend and OpenAI route are disabled unless a
later reviewed release explicitly configures them.

## Apple surfaces and privacy

- App Intents start or open an app workflow and can save a user-supplied web URL. They do not speak private resume or
  military information.
- Spotlight indexing is off by default and includes only application metadata such as role, employer, platform, status,
  and deadline. It excludes resume text, notes, job text, evidence, and files.
- Widget application details are separately opt-in. The snapshot is minimal, completely file-protected, and redacted
  while locked by WidgetKit privacy behavior.
- The Share extension accepts bounded user-selected HTTP(S) URL/text, rejects embedded credentials and unsafe schemes,
  and requires a keep/replace choice before changing existing job material.
- Share Sheet and AirDrop are user-controlled handoffs. ApplyReady Vets does not auto-apply, scrape job sites, capture
  third-party passwords, or claim LinkedIn/Indeed/Workday account integration.

## Honest remaining architecture gates

- Signed App Group tests for the app, Share extension, and widget on physical devices.
- Physical-device Foundation Models quality, availability, latency, refusal, context, thermal, language, and fallback
  tests.
- StoreKit sandbox purchase, pending, cancellation, restore, refund/revocation, Ask to Buy, and interrupted-purchase
  tests against the real App Store Connect product.
- PDF/RTF/TXT visual and parser fixtures, especially federal two-page layouts, OCR edge cases, and accessibility-sized
  content.
- Complete assistive-technology, compact-phone, iPad, rotation, interruption, storage-pressure, and migration tests.
- Production service identity/security/privacy work if a public optional service is ever enabled.
