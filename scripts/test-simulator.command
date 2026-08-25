#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

if ! bounded_simctl 20 list devices available -j >"$AUTOMATION/devices.json" 2>"$LOGS/simulator-tests.log"; then
  echo "Simulator services are unavailable. Run doctor.command first."
  pause_if_double_clicked
  exit 2
fi

DEVICE_ID="$(/usr/bin/python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(next((x["udid"] for xs in d.get("devices",{}).values() for x in xs if x.get("isAvailable") and x.get("name","").startswith("iPhone")), ""))' "$AUTOMATION/devices.json")"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No iPhone Simulator is installed. Open Xcode Settings → Components and install the iOS runtime."
  pause_if_double_clicked
  exit 2
fi

# Xcode 27 beta can leave its simulated StoreKit storefront open after a test
# session, causing the next SKTestSession to return an empty catalog. Reboot the
# selected Simulator before each complete run. This preserves app data while
# resetting the beta system services that app termination alone cannot clear.
DEVICE_STATE="$(
  bounded_simctl 20 list devices -j \
    | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); u=sys.argv[1]; print(next((x.get("state", "") for xs in d.get("devices", {}).values() for x in xs if x.get("udid") == u), ""))' "$DEVICE_ID"
)"
if [[ "$DEVICE_STATE" == "Booted" ]]; then
  bounded_simctl 30 reboot "$DEVICE_ID"
else
  bounded_simctl 30 boot "$DEVICE_ID"
fi

SIMULATOR_READY=0
for attempt in {1..60}; do
  DEVICE_STATE="$(
    bounded_simctl 20 list devices -j \
      | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); u=sys.argv[1]; print(next((x.get("state", "") for xs in d.get("devices", {}).values() for x in xs if x.get("udid") == u), ""))' "$DEVICE_ID"
  )"
  if [[ "$DEVICE_STATE" == "Booted" ]] \
    && bounded_simctl 10 spawn "$DEVICE_ID" launchctl print system >/dev/null 2>&1; then
    SIMULATOR_READY=1
    break
  fi
  sleep 1
done
if [[ "$SIMULATOR_READY" != "1" ]]; then
  echo "The selected iPhone Simulator did not become ready within 60 seconds."
  pause_if_double_clicked
  exit 2
fi

# Stop both app shells after the reboot so no stale foreground process can
# interfere with the StoreKit session or the UI-test launch contract.
bounded_simctl 15 terminate \
  "$DEVICE_ID" com.jonathanhogue.applyreadyvets \
  >/dev/null 2>&1 || true
bounded_simctl 15 terminate \
  "$DEVICE_ID" com.jonathogue.applyreadyvets.uitests.xctrunner \
  >/dev/null 2>&1 || true
bounded_simctl 15 uninstall \
  "$DEVICE_ID" com.jonathanhogue.applyreadyvets.uitests.xctrunner \
  >/dev/null 2>&1 || true

# Xcode installs its UI-test runner as a separate Home Screen app. Always remove
# that shell, including after a failed run, so it cannot be mistaken for a
# second ApplyReady Vets product.
function clean_up_test_runner() {
  bounded_simctl 15 uninstall \
    "$DEVICE_ID" com.jonathanhogue.applyreadyvets.uitests.xctrunner \
    >/dev/null 2>&1 || true
}
trap clean_up_test_runner EXIT

(cd "$IOS" && xcodegen generate)
set -o pipefail
isolated_xcodebuild \
  -project "$IOS/ApplyReadyVets.xcodeproj" \
  -scheme ApplyReadyVets \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$AUTOMATION/SimulatorTestDerivedData" \
  test | tee "$LOGS/ios-simulator-tests.log"

# Leave the real app open after a green run for manual inspection.
clean_up_test_runner
bounded_simctl 20 launch \
  "$DEVICE_ID" com.jonathanhogue.applyreadyvets \
  >/dev/null 2>&1 || true

open_simulator_ui
echo
echo "Live iPhone Simulator tests passed."
pause_if_double_clicked
