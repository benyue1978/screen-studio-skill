#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [display-query]"
  echo "Example: $0 'Built-in Retina Display'"
  echo "Starts Screen Studio display recording."
  echo "Requires exactly one matching display."
  echo "If the query is missing or matches zero or multiple displays, it exits with an error."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" record-display "${1-}"
