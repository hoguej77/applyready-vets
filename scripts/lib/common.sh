#!/bin/zsh

set -euo pipefail

COMMON_FILE="${(%):-%N}"
SCRIPT_DIR="$(cd "$(dirname "$COMMON_FILE")/.." && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS="$ROOT/ios"
BACKEND="$ROOT/backend"
AUTOMATION="$ROOT/.automation"
LOGS="$ROOT/logs"
if [[ -z "${XCODE_APP:-}" ]]; then
  if [[ -d "/Applications/Xcode-beta.app" ]]; then
    XCODE_APP="/Applications/Xcode-beta.app"
  else
    XCODE_APP="/Applications/Xcode.app"
  fi
fi

if [[ ! -d "$XCODE_APP" ]]; then
  echo "Xcode was not found at $XCODE_APP"
  echo "Install a version of Xcode supported by this macOS release, then run this again."
  exit 1
fi

export DEVELOPER_DIR="$XCODE_APP/Contents/Developer"
mkdir -p "$AUTOMATION/home/Library/Caches" "$AUTOMATION/DerivedData" "$AUTOMATION/ModuleCache" "$LOGS"

function xcode_major_version() {
  "$DEVELOPER_DIR/usr/bin/xcodebuild" -version 2>/dev/null \
    | sed -n '1s/^Xcode \([0-9][0-9]*\).*/\1/p'
}

function require_xcodegen() {
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen is required. Install it with: brew install xcodegen"
    exit 1
  fi
}

function isolated_xcodebuild() {
  local major
  major="$(xcode_major_version)"

  # Xcode 27's signed Swift macro service needs the normal macOS user context.
  # Older Xcode releases keep the project-local cache isolation that originally
  # worked around nested Swift Package sandbox failures.
  if [[ "$major" == <-> ]] && (( major >= 27 )); then
    "$DEVELOPER_DIR/usr/bin/xcodebuild" "$@"
    return
  fi

  HOME="$AUTOMATION/home" \
  CFFIXED_USER_HOME="$AUTOMATION/home" \
  XDG_CACHE_HOME="$AUTOMATION/home/Library/Caches" \
  CLANG_MODULE_CACHE_PATH="$AUTOMATION/ModuleCache" \
  "$DEVELOPER_DIR/usr/bin/xcodebuild" "$@"
}

function bounded_simctl() {
  local timeout_seconds="${1:-20}"
  shift

  # Xcode 27 beta's CoreSimulator can occasionally leave a command such as
  # `terminate` waiting forever after a reboot. Keep development automation
  # recoverable: a failed simulator command should report its boundary instead
  # of making the command center appear stuck.
  /usr/bin/python3 - "$timeout_seconds" "$DEVELOPER_DIR/usr/bin/simctl" "$@" <<'PY'
import subprocess
import sys

timeout_seconds = float(sys.argv[1])
command = sys.argv[2:]

try:
    completed = subprocess.run(command, timeout=timeout_seconds)
except subprocess.TimeoutExpired:
    print(
        f"Simulator command timed out after {timeout_seconds:g} seconds: {' '.join(command[1:])}",
        file=sys.stderr,
    )
    raise SystemExit(124)

raise SystemExit(completed.returncode)
PY
}

function open_simulator_ui() {
  local device_hub="$XCODE_APP/Contents/Applications/DeviceHub.app"
  local legacy_simulator="$XCODE_APP/Contents/Developer/Applications/Simulator.app"

  if [[ -d "$device_hub" ]]; then
    open "$device_hub"
  elif [[ -d "$legacy_simulator" ]]; then
    open "$legacy_simulator"
  else
    open -a Simulator
  fi
}

function pause_if_double_clicked() {
  if [[ -t 0 && "${HOGUE_NO_PAUSE:-0}" != "1" ]]; then
    echo
    echo "Press any key to close this window."
    read -k 1
    echo
  fi
}
