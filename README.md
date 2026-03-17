# Screen Studio Skill

This repo contains a reusable skill for automating Screen Studio on macOS:

- `skills/screenstudio-macos-automation/SKILL.md`

The key idea is generic target discovery. Playwright and Google Chrome were used during validation, but they are only examples. The reusable workflow is:

- discover candidate windows or displays
- if exactly one candidate matches, compute its live center and auto-confirm it
- if there is ambiguity, fail instead of guessing
- start Screen Studio recording with URL scheme
- hover the chosen target center
- confirm with `Enter`

Important correction:

- `screen-studio://record-window` and `screen-studio://record-display` both enter selection mode first
- neither one means recording has actually started yet
- you still need to move the mouse onto the intended target and press `Enter`

## Important Notes

1. Prefer URL schemes over shortcuts.

- Prefer:
  - `screen-studio://record-window`
  - `screen-studio://record-display`
  - `screen-studio://finish-recording`
- These are more reliable than keyboard shortcuts because they do not depend on shortcut conflicts.
- Keep shortcuts only as a fallback if a URL scheme stops working on a given Screen Studio version.

2. Use window recording, and configure the save behavior manually once.

- The validated automation flow uses `Record single window`.
- Before relying on automation, do one manual recording session in Screen Studio.
- When the floating action appears for the selected window, change it from the default `Record and create project` behavior to `Record & Save`.
- The automation assumes the window-selection step can then be confirmed with `Enter`.
- For display recording, you still need to move the mouse to the intended display center and press `Enter`.

3. After recording finishes, the file still needs to be named and saved manually.

- The current workflow automates starting recording, selecting the target window, driving the target app, and stopping recording.
- It does not automate the final file naming or save dialog.
- After Screen Studio stops recording, manually choose the file name and save location.

## Better Script Entry Points

The repo now includes a generic action runner:

- `skills/screenstudio-macos-automation/scripts/run_action.sh`

Recommended usage:

- `./skills/screenstudio-macos-automation/scripts/run_action.sh record-window "Google Chrome playwright.dev"`
- `./skills/screenstudio-macos-automation/scripts/run_action.sh record-display "Built-in"`
- `./skills/screenstudio-macos-automation/scripts/run_action.sh finish-recording`

Why this is better than the original one-off helpers:

- it uses query-based target matching instead of hardcoded coordinates
- it auto-confirms only when there is exactly one match
- it fails loudly when matching is ambiguous, which is safer for AI callers
- it keeps window recording and display recording under one consistent interface
