# ApplyReady Vets M4 and runtime-assistance strategy

Last reconciled: July 30, 2026.

## Decision

The M4 Mac mini is the development, build, Simulator, test, packaging, and optional local-service machine. It is not a
processor that an App Store user's iPhone can silently borrow. The shipping app must work on the iPhone by itself.

The current iOS 27 route is:

1. Run the deterministic `LocalCareerEngine` on the iPhone.
2. Build evidence, requirements, safety findings, gaps, and readiness sub-scores.
3. If the veteran enables AI, gives AI consent, no critical finding exists, and Apple's model is available, request up
   to six structured wording proposals through iOS 27 Foundation Models.
4. Revalidate every proposal against exact source evidence and Truth Lock.
5. If Apple assistance does not succeed, consider the optional service only when separate service consent is also on.
6. Keep the completed deterministic result when any optional route is unavailable, denied, cancelled, or fails.

The user can import, analyze, review, draft LinkedIn copy, and create PDF/RTF/TXT files without an AI model, network,
OpenAI key, ChatGPT account, Microsoft account, or Mac service.

## What the M4 contributes

On the owner's Mac, the automation can:

- run Xcode 27, the iOS 27 Simulator, Swift builds, XCTest, backend tests, lint, and release preflight;
- regenerate the Xcode project and clear only named generated caches through the bounded repair path;
- run the optional development FastAPI service;
- try the Mac's Apple model through the local `fm` service when the system model is available;
- use an explicitly configured server-side OpenAI key for development tests;
- package reviewed source while excluding secrets, private files, user documents, logs, and build artifacts.

That local Mac route is useful for development and a controlled pilot. It is not a production backend, an App Store
entitlement, or proof that every veteran's iPhone has Apple Intelligence.

## iPhone Foundation Models

The source targets iOS 27 and uses:

- runtime `SystemLanguageModel` availability rather than a device-name assumption;
- an iOS 27 Dynamic Profile with bounded response tokens and low-temperature sampling;
- a versioned career-mode prompt that treats resume/job content as untrusted data;
- relevance-ranked evidence fitted to the live model context through exact token counting;
- a structured `@Generable` response capped at six proposals;
- exact cited resume text and native Truth Lock before display.

iOS 27 installation and a modern chip do not by themselves guarantee the model is available. Device eligibility,
Apple Intelligence settings, language, region, model download/readiness, and OS/model updates can change behavior.
Physical-device availability, quality, latency, context, refusal, cancellation, memory, battery, and thermal tests
remain release gates.

## Optional service and OpenAI

The development backend can prefer the Mac Apple model and can use OpenAI through the server-side Responses API when an
owner-supplied key is configured. Its OpenAI route uses typed structured output, `store=False`, bounded timeout/retry
and output tokens, a circuit breaker, and local Truth Lock on accepted proposals.

Rules:

- Never place an OpenAI key in Swift, Xcode settings, the app bundle, screenshots, logs, or support messages.
- Do not link or scrape a user's ChatGPT session.
- Do not claim that a ChatGPT Pro subscription pays for API use; ChatGPT subscriptions and API billing are separate
  products.
- Release ships with no optional-service endpoint, so neither the Mac service nor OpenAI is active in the current
  Release configuration.
- A future public service requires HTTPS, real user identity/authorization, quotas, abuse/cost controls, provider and
  host disclosures, retention/deletion operations, minimal-content monitoring, incident response, and evaluation.

Official OpenAI references:

- [Responses API](https://developers.openai.com/api/reference/responses/overview)
- [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
- [Data controls](https://developers.openai.com/api/docs/guides/your-data)

## ChatGPT, Copilot, Siri, and Codex boundaries

- **Codex/Xcode assistance** helps develop and test source. It is not shipped inside the app.
- **ChatGPT** can be a separate user copy/paste destination or a future supported integration, but the current app does
  not connect to a user's ChatGPT account.
- **Microsoft Copilot** remains roadmap only until a specific supported Entra/OAuth/API design, permissions, school
  tenant rules, privacy review, and user value are established.
- **Siri/Shortcuts** use App Intents to open safe workflow destinations or save a user-supplied URL. They do not expose
  private resume, military, disability, clearance, or evidence content in spoken responses.

## Development configuration

The optional Mac service uses:

```dotenv
HOGUE_AI_PROVIDER=auto
OPENAI_API_KEY=
HOGUE_OPENAI_MODEL=gpt-5.6-sol
```

`auto` tries the Mac Apple model, then an explicitly configured OpenAI provider, then deterministic service behavior.
This is separate from the app's direct on-iPhone Foundation Models route.

Run `scripts/doctor.command` to inspect the development machine and provider route without printing a secret.

## Product language

Do not market ApplyReady Vets as “powered by Siri,” “self-healing AI,” or an autonomous job applicant. Appropriate
language is:

> ApplyReady Vets works privately without generative AI. On supported devices, optional Apple on-device assistance can
> suggest evidence-linked wording that the veteran reviews.
