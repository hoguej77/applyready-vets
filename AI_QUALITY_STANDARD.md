# ApplyReady Vets AI quality standard

Updated August 1, 2026. This is a release control, not a claim that any model is universally “the best.” ApplyReady
Vets earns trust by measuring the veteran-career tasks it actually performs.

## Required release floor

- At least **98% useful output** across 50 current straightforward, safe veteran fixtures. One miss produces exactly
  98%; two misses fail the gate.
- At least **50% bounded Apple-model yield** before the code-native local fallback. This prevents the safe fallback
  from hiding a weak generative route.
- **100%** across every safety metric: Truth Lock acceptance, exact resume-line citations, trusted local provenance,
  forbidden-claim exclusion, sensitive-content exclusion, required AI pauses, and the six-proposal limit.
- A failure blocks the AI-quality milestone. The threshold must not be lowered to make a build green.
- Re-run after any prompt, Truth Lock, model-routing, Foundation Models, Xcode, iOS, or corpus change.

## Current evaluated architecture

1. The deterministic private career engine builds the evidence ledger and a complete usable baseline.
2. A clean, single-use Apple Foundation Models session is prewarmed for the selected career mode.
3. Structured generation runs at zero randomness against bounded, relevance-ranked evidence.
4. Exact citation, sensitive-content policy, and Truth Lock screen every suggestion.
5. When generation fails its gate, one bounded repair attempt receives rejection reasons plus prevalidated exact-word
   candidate rearrangements; the structured model response must copy a candidate without adding language.
6. If both model attempts fail, a verified local repair may only reorder the candidate's exact cited words. It is
   labeled “Verified local repair,” never misrepresented as model-written text.
7. Nothing is auto-approved, auto-exported, or auto-submitted.

Truth Lock verification of AI suggestions is on by default. A person may turn pre-display verification off in
Settings to inspect evidence-linked AI wording as an **unverified draft**. Sensitive-content blocking remains on, and
employer-facing export still requires Truth Lock validation. This control cannot bypass the final safety boundary.

## Evaluation corpus

The Apple Evaluations framework runs 54 synthetic cases: 50 expected-usefulness cases across all six U.S.
armed-service branches and varied occupations, plus four explicit rejection/safety cases. Coverage includes federal
grade/eligibility, healthcare licensing, education credentials, job-ad prompt injection, clearance claims, unsupported
numbers, limiting language, and critical sensitive-data pause behavior. Synthetic data avoids using a veteran's real
resume or identity in the test record.

For this automated gate, “useful” means at least one changed, exact-cited proposal survived every native safety and
provenance check. It is not a substitute for human judgment about whether the wording is better.

On August 1, 2026, the expanded focused gate passed, followed by the complete M4 iPhone 17 Pro iOS 27 Simulator suite.
The final integrated result measured **100% hybrid usefulness** and **96% bounded Apple-model yield**; all required
safety/citation/provenance metrics were 100%. The integrated run passed 106 native tests and 4 UI/accessibility tests.
This proves the current local build; it does not replace eligible and ineligible physical-iPhone testing, expert review,
TestFlight, or App Review.

An O*NET Foundation Models tool-calling experiment was intentionally rejected during this validation pass. Direct
offline crosswalk lookup returned the correct branch-specific research, but combining a model tool with structured
resume generation reproducibly failed inside the iOS 27 beta model runtime. The launch architecture therefore keeps
the bundled O*NET crosswalk deterministic and separate from generative resume sessions. Reconsider tool calling only
after a later Xcode/iOS build passes an isolated end-to-end reliability gate; never weaken or skip evaluation outcomes
to make that experiment appear successful.

## Expansion before public claims

- Increase the corpus across branches, ranks, occupations, federal series, education levels, disabilities, languages,
  sparse resumes, long resumes, adversarial job ads, and refusal/context-limit states.
- Record supported-edit yield, rejection reason, time to first useful suggestion, completion latency, cancellation,
  memory, battery, and thermal behavior on physical devices.
- Have veteran employment, federal hiring, accessibility, privacy, OPSEC, and bias reviewers inspect fixtures and
  accepted wording.
- Publish only measurements that the final signed binary and release OS reproduce.
