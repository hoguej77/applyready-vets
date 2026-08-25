#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

echo "ApplyReady Vets development doctor"
echo "================================"
echo "Mac: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "Chip: $(uname -m)"
echo "Xcode: $(isolated_xcodebuild -version | tr '\n' ' ')"
echo "Developer directory: $DEVELOPER_DIR"
XCODE_MAJOR="$(xcode_major_version)"
if [[ "$XCODE_MAJOR" == <-> ]] && (( XCODE_MAJOR >= 27 )); then
  echo "Xcode build mode: standard user context (Swift macro compatible)"
else
  echo "Xcode build mode: project-local compatibility caches"
fi
echo "Python: $(python3 --version 2>&1)"
echo "XcodeGen: $(xcodegen --version 2>&1 || echo missing)"

if codesign --verify --deep --strict "$XCODE_APP" >/dev/null 2>&1; then
  echo "Xcode signature: valid"
else
  XCODE_SIGNING_INFO="$(codesign -dv --verbose=4 "$XCODE_APP" 2>&1 || true)"
  if [[ "$XCODE_SIGNING_INFO" == *"Identifier=com.apple.dt.Xcode"* \
      && "$XCODE_SIGNING_INFO" == *"TeamIdentifier=59GAB85EFG"* ]]; then
    echo "Xcode signature: Apple beta identity present (macOS beta trust warning)"
  else
    echo "Xcode signature: NEEDS ATTENTION"
    codesign --verify --deep --strict "$XCODE_APP" 2>&1 | sed -n '1,5p' || true
  fi
fi

if bounded_simctl 20 list devices available >/dev/null 2>"$LOGS/simulator-doctor.log"; then
  echo "Simulator service: ready"
else
  echo "Simulator service: NEEDS ATTENTION"
  if grep -q "CoreSimulator is out of date" "$LOGS/simulator-doctor.log"; then
    echo "Xcode and the running CoreSimulator service have different versions."
  fi
  echo "See $LOGS/simulator-doctor.log"
fi

echo
echo "AI readiness"
echo "------------"
if [[ -x /usr/bin/fm ]]; then
  FM_STATUS="$(/usr/bin/fm available 2>&1 || true)"
  if [[ "$FM_STATUS" == *"System model available"* ]]; then
    echo "Apple on-device model: available"
  else
    echo "Apple on-device model: unavailable"
    echo "Enable Apple Intelligence and download its model in System Settings."
  fi
else
  echo "Apple on-device model: not included in this macOS version"
fi

ENV_FILE="$BACKEND/.env"
if [[ -f "$ENV_FILE" ]]; then
  AI_PROVIDER="$(sed -n 's/^HOGUE_AI_PROVIDER=//p' "$ENV_FILE" | tail -n 1)"
  [[ -n "$AI_PROVIDER" ]] || AI_PROVIDER="auto"
  echo "Configured AI route: $AI_PROVIDER"
  if grep -Eq '^OPENAI_API_KEY=.+$' "$ENV_FILE"; then
    echo "OpenAI cloud fallback: configured"
  else
    echo "OpenAI cloud fallback: optional and not configured"
  fi
else
  echo "Configured AI route: auto (setup.command will create backend/.env)"
  echo "OpenAI cloud fallback: optional and not configured"
fi

echo
echo "Project: $ROOT"
pause_if_double_clicked
