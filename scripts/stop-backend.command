#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

if [[ -f "$LOGS/backend.pid" ]]; then
  PID="$(cat "$LOGS/backend.pid")"
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID"
    echo "Stopped backend process $PID."
  else
    echo "Saved backend process is no longer running."
  fi
  : > "$LOGS/backend.pid"
else
  echo "No saved backend process was found."
fi
pause_if_double_clicked
