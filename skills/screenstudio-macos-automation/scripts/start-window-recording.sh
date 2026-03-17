#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 1 ]]; then
  echo "Usage: $0 <query>"
  echo "Example: $0 'Google Chrome playwright.dev'"
  echo "Starts Screen Studio window recording."
  echo "Requires at least one matching window."
  echo "If multiple windows match, it chooses the first match in current window order."
  echo "If the query matches zero windows, it exits with an error."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" record-window "$*"
