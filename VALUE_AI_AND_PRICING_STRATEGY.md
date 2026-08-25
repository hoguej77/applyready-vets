# ApplyReady Vets value, assistance, and $5.99 strategy

Last reviewed: July 30, 2026

## The decision

- Free download and one complete application workspace from import through export.
- **ApplyReady Vets Complete: $5.99 once** in the U.S. storefront for unlimited tracked workspaces.
- Complete is the only consumer purchase.
- No subscription, trial conversion, tip ladder, ads, AI credits, export fee, or feature packs.
- Organization licensing and sponsored access are the separate business channel.

At $5.99, the app is priced at roughly one week of several resume subscriptions. Current visible U.S. App Store
examples include:

| Product | Visible purchase examples | ApplyReady Vets position |
| --- | --- | --- |
| [Resume Builder+](https://apps.apple.com/us/app/resume-builder/id1047522998) | $4.99–$6.99 weekly; $9.99 monthly; $19.99 semester | Complete lifetime costs about one week |
| [Kickresume](https://apps.apple.com/us/app/kickresume-ai-resume-builder/id1523618695) | $9.95 monthly; $24.95 yearly; $27.99 proofreading | Complete is below one month |
| [Resume Star](https://apps.apple.com/us/app/resume-star-pro-cv-maker/id730643547) | $7.99, $14.99, and $34.99 optional one-time payments | Complete is lower than its smallest visible payment |
| [Resume Builder Pro with AI](https://apps.apple.com/us/app/resume-builder-pro-with-ai/id1457411537) | Visible products from $5.99 through $29.99 | Complete uses one product instead of a ladder |
| [AI Resume Builder, CV Maker](https://apps.apple.com/us/app/ai-resume-builder-cv-maker/id6749149043) | $4.99 weekly; $12.99 monthly; $39.99 yearly; $59.99 lifetime | Complete lifetime is about one tenth of its visible lifetime price |

Prices and availability can change. App Store Connect must display Apple's localized price before a purchase; marketing
copy should say “$5.99 in the U.S. storefront” rather than imply every country uses U.S. dollars.

## Why not simply use ChatGPT or Gemini?

ChatGPT and Gemini are capable general-purpose assistants. ChatGPT Projects can keep chats, files, and custom
instructions together, and Gemini can upload/analyze files and perform source-backed Deep Research. ApplyReady Vets
must not pretend its underlying model is inherently smarter than those products.

Official capability references:

- [ChatGPT Projects](https://help.openai.com/en/articles/10169521-projects-in-chatgpt)
- [ChatGPT file storage and Library](https://help.openai.com/en/articles/20001052-library)
- [Gemini file upload and analysis](https://support.google.com/gemini/answer/14903178)
- [Gemini Deep Research](https://support.google.com/gemini/answer/15719111)

The product earns its price through a purpose-built workflow that a blank chat does not automatically provide:

1. **A veteran application is the durable object.** The job link, posting, resume, status, deadline, notes, required
   documents, approved wording, and packet versions remain together.
2. **Evidence is separate from generated wording.** Each proposed material change must cite candidate evidence.
3. **Truth Lock is enforced in code.** Unsupported numbers, copied target titles, missing citations, sensitive content,
   dropped qualifiers, and unapproved edits can be rejected after generation rather than trusted because a prompt asked
   nicely.
4. **Military context is built in.** The offline O*NET crosswalk covers all six branches and is labeled as occupational
   context—not proof that a veteran has a civilian credential.
5. **Civilian and federal paths stay distinct.** Federal checks use dated USAJOBS requirements and individual readiness
   findings instead of a fake universal “ATS score.”
6. **External sites use honest handoffs.** The app stores and opens LinkedIn, Indeed, Workday, USAJOBS, JOFDAV, and
   employer links and prepares candidate-reviewed copy without collecting passwords, scraping, or pretending to submit.
7. **The private core works without an account or model.** Local rules, safety checks, review, protected Files output,
   and the tracker remain useful if assistance is unavailable or declined.
8. **It behaves like an iPhone app.** Files import/export, Share Extension input, Siri/Shortcuts entry points, protected
   storage, accessibility, native navigation, and StoreKit are part of the workflow.

The plain-language promise is:

> A chatbot can draft text. ApplyReady Vets helps a veteran build, verify, organize, and finish the application.

## Assistance architecture

Assistance is infrastructure, not the brand:

1. Private deterministic analysis always runs.
2. On eligible devices, explicitly enabled Apple on-device assistance can propose wording.
3. An explicitly consented service can be a bounded fallback when configured.
4. Every proposal is treated as untrusted and must pass the native evidence and safety validators.
5. The candidate approves, edits, or rejects every material change.

The service prompt is versioned and organized around outcome, success criteria, a prompt-injection trust boundary,
Truth Lock invariants, structured output, and explicit stop conditions. This follows current OpenAI guidance to specify
the goal, constraints, tool/data boundaries, output contract, and stopping behavior:

- [OpenAI GPT-5.6 Sol migration guide](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
- [OpenAI GPT-5.6 prompt guidance](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)

The optional backend defaults to `gpt-5.6-sol` for its high-quality fallback role. This was not validated with a live
paid API request in this pass. Model selection remains server-side and must be evaluated with de-identified fixtures
before a production service is enabled.

## Lifetime-price economics

Assuming enrollment in Apple's Small Business Program and a 15% commission, a $5.99 purchase yields about $5.09 before
refunds, tax effects, support, marketing, hosting, and other costs.

| Complete purchases | Customer spend | Estimated proceeds after 15% Apple commission |
| ---: | ---: | ---: |
| 10,000 | $59,900 | $50,915 |
| 20,000 | $119,800 | $101,830 |
| 30,000 | $179,700 | $152,745 |
| 40,000 | $239,600 | $203,660 |
| 50,000 | $299,500 | $254,575 |

The $5.99 price cannot responsibly include unlimited paid cloud generations forever. The purchased offline and
on-device features must remain unlimited, but production cloud assistance needs one of these sustainable arrangements:

- organization-funded access for sponsored cohorts;
- a measured operating allowance funded by organization revenue;
- user-controlled processing through a future supported provider arrangement;
- or no hosted fallback until its retention, privacy, abuse, and per-completed-packet costs are proven.

Do not add hidden credits after selling “everything included.” If economics later require a different cloud service,
change the offer prospectively and clearly without removing purchased local features.

## Beginner command center

The project has one safe command surface:

```zsh
./scripts/applyready.command help
```

It routes `check`, `run`, `files`, `test`, `test-live`, `release`, `repair`, `build`, `package`, `xcode`, and `stop` to
the reviewed automation. Double-clicking `scripts/applyready.command` presents the common choices in plain language.
The repair action only clears allowlisted generated caches, regenerates the project, and retests; it does not rewrite
source code or user documents.

