# ApplyReady Vets product decision

Last updated: July 30, 2026

## Current decision

The veteran-first app should move forward publicly as **ApplyReady Vets**.

- App Store name: `ApplyReady Vets`
- Subtitle: `Veteran Career Builder`
- Tagline: `From service to submitted.`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Paid unlock: `ApplyReady Vets Complete`
- Developer display goal: `Jonathan Hogue Develops`
- Marketing version: `0.7.0`
- Build number: `18`
- Civilian spin-off: unnamed for now

The Xcode project, scheme, targets, Swift modules, core package, app product, tests, and source folders now use
`ApplyReadyVets`. `MusterForward` remains only in compatibility migrations for earlier beta keychain and draft data.

## What the app is

ApplyReady Vets is not another template resume builder. It is a veteran application workspace:

- Resume import and job-posting import.
- Evidence-backed resume improvement.
- Truth Lock review before anything is exported.
- Veteran-to-civilian translation.
- Isolated per-job workspaces, deadlines, required documents, and packet versions.
- Dated USAJOBS/federal readiness guidance and two-page PDF enforcement.
- Offline O*NET military occupation mapping.
- LinkedIn profile copy.
- Employer-facing PDF, editable RTF, and parser-safe TXT plus a separate private TXT review.

Executive, Workday field-by-field, college, federal-contractor, promotion, cover-letter, interview, and broader packet
materials remain roadmap or development-service history unless the native app explicitly implements and validates them.

## Non-affiliation rule

The product must clearly say:

> ApplyReady Vets is an independent career-writing tool. It is not affiliated with, endorsed by, or operated by the U.S.
> Department of Veterans Affairs, Department of Defense, OPM, USAJOBS, LinkedIn, Indeed, Workday, Apple, Microsoft,
> OpenAI, Zelle, or any employer.

Do not use the VA seal, branch seals, government emblems, official insignia, or visual designs that imply endorsement.
Use civic colors and original abstract marks only.

## Business model recommendation

Keep the launch model simple:

1. Free download.
2. One useful free job packet so veterans can judge trust and quality.
3. One transparent **$5.99 lifetime unlock**.
4. No consumer tip ladder.
5. Organization licensing for colleges, veteran nonprofits, workforce boards, transition programs, and employers.

Avoid subscriptions, ads, credit packs, hidden upsells, and personal Zelle as the main payment path.

### Pricing decision

The launch decision is:

- Free download.
- One complete, tracked, exportable application workspace free.
- `ApplyReady Vets Complete`: **$5.99 once** in the U.S. storefront for unlimited tracked application workspaces.
- No later price ladder, subscription, ad tier, AI credits, feature packs, or export ransom.
- No consumer tips at launch; Complete is the only consumer purchase.

At $5.99, 40,000 purchases produce $239,600 in customer spend and an estimated $203,660 after a 15% Apple commission,
before refunds, taxes, support, marketing, legal, research, hosting, and other operating costs. Reaching $200,000 of
operating contribution after a $40,000 reserve would require about 47,140 purchases. At 100,000 installs that is roughly
47% conversion, so the honest plan cannot depend on consumer purchases alone. Organization licensing, sponsored
veteran access, and tightly bounded service costs are required for the larger revenue goal. This is a planning model,
not a guarantee.

Refunds cannot be blocked by app design. Apple controls the App Store refund process. The correct approach is to provide
clear purchase copy, restore purchases, support links, App Store Server Notifications, and consumption/refund handling.

## Developer and company naming

The desired App Store developer display is `Jonathan Hogue Develops`. Apple display names depend on enrollment type and
the account/legal entity setup:

- Individual enrollment usually displays the individual legal name.
- Organization enrollment can display the legal entity/developer name after verification.

If the goal is to show `Jonathan Hogue Develops`, form and enroll an organization whose legal/business name supports that
display. A practical LLC name is `Jonathan Hogue Develops LLC`. A broader umbrella alternative is `Hogue Career Labs LLC`.

## LLC and Apple launch path

High-level path, not legal advice:

1. Pick final LLC name.
2. File LLC formation through LegalZoom or directly through the state.
3. Get EIN from IRS.
4. File required state initial/ongoing reports.
5. Open business bank account.
6. Get business email/domain.
7. Request/confirm D-U-N-S number if enrolling Apple as an organization.
8. Pay Apple Developer Program annual fee.
9. Create app identifier for `com.jonathanhogue.applyreadyvets`.
10. Create App Store Connect app record.
11. Configure IAP products.
12. Add privacy policy, terms, support URL, screenshots, and review notes.
13. Upload TestFlight build.
14. Run internal and external beta.
15. Submit to App Review.

Apple sources:

- Apple Developer Program enrollment: <https://developer.apple.com/help/account/membership/program-enrollment/>
- Apple Developer Program fee: <https://developer.apple.com/programs/enroll/>
- Set developer name: <https://developer.apple.com/help/app-store-connect/create-an-app-record/set-your-developer-name/>
- App Store Connect: <https://developer.apple.com/app-store-connect/>

## Immediate engineering state

Implemented in this pass:

- The public and internal product identity is `ApplyReady Vets 0.7.0`, build `18`, with bundle ID
  `com.jonathanhogue.applyreadyvets`.
- A required private career engine, evidence ledger, readiness sub-scores/gap/safety review, veteran-language
  translation, Truth Lock, LinkedIn drafting, and protected PDF/RTF/TXT export run without an account, network, or AI
  model.
- Local import supports text-family files, RTF, HTML, images, selectable PDFs, and bounded Vision OCR for scanned PDFs.
- A native Share Extension accepts user-selected HTTP(S) job links and text through a protected App Group inbox and
  asks before replacing existing job text.
- Full-workspace autosave, root-first authoritative commits, checksummed recovery, corrupt-file quarantine, Keychain
  protection, verified local-erasure retry, Release endpoint policy, exact proposal citations, and final export
  revalidation are implemented.
- StoreKit product IDs use the `applyreadyvets` namespace. The current Release-candidate source enables the one-free /
  unlimited-Complete boundary; the local catalog is test-only. Initial entitlement resolution precedes workspace
  shortcuts, and the paywall can retry a failed catalog load. App Store Connect product creation and signed sandbox
  testing still remain.
- Each tracked application has an isolated protected workspace. The tracker stores platform/employer links, status,
  notes, deadline, required documents, and versioned export filenames.
- The bundled August 2024 O*NET crosswalk contains 12,921 mappings across all six branches.
- Apple on-device assistance is optional and eligibility/consent gated. Any service fallback requires separate consent;
  Release ships with no service endpoint.
- The prior names remain only in historical records and narrowly scoped compatibility migrations.
- The README, changelog, release notes, architecture, privacy, testing, competitor audit, and roadmap describe the
  current source boundary and identify external release gates.

Deferred:

- Microsoft Copilot/Azure/education-account integration.
- Production HTTPS backend and user accounts.
- Native DOCX, Workday field-by-field copy, cover/interview/supplemental materials, broader packet outputs, and Share
  Extension file attachments. PDF/RTF/TXT and federal two-page rejection are already implemented.
- Physical-device App Group, Foundation Models, accessibility, StoreKit, TestFlight, and App Review validation.
- Final legal/trademark clearance.
