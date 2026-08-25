#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

if ! bounded_simctl 20 list devices available -j >"$AUTOMATION/devices.json"; then
  echo "Simulator services are unavailable. Run doctor.command first."
  pause_if_double_clicked
  exit 2
fi

DEVICE_ID="$(/usr/bin/python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(next((x["udid"] for xs in d.get("devices",{}).values() for x in xs if x.get("isAvailable") and x.get("state") == "Booted" and x.get("name","").startswith("iPhone")), ""))' "$AUTOMATION/devices.json")"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No iPhone Simulator is booted. Run start-everything.command first."
  pause_if_double_clicked
  exit 2
fi

if ! DATA_CONTAINER="$(bounded_simctl 20 get_app_container \
  "$DEVICE_ID" com.jonathanhogue.applyreadyvets data 2>/dev/null)"; then
  echo "ApplyReady Vets is not installed on the booted Simulator."
  echo "Run start-everything.command first."
  pause_if_double_clicked
  exit 2
fi

FILES_ROOT="$DATA_CONTAINER/Documents"
mkdir -p "$FILES_ROOT/Samples" "$FILES_ROOT/Output"
open "$FILES_ROOT"

echo "Opened the live Simulator Files container:"
echo "$FILES_ROOT"
echo
echo "Files placed here appear under Browse → On My iPhone → ApplyReady Vets."
pause_if_double_clicked
