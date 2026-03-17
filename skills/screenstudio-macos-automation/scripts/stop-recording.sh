#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0"
  echo "Stops Screen Studio recording using screen-studio://finish-recording."
  exit 0
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/run_action.sh" finish-recording
