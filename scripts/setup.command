#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

echo "Preparing Xcode components…"
isolated_xcodebuild -checkFirstLaunchStatus

echo "Preparing Python service…"
if [[ ! -x "$BACKEND/.venv/bin/python" ]]; then
  python3 -m venv "$BACKEND/.venv"
fi
"$BACKEND/.venv/bin/pip" install -e "${BACKEND}[dev]"

if [[ ! -f "$BACKEND/.env" ]]; then
  cp "$BACKEND/.env.example" "$BACKEND/.env"
  echo "Created backend/.env. AI will prefer the M4's local Apple model and safely fall back when unavailable."
fi

echo "Generating Xcode project…"
(cd "$IOS" && xcodegen generate)

echo "Running unsigned iPhone build…"
HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/build-ios.command"

echo
echo "Setup complete."
echo "Double-click start-everything.command to launch the backend and Simulator."
pause_if_double_clicked
