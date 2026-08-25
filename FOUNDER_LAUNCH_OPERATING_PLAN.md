# ApplyReady Vets founder launch operating plan

Last verified: August 1, 2026

This is the start-to-finish operating plan for turning the current source into a real App Store business. It is a
planning and execution record, not a promise of installs, revenue, trademark availability, legal compliance, or App
Review approval. Jonathan approves and performs identity-bound actions such as purchases, legal signatures, banking,
tax submissions, Apple agreements, and production publication. Codex can prepare, validate, document, and automate the
safe local work around those actions.

## Executive decision

- **Veteran app working name:** `ApplyReady Vets`, pending full trademark, common-law, domain, App Store, and state-name
  clearance.
- **Recommended company umbrella:** `Hogue Career Systems LLC`, pending California name clearance. This is stronger
  than tying the company to one app and can later own a separate civilian product.
- **Consumer promise:** one complete application workspace free, then `ApplyReady Vets Complete` for **$5.99 once** in
  the U.S. storefront. No subscription, ads, tip ladder, AI-credit packs, or export ransom.
- **Launch scope:** United States, current-generation iOS 27 devices, veteran-first, English-first.
- **Primary outcome:** completed trusted application packets, not downloads, time in app, or AI generations.
- **Business target:** pursue 100,000 verified installs and $200,000 of revenue over a 36-month planning horizon. These
  are operating targets, not forecasts or guarantees.

Do not create the civilian spin-off, VA disability estimator, retirement calculator, or branch promotion-packet
builders before the first product proves safe exports, retention, purchase behavior, and veteran usefulness.

## Current source truth

The project is not starting from zero. Version `0.7.0` build `18` currently has a local release candidate with:

- app, Share extension, widget, Siri/Shortcuts, Files import/export, StoreKit test catalog, privacy manifest, and native
  accessibility audit coverage;
- a protected application workspace, job tracker, readiness sub-scores, Truth Lock evidence review, O*NET military
  crosswalk, civilian/federal modes, LinkedIn kit, official-resource links, and bounded on-device assistance;
- one free workspace and one $5.99 lifetime non-consumable product;
- no production cloud endpoint, third-party SDK, tracking domain, credential capture, scraping, or auto-apply claim;
- passing local release-candidate, source-policy, backend, native, UI, AI-quality, and unsigned Release checks.

The strict App Store preflight intentionally remains blocked on exactly three source settings:

1. Jonathan's paid Apple Developer `DEVELOPMENT_TEAM` identifier.
2. A public HTTPS support URL.
3. A public HTTPS privacy-policy URL.

Passing the source preflight will not replace signed device, StoreKit sandbox, TestFlight, legal, privacy,
accessibility, or App Review validation.

## Name and company gate

Preliminary checks completed August 1, 2026:

- the official USPTO word-mark search returned no exact result for `ApplyReady Vets`, `ApplyReady`, or `Apply Ready`;
- a broad public web/App Store search did not surface an obvious exact app-name conflict;
- Verisign `.com` RDAP returned no registration record for `applyreadyvets.com`, `applyreadyvet.com`, or
  `hoguecareersystems.com` at the time checked.

These are knockout screens, not legal clearance or a guarantee that a registrar will sell a domain. Before money is
spent on a logo, entity, or trademark filing:

1. Search confusingly similar spellings, sounds, meanings, and related software/employment services in the USPTO
   system—not only exact matches.
2. Search California bizfile, other state entities, App Store/Google Play, web, social handles, and common-law use.
3. Confirm the desired `.com` and matching support-email domain at a registrar.
4. Have a U.S. trademark attorney review the finalist and the likely software/service classes.
5. Jonathan makes the final name decision before the App Store record, LLC filing, or trademark application is
   submitted.

The USPTO explains that an exact search is insufficient because likelihood of confusion can involve similar wording,
sound, meaning, commercial impression, and related goods or services:
[Federal trademark searching](https://www.uspto.gov/trademarks/search/federal-trademark-searching).

## Company formation sequence

Assuming Jonathan forms a California single-member LLC, use this order:

1. Clear the legal entity name and choose the registered agent and business address.
2. File California Articles of Organization through official bizfile. The current official filing fee is **$70**.
3. Create and sign a single-member operating agreement; do not upload it to Apple or make it public.
4. File the initial Statement of Information within 90 days. The current official fee is **$20**.
5. Obtain an EIN directly from the IRS after the LLC exists. The IRS issues EINs free; do not pay a third party merely
   to obtain one.
6. Open a separate business bank account and bookkeeping system; do not mix personal and business funds.
7. Calendar California Form 568 and the **$800 annual LLC tax**. The first-year waiver applied only to qualifying
   entities formed during 2021–2023; assume it does not cover a 2026 formation unless a qualified professional says
   otherwise.
8. Recheck current FinCEN BOI requirements immediately before and after formation. As of this review, FinCEN states
   that U.S.-created domestic entities are exempt under its interim final rule.
9. Have a California attorney/CPA verify tax classification, deductible startup costs, local business-license needs,
   sales-tax questions, privacy obligations, insurance, and the company/name/IP assignment.

Official sources:

- [California LLC forms and fees](https://www.sos.ca.gov/business-programs/cannabizfile/cannabis-forms-and-fees/limited-liability-companies-llc-california)
- [California FTB LLC requirements](https://www.ftb.ca.gov/file/business/types/limited-liability-company/index.html)
- [IRS EIN application](https://www.irs.gov/businesses/small-businesses-self-employed/get-an-employer-identification-number)
- [FinCEN BOI interim-rule Q&A](https://www.fincen.gov/boi/ifr-qa)

## Public web foundation

Before Apple organization enrollment, create one small, professional site on the final company domain. It must include:

- a real company/app home page;
- support page with a monitored domain email and response expectation;
- privacy policy that matches the shipping binary and optional-service state;
- terms of use, non-affiliation notice, safety limits, and contact information;
- deletion/export instructions and a dated official-sources page;
- no VA, DoD, military-branch, LinkedIn, Indeed, Workday, USAJOBS, or Apple logo or wording that implies endorsement.

Do not publish placeholder legal text as final. The existing drafts are starting materials for independent legal and
privacy review. Once the final support and privacy pages are public, insert their HTTPS URLs in `ios/project.yml` and
rerun `make app-store-preflight`.

## Apple organization and signing sequence

An organization account is preferred because Apple displays the legal entity as the seller. Apple currently requires
an organization to be a legal entity, have a D-U-N-S number, use an organization-associated email/domain and functional
website, and have an Account Holder with authority to bind the organization. The Apple Developer Program currently
costs **$99 per membership year**.

1. Form the LLC and obtain EIN/bank records first.
2. Request or confirm the LLC's free D-U-N-S number; allow for D&B and Apple synchronization.
3. Create the company-domain email and functional site.
4. Enroll as an organization using Jonathan's legal name and authority—not the app name or a DBA.
5. Accept current developer agreements and pay the membership only after Apple verifies the organization.
6. Enroll in Apple's Small Business Program after the paid-app agreement is available and eligibility is confirmed;
   the reduced commission is not automatic.
7. Register the app, Share extension, widget, and App Group identifiers exactly as documented.
8. Select the Apple team in Xcode, regenerate the project, create the app record, and configure agreements, tax, and
   banking in App Store Connect.

Official sources:

- [Apple Developer enrollment](https://developer.apple.com/programs/enroll/)
- [D-U-N-S requirements](https://developer.apple.com/help/account/membership/D-U-N-S/)
- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)

## TestFlight and App Review gate

The initial public version should become `1.0.0` only after the signed release candidate passes this gate:

1. Create the non-consumable `com.jonathanhogue.applyreadyvets.complete.lifetime` at the $5.99 U.S. price point.
2. Test purchase, cancellation, pending/Ask to Buy, restore, offline entitlement, interruption, refund, and revocation
   with signed StoreKit sandbox accounts.
3. On a physical eligible iPhone, test Share Sheet, Siri/App Intents, widget privacy, Files import/export, Foundation
   Models availability/fallback, protected storage, airplane mode, low storage, reinstall, and data recovery.
4. Complete VoiceOver, Voice Control, Dynamic Type, Reduce Motion, contrast, keyboard, compact-phone, and iPad testing.
5. Run a closed TestFlight cohort of 20–50 veterans, transitioning service members, spouses, federal-career users, and
   accessibility participants. Never use real classified, controlled, medical, or employer-confidential documents.
6. Fix all critical/high findings involving unsupported claims, data loss, export, purchase, privacy, accessibility,
   crashes, misleading integration, or non-affiliation.
7. Complete App Store privacy answers, age rating, accessibility labels, screenshots, metadata, support/privacy URLs,
   review notes, and the first in-app purchase submission against the exact tested binary.
8. Submit manually through Jonathan's Apple account. Apple requires the first non-consumable to be submitted with a new
   app version.

Official sources:

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Submit an in-app purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)

## Revenue model and honest target math

Assumptions: 100,000 verified installs, $5.99 U.S. price, Apple Small Business Program eligibility/enrollment, 15%
commission, and no allowance here for taxes, refunds, chargebacks, support, acquisition, insurance, legal work, or
hosted-service cost.

| Lifetime conversion | Purchases | Customer spend | Estimated proceeds after Apple |
| ---: | ---: | ---: | ---: |
| 5% | 5,000 | $29,950 | $25,458 |
| 8% | 8,000 | $47,920 | $40,732 |
| 10% | 10,000 | $59,900 | $50,915 |
| **12% planning target** | **12,000** | **$71,880** | **$61,098** |
| 20% | 20,000 | $119,800 | $101,830 |
| 33.4% | 33,390 | $200,006 | $170,005 |
| 47.1% | 47,140 | $282,369 | $240,013 |

At 12% conversion, the gap from consumer proceeds to $200,000 of developer revenue is about **$138,902** before
organization-channel costs. If the goal instead means $200,000 of operating contribution while preserving a $40,000
operating reserve, the gap is about **$178,902**. A consumer-only model would require roughly 39,282 purchases for
$200,000 after Apple's commission, or roughly 47,138 purchases for $200,000 plus that reserve. Those conversion rates
are not a responsible base case.

The recommended blended path is:

- keep the transparent $5.99 consumer lifetime purchase;
- prove completion, retention, accessibility, privacy, and support burden first;
- then run three to five paid organization pilots with colleges, workforce boards, transition programs, and
  veteran-serving nonprofits;
- price pilots from actual cohort size, onboarding, support, privacy review, reporting, and hosted-assistance cost—not
  from a guessed public price card;
- keep individual veteran content private and never sell personal resume/activity data to employers;
- have counsel review any sponsored-access or institutional digital-feature model for App Store payment compliance.

## Thirty-six-month install path

100,000 installs is a distribution program, not an engineering milestone.

| Stage | Verified-install milestone | Required proof before scaling |
| --- | ---: | --- |
| Closed beta | 50–300 | Safe export, no critical claim escape, usable accessibility, purchase recovery |
| Launch proof | 1,000 | At least 50% first import, 35% reviewed export, support process working |
| Channel proof | 10,000 | 20% four-week return, 10–12% lifetime conversion, reliable attribution |
| Partnership scale | 25,000 | Repeatable organization pilot, referral/ASO engine, acceptable support cost |
| National scale | 100,000 | Multiple durable channels, stable quality guardrails, sustainable unit economics |

Initial acquisition order:

1. Moderated veteran and military-spouse beta communities.
2. Veteran service organizations, state workforce agencies, colleges, transition programs, and military-friendly
   career offices.
3. App Store product-page optimization, credible veteran stories with consent, educational content, and referral loops.
4. Earned press, podcasts, transition workshops, and organization-sponsored cohorts.
5. Paid acquisition only after activation, export completion, conversion, refund, and support economics are measured.

The addressable audience is real but does not guarantee adoption: the Census Bureau reported about **15.7 million**
U.S. veterans in 2024, and the Department of Labor says more than **200,000** service members transition to civilian
life each year.

Sources:

- [U.S. Census Bureau Veterans Day 2025 facts](https://www.census.gov/newsroom/facts-for-features/2025/veterans-day.html)
- [DOL Transition Assistance Program](https://www.dol.gov/agencies/vets/programs/tap)

## KPI contract

North Star: **monthly completed trusted application packets**.

| Metric | Initial gate |
| --- | ---: |
| Welcome to first job/resume import | 50%+ |
| First import to completed analysis | 45%+ |
| Analysis to reviewed export | 35%+ |
| Four-week return | 20%+ |
| Lifetime Complete conversion | 10–12% |
| Crash-free sessions | 99.8%+ |
| Successful export attempts | 99.5%+ |
| Critical unsupported-claim escapes | 0 |
| VoiceOver task completion in moderated testing | 90%+ |

Do not collect veteran documents or personal content merely to measure these metrics. Analytics must be consented,
minimal, documented in the privacy policy/manifest/labels, and reviewed before any SDK or endpoint is added.

## Immediate action board

### Jonathan — next decisions and identity-bound work

1. Decide whether the `$200,000` target means gross customer spend, developer proceeds, or operating contribution.
2. Approve `ApplyReady Vets` as the finalist for full professional clearance and `Hogue Career Systems LLC` as the
   company-name finalist, or choose replacements before filing.
3. Select the business/registered-agent address and whether a commercial registered agent will be used.
4. Approve the domain purchase, LLC filing, D-U-N-S request, Apple membership, and professional reviews one at a time
   when each is ready.
5. Identify 20–50 consented beta participants across the target groups; no sensitive resumes are needed yet.

### Codex — safe work that can continue locally

1. Keep the app release candidate passing while replacing only confirmed legal/company URLs and identifiers.
2. Convert approved legal/support drafts into the public-site package and validate every app link.
3. Prepare the Xcode/Apple identifier worksheet, App Store metadata, screenshot plan, privacy answers, review notes, and
   signed-test scripts.
4. Maintain `GROWTH_MEASUREMENT_AND_LAUNCH_PLAN.md`, its portable founder report, the beta severity rubric, and the
   privacy-preserving launch KPI contract without adding a tracking SDK.
5. Update README, changelog, roadmap, and release notes after every material decision or code change.

## Stop/go rule

Do not submit to App Review until `make app-store-release-check` passes and the signed TestFlight checklist is complete. Do
not scale marketing until the first 1,000 verified installs meet the activation/export/support gates. Do not promise
100,000 installs, $200,000 revenue, a job, an interview, ATS passage, benefit eligibility, or government affiliation.
