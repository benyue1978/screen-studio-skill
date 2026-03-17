#!/bin/zsh
set -euo pipefail

repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${(%):-%N}")" && pwd)"
  cd "$script_dir/../../.." && pwd
}

trim_whitespace() {
  local value="${1-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  print -r -- "$value"
}

screenstudio_log_dir() {
  if [[ -n "${SCREENSTUDIO_LOG_DIR:-}" ]]; then
    print -r -- "$SCREENSTUDIO_LOG_DIR"
    return
  fi

  print -r -- "$(repo_root)/.screenstudio-logs"
}

screenstudio_log_file() {
  print -r -- "$(screenstudio_log_dir)/screenstudio.log"
}

log_event() {
  local log_dir log_file timestamp
  log_dir="$(screenstudio_log_dir)"
  mkdir -p "$log_dir"
  log_file="$(screenstudio_log_file)"
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  print -r -- "$timestamp | $*" >> "$log_file"
}
