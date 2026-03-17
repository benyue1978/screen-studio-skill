#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [display-query]"
  echo "Example: $0 'Built-in Retina Display'"
  echo "Starts Screen Studio display recording."
  echo "If one display matches the query, it moves the mouse to that display center and confirms with Enter."
  echo "If there is no query or there are multiple matches, it opens the Screen Studio picker for manual selection."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" record-display "${1-}"
