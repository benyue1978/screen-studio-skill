#!/bin/zsh
set -euo pipefail

mouse_lib_dir="$(cd "$(dirname "${(%):-%N}")" && pwd)"
source "$mouse_lib_dir/common.sh"

convert_display_center_to_cg_point() {
  local x="$1"
  local y="$2"

  swift -e "import AppKit
let mainHeight = NSScreen.screens.first?.frame.maxY ?? 0
let convertedY = mainHeight - Double(\"$y\")!
print(\"\(Int(Double(\"$x\")!)) \(Int(convertedY))\")
"
}

mouse_target_point() {
  local target_type="$1"
  local x="$2"
  local y="$3"

  case "$target_type" in
    display)
      convert_display_center_to_cg_point "$x" "$y"
      ;;
    window)
      print -r -- "$x $y"
      ;;
    *)
      print -u2 -- "Unknown mouse target type: $target_type"
      return 1
      ;;
  esac
}

move_mouse_to_point() {
  local target_type="$1"
  local x="$2"
  local y="$3"
  local settle="${4:-0.8}"
  local converted converted_x converted_y

  converted="$(mouse_target_point "$target_type" "$x" "$y")"
  converted_x="${converted%% *}"
  converted_y="${converted##* }"
  log_event "mouse-target" "type=$target_type" "raw_x=$x" "raw_y=$y" "cg_x=$converted_x" "cg_y=$converted_y"

  swift -e "import Foundation
import CoreGraphics
let p = CGPoint(x: Double(\"$converted_x\")!, y: Double(\"$converted_y\")!)
if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left) {
  move.post(tap: .cghidEventTap)
}
Thread.sleep(forTimeInterval: Double(\"$settle\")!)
"
}

press_enter() {
  osascript <<'EOF'
tell application "System Events"
  key code 36
end tell
EOF
}

activate_app() {
  local app_name="$1"
  log_event "activate-app" "app=$app_name"
  osascript -e "tell application \"$app_name\" to activate"
}

activate_pid() {
  local pid="$1"
  local app_name="${2:-}"

  swift -e "import AppKit
let pid = pid_t($pid)
if let app = NSRunningApplication(processIdentifier: pid) {
  app.activate(options: [])
}
" || {
    if [[ -n "$app_name" ]]; then
      activate_app "$app_name"
    fi
  }
}
