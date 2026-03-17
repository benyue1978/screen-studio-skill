#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 1 ]]; then
  echo "Usage: $0 <query>"
  echo "Example: $0 'Google Chrome playwright.dev'"
  echo "Starts Screen Studio window recording."
  echo "If one window matches the query, it activates that app, moves the mouse to the window center, and confirms with Enter."
  echo "If there are zero or multiple matches, it opens the Screen Studio picker for manual selection."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" record-window "$*"
