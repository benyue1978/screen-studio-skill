#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0"
  echo "Stops Screen Studio recording using the default finish shortcut."
  exit 0
fi

osascript <<'APPLESCRIPT'
tell application "Screen Studio" to activate
delay 1.5
tell application "System Events"
  keystroke return using {command down, control down}
end tell
APPLESCRIPT
