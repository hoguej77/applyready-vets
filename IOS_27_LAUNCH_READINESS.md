# iOS 27 launch readiness

Verified August 2, 2026 against Xcode 27 beta 4 (`27A5228h`) and the installed iOS 27 beta SDK.

## Product decision

ApplyReady Vets is now an **iOS 27-only** product. The app, Share extension, widget, and test targets all use iOS 27 as
their minimum deployment version. This removes older-OS compatibility code and makes the 2026 Apple platform the
product baseline.

iOS 27 support and Apple Intelligence eligibility are different. The deterministic private career engine, Truth Lock,
tracker, import, export, O*NET mapping, federal checks, and LinkedIn drafting work on every supported iOS 27 device.
Foundation Models assistance is optional and activates only when
`SystemLanguageModel.default.availability == .available`.

## Implemented in the current source

| Surface | Current implementation | User value and boundary |
| --- | --- | --- |
| Foundation Models | iOS 27 `LanguageModelSession.Profile`, single-use prewarming, explicit system-model route, zero temperature, response-token cap, structured `@Generable` output, model `contextSize`, exact `tokenCount` budgeting, and Apple error-specific safe fallback | Uses the current on-device model without a per-request API charge. The private rules engine runs first. Model output gets one bounded repair attempt; an exact-word local repair provides a safe floor with honest provenance. |
| Career-specific model behavior | Versioned, mode-specific civilian, federal, healthcare, and education instructions; job and resume material is explicitly treated as untrusted data; evidence is ranked by requirement relevance before fitting the model context | Better wording is prioritized without keyword stuffing, invented qualifications, prompt injection, or ATS guarantees. An empty result is valid. |
| Evaluations and Truth Lock | 54 synthetic veteran/adversarial cases, including 50 expected-usefulness cases; 98% hybrid-usefulness floor; 50% bounded-model-yield floor; perfect citation, Truth Lock, provenance, forbidden-claim, sensitive-data, pause, and proposal-limit floors; verification on by default with an optional unverified-draft view | The final integrated run measured 100% hybrid usefulness and 96% bounded Apple-model yield. Disabling pre-display verification does not disable sensitive blocking or final export verification. Physical-device and expert validation remain required. |
| Siri and Shortcuts | App Intents start an application, open Truth Lock, open LinkedIn drafting, and save a user-supplied job URL | Spoken dialogs do not repeat resume text, service details, disability information, or evidence. |
| Spotlight | Optional local indexing of role, employer, platform, status, and deadline with a deep link to the matching tracker record | Off by default. Resume text, notes, evidence, job-ad text, and files are never indexed. |
| WidgetKit | Small and medium “Next Application” widget backed by a minimal App Group snapshot | Active count is minimal. Role/employer/status/deadline enter the snapshot only after a separate Settings opt-in; privacy redaction replaces details while locked. Resume/evidence content is never stored there. |
| Share extension | iOS 27 object-loading APIs receive user-selected URLs or text into a bounded, protected App Group inbox | No scraping, credentials, background submission, or silent replacement of existing work. |
| Native design | Standard SwiftUI tabs, navigation, lists, forms, toolbars, sheets, search, system typography, semantic colors, and SF Symbols | Current system components adopt the iOS 27 appearance. Custom content cards remain readable content surfaces instead of receiving decorative glass effects. |
| Protected onboarding and profiles | Four-stage value/profile/assistance/review onboarding plus add, switch, edit, and remove controls for local household profiles | Requests only a preferred name and optional career context, keeps each person's app data isolated, never turns a provider on automatically, and preserves the installation-wide purchase boundary. Local profiles are not online accounts or cross-device sync. |
| Files and OCR | Files picker, security-scoped URLs, PDFKit, bounded Vision OCR, and local Core Graphics/Core Text output | The veteran controls import/export. OCR carries verification warnings. Export creates PDF/RTF/TXT plus a separate private TXT review; federal PDFs over two pages are rejected. |
| StoreKit 2 | One free workspace and one transparent $5.99 lifetime Complete purchase | No subscription, credits, ads, tips, or repeated upsell. Release-candidate source enables the boundary, but the product is not purchasable until App Store Connect and signed sandbox testing pass. |

The current Xcode 27 test and unsigned Release builds compile the app, Share extension, widget, unit tests, and UI tests
for iOS 27. The August 2 integrated M4 Simulator run passed 112 native and 5 UI/accessibility tests after the protected
onboarding, household-profile, and App Review cleanup passes.

## Features intentionally not claimed as launch-ready

- **Private Cloud Compute:** Apple requires a managed entitlement. PCC also requires a network and has quota behavior.
  It will not be enabled or marketed until the entitlement is approved, privacy copy is reviewed, quota/failure behavior
  is tested, and the veteran explicitly chooses it. The unlimited offline system model remains the launch preference.
- **Core AI / bring-your-own model:** iOS 27 exposes a route for app-owned on-device models, but ApplyReady Vets does not
  yet have a validated proprietary model that justifies the additional download size, training governance, bias
  evaluation, and maintenance burden.
- **Multimodal Foundation Models:** document OCR already uses Vision with bounded pages and verification warnings.
  Images will not be passed into a generative model merely because the SDK permits it. A later multimodal feature must
  outperform the existing deterministic OCR path on curated military-document fixtures without weakening privacy.
- **Automatic LinkedIn, Indeed, or Workday submission:** Apple APIs do not grant permission to sign into or automate
  those services. Current integration is Share Sheet capture, copy-ready content, official-link handoff, and local
  status tracking.
- **“Self-healing” production code:** the app can validate, recover protected state, fall back safely, and run automated
  tests. It cannot rewrite and ship itself. Code changes still require review, signed builds, TestFlight, and App Review.

## Release gates for Apple’s later-2026 OS launch

1. Rebuild with Apple’s iOS 27 release-candidate or final Xcode. Beta 4 compilation is not the public-release artifact.
2. Re-run the Foundation Models evaluation corpus because Apple states that the iOS 27 model changed and prompts need
   retesting. Measure supported-edit rate, unsupported-claim rejection, citation accuracy, refusal rate, latency,
   memory, battery/thermal behavior, and the empty-result rate.
3. Test on at least one eligible physical iPhone with Apple Intelligence available and one iOS 27 device where the
   system model is unavailable. The private workflow must complete on both.
4. Test signed App Group behavior for Share extension and widget, Spotlight opt-in/off/deletion, Siri phrases, StoreKit
   purchase/restore/revocation, Files import/export, interruptions, offline use, and device restart.
5. Complete VoiceOver, Voice Control, Larger Text at 200% and accessibility sizes, dark mode, contrast, Reduce Motion,
   small-phone, iPad, first-launch, settings, purchase, and deletion tests. App Store accessibility claims must cover
   every common task, not selected screenshots.
6. Confirm the privacy manifest, App Privacy answers, accessibility nutrition labels, age rating, export compliance,
   review notes, support URL, privacy-policy URL, screenshots, and compatibility copy against the final binary.
7. Upload a signed archive to TestFlight, run a veteran beta, fix high-severity findings, then submit manually through
   the owner’s Apple Developer account.

## Official Apple sources

- [What’s new in iOS](https://developer.apple.com/ios/whats-new/)
- [Foundation Models updates](https://developer.apple.com/documentation/Updates/FoundationModels)
- [Foundation Models framework](https://developer.apple.com/documentation/FoundationModels)
- [Private Cloud Compute language model](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel)
- [Dynamic sessions, instructions, and profiles](https://developer.apple.com/documentation/foundationmodels/composing-dynamic-sessions-with-instructions-and-profiles)
- [Evaluations framework](https://developer.apple.com/documentation/evaluations)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [SwiftUI document-based apps](https://developer.apple.com/documentation/swiftui/creating-a-document-based-app)
- [Human Interface Guidelines: materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [App Store accessibility nutrition labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
- [What’s new on the App Store](https://developer.apple.com/app-store/whats-new/)

Beta APIs, App Store submission requirements, and final device compatibility can change before release. This file must
be reverified against Apple’s release candidate; it is a launch control, not a prediction of Apple’s schedule.
