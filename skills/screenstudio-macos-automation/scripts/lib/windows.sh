#!/bin/zsh
set -euo pipefail

windows_lib_dir="$(cd "$(dirname "${(%):-%N}")" && pwd)"
source "$windows_lib_dir/common.sh"

read_window_records() {
  osascript -l JavaScript <<'EOF'
const se = Application("System Events");
const procs = se.applicationProcesses.whose({ backgroundOnly: false })();

function sanitize(value) {
  return String(value || "").replace(/\t/g, " ").replace(/\n/g, " ").trim();
}

const lines = [];
for (const proc of procs) {
  let appName = "";
  try {
    appName = sanitize(proc.name());
  } catch (err) {
    continue;
  }

  let windows = [];
  try {
    windows = proc.windows();
  } catch (err) {
    continue;
  }

  for (let idx = 0; idx < windows.length; idx += 1) {
    const win = windows[idx];
    try {
      const title = sanitize(win.name());
      const position = win.position();
      const size = win.size();
      const x = Number(position[0]);
      const y = Number(position[1]);
      const width = Number(size[0]);
      const height = Number(size[1]);
      if (!Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(width) || !Number.isFinite(height)) {
        continue;
      }
      if (width <= 0 || height <= 0) {
        continue;
      }
      const centerX = Math.floor(x + width / 2);
      const centerY = Math.floor(y + height / 2);
      lines.push([`${appName}-${idx + 1}`, appName, title, x, y, width, height, centerX, centerY].join("\t"));
    } catch (err) {
      continue;
    }
  }
}
lines.join("\n");
EOF
}

match_windows() {
  local query="${1-}"
  local query_lc="${query:l}"
  local record id app_name title x y width height center_x center_y
  local combined
  local -a records

  records=("${(@f)$(read_window_records)}")

  for record in "${records[@]}"; do
    IFS=$'\t' read -r id app_name title x y width height center_x center_y <<< "$record"
    [[ -z "$id" ]] && continue
    combined="${app_name:l} ${title:l}"
    if [[ -z "$query_lc" || "$combined" == *${query_lc}* ]]; then
      print -r -- "$id"$'\t'"$app_name"$'\t'"$title"$'\t'"$center_x"$'\t'"$center_y"
    fi
  done
}
