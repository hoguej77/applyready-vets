#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

function usage() {
  echo "ApplyReady Vets command center"
  echo
  echo "Usage: ./scripts/applyready.command <command>"
  echo
  echo "  check       Check this Mac, Xcode, Simulator, and optional AI routes"
  echo "  run         Build, install, and open the app in iPhone Simulator"
  echo "  files       Open the running Simulator's real Samples and Output folders"
  echo "  test        Run the complete local quality gate"
  echo "  test-live   Run the quality gate including live Simulator tests"
  echo "  release     Show release checks and founder-controlled launch blockers"
  echo "  repair      Clear only safe build caches, regenerate, and retest once"
  echo "  build       Build an unsigned iPhone app"
  echo "  package     Create the reviewed source handoff package"
  echo "  xcode       Generate and open the Xcode project"
  echo "  stop        Stop the optional local service"
  echo "  help        Show this guide"
}

function choose_command() {
  echo "ApplyReady Vets command center" >&2
  echo >&2
  echo "1. Run the app in iPhone Simulator" >&2
  echo "2. Check this Mac and Xcode" >&2
  echo "3. Run all local quality checks" >&2
  echo "4. Open Simulator Samples and Output" >&2
  echo "5. Review release blockers" >&2
  echo "6. Open the Xcode project" >&2
  echo >&2
  read "choice?Choose 1–6: "
  case "$choice" in
    1) echo "run" ;;
    2) echo "check" ;;
    3) echo "test" ;;
    4) echo "files" ;;
    5) echo "release" ;;
    6) echo "xcode" ;;
    *) echo "help" ;;
  esac
}

COMMAND="${1:-}"
if [[ -z "$COMMAND" ]]; then
  if [[ -t 0 ]]; then
    COMMAND="$(choose_command)"
  else
    COMMAND="help"
  fi
fi

case "$COMMAND" in
  check|doctor)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/doctor.command"
    ;;
  run|start|simulator)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/start-everything.command"
    ;;
  files|simulator-files)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/open-simulator-files.command"
    ;;
  test|quality)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/quality-gate.command"
    ;;
  test-live)
    HOGUE_NO_PAUSE=1 HOGUE_QUALITY_RUN_SIMULATOR=1 "$SCRIPT_DIR/quality-gate.command"
    ;;
  release|preflight)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/release-preflight.command" --release-candidate
    ;;
  repair)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/repair-and-validate.command"
    ;;
  build)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/build-ios.command"
    ;;
  package)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/package-source.command"
    ;;
  xcode)
    require_xcodegen
    (cd "$IOS" && xcodegen generate)
    open -a "$XCODE_APP" "$IOS/ApplyReadyVets.xcodeproj"
    echo "Opened ApplyReadyVets.xcodeproj in $XCODE_APP."
    ;;
  stop)
    HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/stop-backend.command"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo
    usage
    exit 2
    ;;
esac
