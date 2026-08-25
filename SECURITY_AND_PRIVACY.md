# Security and privacy design

Current implementation: ApplyReady Vets 0.7.0, build 18.

This is an engineering design record and beta policy draft, not legal advice. A privacy professional should review the
final product, hosted services, privacy policy, and App Store disclosures.

## Data flow

| Data or action | Private device path | Optional service path | Consent / current limit |
|---|---|---|---|
| Workspace draft and review state | Root state and isolated per-application snapshots use versioned JSON envelopes in Application Support with atomic writes, complete file protection, SHA-256 corruption checks, and last-known-good backups | Not sent merely because it is saved | Local autosave includes draft, analysis, proposal decisions, step, LinkedIn kit, and the active application's export state |
| Household profiles | Preferred name, service relationship, optional branch/career direction, assistance preference, and profile-scoped workspace references are stored in the protected local root | None | Profiles are local partitions, not accounts or cross-device family sync. The app explicitly does not request SSN, DoD ID, VA claim number, birth date, or medical data during onboarding. Removing a person deletes that profile's in-app tracker/workspace records; previously exported Files copies remain user-managed. |
| Apple system backup | User-authored Application Support and Documents content remains eligible for device or iCloud Backup under the user's Apple settings | ApplyReady Vets has no access to the user's encrypted Apple backup service | Current-device deletion does not claim to erase older OS-managed backups; users manage those backups through Apple settings |
| Supported document import | TXT/Markdown/CSV/TSV, RTF, HTML, image, selectable PDF, and bounded scanned-PDF OCR are processed on-device; 20 MB maximum | Unsupported formats can be uploaded for extraction | Separate service consent is required before an unsupported file is uploaded; OCR warns about lower confidence and verification |
| Job text and source URL | Pasted text and saved source URL stay in the protected workspace | User-invoked page retrieval calls the configured service | Retrieval requires separate service consent and preserves the link on denial or failure |
| Job Tracker | Separate protected, checksummed ledger stores user-entered application links, status, notes, deadlines, required documents, and packet filenames | None | One workspace is free; Complete affects creation of additional workspaces, not access to existing data |
| Share Extension | User-selected URL/text is bounded and atomically written to the file-protected App Group inbox; existing job text or link requires a replace/keep decision | None | Rejects URL credentials, unsafe schemes, oversized/full inboxes, and corrupt payloads; a new link cannot silently attach to old text; physical-device App Group registration/testing remains |
| Core analysis | `LocalCareerEngine` builds evidence, gaps, safety findings, readiness estimates, and deterministic proposals | None required | Works without AI consent, a model, or a network |
| Apple writing assistance | A bounded evidence subset is processed by Apple's on-device model on an eligible iOS 27 device | None | Requires AI enabled, explicit AI consent, runtime availability, and no critical safety finding; installation alone does not guarantee Apple Intelligence availability |
| Service writing fallback | Not used when Apple assistance succeeds; phone retains its private evidence, safety findings, job analysis, gaps, and scores | Request goes to the configured service; its Apple or OpenAI provider may propose wording | Requires AI enabled, AI consent, service consent, and no critical finding; at most 12 bounded pending proposals are accepted and each is revalidated against exact phone evidence |
| LinkedIn kit | Built locally from the approved/verified working material | Not required by the current local flow | No LinkedIn credentials, sign-in, scraping, profile changes, or publishing |
| Export | Protected employer-facing PDF, editable RTF, and parser-safe TXT files plus a separate private TXT review are saved in the app's Files-visible Output folder | A richer ZIP endpoint remains available to the development service but is not the normal iPhone export | Employer files contain identical candidate-reviewed wording; PDF publication uses a complete-protection same-volume staging file, validation, and atomic replacement; exported copies remain until deleted, and shared copies leave the app's control |
| Service token | Stored in iOS Keychain for this device | Sent as a bearer token to a configured development service | This shared token is not production identity |
| OpenAI key | Never stored in the app | Server environment only | Must never appear in Swift, the bundle, screenshots, project files, or client settings |
| Service URL | Debug default in app-only settings; Release bundle default is empty | Used only when a request takes an optional service path | Debug editor is not compiled into Release; APIClient accepts only secure HTTPS in Release |

The development service has no application database and processes request content in memory. Hosting infrastructure may
still create network/access logs, and any configured provider processes submitted content under that account's terms and
data controls. Those realities must be documented and verified before a public service is enabled.

## Controls implemented

- Local-first core: supported-file import, analysis, Truth Lock review, LinkedIn drafting, and basic export do not require a
  service.
- Explicit AI toggle, AI consent, and a separate optional-service consent.
- Profile-level assistance choices map to Private Core, Apple on-device, or external help by approval. Choosing the
  external level does not activate a provider: the current Release flow is a user-reviewed preview followed by the
  Apple Share Sheet, with no ChatGPT/Copilot account link or client-side API key.
- Apple [Foundation Models](https://developer.apple.com/documentation/foundationmodels) are preferred on an eligible
  iOS 27 device. If unavailable, service AI is attempted only when both consent gates are satisfied.
- Every enhancement failure keeps the completed deterministic private baseline.
- Critical privacy/OPSEC findings pause generative assistance.
- Native scanning for SSN-like patterns, date-of-birth labels, medical/disability phrases, and sensitive
  clearance/operation patterns.
- The deterministic proposal generator is capped at eight proposals.
- Evidence citations and exact-number checks for every suggestion.
- Native Apple-device proposals are capped at six, must exactly reference supplied resume text, and pass native Truth
  Lock before verified display. The optional unverified-draft view still requires exact citation and sensitive-content
  screening; final approval and export always require Truth Lock.
- Optional-service responses are capped by transport size and cannot replace the private analysis. Only bounded,
  deduplicated, pending proposals with exact local resume evidence can pass the native service gate.
- The veteran must approve or edit proposals; nothing is applied or submitted automatically.
- No LinkedIn credentials or automated publishing.
- Security-scoped file access, a 20 MB local import limit, allowlisted local formats, and clear fallback behavior.
- The optional service performs public-URL validation and redirect revalidation; private, loopback, link-local, reserved,
  multicast, and credential-bearing destinations are blocked there.
- Sanitized download and multipart filenames.
- HTTP(S)-only manual, Shortcut, handoff, and shared job links with credential rejection; bounded resume, job, profile,
  tracker, upload, JSON-request, JSON-response, and export-response sizes.
- The full `WorkspaceDraft`—including profile, military-service, and federal fields—is validated before save or
  analysis. Tracker records, required documents, packet versions, and edited proposals have separate bounds.
  RTF/HTML source and extracted-text ceilings, bounded OCR/PDF accumulation, a 2,048-character normalized URL ceiling,
  and bounded O*NET queries/results keep local ingestion within explicit resource budgets.
- An ephemeral client session without persistent URL cache, cookie storage, or credential storage; same-origin
  redirects only; cross-origin redirects, HTTPS downgrades, URL user information, oversized declared/streamed bodies,
  and unsafe multipart filenames are rejected.
- Service error text is control-stripped, redacted, length-bounded, and presented without echoing arbitrary server
  content. Task cancellation cancels the underlying request.
- Protected root and per-application workspace envelopes, primary/recovery verification, corrupt-file quarantine,
  legacy-workspace migration, and deletion of managed workspace/export files.
- The authoritative root workspace commits before its per-application projection. Application deletion removes the
  tracker record, protected application projection, matching quarantine files, widget projection, and Spotlight record
  while preserving the reusable profile and base resume.
- Local erase uses independently verified deletion attempts for workspaces, recovery/quarantine copies, tracker state,
  Keychain items, app-managed exports, shared inbox data, widget data, and Spotlight records. A persistent marker
  prevents saved work from reopening and retries an interrupted local erase until its local deletions succeed.
- Spotlight and widget details are separately opt-in. Persistent privacy-revocation markers, verified projection
  replacement, stale-detail clearing, and protected-data-unavailable handling prevent silent retention or false
  presentation of application metadata.
- Keychain token, complete file protection, app-only UserDefaults reason, and no tracking declaration.
- Intentional backup policy: user-authored work remains eligible for Apple system backup; the app does not describe
  backup-eligible local storage as strictly device-only.
- Debug defaults to loopback, Release defaults to no endpoint, and endpoint classification distinguishes secure remote
  HTTPS from insecure remote HTTP.
- Development API token comparison uses a constant-time function.
- Production mode fails closed with a 503 response when service authentication is not configured.
- Production interactive API docs are disabled when `HOGUE_ENVIRONMENT=production`.

## Threats and remaining production work

| Threat | Build 18 mitigation | Required before public launch |
|---|---|---|
| Fabricated resume claim | Evidence IDs, unsupported-number, target-title, sensitive-content, resume-source, exact Apple cited-line, veteran approval, and final export-time validation | Consider validation at every keystroke as well as export; enlarge the adversarial corpus and obtain independent review |
| Corrupt local workspace | SHA-256 corruption check, atomic protected write, valid-primary backup, restore/quarantine path | Test power loss, storage pressure, OS upgrade, migration, backup corruption, and recovery on physical devices |
| Malicious workspace modification | App sandbox and iOS file protection | Do not call the unkeyed SHA-256 checksum an authenticity proof; assess keyed integrity only if the threat model requires it |
| Secret embedded in mobile app | OpenAI key stays server-side | Managed secret vault and rotation |
| One service user reading another user's data | No database in the development service | Real user identity, object authorization, tenant isolation before accounts or retained objects |
| Brute force / cost abuse | Optional shared token | Per-user auth, rate limits, quotas, anomaly alerts |
| Resume data retained too long | Private core remains on-device; development service has no app database | Document provider/host logs and retention; implement verifiable deletion before public service use |
| Accidental service disclosure | Separate service-consent toggle for unsupported files, job-page retrieval, and AI fallback | Test every outbound path and permission transition on physical devices |
| Insecure or development endpoint in Release | Release URL is empty; editor is Debug-only; APIClient accepts only secure HTTPS in Release, rejects local/private/insecure endpoints, and permits only same-origin non-downgrade redirects | Add staging certificate, failure, DNS-rebinding, and network-change integration tests before enabling a public endpoint |
| Malicious URL / SSRF | Optional service address checks and redirect revalidation | DNS-rebinding-resistant egress proxy and network allow policy |
| Malicious parser input | File/type/size limits | Sandboxed extraction workers, timeouts, malware scanning, patched dependencies |
| Prompt injection in job/resume | Evidence-only schema and output revalidation | Dedicated injection red-team suite and provider evaluations |
| Compromised optional service response | Phone retains its local analysis and accepts only bounded pending proposals tied to exact local evidence and native Truth Lock | Signed release/staging integration tests, certificate tests, and independent service security review |
| Sensitive military information | OPSEC scan and warnings | Veteran/OPSEC expert review and improved taxonomy |
| Export disclosure, stale copy, or backup misunderstanding | File-protected Files Output folder, separate private-report label, user-controlled share sheet, current-device deletion, and explicit Apple system-backup disclosure | Test Files, Mail, AirDrop, restore/delete/backup behavior, managed-device policy, and user understanding on signed physical devices |
| Compromised host | Minimal data storage | Hardened images, patch SLAs, TLS, WAF, audit logs without content, incident plan |

## Draft user-facing privacy summary

ApplyReady Vets processes the resume, job posting, preferred name, optional career context, and other profile
information you choose to provide. Separate local household profiles keep each person's work apart on the same device;
they are not online accounts or cross-device family sync. Its private
career engine, Truth Lock review, LinkedIn drafting, and PDF/RTF/TXT export run locally. Your workspace and recovery copy
are stored with iOS file protection and may be included in Apple system backups according to the user's settings. ApplyReady
Vets does not receive those backups. Removing a household profile deletes that person's protected in-app work, but
copies already exported to Files remain under your control. If you enable and consent to optional AI, an eligible device may add on-device
wording suggestions. If you separately allow the optional ApplyReady Vets service, unsupported documents or an AI
fallback may be sent to the service you configure. Requesting automatic retrieval of a public job page also uses that
configured service; saving the link or pasting the job text does not. A service-configured OpenAI provider may receive
only the content allowed by the service's redaction and consent rules. The app does not log in to LinkedIn or Microsoft
Copilot, scrape profiles, submit applications, publish content automatically, or track users across apps.

Before release, replace this summary with a complete policy that names the operating legal entity and contact, hosting region, subprocessors, purposes, retention periods, security practices, user rights, deletion/export process, age requirements, breach contact, policy date, and jurisdiction-specific disclosures.

## App Store checklist

- Confirm the privacy manifest against the final binary’s Xcode privacy report.
- Ensure App Store privacy answers match actual backend and AI-provider behavior.
- Publish a working privacy-policy URL and support URL.
- Add in-app account deletion if accounts are introduced.
- Test the service-consent gate for job-page retrieval, unsupported-file upload, and AI fallback on physical devices.
- Verify Release endpoint enforcement with empty, malformed, HTTP, localhost/private-network, HTTPS, redirect, and
  certificate-failure fixtures.
- Expand final export validation fixtures for user-edited text.
- Expand exact Apple proposal-to-cited-resume-line fixtures.
- Confirm consent text, provider list, redaction, retention, deletion, and log behavior before any production service or AI
  call.
- Verify protected workspace recovery, deletion, and temporary-export cleanup on physical devices.
- Review every third-party SDK and its manifest/signature; the current iOS target intentionally has no third-party SDK.
- Replace the shared development token with production identity and authorization if the optional service ships.
