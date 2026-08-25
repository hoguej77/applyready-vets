#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

if [[ ! -x "$BACKEND/.venv/bin/pytest" ]]; then
  HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/setup.command"
fi

echo "Running backend tests…"
# The test server is treated as a non-loopback caller. Give it an ephemeral,
# non-production bearer token so the tests exercise authentication without
# depending on a developer's local .env file or any real credential.
TEST_API_TOKEN="applyreadyvets-test-$(/usr/bin/uuidgen)"
(cd "$BACKEND" && \
  HOGUE_ENVIRONMENT=test \
  HOGUE_API_TOKEN="${TEST_API_TOKEN}" \
  HOGUE_TEST_API_TOKEN="${TEST_API_TOKEN}" \
  .venv/bin/pytest -q && \
  .venv/bin/ruff check app tests)

echo "Generating and compiling iOS app + XCTest target…"
(cd "$IOS" && xcodegen generate)
isolated_xcodebuild \
  -project "$IOS/ApplyReadyVets.xcodeproj" \
  -scheme ApplyReadyVets \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$AUTOMATION/TestDerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing | tee "$LOGS/ios-tests-build.log"

echo
echo "All non-Simulator checks passed."
if bounded_simctl 20 list devices available >/dev/null 2>&1; then
  echo "Simulator service is ready; start-everything.command can run the app."
else
  echo "Simulator execution is unavailable; confirm the iOS runtime in Xcode Settings → Components."
fi
pause_if_double_clicked
