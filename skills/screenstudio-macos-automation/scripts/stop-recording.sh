#!/bin/zsh
set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0"
  echo "Stops Screen Studio recording using screen-studio://finish-recording."
  exit 0
fi

open 'screen-studio://finish-recording'
