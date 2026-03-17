#!/bin/zsh
set -euo pipefail

typeset -grA SCREENSTUDIO_DEEPLINKS=(
  record-display "screen-studio://record-display"
  record-window "screen-studio://record-window"
  record-area "screen-studio://record-area"
  finish-recording "screen-studio://finish-recording"
  cancel-recording "screen-studio://cancel-recording"
  restart-recording "screen-studio://restart-recording"
  toggle-recording-area-cover "screen-studio://toggle-recording-area-cover"
  toggle-recording-controls "screen-studio://toggle-recording-controls"
  open-projects-folder "screen-studio://open-projects-folder"
  open-settings "screen-studio://open-settings"
  copy-and-zip-project "screen-studio://copy-and-zip-project"
)

deeplink_url() {
  local action_id="${1-}"
  print -r -- "${SCREENSTUDIO_DEEPLINKS[$action_id]-}"
}
