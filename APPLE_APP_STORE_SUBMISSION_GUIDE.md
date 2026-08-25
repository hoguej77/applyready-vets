# ApplyReady Vets App Store submission guide

Product configuration reconciled: August 1, 2026. Re-check all Apple requirements against the current official pages
and the final submission Xcode before upload.

Official Apple sources:

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Add a new app: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- D-U-N-S Number: https://developer.apple.com/help/account/membership/D-U-N-S/
- Submit an In-App Purchase:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/
- View and edit In-App Purchase information:
  https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information/
- Export compliance:
  https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- Upcoming submission requirements: https://developer.apple.com/news/upcoming-requirements/
- Accessibility Nutrition Labels:
  https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/

## August 1, 2026 Apple-rule verification

- Since April 28, 2026, Apple requires App Store Connect uploads to be built with Xcode 26 or later and an iOS 26 or
  later SDK. ApplyReady Vets exceeds that minimum, but Xcode 27 beta 4 is still a development toolchain. Use the latest
  non-beta Xcode that App Store Connect lists as supported when creating the actual TestFlight/App Store archive.
- Apple requires a privacy-policy URL in App Store Connect and an easily accessible privacy-policy link inside the
  app. The final policy must explain collection, sharing, retention/deletion, consent revocation, and any third-party
  processing. The current Release configuration has no service endpoint and declares no collected data; enabling a
  production service or cloud AI later requires new disclosure answers and another review.
- Apple now uses the updated 4+, 9+, 13+, 16+, and 18+ age-rating system. The current career utility may qualify for 4+
  if the questionnaire confirms no medical/treatment information, unrestricted web access, social features, or other
  rated content. A future VA-disability or medical-information feature requires a fresh questionnaire and may raise
  the rating.
- Accessibility Nutrition Labels appear on the product page. Do not claim VoiceOver, Voice Control, Larger Text, or
  other support based only on automated tests; complete every common task with the relevant feature on signed physical
  devices first.
- If the app is offered in the European Union, App Store Connect requires Digital Services Act trader-status disclosure
  and, when applicable, verification of the contact information displayed to EU customers.
- The first non-consumable In-App Purchase must be submitted with the first app version. The Paid Apps Agreement, tax,
  and banking setup must be complete before the product can be sold.
- App Review requires final, functional URLs, accurate screenshots/metadata, a working purchase visible to review, and
  detailed review instructions. ApplyReady Vets' built-in safe demo mode should be documented in Review Notes.

## Pre-submission blockers

Do not submit until these are complete:

- LLC or chosen legal entity formed.
- Apple Developer organization account approved.
- D-U-N-S verified by Apple.
- Business email and support email live.
- Privacy Policy URL live.
- Terms of Use URL live.
- Support URL live.
- App Store screenshots ready.
- App Store privacy labels matched to real behavior.
- The one non-consumable In-App Purchase configured.
- App builds signed under the organization account.
- Production backend decision made.
- Any cloud AI provider terms and privacy disclosures reviewed.
- VA/DoD/non-affiliation language reviewed.

An LLC is not required to write or test the app. It is the recommended order only if the founder wants an organization
seller name and business separation. Individual enrollment displays the founder's legal personal name as the seller;
organization enrollment requires a verified legal entity, D-U-N-S Number, organization-domain email, public functional
website, and a person with legal authority to bind the entity.

## App Store Connect metadata draft

The canonical local draft is [`app-store-metadata.json`](app-store-metadata.json). It contains the complete description,
review notes, one-product IAP metadata, privacy-answer stop gate, prohibited-claim list, and intentional owner
placeholders. `make metadata-draft-check` enforces Apple's current name, subtitle, promotional-text, description,
keyword, and review-note limits. `make metadata-release-check` additionally requires final HTTPS URLs, owner contacts,
version `1.0.0`, a new build number, final IAP screenshot, and removal of every draft marker. App Store Connect and the
final signed binary remain authoritative.

### Name

ApplyReady Vets

### Subtitle

Veteran Career Builder

### Category

Primary: Business

Secondary: Productivity

### Developer display goal

Jonathan Hogue Develops

Apple controls the displayed seller/developer name based on enrollment and account/legal-entity setup. If enrolled as an
individual, the personal legal name may be displayed. If enrolled as an organization, the verified organization/developer
name can appear after Apple approval.

### Version

Current beta marketing version: `0.7.0`

Current beta build number: `18`

First public submission target after beta approval: `1.0.0` with a new unique build number greater than `18`.

### Age rating target

Target: likely `4+` if the app remains a private career-writing utility with no social feed, mature content, medical
advice, benefits decisions, or public user-generated content. The App Store Connect age questionnaire must be answered
honestly at submission under Apple's updated 2026 rating system. Reassess before adding a VA-disability calculator,
medical/treatment information, or unrestricted in-app browsing.

### Promotional text draft

Build evidence-backed job packets from your resume, service history, and target job posting.

### Short description draft

ApplyReady Vets helps veterans turn verified military and civilian experience into honest PDF, RTF, and TXT resumes,
LinkedIn copy, federal readiness checks, and organized application workspaces without inventing unsupported claims.

### Keywords draft

veteran,resume,career,job search,military transition,federal resume,ATS,job tracker,career tools

### Support URL

TBD

### Privacy Policy URL

TBD

## In-App Purchase setup

The current Release-candidate source sets `HOGUE_STOREFRONT_ENABLED` to `YES`, and the preflight requires that setting.
This is only a source contract. Do not submit or call Complete purchasable until every feature named on the purchase
page is delivered and purchase, pending, cancellation, restore, offline entitlement, Ask to Buy, refund/revocation,
family-sharing decision, interruption, and failure cases pass signed sandbox testing.

### Non-consumable product

Product reference name: ApplyReady Vets Complete

Product ID: `com.jonathanhogue.applyreadyvets.complete.lifetime`

Type: Non-consumable

Launch price decision: `$5.99` once in the U.S. storefront.

Keep the consumer price stable. Do not use a founding-price or later mature-price ladder.

Unlocks:

- unlimited tracked application workspaces and their associated version histories.

The free workspace already includes import, local analysis, Truth Lock, LinkedIn copy, federal checks, and
PDF/RTF/TXT export. Do not describe Complete as selling unimplemented cover letters, interview tools, future features,
or separate AI quality.

Must not paywall:

- Truth Lock safety checks;
- viewing/deleting/exporting user-owned data;
- legal and privacy disclosures;
- basic free evaluation workspace.

### One-product storefront

Do not create optional tip products for launch. Complete is the only consumer purchase. This keeps the App Store
listing, purchase testing, support burden, and user promise simple.

Refund note: Apple controls App Store refund decisions. The app can provide support, restore purchases, use App Store
Server Notifications, and update access after refunded transactions, but it should not promise “no refunds.”

### First In-App Purchase review — required sequence

Apple requires the first In-App Purchase to be submitted with a new app version. For the initial release:

1. Create the non-consumable with the exact product ID above.
2. Add its English display name and description, set availability, and select the `$5.99` U.S. price point.
3. Upload an App Review screenshot that clearly shows the Complete purchase screen. This screenshot is for review,
   not the public App Store gallery.
4. Add review notes explaining that the free workspace is complete and the purchase unlocks unlimited tracked
   workspaces only.
5. Finish agreements, tax, banking, and any required product metadata until the product is eligible for review.
6. On the app version submission page, add ApplyReady Vets Complete under In-App Purchases and click **Add for Review**.
7. Submit the app version and this first In-App Purchase together. Do not submit the product by itself first.
8. After approval, verify the product is available in the intended storefronts before enabling launch marketing.

### Export-compliance record

The reviewed source uses SHA-256 integrity hashes and Apple operating-system networking, not custom encryption.
`ITSAppUsesNonExemptEncryption` is therefore set to `NO` for this source snapshot. Re-run the export-compliance
determination against the final binary before every submission if networking, cryptography, VPN, secure messaging,
or data-protection behavior changes. The developer remains responsible for accurate U.S. and destination-country
answers.

## Xcode release steps

1. Install the latest non-beta Xcode accepted by App Store Connect and re-run the complete quality, Simulator, and
   physical-device suites. Do not archive the public release with the current beta 4 toolchain.
2. Open `ios/ApplyReadyVets.xcodeproj` and select the `ApplyReadyVets` scheme.
3. Confirm bundle ID is `com.jonathanhogue.applyreadyvets`.
4. Confirm the Share extension, widget, and App Group identifiers match the registered Apple resources.
5. Set signing team to the Apple Developer organization.
6. Confirm iOS 27 compatibility, version, and build number.
7. Select `Any iOS Device` or an archive destination.
8. Product > Archive.
9. In Organizer, validate archive.
10. Distribute App > App Store Connect.
11. Upload and wait for App Store Connect processing.

## TestFlight steps

1. Add the processed build to TestFlight.
2. Add internal testers first.
3. Verify onboarding, import, AI consent, analysis, Truth Lock, LinkedIn kit, export, Settings, legal screens, and purchase restore.
4. Add external testers only after internal test passes.
5. Include review notes explaining:
   - independent veteran career-writing tool;
   - not affiliated with VA/DoD/government;
   - AI is optional and outputs are user-reviewed;
   - app does not publish to LinkedIn or automate job applications;
   - app does not provide legal, benefits, claims, disability, or hiring decisions.

## App Review notes draft

ApplyReady Vets is an independent career-writing and job-packet tool for veterans. It is not affiliated with, endorsed by, or operated by the U.S. Department of Veterans Affairs, Department of Defense, USAJOBS, LinkedIn, Indeed, Workday, Apple, Microsoft, OpenAI, or any employer.

The app helps users review their own resume and job-posting text, create evidence-backed suggestions, and export materials. AI features are optional and user-controlled. The app does not make benefits determinations, disability determinations, legal determinations, eligibility decisions, hiring promises, or ATS guarantees. The LinkedIn kit is copy-ready text only; the app does not log in to LinkedIn, publish, scrape, auto-connect, auto-message, or automate job applications.

## Common rejection risks

- Missing privacy policy URL.
- Incomplete app or placeholder screens.
- Digital unlock sold outside IAP.
- Unclear AI/data handling.
- Claims implying government affiliation.
- Unsupported benefit, disability, hiring, or ATS claims.
- App metadata promises features that are not working.
- No restore-purchase path.
- No test instructions for reviewers.
