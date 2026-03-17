#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
script_path="$0"
source "$script_dir/lib/common.sh"
source "$script_dir/lib/deeplinks.sh"
source "$script_dir/lib/windows.sh"
source "$script_dir/lib/displays.sh"
source "$script_dir/lib/mouse.sh"

picker_delay="${SCREENSTUDIO_PICKER_DELAY:-1.2}"
hover_settle="${SCREENSTUDIO_HOVER_SETTLE:-0.8}"

open_deeplink() {
  local url="$1"
  log_event "open-deeplink" "url=$url"
  open "$url"
}

run_selected_display() {
  local id="$1"
  local center_x="$2"
  local center_y="$3"
  local url

  url="$(deeplink_url record-display)"
  log_event "selected-display" "id=$id" "center_x=$center_x" "center_y=$center_y"
  open_deeplink "$url"
  sleep "$picker_delay"
  move_mouse_to_point display "$center_x" "$center_y" "$hover_settle"
  press_enter
}

run_selected_window() {
  local id="$1"
  local app_name="$2"
  local center_x="$3"
  local center_y="$4"
  local url

  url="$(deeplink_url record-window)"
  log_event "selected-window" "id=$id" "app=$app_name" "center_x=$center_x" "center_y=$center_y"
  open_deeplink "$url"
  sleep "$picker_delay"
  activate_app "$app_name"
  sleep 0.4
  move_mouse_to_point window "$center_x" "$center_y" "$hover_settle"
  press_enter
}

match_count() {
  local matches="$1"
  print -r -- "$matches" | sed '/^$/d' | wc -l | tr -d ' '
}

print_display_matches() {
  local matches="$1"
  local id name center_x center_y

  while IFS=$'\t' read -r id name center_x center_y; do
    [[ -z "$id" ]] && continue
    print -u2 -- "- $name ($id) center=[$center_x,$center_y]"
  done <<< "$matches"
}

print_window_matches() {
  local matches="$1"
  local id app_name title center_x center_y

  while IFS=$'\t' read -r id app_name title center_x center_y; do
    [[ -z "$id" ]] && continue
    print -u2 -- "- $app_name | $title ($id) center=[$center_x,$center_y]"
  done <<< "$matches"
}

run_record_display() {
  local query matches id name center_x center_y count

  query="$(trim_whitespace "${1-}")"
  log_event "run-record-display" "query=$query"
  if [[ -z "$query" ]]; then
    print -u2 -- "record-display requires a display query in strict mode."
    print -u2 -- "Example: $script_path record-display 'Built-in Retina Display'"
    exit 1
  fi

  matches="$(match_displays "$query")"
  count="$(match_count "$matches")"
  log_event "display-match-count" "query=$query" "count=$count"
  if [[ "$count" != "1" ]]; then
    if [[ "$count" == "0" ]]; then
      print -u2 -- "No displays matched query: $query"
    else
      print -u2 -- "Expected exactly 1 display match for query: $query"
      print -u2 -- "Found $count matches:"
      print_display_matches "$matches"
    fi
    exit 1
  fi

  IFS=$'\t' read -r id name center_x center_y <<< "$matches"
  run_selected_display "$id" "$center_x" "$center_y"
}

run_record_window() {
  local query matches id app_name title center_x center_y count

  query="$(trim_whitespace "${1-}")"
  log_event "run-record-window" "query=$query"
  if [[ -z "$query" ]]; then
    print -u2 -- "record-window requires a window query in strict mode."
    print -u2 -- "Example: $script_path record-window 'Google Chrome playwright.dev'"
    exit 1
  fi

  matches="$(match_windows "$query")"
  count="$(match_count "$matches")"
  log_event "window-match-count" "query=$query" "count=$count"
  if [[ "$count" == "0" ]]; then
    print -u2 -- "No windows matched query: $query"
    exit 1
  fi

  IFS=$'\t' read -r id app_name title center_x center_y <<< "$(print -r -- "$matches" | sed -n '1p')"
  run_selected_window "$id" "$app_name" "$center_x" "$center_y"
}

run_simple_action() {
  local action_id="$1"
  local url

  url="$(deeplink_url "$action_id")"
  if [[ -z "$url" ]]; then
    print -u2 -- "Unknown action: $action_id"
    exit 1
  fi
  open_deeplink "$url"
}

action_id="$(trim_whitespace "${1-}")"
query="$(trim_whitespace "${2-}")"

case "$action_id" in
  record-display)
    run_record_display "$query"
    ;;
  record-window)
    run_record_window "$query"
    ;;
  "")
    print -u2 -- "Usage: $0 <action-id> [query]"
    exit 1
    ;;
  *)
    run_simple_action "$action_id"
    ;;
esac
