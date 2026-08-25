#!/bin/zsh

set -euo pipefail

XCODE_BETA="/Applications/Xcode-beta.app"
DEVELOPER_PATH="$XCODE_BETA/Contents/Developer"

echo "Linking Xcode beta for command-line builds"
echo "=========================================="

if [[ ! -d "$DEVELOPER_PATH" ]]; then
  echo "Xcode beta was not found at $XCODE_BETA."
  echo "Install Xcode beta first, then run this again."
  exit 1
fi

echo "Installed beta:"
"$DEVELOPER_PATH/usr/bin/xcodebuild" -version

echo
echo "This will ask for your Mac password because xcode-select changes a system setting."
sudo xcode-select --switch "$DEVELOPER_PATH"

echo
echo "Running Apple's first-launch setup if needed."
sudo "$DEVELOPER_PATH/usr/bin/xcodebuild" -runFirstLaunch || true

echo
echo "Current command-line developer path:"
xcode-select -p

echo
echo "Done. Codex automation also sets DEVELOPER_DIR directly, so these scripts can use Xcode beta even if the global link changes later."

if [[ -t 0 && "${HOGUE_NO_PAUSE:-0}" != "1" ]]; then
  echo
  echo "Press any key to close this window."
  read -k 1
  echo
fi
