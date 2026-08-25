# AI, device, and provider strategy

Last updated: August 1, 2026

## Decision

The current iOS 27 source implements a local-first capability ladder:

1. **Private LocalCareerEngine** — the required baseline, available after install without a model, account, or network.
   It builds the evidence ledger, analyzes the job, identifies gaps and safety concerns, calculates explainable readiness
   estimates, drafts conservative translations, runs Truth Lock, builds the LinkedIn kit, and supports local export.
2. **Apple Foundation Models on the iPhone** — the preferred optional writing enhancement on an eligible iOS 27 device.
   It runs only after the local baseline, explicit AI consent, runtime availability, and the critical-safety gate.
3. **Optional service fallback** — used for AI only when on-device assistance is unavailable and both AI consent and
   separate service consent are on. The development service can prefer Apple Foundation Models on the M4 Mac and can use
   a server-side OpenAI provider when configured.

Microsoft Copilot should be a later integration, not a launch blocker.

## iOS compatibility

The founder selected a current-generation-only App Store posture:

- Minimum app target: iOS 27 for the app, Share extension, widget, and tests.
- Private core experience: every supported iOS 27 device; it does not require Apple Intelligence or a configured service.
- Best optional writing-assistance experience: iOS 27 with Apple Intelligence available at runtime.
- Optional service fallback: separately configured, separately consented, and never required for the core workflow.
- Direct on-device Foundation Models: runtime-gated; do not assume availability.

iOS 27 installation still does not guarantee Apple Intelligence availability on every device, language, or region.
Foundation Models availability is checked at runtime.

Official Apple sources:

- Foundation Models framework: <https://developer.apple.com/documentation/foundationmodels>
- Generating content with Foundation Models: <https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models>
- Apple Intelligence developer overview: <https://developer.apple.com/apple-intelligence/>
- What’s new in iOS: <https://developer.apple.com/ios/whats-new/>
- Foundation Models updates: <https://developer.apple.com/documentation/Updates/FoundationModels>
- How to get Apple Intelligence: <https://support.apple.com/en-us/121115>

## Provider routing

Current route:

```text
Resume/job/profile
  → private LocalCareerEngine baseline
  → evidence ledger + privacy/OPSEC/job-risk scan + deterministic proposals
  → native Truth Lock
  → if AI enabled and AI consented, with no critical finding:
       Apple on-device model when available
       otherwise optional service only with separate service consent
  → one clean prewarmed Apple session with zero-randomness structured output
  → native Truth Lock on Apple-device proposals; one bounded model repair after rejection
  → exact-word local repair only if both model attempts fail, with honest local provenance
  → optional-service response may add only bounded pending proposals that pass exact local-evidence and native Truth Lock checks
  → keep the private baseline if enhancement fails
  → user approval
  → local LinkedIn drafting or local verified-resume export
```

AI output is never treated as the source of truth. The supplied veteran evidence, Truth Lock checks, and veteran approval
remain the controlling layers.

The current build checks `SystemLanguageModel.default.availability` and distinguishes an available model from Apple Intelligence
being disabled, the model not being ready, an ineligible device, or an unknown state. On eligible devices,
an iOS 27 Dynamic Profile specifies the system model, sampling temperature, and response limit. The prompt is fitted to
the live context with exact token counting, and `LanguageModelSession.respond` returns a structured `@Generable`
envelope capped at six proposals. Each proposal must cite
supplied evidence, use original text found in the source resume, avoid unsupported numbers and sensitive content, and pass
native Truth Lock before normal display. When the optional unverified-draft view is selected, exact citation and
sensitive-content gates still run before display, and full Truth Lock is required before approval/export. The current
source also requires at least one cited resume evidence item to equal the proposal's claimed original text.

The Apple Evaluations framework now runs 54 synthetic veteran scenarios, including 50 expected-usefulness cases across
all six branches and varied occupations. Release requires at least 98% hybrid usefulness, at least 50% bounded
Apple-model yield before local fallback, and 100% for citation, Truth Lock, provenance, forbidden-claim,
sensitive-data, safety-pause, and proposal-limit metrics. The final August 1 M4 Simulator run measured 100% hybrid
usefulness and 96% bounded model yield. See [AI_QUALITY_STANDARD.md](AI_QUALITY_STANDARD.md).

The launch session deliberately disables model tool calling. An August 1 experiment registered the bundled O*NET
crosswalk as an exact branch/code research tool; the lookup itself passed, but tool use combined with structured resume
generation triggered a reproducible iOS 27 beta inference failure. O*NET remains an offline code-native feature until a
later Apple runtime passes an isolated tool-plus-structured-output reliability gate.

Truth Lock verification of AI suggestions is a persistent setting and defaults on. Turning it off exposes exact-cited
wording only as an unverified draft. Critical sensitive content remains blocked, and candidate approval/export still
must pass Truth Lock. The setting changes visibility and exploration, not the employer-facing safety boundary.

The iPhone is now a standalone **private rules** analysis engine. Foundation Models improve wording but are not required
to analyze, review, draft LinkedIn copy, or export. Physical-device quality, latency, context-limit, refusal, thermal,
language/region, model-update, and fallback tests still gate claims about the optional generative experience.

## Consent and failure rules

- The private baseline runs without AI consent.
- Enabling AI is not consent by itself; the separate AI consent must also be on.
- Service fallback additionally requires service consent. Unsupported file conversion uses that same service consent.
- A critical sensitive-information finding pauses all generative assistance.
- Apple-device or service failure never discards the completed local baseline.
- The service never replaces the local evidence, safety findings, job analysis, gaps, or readiness scores. Its accepted
  contribution is limited to locally revalidated pending wording proposals.
- Saving a job link and pasting job text stay local. User-invoked page retrieval uses the configured service only after
  separate service consent; without it, the link remains saved and the app requests paste or permission.
- No provider approves a proposal or submits an application for the veteran.

## OpenAI rules

OpenAI keys must stay on the backend. Do not store them in Swift, the app bundle, screenshots, Xcode project files, or
client-side settings.

The development backend uses the OpenAI Responses API with a typed structured-output schema, `store=False`, bounded
output tokens, bounded retry/timeout settings, and a circuit breaker. Include a privacy-preserving safety identifier for
signed-in users or sessions when appropriate. Redact direct personal contact information and sensitive patterns before
cloud AI use. A public OpenAI-backed service also requires published provider/host retention terms, deletion controls,
per-user authorization, rate limits, cost controls, and production evaluation. The Release
configuration contains no service endpoint, so OpenAI is disabled unless a later reviewed release deliberately
configures a production service.

Official OpenAI sources:

- Responses API: <https://developers.openai.com/api/reference/responses/overview>
- Structured Outputs: <https://developers.openai.com/api/docs/guides/structured-outputs>
- Data controls: <https://developers.openai.com/api/docs/guides/your-data>
- Safety identifiers: <https://developers.openai.com/api/docs/guides/safety-best-practices#implement-safety-identifiers>

## ChatGPT account linking

Do not promise that a user can “link their ChatGPT account” to power the app unless OpenAI provides a supported account
linking or app integration path for this exact use case.

Safe launch approach:

- Launch the private core without requiring a ChatGPT account.
- If cloud AI is later enabled, use the product owner's backend/OpenAI API project rather than a user's ChatGPT password.
- Give users clear consent, privacy, and deletion controls.
- Optionally create a future ChatGPT app or companion workflow after the mobile app is stable.

## Microsoft Copilot account linking

Do not scrape or automate Copilot. A student Copilot integration would need a separate Microsoft identity and compliance
design:

- Microsoft Entra ID / OAuth.
- Microsoft Graph permissions, if any school data is used.
- Tenant/admin consent requirements.
- Clear boundaries for student, school, and personal accounts.
- Microsoft terms review.

For launch, document Copilot as roadmap only. Users can manually copy ApplyReady Vets outputs into Microsoft tools.

## Siri / Shortcuts / Apple Intelligence

The app should use Apple Intelligence where the SDK permits it, but the app should not be positioned as “powered by
Siri.” Practical first-party Apple integration path:

- App Shortcuts for “Create job packet,” “Open last packet,” and “Check application readiness.”
- Direct Foundation Models provider only on supported OS/device/runtime.
- Fallback to the deterministic private core first; use the optional service only with the additional consent.

Siri and Shortcuts should open private workflow destinations or accept a user-supplied job URL. They should not speak
resume evidence, military-service details, disability information, or other sensitive content. Apple's
[App Intents](https://developer.apple.com/documentation/appintents/app-intents) are the supported integration surface;
the app should not be marketed as “powered by Siri.”

## Endpoint posture

- Debug defaults to the owner's local development service at `http://127.0.0.1:8000`.
- Release ships with an empty service URL; the developer connection editor is excluded from Release.
- The capability registry classifies not-configured, local/private-network development, secure HTTPS, and
  insecure/invalid remote endpoints.
- `APIClient` enforces that classification: Release accepts only secure HTTPS, while Debug may also use a
  local/private-network development address.

The former localhost blocker no longer applies to the core app: the current source performs supported import, analysis,
Truth Lock review, LinkedIn drafting, and PDF/RTF/TXT export locally.

## What to build next

1. Validate direct structured `LanguageModelSession` proposals on physical eligible iPhones:
   - model unavailable/disabled/downloading and ineligible-device states;
   - context limits, refusals, cancellation, interrupted work, and low-power/thermal behavior;
   - supported languages, regions, iOS point releases, and model changes;
   - duplicate, unsupported-number, sensitive-content, and prompt-injection fixtures.
2. Keep Release service-free until production identity, authorization, retention, deletion, rate limiting, monitoring,
   provider disclosures, and incident controls exist. Add outbound-path integration tests before enabling it.
3. Expand the current Evaluations/Truth Lock adversarial corpus and have veteran/OPSEC/career experts review the
   evidence, metrics, and edit rules.
4. App Store metadata warning:
   - “AI features vary by device, OS, region, language, and configured service.”
5. Add OCR fixture coverage, extend the URL/text Share Extension to safe user-selected files, and complete EventKit and
   local-notification milestones documented in
   [VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md](VETERAN_WORKFORCE_AND_INTEGRATION_GAP_AUDIT.md).
