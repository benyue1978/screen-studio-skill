#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 3 ]]; then
  echo "Usage: $0 <app-name> <center-x> <center-y>"
  echo "Example: $0 \"Google Chrome\" 720 530"
  echo "Starts Screen Studio window recording using screen-studio://record-window."
  exit 0
fi

app_name="$1"
center_x="$2"
center_y="$3"

open 'screen-studio://record-window'

sleep 2
osascript -e "tell application \"$app_name\" to activate"
sleep 1.5

"$(dirname "$0")/move-mouse-to-point.sh" "$center_x" "$center_y" 1.2

osascript <<'APPLESCRIPT'
tell application "System Events"
  key code 36
end tell
APPLESCRIPT
