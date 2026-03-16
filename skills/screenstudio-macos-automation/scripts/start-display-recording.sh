#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0"
  echo "Starts Screen Studio display recording using screen-studio://record-display."
  exit 0
fi

open 'screen-studio://record-display'
