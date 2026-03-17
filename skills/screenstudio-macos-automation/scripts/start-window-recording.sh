#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" || $# -lt 1 ]]; then
  echo "Usage: $0 <query>"
  echo "Example: $0 'Google Chrome playwright.dev'"
  echo "Starts Screen Studio window recording."
  echo "Requires exactly one matching window."
  echo "If the query matches zero or multiple windows, it exits with an error and prints the candidates."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" record-window "$*"
