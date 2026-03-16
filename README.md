# Screen Studio Skill

This repo contains a reusable skill for automating Screen Studio on macOS:

- [skills/screenstudio-macos-automation/SKILL.md](/Users/song.yue/git/screen-studio-skill/skills/screenstudio-macos-automation/SKILL.md)

## Important Notes

1. Make sure the Screen Studio shortcuts work on this Mac before trying automation.

- The default `Start new Recording / Finish recording` shortcut is `Command + Control + Return`.
- If that shortcut opens another app or does nothing, fix the shortcut conflict first.
- Screen Studio automation will be unreliable until the shortcut reaches Screen Studio consistently.

2. Use window recording, and configure the save behavior manually once.

- The validated automation flow uses `Record single window`.
- Before relying on automation, do one manual recording session in Screen Studio.
- When the floating action appears for the selected window, change it from the default `Record and create project` behavior to `Record & Save`.
- The automation assumes the window-selection step can then be confirmed with `Enter`.

3. After recording finishes, the file still needs to be named and saved manually.

- The current workflow automates starting recording, selecting the target window, driving the target app, and stopping recording.
- It does not automate the final file naming or save dialog.
- After Screen Studio stops recording, manually choose the file name and save location.
