#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 3 ]]; then
  echo "Usage: $0 <app-name> <center-x> <center-y>"
  echo "Example: $0 \"Google Chrome\" 720 530"
  exit 0
fi

app_name="$1"
center_x="$2"
center_y="$3"

osascript <<APPLESCRIPT
tell application "Screen Studio" to activate
delay 2.5
tell application "System Events"
  keystroke return using {command down, control down}
end tell
delay 2.0
tell application "Screen Studio" to activate
delay 1.5
tell application "System Events"
  keystroke "4" using {command down, option down}
end tell
APPLESCRIPT

sleep 2
osascript -e "tell application \"$app_name\" to activate"
sleep 1.5

"$(dirname "$0")/move-mouse-to-point.sh" "$center_x" "$center_y" 1.2

osascript <<'APPLESCRIPT'
tell application "System Events"
  key code 36
end tell
APPLESCRIPT
