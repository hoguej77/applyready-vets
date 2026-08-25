#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

CORE_PACKAGE="$IOS/Packages/ApplyReadyVetsCore"
RUN_SIMULATOR="${HOGUE_QUALITY_RUN_SIMULATOR:-0}"

if [[ "$RUN_SIMULATOR" != "0" && "$RUN_SIMULATOR" != "1" ]]; then
  echo "HOGUE_QUALITY_RUN_SIMULATOR must be 0 or 1."
  exit 2
fi
if [[ ! -x "$BACKEND/.venv/bin/pytest" || ! -x "$BACKEND/.venv/bin/ruff" ]]; then
  echo "Backend development tools are missing."
  echo "Run scripts/repair-and-validate.command for a bounded local repair, or run setup.command."
  exit 2
fi

echo "Quality gate 1/7: shell syntax"
while IFS= read -r -d '' script; do
  /bin/zsh -n "$script"
done < <(
  /usr/bin/find "$SCRIPT_DIR" -type f \( -name '*.command' -o -name '*.sh' \) -print0
)
HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/release-preflight.command" --self-test

echo "Quality gate 2/7: source-package policy"
HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/check-source-policy.command" --self-test
HOGUE_NO_PAUSE=1 HOGUE_PACKAGE_VALIDATE_ONLY=1 "$SCRIPT_DIR/package-source.command"

echo "Quality gate 3/7: backend tests, lint, and iOS test compilation"
HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/test-all.command"

echo "Quality gate 4/7: standalone Swift core tests"
rm -rf "$AUTOMATION/QualitySwiftPackage"
/usr/bin/xcrun swift test \
  --package-path "$CORE_PACKAGE" \
  --scratch-path "$AUTOMATION/QualitySwiftPackage" \
  2>&1 | tee "$LOGS/quality-swift-package.log"

echo "Quality gate 5/7: unsigned Release build"
(cd "$IOS" && xcodegen generate)
rm -rf "$AUTOMATION/QualityReleaseDerivedData"
isolated_xcodebuild \
  -project "$IOS/ApplyReadyVets.xcodeproj" \
  -scheme ApplyReadyVets \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$AUTOMATION/QualityReleaseDerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee "$LOGS/quality-ios-release.log"

echo "Quality gate 6/7: local release preflight"
HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/release-preflight.command" --release-candidate

echo "Quality gate 7/7: optional live Simulator tests"
if [[ "$RUN_SIMULATOR" == "1" ]]; then
  HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/test-simulator.command"
else
  echo "Skipped by default. Set HOGUE_QUALITY_RUN_SIMULATOR=1 to include the live suite."
fi

echo
echo "PASS: bounded local quality gate completed."
pause_if_double_clicked
