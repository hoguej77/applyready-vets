# ApplyReady Vets legal and launch master plan

Product configuration reconciled: July 30, 2026. Re-check every government fee, deadline, tax rule, Apple requirement,
and legal form against its official source immediately before acting.

This is an operating checklist, not legal, tax, accounting, or trademark advice. Use it to organize the work before speaking with a California business attorney, CPA, and trademark counsel.

Assumption: the founder is forming in California. If the company will be formed in a different state, replace the state-specific steps before filing.

## 1. Entity decision

Recommended starting structure: California limited liability company.

Why:

- Keeps the business separate from the founder personally.
- Fits an early-stage solo app company.
- Can open a business bank account, Apple Developer organization account, contracts, and insurance under the company.
- Easier to manage than a corporation at this stage.

Tradeoff:

- California LLCs owe an $800 annual tax if organized or doing business in California.
- If raising venture capital later, a Delaware C-corp may become more appropriate.

## 2. Proposed company and product names

Working product name:

- App: `ApplyReady Vets`
- App subtitle: `Veteran Career Builder`
- Paid unlock: `ApplyReady Vets Complete`
- Bundle ID: `com.jonathanhogue.applyreadyvets`
- Desired developer display: `Jonathan Hogue Develops`

Possible legal entity names:

- `Jonathan Hogue Develops LLC`
- `ApplyReady Vets LLC`
- `Hogue Career Systems LLC`
- `Truth Lock Career Systems LLC`

Recommended entity name for the user's current preference: **Jonathan Hogue Develops LLC**.

Reason: it is closest to the desired App Store developer display. A broader umbrella such as `Hogue Career Systems LLC`
or `Hogue Career Labs LLC` is still cleaner if multiple apps will be launched later.

Before filing:

- Search California Secretary of State business names.
- Search USPTO trademarks.
- Search App Store names.
- Search domains and social handles.
- Have counsel confirm the final name does not create confusion.

## 3. California LLC formation steps

### Step 1: Choose the LLC name

California LLC names must be distinguishable in Secretary of State records and must not mislead the public. A proposed LLC name must include an LLC identifier such as `LLC`, `L.L.C.`, or `Limited Liability Company`.

Recommended entity name for review: `Jonathan Hogue Develops LLC`, `Hogue Career Systems LLC`, or final counsel-approved name.

Official source: https://www.sos.ca.gov/administration/regulations/current-regulations/business/business-entity-names

### Step 2: Choose a registered agent

Use either:

- a commercial registered agent; or
- an individual California resident willing to accept service of process.

Do not casually use a home address if privacy matters. Registered agent and business addresses may become public.

### Step 3: File Articles of Organization

File California Form LLC-1 online through bizfile.

Official source: https://www.sos.ca.gov/business-programs/business-entities/forms

Current official fee shown by California SOS for LLC Articles of Organization: `$70`.

Official source: https://www.sos.ca.gov/business-programs/cannabizfile/cannabis-forms-and-fees/limited-liability-companies-llc-california

### Step 4: File Statement of Information

California LLCs must file the Statement of Information within 90 days of initial registration and every two years after that.

Current official fee shown by California SOS: `$20`.

Official source: https://www.sos.ca.gov/business-programs/cannabizfile/cannabis-forms-and-fees/limited-liability-companies-llc-california

### Step 5: Pay California LLC annual tax

California FTB states that every LLC doing business in California or organized in California must pay an annual tax of `$800`.

The first-year annual tax is due by the 15th day of the 4th month from the date the LLC is filed with the Secretary of State. Later annual tax payments are due on the 15th day of the 4th month of the taxable year.

Official source: https://www.ftb.ca.gov/file/business/types/limited-liability-company/index.html

### Step 6: Get an EIN

Apply directly through the IRS. The IRS states an EIN can be obtained online for free in minutes if approved.

Official source: https://www.irs.gov/businesses/small-businesses-self-employed/get-an-employer-identification-number

Do not pay third-party sites for an EIN unless you intentionally hire a professional.

### Step 7: BOI / FinCEN check

As of this review date, FinCEN states that entities created in the United States and their beneficial owners are exempt from BOI reporting under the interim final rule.

Official source: https://www.fincen.gov/boi

Because this rule has changed before, re-check FinCEN immediately before and after forming the LLC.

### Step 8: Open business operations

After the LLC and EIN exist:

- open a business checking account;
- get a business credit/debit card;
- create bookkeeping categories;
- buy domain and business email;
- set up password manager and 2FA;
- create support email;
- consider professional liability, cyber, and general liability insurance;
- apply for Apple Developer Program organization enrollment.

## 4. LLC filing worksheet

Use this to prepare the official forms. Do not place private data in source control.

### Articles of Organization worksheet

| Field | Planned answer |
| --- | --- |
| LLC legal name | `Jonathan Hogue Develops LLC`, `Hogue Career Systems LLC`, or final counsel-approved name |
| Initial street address | `TBD - use business/registered office, not casual home address` |
| Initial mailing address | `TBD` |
| Registered agent type | `TBD - commercial agent recommended for privacy` |
| Registered agent name | `TBD` |
| Registered agent street address | `TBD` |
| Management | `One manager` if founder-managed; confirm with counsel |
| Organizer | `Founder or filing service` |
| Purpose | Usually broad lawful business purpose unless form requires otherwise |

### Statement of Information worksheet

| Field | Planned answer |
| --- | --- |
| LLC name | Same as filed Articles |
| California entity number | Assigned after filing |
| Principal office address | `TBD` |
| Mailing address | `TBD` |
| Manager/member name and address | `TBD` |
| Registered agent | Same as current agent |
| Type of business | Software application and career-document preparation tools |
| CEO, if required by form | `TBD` |
| Authorized signer | Founder/manager |

## 5. Apple Developer organization setup

For an Apple Developer Program organization account, Apple requires the organization to be a legal entity and have a D-U-N-S Number, except for government entities. Apple uses the D-U-N-S Number to verify identity, legal entity status, and address.

Official sources:

- https://developer.apple.com/help/account/membership/D-U-N-S/
- https://developer.apple.com/programs/enroll/

Recommended path:

1. Form LLC.
2. Get EIN.
3. Get domain and business email.
4. Check/request D-U-N-S after the LLC record exists.
5. Enroll as an Apple Developer organization.
6. Complete App Store Connect agreements, tax, and banking.

## 6. App Store upload process

Official Apple upload source: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/

Official Apple app-record source: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/

Steps:

1. Confirm Apple Developer Program organization enrollment is active.
2. In Certificates, Identifiers & Profiles, create identifiers for the app, Share extension, widget, and the shared App
   Group used by all three targets.
3. Enable only the capabilities required by the final signed binary. The current source uses an App Group; other
   capability requests should be justified and revalidated.
4. In App Store Connect, create a new app record for `ApplyReady Vets`.
5. Fill metadata: name, subtitle, description, keywords, category, support URL, marketing URL if used, privacy policy URL, age rating.
6. Configure App Privacy details before review.
7. Configure `ApplyReady Vets Complete` as a non-consumable In-App Purchase.
8. Do not create consumer tip, donation, subscription, credit, or feature-pack products for the planned launch.
9. Create screenshots and app preview assets from the final tested binary.
10. Archive the app in the non-beta Xcode version Apple accepts for submission.
11. Validate and upload the archive from Xcode Organizer or Transporter.
12. Wait for build processing in App Store Connect.
13. Add the build to TestFlight.
14. Test internally, then run an approved external veteran beta if appropriate.
15. Fix beta feedback and App Review issues.
16. Submit the final app for App Review only through the owner's authorized Apple account.

## 7. Apple compliance rules that matter most

Apple App Review Guidelines source: https://developer.apple.com/app-store/review/guidelines/

App Privacy Details source: https://developer.apple.com/app-store/app-privacy-details/

Critical rules for this app:

- Digital feature unlocks must use Apple In-App Purchase.
- Do not route digital unlocks to Zelle, Cash App, external checkout, license codes, or hidden payment links.
- The current launch offer has no tips or donations. If fundraising is ever revisited through an approved nonprofit
  relationship, treat it as a separate reviewed design and never use it to unlock digital features.
- Do not imply VA, DoD, USAJOBS, LinkedIn, Indeed, Workday, Apple, or employer affiliation.
- Do not use VA seals, military branch insignia, or official government marks.
- Do not promise ATS success, interviews, eligibility, disability ratings, compensation, hiring, or government benefits.
- Explain AI use, cloud processing, redaction, retention, and deletion plainly.
- Give App Review any needed demo credentials or instructions.
- Make sure the app is complete, stable, and not just a shell around future features.
- Match App Store privacy labels to actual data collection and backend behavior.

## 8. Public legal documents needed before launch

Create and have reviewed:

- Terms of Use.
- Privacy Policy.
- AI and Truth Lock disclosure.
- Non-affiliation notice.
- Support and refund policy.
- Data deletion/export process.
- Organization licensing agreement.
- Beta tester agreement or TestFlight instructions.
- Security contact and vulnerability reporting process.

## 9. Overlooked product requests now tracked

These requests are now part of the launch plan:

- Better name and brand architecture.
- LLC formation and Apple organization setup.
- App Store upload and review process.
- Apple payment compliance.
- One-time lifetime unlock instead of subscription upsells.
- One non-consumable Complete purchase with no consumer tip ladder.
- Future non-veteran spin-off.
- LinkedIn builder without prohibited automation.
- Job-link workspace for LinkedIn, Indeed, Workday, USAJOBS, and employer pages.
- VA disability calculator as educational estimate only.
- Retirement calculator deferred until expert review.
- README, changelog, release notes, and roadmap alignment.

## 10. Current source versus legal launch

The source currently targets iOS 27 and implements one free completed application plus one $5.99 lifetime
non-consumable for unlimited workspaces. It also contains a Share extension, widget, and shared App Group. The
Release-candidate source enables the StoreKit boundary but ships no optional-service endpoint.

None of those source settings completes the external launch work. Before calling the app purchasable or
release-ready:

1. Register all identifiers and the App Group under the paid Apple Developer team.
2. Create the exact non-consumable product in App Store Connect.
3. Complete agreements, tax, and banking through the owner's authorized account.
4. Test signed purchase, pending, cancellation, restore, refund/revocation, Ask to Buy, interruption, and offline
   behavior.
5. Test Share, widget, Siri/Shortcuts, Spotlight, Files, accessibility, and optional Apple Foundation Models on physical
   devices.
6. Publish reviewed privacy/support documents that match the final binary and any actual service/provider behavior.
7. Complete TestFlight and independent legal, privacy, accessibility, employment, benefits, security, and OPSEC review.

The app must not file an LLC, accept contracts, enter tax/banking information, purchase Apple membership, or submit an
App Store build automatically. Those are founder-controlled identity and legal actions.
