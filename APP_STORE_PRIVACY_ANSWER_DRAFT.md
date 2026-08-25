# ApplyReady Vets App Store privacy answer draft

Reviewed source: ApplyReady Vets 0.7.0 build 18. This is a source-derived draft, not a substitute for App Store
Connect's current questions, the final Xcode privacy report, or privacy counsel. Reconcile it again against the exact
signed binary immediately before publishing the answers.

## Current launch recommendation

For the currently reviewed Release configuration, the likely App Store answer is **Data Not Collected** by the
developer:

- the app has no default public service endpoint;
- the private core processes work locally;
- app-managed content remains in the app sandbox/Files unless the user chooses to share it;
- the app contains no third-party analytics or advertising SDK;
- the privacy manifest declares no collected-data types, no tracking, and no tracking domains;
- the developer does not receive Apple system backups;
- Apple processes App Store purchases under Apple's platform relationship rather than sending full resume content to
  the developer.

Apple's definitions and final questionnaire control. “Data Not Collected” must be changed if any data is transmitted
off-device to the developer or its third-party partners for more than the narrow on-device/platform behavior Apple
excludes from collection.

## Tracking

| Question | Draft answer | Evidence |
| --- | --- | --- |
| Does the app track users across other companies' apps or websites? | No | No tracking SDK, IDFA, tracking domains, ads, or data-broker sharing in the reviewed source. |
| Is data used for third-party advertising? | No | No advertising system. |
| Is data sold to data brokers or employers? | No | Product policy prohibits selling individual resume/veteran activity data. |

## Important distinctions

- Local resume, job, profile, tracker, and export content is sensitive but is not “collected by the developer” merely
  because the app stores it on the user's device.
- Household profiles are local partitions, not accounts or cross-device family sharing. Their preferred name,
  relationship to service, optional branch/career direction, and assistance preference remain local in the reviewed
  Release path. Removing a profile does not delete copies the user previously exported to Files.
- A user choosing Apple's share sheet, opening a website, sending an email, or exporting a file gives the destination
  its own data relationship. The app must accurately explain that handoff.
- Apple on-device Foundation Models are preferred and explicitly consented. Verify Apple's current privacy-label
  treatment and the actual runtime path before final answers.
- “External help by approval” currently means a user-reviewed preview and Apple Share Sheet. It does not authenticate
  to ChatGPT or Copilot, embed an external-provider key, or enable the optional development endpoint.
- Purchase history/transaction entitlement is used to unlock Complete. Verify the StoreKit data treatment in Apple's
  current instructions; do not invent a “Purchases” collection disclosure without applying Apple's definitions.

## If any public optional service is enabled

Stop the release and repeat the privacy review. At minimum determine whether the service collects:

- user content: resume, job posting, profile, unsupported document, and prompts;
- user ID or device/account identifier;
- purchase/entitlement state;
- diagnostics, network logs, IP address, or crash data;
- support communications;
- usage/analytics events.

For every applicable type, document purpose, linkage to identity, tracking status, processor/subprocessor, hosting
region, retention, deletion, security, consent, and whether collection is optional. Update the in-app disclosure,
privacy policy, privacy manifest if required, App Store answers, review notes, threat model, tests, and support process
before the endpoint is shipped.

## Final evidence checklist

- [ ] Xcode privacy report for the signed archive reviewed.
- [ ] `PrivacyInfo.xcprivacy` files for app and widget reviewed.
- [ ] Binary dependency/SDK inventory reviewed; no undeclared SDK added.
- [ ] Release endpoint is blank or the full service review above is complete.
- [ ] All outbound paths tested with consent denied, revoked, offline, interrupted, and unavailable.
- [ ] Public privacy policy matches the final entity, contact, binary, service state, and StoreKit behavior.
- [ ] Privacy counsel reviewed the public policy and App Store answers.
- [ ] Account Holder publishes the answers in App Store Connect.

Official reference: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
