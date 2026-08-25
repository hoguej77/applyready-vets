# ApplyReady Vets signed beta and TestFlight plan

Purpose: prove the release on real signed devices and with representative users before App Review. This plan does not
authorize invitations, uploads, messages, publication, or use of sensitive documents.

## Entry gate

- Final app/company identity approved for beta use.
- Apple organization, signing, identifiers, App Group, StoreKit product, support URL, and privacy URL configured.
- `make app-store-preflight` passes.
- Full local quality and live Simulator suites pass on the candidate commit/source package.
- Public-site legal/privacy draft independently reviewed for beta.
- Testers receive safe-data and non-disclosure instructions before installing.

## Cohort

Start with 20–50 consented testers:

- veterans from at least four branches, including enlisted and officer experience;
- transitioning service members and military spouses;
- civilian/private-sector applicants and federal/USAJOBS applicants;
- at least five VoiceOver, Voice Control, large-text, motor, cognitive, or low-vision accessibility participants;
- a mix of supported Apple Intelligence availability states and at least one supported state where Foundation Models is
  unavailable or disabled.

Do not claim statistical representativeness from this cohort.

## Data-safety rule

Use synthetic fixtures, the built-in demo, or heavily redacted tester-owned content. Never ask testers to upload or
send DD-214s, Social Security numbers, medical/disability records, security questionnaires, classified/controlled
material, full personnel records, passwords, authentication codes, proprietary employer documents, or unrelated
identity documents. Support reports must omit resume bodies unless a tester separately consents to a minimal redacted
excerpt needed to reproduce a defect.

## Signed physical-device matrix

| Area | Required result |
| --- | --- |
| Install/launch | Clean install, upgrade, relaunch, background/foreground, restart, and low-power behavior are stable. |
| Protected storage | Save, corrupt/recover fixture, delete, reinstall, locked-device behavior, and low-storage handling match policy. |
| Files | Import every supported type; cancel; deny access; export PDF/RTF/TXT; inspect formatting and parser-safe text. |
| Share extension | Share job URL/text, reject credentials/unsafe schemes/oversize, resolve replace/keep decision, and verify App Group restart behavior. |
| Widget | Opt-in/out, redaction, stale-data clearing, locked-device privacy, deletion, and deep link. |
| Siri/App Intents | Each shortcut opens the right destination, respects privacy settings, and handles missing workspace or pending URL safely. |
| Spotlight | Opt-in/out, indexed title privacy, stale deletion, deep link, and protected-data-unavailable handling. |
| Foundation Models | Explicit consent, eligible success, unavailable fallback, disabled setting, cancellation, invalid output rejection, and Truth Lock. |
| Offline/interruption | Airplane mode, network loss, backgrounding, call/lock interruption, and cancellation preserve the deterministic baseline. |
| StoreKit | Purchase, cancel, pending, Ask to Buy, restore, offline entitlement, reinstall, refund, revocation, and Store outage. |
| Accessibility | VoiceOver, Voice Control, largest text, bold text, contrast, Reduce Motion, button shapes, keyboard, pointer, rotation, and dark mode. |
| Compatibility | Smallest supported iPhone, current large iPhone, eligible iPad if shipped, and supported region/language settings. |

## Core task script

Each tester should complete these tasks without coaching after the safe-data briefing:

1. Start with demo data and explain the app's purpose and non-affiliation.
2. Create/import a safe resume and real or synthetic job posting.
3. Understand each readiness sub-score and identify one recommended action.
4. Review, edit, reject, and approve Truth Lock proposals without adding an unsupported claim.
5. Produce and inspect a civilian packet.
6. Switch to federal mode and identify the distinct federal checks.
7. Create and copy the LinkedIn kit without believing the app published it.
8. Save the job link, status, notes, deadline, required documents, and packet version.
9. Find official veteran resources and understand that links do not imply affiliation.
10. Understand the free boundary, purchase/restore flow, privacy controls, and local data deletion.

## Severity rubric

| Severity | Definition | Release action |
| --- | --- | --- |
| Critical | Data loss/disclosure, credential capture, unauthorized submission, payment/access failure affecting many users, critical unsupported claim escaping export, crash loop, or government-affiliation deception | Stop beta distribution; fix and rerun the complete affected and regression matrices. |
| High | Common-task blocker, inaccessible core task, wrong entitlement, broken export, unsafe handoff, material federal/benefit misinformation, or recovery failure | No App Review submission until fixed and verified. |
| Medium | Workaround exists; meaningful confusion, layout, performance, or uncommon-flow failure | Triage before submission; document decision and regression coverage. |
| Low | Cosmetic issue with no material task, privacy, safety, accessibility, payment, or data effect | Schedule transparently; do not let accumulation degrade usability. |

## Feedback record

Collect only:

- tester code, not resume name;
- device model, iOS build, app version/build, accessibility settings, and AI availability state;
- task attempted, expected result, actual result, reproducible steps, severity suggestion, and optional redacted screenshot;
- whether the issue involved privacy, payment, export, evidence accuracy, accessibility, performance, or understanding;
- consent to follow up and a separate contact channel controlled by the founder.

Do not add a third-party analytics or feedback SDK merely for beta. Use Apple's TestFlight feedback or a separately
approved minimal process whose privacy terms match the beta notice.

## Exit gate

- Zero open Critical or High findings.
- All StoreKit state transitions pass with signed sandbox evidence.
- Zero known critical unsupported-claim escapes across the current evaluation corpus and beta-reported cases.
- Core task completion is at least 90% in the moderated accessibility cohort.
- Crash-free sessions meet 99.8% or the sample limitation is explicitly documented.
- Export attempts meet 99.5% success or every failure is explained and fixed.
- Support can reproduce, triage, and close issues without collecting unsafe data.
- App Review metadata, screenshots, privacy answers, accessibility labels, and notes match the tested binary.
- Founder signs the release decision record before `1.0.0` is archived for submission.

