#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/start-backend-background.command"

if ! bounded_simctl 20 list devices available -j >"$AUTOMATION/devices.json" 2>"$LOGS/simulator.log"; then
  echo
  echo "The app and backend are built, but Apple Simulator services are not ready."
  echo "Run doctor.command, then open Xcode Settings → Components and confirm the iOS 27 Simulator is installed."
  pause_if_double_clicked
  exit 2
fi

DEVICE_ID="$(/usr/bin/python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(next((x["udid"] for xs in d.get("devices",{}).values() for x in xs if x.get("isAvailable") and x.get("name","").startswith("iPhone")), ""))' "$AUTOMATION/devices.json")"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No iPhone Simulator is installed. In Xcode, open Settings → Components and install an iOS Simulator runtime."
  pause_if_double_clicked
  exit 2
fi

bounded_simctl 30 boot "$DEVICE_ID" >/dev/null 2>&1 || true
bounded_simctl 120 bootstatus "$DEVICE_ID" -b
open_simulator_ui

(cd "$IOS" && xcodegen generate)
isolated_xcodebuild \
  -project "$IOS/ApplyReadyVets.xcodeproj" \
  -scheme ApplyReadyVets \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$AUTOMATION/SimulatorDerivedData" \
  build | tee "$LOGS/ios-simulator-build.log"

APP="$AUTOMATION/SimulatorDerivedData/Build/Products/Debug-iphonesimulator/ApplyReadyVets.app"
bounded_simctl 60 install "$DEVICE_ID" "$APP"
bounded_simctl 20 launch "$DEVICE_ID" com.jonathanhogue.applyreadyvets

DATA_CONTAINER="$(bounded_simctl 20 get_app_container \
  "$DEVICE_ID" com.jonathanhogue.applyreadyvets data)"
FILES_ROOT="$DATA_CONTAINER/Documents"
SAMPLES="$FILES_ROOT/Samples"
OUTPUT="$FILES_ROOT/Output"

for _ in {1..20}; do
  if [[ -f "$SAMPLES/Sample Veteran Resume.txt" &&
        -f "$SAMPLES/Sample Job Posting.txt" &&
        -d "$OUTPUT" ]]; then
    break
  fi
  sleep 0.5
done

if [[ ! -f "$SAMPLES/Sample Veteran Resume.txt" ||
      ! -f "$SAMPLES/Sample Job Posting.txt" ||
      ! -d "$OUTPUT" ]]; then
  echo
  echo "The app launched, but its Files test workspace was not created."
  echo "Check $LOGS/ios-simulator-build.log and rerun this command."
  pause_if_double_clicked
  exit 2
fi

open "$FILES_ROOT"

echo
echo "ApplyReady Vets is running on the installed iOS Simulator."
echo "Verified Files inputs:"
echo "  $SAMPLES/Sample Veteran Resume.txt"
echo "  $SAMPLES/Sample Job Posting.txt"
echo "Verified Files output folder:"
echo "  $OUTPUT"
echo
echo "In the app choose a file, then Browse → On My iPhone → ApplyReady Vets → Samples."
echo "After export, use Files → Browse → On My iPhone → ApplyReady Vets → Output."
echo "Finder also opened the Simulator's live Documents container for adding your own test files."
pause_if_double_clicked
