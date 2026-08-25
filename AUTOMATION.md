# Local M4 automation

Everything in this file runs on this Mac. Codex created the application source and uses the locally installed Xcode, iOS SDK, Swift compiler, Python, and Apple Silicon processor.

## Easiest path

Open the `scripts` folder in Finder and double-click:

1. `doctor.command` — verifies Xcode, Simulator services, Python, XcodeGen, the Apple on-device model, and the configured AI route.
2. `setup.command` — creates the Python environment, installs dependencies, creates `.env`, generates the Xcode project, and performs an unsigned iPhone build.
3. `start-everything.command` — starts the backend, boots the first available iPhone Simulator, builds, installs, and launches ApplyReady Vets.
4. `test-all.command` — runs backend tests/lint plus app and XCTest compilation.
5. `test-simulator.command` — boots an available iPhone and executes the live XCTest suite.
6. `stop-backend.command` — stops the background development service.
7. `check-source-policy.command` — rejects private settings, user documents, credentials, logs, caches, unsafe ZIP paths, and build products from a staged source directory or ZIP.
8. `package-source.command` — stages a clean source tree, creates and verifies a per-file SHA-256 manifest, scans the staged tree and ZIP, and publishes the ZIP plus its archive checksum only after every check passes.
9. `release-preflight.command` — uses an explicit `--release-candidate`, `--app-store`, `--beta`, or `--self-test` mode. The default
   release-candidate mode verifies identity/version parity, App Group and privacy declarations, an empty Release service
   endpoint, an enabled one-product Release storefront, StoreKit identifiers/catalog isolation, App Intents, and
   accessibility-audit registration. Beta mode instead requires the Release storefront to be off. Self-test exercises
   the bounded project-setting parser with normal, mismatched, duplicate, and 25,000-line fixtures.
10. `quality-gate.command` — runs shell syntax validation, packaging-policy tests, backend tests/lint, iOS test compilation, Swift core tests, an unsigned Release build, and the local release preflight.
11. `repair-and-validate.command` — performs at most one allowlisted generated-cache cleanup and one retry. It never edits source, private settings, drafts, or user documents.
12. `link-xcode-beta.command` — switches the Mac's global command-line Xcode path to `/Applications/Xcode-beta.app` when Apple tooling says the selected Xcode is unsupported.

The same tasks work from Terminal:

```bash
cd "/Users/jonathanhogue/Documents/Codex/2026-07-13/files-mentioned-by-the-user-hogueresmaster/outputs/HogueResMasterApp"
make doctor
make setup
make test
make test-live
make source-policy
make preflight
make app-store-preflight
make quality
make repair
make start
make package
```

Build caches and logs stay inside this project under `.automation/` and `logs/`. They are listed in `.gitignore` and are independently excluded and rejected by the source-package policy.

## Safe packaging and local quality gates

`package-source.command` does not copy the live tree directly into a shareable ZIP. It first copies into a temporary staging directory with explicit exclusions for:

- `.env` files other than the empty `.env.example` template;
- `tmp`, logs, uploads, attachments, downloads, exports, and private-data directories;
- PDF, Word, PowerPoint, spreadsheet, archive, key, certificate, provisioning, and database files;
- Python, Swift Package, Xcode, test, cache, and local-user build artifacts.

The standalone policy checker then scans every staged path and text file for forbidden paths, populated credential assignments, strong secret formats, unexpected binaries, traversal paths, symlinks, oversized files, and archive expansion risk. The package includes `SOURCE_MANIFEST.sha256`, which records every included source file. The finished ZIP is scanned again and receives a separate `.zip.sha256` checksum beside it. Any failed check stops publication.

Run the policy without creating a published ZIP:

```bash
make source-policy
```

Run the bounded local release-quality gate:

```bash
make quality
```

Run only the fast source-controlled release contract check:

```bash
make preflight
# equivalent:
./scripts/release-preflight.command --release-candidate
```

After the paid Apple team and public URLs are configured, run the stricter submission check:

```bash
make app-store-preflight
```

To verify a deliberately disabled Release storefront instead, run:

```bash
./scripts/release-preflight.command --beta
```

Passing either mode means only that source matches the selected local contract. It does not mean the app is signed,
uploaded, purchasable, legally approved, or ready for public release. The command prints those founder-controlled gates
separately. `make quality`, `make preflight`, and the command center's `release` action currently select
`--release-candidate`.

Live Simulator execution is intentionally optional because Simulator availability can change independently of source quality:

```bash
HOGUE_QUALITY_RUN_SIMULATOR=1 make quality
```

If generated caches or the generated Xcode project become stale, run:

```bash
make repair
```

The repair path is capped at two total validation attempts. Its only repair pass clears four named generated-build locations and regenerates `ios/ApplyReadyVets.xcodeproj` from `ios/project.yml`. Missing project-local Python development tools may be installed into `backend/.venv`. It does not modify application code or delete `.env`, drafts, research, documents, exports, or other user files. A code, test, privacy, or packaging-policy failure remains failed for human review.

## Current machine status

Xcode 27 beta 4 (build 27A5228h) is installed at `/Applications/Xcode-beta.app` on this M4 Mac running macOS 27 beta 4. The iOS 27 beta 4 platform and Simulator runtime are installed. A real unsigned arm64 iPhone build completed successfully with the iOS 27 SDK.

Xcode 27 uses signed Swift macro services for SwiftUI state and observation. Those services require the normal macOS user context. The automation detects Xcode 27 or newer and uses that mode automatically; older Xcode versions retain project-local compatibility caches.

The automation prefers `/Applications/Xcode-beta.app` and falls back to `/Applications/Xcode.app`. Do not weaken Gatekeeper, remove quarantine attributes, or ad-hoc sign Xcode.

If `xcode-select -p` still reports `/Library/Developer/CommandLineTools`, double-click `scripts/link-xcode-beta.command` or run:

```bash
sudo xcode-select --switch /Applications/Xcode-beta.app/Contents/Developer
sudo /Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild -runFirstLaunch
```

## AI automation

`backend/.env` controls routing:

```dotenv
HOGUE_AI_PROVIDER=auto
```

- `auto`: Apple on-device model first, optional OpenAI fallback second.
- `apple`: local Apple system model only.
- `openai`: OpenAI only; requires a server-side key.

All three modes retain deterministic analysis and Truth Lock. `doctor.command` reports availability without printing any secret. Double-clicking the launchers runs the backend from the Mac's normal application context, which is required by the beta Apple Foundation Models command-line service.
