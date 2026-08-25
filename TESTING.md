# Validation ledger

Updated August 24, 2026 for ApplyReady Vets 0.7.0, build 18, using Xcode 27 (`27A5228h`), Swift 6.4,
and the iOS 27 beta SDK on the owner's M4 Mac.

This file distinguishes evidence already observed from checks that must be rerun after the current integration pass. A
passing local build is not evidence of Apple signing, StoreKit sandbox behavior, physical-device Foundation Models
quality, TestFlight acceptance, legal approval, or App Store readiness.

## Latest observed results

| Check | Latest observed result | Scope / limitation |
| --- | --- | --- |
| Backend tests | 44 passed; the suite also reported 2 subtests | One third-party Starlette deprecation warning; no live provider call |
| Backend Ruff lint | Passed | Current Python source |
| Standalone `ApplyReadyVetsCore` | 17 of 17 passed | Current source; includes backward-compatible status-evidence decoding and safe filename checks |
| Native iOS XCTest suite | 112 of 112 passed | Clean iPhone 17 Pro (iOS 27.0) Simulator run on August 2, 2026; includes the 3 minute 34 second live Apple Evaluations framework test, the full simulated StoreKit lifecycle, and household-profile tests in one invocation |
| Native iOS UI/accessibility suite | 5 of 5 passed | Same clean Simulator; covers all four onboarding stages, welcome/Today accessibility, maximum Dynamic Type, Files picker Browse/Shared/Recents/Samples flow, and the Complete boundary |
| Current iOS 27 generic test build | Passed | App, unit-test, and UI-test targets compile after the protected status-evidence and Image Playground Headshot Studio additions; this Mac currently has no installed Simulator device/runtime, so it is not a live UI run |
| Veteran AI quality gate | Passed expanded focused and integrated runs | 54 scenarios/50 expected-usefulness cases; final integrated result was 100% hybrid usefulness and 96% bounded Apple-model yield against 98% and 50% floors; all required safety/citation/provenance metrics were 100% |
| Focused API security tests | 8 of 8 passed | Run after the API client hardening |
| Current Swift source parse | Passed | Every Swift file after the final privacy and export-status patches |
| App Intents and URL-policy typecheck | Passed | Current iOS 27 Shortcut intents plus bounded public HTTP(S) job-link policy |
| Latest unsigned Release Simulator build | Passed | App, Share extension, and widget compile together from the current source under the installed Xcode 27 beta 4 toolchain |
| Release preflight self-test | Passed | Includes a bounded 25,000-line parser fixture and mode mismatch checks |
| Release-candidate preflight | Passed | Confirms the source contract only; it does not sign, upload, or sell the app |
| Apple signing readiness | Blocked outside source | A paired physical iPhone 17 Pro Max is visible, but macOS reports zero valid code-signing identities; a paid Apple Developer team/certificate must be selected before a device/TestFlight build |
| Privacy-safe source package validation | Passed | 176 source files staged; ZIP manifest, secret/path scan, and archive traversal checks passed |
| Shell syntax | Passed | Project automation scripts |

The current complete Simulator results are stored at:

- Native: `/private/tmp/ApplyReadyVetsFullRegressionFinal/Logs/Test/Test-ApplyReadyVets-2026.08.02_02-33-57--0700.xcresult`
- UI: `/private/tmp/ApplyReadyVetsFullUIFinal/Logs/Test/Test-ApplyReadyVets-2026.08.02_02-31-14--0700.xcresult`

The recorded complete run contains 112 XCTest cases and 5 UI/accessibility cases. Its single live Apple evaluation test
executed the 54-scenario quality gate and passed in 3 minutes 34 seconds. The most recent recorded aggregate metrics
remain 100% hybrid usefulness and 96% bounded model yield against 98% and 50% floors, with all required
safety/citation/provenance metrics at 100%. Do not add these results to earlier historical focused-test counts.

As of the current iOS 27 beta integration, the 54-scenario Apple-model test is deliberately opt-in via
`make ai-quality`. Some beta simulator runtimes report the model as available but do not answer a generation request.
The application now has a 20-second deadline and safely returns its local analysis in that case; the explicit model
gate still fails rather than masking an unresponsive runtime, and must be rerun on the signed release device.

The five UI tests separately inspect every onboarding stage; audit the welcome, import, and personalized Today screens;
launch first-run onboarding at the largest accessibility text size; exercise Files Browse/Shared/Recents/Samples and
real sample intake; and prove the second-workspace Complete boundary. They also prove both starting actions and the
full independence/limitations notice remain reachable.
The Simulator launcher now performs a bounded data-preserving reboot before StoreKit testing, terminates stale app
shells, and removes Xcode's temporary UI-test Home Screen app even when a run fails. This prevents Xcode 27 beta's
repeat-run storefront contamination and the misleading duplicate icon without erasing the app's local data.

The August 1 pass also evaluated, then rejected, registering the bundled O*NET lookup as a Foundation Models tool in
the structured resume-writing session. The direct exact-code lookup test passed, but the combined session produced an
iOS 27 beta model-runtime inference failure. The current source keeps O*NET search code-native and tool calling disabled
for resume generation. All 54 evaluation fixtures must produce an outcome; missing subject results fail the gate rather
than disappearing from aggregate percentages.

## Current automated coverage

### Local data and product rules

- Root workspace and isolated per-application workspace round-trip, recovery, migration, and deletion.
- Protected household-profile persistence, assistance-choice mapping, profile-scoped workspace/tracker isolation,
  deletion with preservation of other people, and refusal to remove the final profile outside full local erase.
- Atomic/checksummed tracker persistence, status/deadline/required-document fields, and versioned packet filenames.
- One complete tracked application free and unlimited workspace creation only with Complete.
- Input ceilings for resume, job, profile, military-service, federal, tracker, required-document, and proposal-edit data.
- Safe Files output lookup that rejects traversal, NUL, missing files, and paths outside the managed Output directory.
- Local PDF/RTF/TXT bundle generation, separate private review, and final Truth Lock revalidation.
- Federal PDF rejection when rendering exceeds two pages.
- O*NET release metadata, integrity, exact-code search, title search, record count, and a known mapping.
- Federal requirement checks without a vague overall federal score.

### Evidence and assistance

- Evidence-ledger construction, separate readiness sub-scores, safety findings, and conservative translations.
- Exact resume-source citation for Apple proposals.
- Rejection of unsupported numbers, sensitive content, copied target titles, missing sources, ambiguous replacements,
  overlapping edits, forged service evidence, remote preapproval, and unsupported service claims.
- Prompt-version, untrusted-input, relevance-ranking, and token-budget contracts.
- Apple Evaluations coverage for 54 scenarios/50 expected-usefulness cases across all six branches, prompt injection,
  clearance, federal grade/eligibility, healthcare and education credentials, sensitive-data pause, a 98% hybrid floor,
  a 50% bounded-model floor, and perfect safety/citation floors.
- Truth Lock defaults-on persistence, labeled unverified-draft behavior, sensitive-output blocking even when
  pre-display verification is off, bounded model repair, and exact-word local fallback provenance.
- Deterministic baseline preservation when optional assistance is unavailable or rejected.

### Integration and transport

- Share inbox round-trip, acknowledgement, credential-bearing URL rejection, bounded input, and explicit replace/keep
  behavior.
- HTTP(S)-only manual and Shortcut job links with domain-boundary recognition.
- Release/Debug endpoint policy.
- Ephemeral URLSession configuration without persistent cookies, caches, or credentials.
- Same-origin redirects only, with cross-origin, downgrade, and user-information rejection.
- Request/response ceilings, multipart bounds, cancellation propagation, and bounded/redacted server errors.
- StoreKit catalog/product-ID isolation and entitlement decision helpers. Signed purchase flows remain an external gate.
- Privacy-safe Spotlight identifiers, widget snapshot behavior, and App Intent contracts.

## Integrated rerun record

Run these against a clean generated project and record the new result bundles:

```bash
make quality
HOGUE_QUALITY_RUN_SIMULATOR=1 make quality
```

The August 2, 2026 integrated Simulator run covered items 1, 2, 3, and the Files interaction in item 6 below. A new
clean run is still required after any source, Xcode-beta, entitlement, or StoreKit configuration change. Before a
TestFlight candidate, also complete:

1. All native unit tests, including API, StoreKit, Apple-platform, workspace, export, tracker, federal, and crosswalk
   tests in one invocation.
2. All UI/accessibility tests on the installed iOS 27 Simulator build.
3. A clean unsigned Release build.
4. Release-candidate preflight and source-package policy.
5. A visual walkthrough of Today, Workspace, Applications, Toolkit, paywall, settings, large text, dark mode, compact
   phone, and iPad layouts.
6. Real Files Browse/Recents behavior and visible Output file handoff. The Shared tab may depend on the Simulator's
   Apple-account state and must not be reported as validated merely because the picker opens.
7. Rendered PDF review for normal and federal documents. Test code that counts pages is not a substitute for visual
   typography, clipping, margin, and content-order inspection.

## Signed-device and external gates

These are not completed by local automation:

- Apple Developer signing, provisioning, registration of the app, Share extension, widget, and App Group.
- Share Sheet intake from Safari and representative job apps on a physical iPhone.
- Widget privacy, stale/deleted records, tinted rendering, locked-device behavior, and App Group updates on device.
- Spotlight opt-in/off/deletion, Siri phrases, and Shortcuts on a signed device.
- StoreKit purchase, pending, cancellation, restore, refund/revocation, Ask to Buy, interruption, and offline receipt
  behavior using the real App Store Connect lifetime product. There are no consumer tip products.
- Apple Foundation Models output on eligible and ineligible physical devices, including availability, language/region,
  refusal, context limits, latency, cancellation, low-power, memory, and thermal behavior.
- Physical-device VoiceOver, Voice Control, Switch Control, accessibility Dynamic Type, Reduce Motion, contrast,
  rotation, compact iPhone, iPad, keyboard, and pointer testing.
- Production HTTPS hosting, real user authorization, rate/cost controls, retention/deletion operations, monitoring, and
  incident response if the optional service is ever enabled.
- TestFlight, veteran usability sessions, independent security/privacy/accessibility/employment/benefits/OPSEC review,
  and App Review.

## Automation boundary

`scripts/repair-and-validate.command` may recreate missing project-local development tooling, clear only named generated
caches, regenerate `ios/ApplyReadyVets.xcodeproj` from `ios/project.yml`, and retry once. It cannot rewrite app source,
change privacy or payment policy, hide a failing test, submit a build, or delete `.env`, drafts, research, exports, or
user documents.

`scripts/release-preflight.command` supports:

- `--release-candidate`: Debug and Release storefront settings must both be `YES`.
- `--app-store`: adds hard checks for the Apple signing team and live public HTTPS Support and Privacy URLs.
- `--beta`: Debug must be `YES` and Release must be `NO`.
- `--self-test`: exercises the bounded settings parser and mode policy.

Passing preflight means the selected source contract is internally consistent. Public release blockers remain visible.
