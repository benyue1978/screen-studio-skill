# Screen Studio Skill

This repo contains a reusable skill for automating Screen Studio on macOS:

- `skills/screenstudio-macos-automation/SKILL.md`

The key idea is generic target-window discovery. Playwright and Google Chrome were used during validation, but they are only examples. The reusable workflow is:

- find the real target desktop window
- get its live bounds
- compute its center from those bounds
- start Screen Studio window recording with URL scheme
- hover the target window center
- confirm with `Enter`

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

3. After recording finishes, the file still needs to be named and saved manually.

- The current workflow automates starting recording, selecting the target window, driving the target app, and stopping recording.
- It does not automate the final file naming or save dialog.
- After Screen Studio stops recording, manually choose the file name and save location.
