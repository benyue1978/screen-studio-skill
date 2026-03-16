#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 2 ]]; then
  echo "Usage: $0 <x> <y> [settle-seconds]"
  echo "Example: $0 720 530 1.2"
  exit 0
fi

x="$1"
y="$2"
settle="${3:-0.5}"

swift -e "import Foundation
import CoreGraphics
let p = CGPoint(x: Double(\"$x\")!, y: Double(\"$y\")!)
if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left) {
  move.post(tap: .cghidEventTap)
}
Thread.sleep(forTimeInterval: Double(\"$settle\")!)
"
