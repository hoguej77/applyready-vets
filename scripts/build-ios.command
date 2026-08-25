#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

(cd "$IOS" && xcodegen generate)

set -o pipefail
isolated_xcodebuild \
  -project "$IOS/ApplyReadyVets.xcodeproj" \
  -scheme ApplyReadyVets \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$AUTOMATION/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  build | tee "$LOGS/ios-build.log"

echo
echo "iPhone build succeeded."
echo "App bundle: $AUTOMATION/DerivedData/Build/Products/Debug-iphoneos/ApplyReadyVets.app"
pause_if_double_clicked
