# ApplyReady Vets App Review checklist

Status reconciled August 2, 2026. This is the short operational checklist. The detailed metadata and policy language
remain in `APPLE_APP_STORE_SUBMISSION_GUIDE.md`.

## Locally complete

- [x] Native iOS 27 app, Share extension, widget, App Intents, Files import/export, local career engine, and StoreKit 2
  lifetime entitlement compile together.
- [x] Release has no default external-service endpoint, third-party SDK, advertising tracker, or analytics tracker.
- [x] Privacy manifests, App Group identifiers, bundle identifiers, product ID, version, build, and non-exempt-encryption
  declaration are internally consistent.
- [x] One complete workspace remains free; one non-consumable Complete product unlocks unlimited workspaces.
- [x] First launch creates a protected local profile, discloses non-affiliation, requests no sensitive government or
  medical identifiers, and records an explicit assistance level. Multiple profiles remain isolated; the free boundary
  remains installation-wide; external handoff is preview-and-share only.
- [x] Consumer purchase copy promises only implemented behavior and provides Restore Purchases.
- [x] Historical HogueResMaster and MusterForward strings are limited to dated history or beta-data migration paths.
- [x] Local quality, unsigned Release, source-package, and release-candidate preflight gates pass.

## Owner information required before signing

- [ ] Final seller choice: individual legal name or verified organization.
- [ ] Paid Apple Developer Program team ID.
- [ ] Live public HTTPS Support URL.
- [ ] Live public HTTPS Privacy Policy URL matching the final binary.
- [ ] Final developer/seller name confirmed by Apple.
- [ ] App name, company name, domain, and trademarks cleared by qualified counsel.

Enter the team and URLs in `ios/project.yml`, regenerate the Xcode project, and run:

```zsh
make app-store-release-check
```

That command is expected to fail until the three source settings, public launch site, final App Store metadata, owner
contacts, public version/build, and placeholders are all ready. Never insert personal credentials, API keys, bank
details, tax identifiers, certificates, or provisioning profiles into source.

## Apple portals

- [ ] Register the app, Share, and widget bundle IDs and the App Group.
- [ ] Create the App Store Connect app record.
- [ ] Sign the Paid Apps Agreement and finish tax and banking setup.
- [ ] Create `com.jonathanhogue.applyreadyvets.complete.lifetime` as a $5.99 U.S. non-consumable.
- [ ] Add localized product text and the reviewer-only purchase screenshot.
- [ ] Complete App Privacy, age rating, accessibility labels, export compliance, and EU trader-status questions.
- [x] Create the bounded, machine-checked metadata draft in `app-store-metadata.json`.
- [ ] Replace its support, privacy, marketing, copyright, review-contact, and IAP screenshot placeholders and validate
  the actual App Store Connect entry against the file.
- [ ] Add final screenshots and reconcile every visible claim with the tested shipping binary.

## Signed testing

- [ ] Use the latest non-beta Xcode accepted by App Store Connect for the submission archive.
- [ ] Test an Apple Intelligence-capable physical iPhone and a supported configuration where the model is unavailable.
- [ ] Test signed App Group behavior: Share extension, widget, locked-device privacy, deletion, and restart.
- [ ] Test Siri/App Shortcuts, Spotlight opt-in/off/deletion, Files import/export, offline use, interruptions, and rotation.
- [ ] Test StoreKit purchase, cancellation, pending, Ask to Buy, restore, offline entitlement, refund, and revocation.
- [ ] Complete every common task with VoiceOver, Voice Control, largest text, dark mode, increased contrast, and Reduce
  Motion before selecting App Store accessibility labels.
- [ ] Run a veteran internal TestFlight, fix all release-blocking findings, then run a controlled external beta.

## Submission

- [ ] Set the public marketing version to `1.0.0` and use a new unique build number after beta approval.
- [ ] Archive, Validate App, and upload the exact tested signed build.
- [ ] Attach the first non-consumable purchase to the same version submission.
- [ ] Explain safe demo mode, the one free workspace, purchase boundary, on-device AI, and job-platform handoffs in Review
  Notes.
- [ ] Select manual release so the owner controls the launch date.

Do not submit while `make app-store-release-check` fails. Passing it confirms local source/site/metadata configuration
only; it does not replace signed-device tests, TestFlight, legal/accessibility review, or Apple's decision.
