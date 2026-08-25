# ApplyReady Vets growth, measurement, and launch plan

Last verified: August 1, 2026

This plan connects the shipping product to the founder's 36-month goals of 100,000 first-time downloads and $200,000
of operating contribution. The targets are ambitions, not forecasts or guarantees. No paid acquisition, organization
contract, tracking SDK, or production telemetry service is authorized by this document.

## Executive decision

- **Keep the $5.99 one-time consumer promise.** It is simple, transparent, and differentiated from subscription-heavy
  resume apps. One complete workspace remains free; Complete unlocks unlimited workspaces.
- **Do not optimize for installs alone.** The product's real value is a candidate-reviewed, evidence-backed application
  packet. First-time downloads, trusted packet completion, retention, and proceeds must be reviewed together.
- **Launch without a third-party analytics SDK.** Use App Store Connect Analytics, Sales and Trends, TestFlight, crash
  reports, and structured beta scorecards first. Do not transmit resume, service, job, claim, evidence, or employer text
  for analytics.
- **Treat $200,000 as a blended-business target.** At $5.99 and an assumed 15% Apple commission, consumer sales alone
  require about 39,282 purchases before refunds, tax effects, support, legal, marketing, and operating costs. At
  100,000 installs, that is about 39.3% download-to-purchase conversion. Organization pilots can reduce that dependence,
  but they must be validated and structured consistently with Apple's enterprise-services rules.

## What success means

### North-star outcome

**Monthly trusted packet completions:** the number of distinct application workspaces in which a candidate finishes
Truth Lock review and successfully exports an employer-facing PDF, RTF, or TXT packet during a calendar month.

This is the correct value metric, but the current private Release build does not transmit it. During beta, measure it
through tester scorecards and observed test sessions. After launch, keep it local unless Jonathan explicitly approves a
privacy-reviewed, opt-in aggregate measurement design and the privacy policy/App Store answers are updated before use.

### Primary operating KPIs

| KPI | Definition | Source | 36-month target | Decision it controls |
| --- | --- | --- | --- | --- |
| First-time downloads | Devices downloading the app for the first time, using Apple's definition | App Store Connect Analytics | 100,000 | Whether discovery and channel work are scaling |
| Trusted packet completion | Distinct workspaces with final Truth Lock pass and successful employer-facing export | Beta scorecard now; production source intentionally unavailable | Establish beta baseline, then set cohort targets | Whether the product delivers real candidate value |
| Operating contribution | Apple proceeds plus collected organization revenue, less refunds and direct launch/operation costs, before personal income tax | App Store Connect financial reports plus bookkeeping | $200,000 | Whether the business model is working |

Do not combine “downloads,” “installations,” and “active devices.” Apple defines them differently. Use First-Time
Downloads for the 100,000-install public goal and record any public wording as “first-time downloads” for auditability.

### Driver metrics

| Primary KPI | Driver | Calculation | Current measurement path |
| --- | --- | --- | --- |
| First-time downloads | App Store conversion rate | total downloads and pre-orders / unique device impressions | App Store Connect Analytics |
| First-time downloads | Qualified channel downloads | first-time downloads attributed to a named Apple campaign link | App Store Connect campaign analytics; campaigns appear after Apple's privacy threshold |
| Trusted packet completion | Activation completion | testers completing import, target job, analysis, and Truth Lock / testers who start | TestFlight cohort scorecard |
| Trusted packet completion | Export success | successful final exports / final export attempts | Automated tests plus beta defect log; no production transmission |
| Operating contribution | Download-to-paid conversion | unique paying users / first-time downloads | App Store Connect Analytics and Sales |
| Operating contribution | Organization contribution | collected pilot revenue less direct delivery/support costs | Bookkeeping; no target until customer discovery validates scope |

### Guardrails

| Guardrail | Release floor | Why it cannot be traded away |
| --- | --- | --- |
| Crash-free sessions | At least 99.8% after enough real sessions exist; no unresolved launch/export crash | Trust and App Review quality |
| Export success | At least 99.5% in controlled release/beta attempts and zero known data-loss defects | The app's core promise is a usable file |
| Unsupported employer-facing claim escape | Zero in the versioned evaluation corpus and zero confirmed beta escapes | Veteran credibility and legal/trust risk |
| AI evaluation usefulness | At least 98% on the versioned, representative veteran corpus, with 100% required safety gates | AI must assist, not invent or silently lower quality |
| Accessibility task completion | At least 90% of moderated target users complete the core flow without assistance; no P0/P1 accessibility defect | Equal access and App Store trust |
| Refund/revocation correctness | 100% of signed sandbox cases handled; production refunds monitored | StoreKit entitlement integrity |

Apple usage metrics are based partly on users who opt in to share analytics. Treat them as Apple-defined signals, not a
complete census of every user's behavior.

## Revenue reality at $5.99

The table assumes 100,000 first-time downloads, a $5.99 U.S. price, and a 15% Apple commission. It excludes refunds,
tax effects, exchange rates, support, legal, marketing, hosting, and other costs.

| Download-to-purchase conversion | Purchases | Customer spend | Estimated proceeds after Apple |
| ---: | ---: | ---: | ---: |
| 12% | 12,000 | $71,880 | $61,098 |
| 20% | 20,000 | $119,800 | $101,830 |
| 30% | 30,000 | $179,700 | $152,745 |
| 39.3% | 39,300 | $235,407 | $200,096 |

Approximately 47,138 purchases would produce $240,000 after the assumed commission, leaving a $40,000 planning reserve
before the other excluded costs. This is why the recommended plan preserves a bargain consumer product while later
testing paid organization pilots for colleges, workforce agencies, veteran nonprofits, and employers. Pilot pricing,
support scope, procurement terms, privacy terms, and App Store treatment remain unapproved research questions.

## Privacy-preserving measurement stack

### Use at launch

1. **App Store Connect Analytics:** impressions, product page views, conversion, first-time downloads, sources,
   retention, sessions, crashes, paying users, IAP, proceeds, and refunds where Apple exposes them.
2. **Apple campaign links:** separate partner/channel URLs for veteran organizations, transition programs, colleges,
   federal-career content, earned media, and founder content. Do not use personally identifying campaign tokens.
3. **TestFlight:** invite acceptance, install/session/crash signals, screenshots, written feedback, and the controlled
   completion scorecard in `BETA_TEST_PLAN.md`.
4. **Bookkeeping:** Apple deposits, refunds, legal/filing, support, hosting, creative, and approved marketing costs.
5. **Support log:** issue category, severity, app/build version, resolution time, and confirmed defect. Do not copy a
   veteran's resume or sensitive documents into a growth spreadsheet.

### Do not add for version 1.0

- advertising identifiers, cross-app tracking, fingerprinting, or data brokers;
- third-party analytics or session-replay SDKs;
- resume/job/service text in telemetry;
- hidden remote prompts, undeclared cloud AI, or credential collection;
- custom review gates, review incentives, filtered review prompts, or ranking manipulation.

If product-level production events become necessary, stop before implementation. Define the minimum aggregate event,
obtain explicit consent where required, add an in-app withdrawal path, update the privacy policy and App Store privacy
answers, set retention/deletion limits, validate the final SDK/service, and submit the changed behavior honestly.

## App Store product-page strategy

### Default page promise

**From service to a reviewed application packet—privately, with one complete workspace free.**

Recommended screenshot sequence:

1. Start from a resume, a job, or military service.
2. Translate service experience with the dated offline occupation crosswalk.
3. See specific readiness sub-scores and missing requirements.
4. Review the evidence behind every proposed claim in Truth Lock.
5. Build civilian or federal materials without mixing the rules.
6. Copy a LinkedIn kit and track job links, deadlines, notes, and versions.
7. Export locally; one workspace is free, Complete is $5.99 once.

Each screenshot must show the shipping UI, use synthetic data, fit the final device sizes, remain readable, and avoid VA,
DoD, branch, employer, job-platform, Apple, or other third-party logos.

### Audience-specific pages after the default listing is approved

- **Military-to-civilian:** lead with service translation, occupation mapping, evidence, and civilian wording.
- **Federal career:** lead with announcement requirements, series/grade planning, two-page readiness, and dated official
  source links without implying USAJOBS affiliation.
- **Career accountability:** lead with the tracker, deadlines, packet versions, LinkedIn copy, and private exports.

Apple supports custom product pages with unique URLs and downstream analytics. Submit every custom page for review and
keep its claims inside the implemented feature boundary.

### Product-page optimization

Do not start a test until the default page has enough traffic for a meaningful result. Test one hypothesis at a time,
starting with screenshot order or first-frame promise. Apple currently permits up to three treatments. Do not declare a
winner before App Store Connect reaches an appropriate confidence level, and do not change the app icon merely to chase
noise.

## Launch stages and stop/go gates

### Stage 0 — owner prerequisites

- approve the final app and LLC names after comprehensive clearance;
- form the entity, create domain email/site, enroll Apple organization account, and finish agreements/tax/banking;
- replace support/privacy/marketing/contact placeholders;
- create the exact non-consumable product and configure organization signing;
- run `make app-store-release-check` and resolve every blocker.

### Stage 1 — signed internal TestFlight, 5–15 testers

Go forward only when every P0/P1 issue is closed, purchase/restore/refund-revocation cases pass, the safe demo works,
Files/Share/widget/Siri flows work on physical devices, and App Review can reproduce the full product without credentials.

### Stage 2 — representative external beta, 20–50 testers

Recruit across all six branches, veterans with civilian careers, spouses/caregivers, federal applicants, assistive-
technology users, and varied supported devices. Exit only when at least 90% of moderated testers complete the core flow,
no confirmed unsupported claim reaches export, and the top five usability failures have owners and dispositions.

### Stage 3 — controlled U.S. launch, first 1,000 downloads

Use manual release. Watch crashes, support, refunds, conversion, review themes, and TestFlight-to-production regressions
daily for the first week. Do not buy broad ads. Fix trust and export problems before scaling discovery.

### Stage 4 — repeatable acquisition, 1,000–10,000 downloads

Use named Apple campaign links for every material channel. Build the two strongest custom product pages. Begin product-
page optimization only when traffic supports it. Publish useful veteran career education that demonstrates the workflow
without promising jobs or presenting AI as magic.

### Stage 5 — validated partnerships, 10,000–25,000 downloads

Interview and pilot with organizations only after consumer activation, retention, support cost, and privacy operations
are credible. A pilot must have a written user benefit, scope, security/privacy boundary, support limit, outcome measure,
and procurement owner before pricing is approved.

### Stage 6 — scale toward 100,000 downloads

Scale only the channels that produce retained users, trusted packets, acceptable support load, and sustainable proceeds.
Expand localization, civilian spin-off work, calculators, and promotion-packet modules only through separate evidence,
legal, content, and safety gates.

## Weekly founder review

Review one page every week after launch:

1. first-time downloads by source and campaign;
2. product-page conversion versus Apple's available peer benchmark;
3. retention/session/crash signals with Apple's opt-in limitation stated;
4. paying users, IAP units, estimated proceeds, refunds, and cumulative operating contribution;
5. beta/support completion evidence, export failures, unsupported-claim incidents, and accessibility defects;
6. the one product or channel action to take next, with an owner and date.

Do not use ratings count, time in app, AI generations, or social impressions as the primary definition of success.

## Current evidence and open questions

Evidence reviewed:

- current version 0.7.0 build 18 source, tests, release preflight, product/price decision, privacy posture, and App Review
  checklist;
- Apple's current App Store Connect Analytics, campaign-link, custom-product-page, product-page-optimization, metadata,
  privacy, TestFlight, and App Review documentation;
- scenario math in this plan, which is a model rather than measured demand.

Open decisions Jonathan must make:

1. Approve or reject `ApplyReady Vets` and `Hogue Career Systems LLC` after full clearance.
2. Confirm that the $200,000 goal means operating contribution before personal income tax.
3. Approve the company domain, monitored email, business contact information, and final legal/privacy text.
4. After beta evidence exists, decide whether privacy-preserving aggregate product telemetry is worth the disclosure and
   operating burden. Default is no.

## Official Apple sources

- App Store Connect Analytics: https://developer.apple.com/help/app-store-connect-analytics/
- Metric definitions: https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions
- Campaign links: https://developer.apple.com/help/app-store-connect-analytics/acquisition/campaign-links/
- Product page optimization: https://developer.apple.com/app-store/product-page-optimization/
- Custom product pages: https://developer.apple.com/app-store/custom-product-pages/
- TestFlight: https://developer.apple.com/testflight/
- Platform metadata: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
