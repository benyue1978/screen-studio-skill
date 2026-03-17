#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 2 ]]; then
  echo "Usage: $0 <x> <y> [settle-seconds] [target-type]"
  echo "Example: $0 720 530 1.2 window"
  echo "Target type defaults to window. Use display to convert display-center coordinates."
  exit 0
fi

x="$1"
y="$2"
settle="${3:-0.5}"
target_type="${4:-window}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/lib/mouse.sh"

move_mouse_to_point "$target_type" "$x" "$y" "$settle"
