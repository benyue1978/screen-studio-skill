---
name: screenstudio-macos-automation
description: Use when automating Screen Studio on macOS for screen or window recording, especially when another tool drives the target app and Screen Studio must be coordinated through deeplinks, target discovery, mouse hover, and explicit target-window selection.
---

# Screen Studio macOS Automation

## Overview

Use this skill when Screen Studio is the recorder and another tool drives the app being recorded.

Prefer the bundled scripts over handwritten AppleScript or ad hoc mouse logic. The scripts already handle the validated Screen Studio start and stop flow.

## When to Use

- Recording a browser or desktop app automatically on macOS with Screen Studio
- Another tool drives the target app, such as Playwright, AppleScript, or a native app controller
- The task needs reliable window or display selection before recording starts

Do not use this skill when:

- A different recorder with a real CLI or API is acceptable
- The task depends on advanced Screen Studio editing or export automation that has not been validated on this Mac

## Non-Negotiables

- Use Screen Studio deeplinks through the bundled scripts instead of raw shortcuts.
- `record-window` and `record-display` enter a selection state first. Recording starts only after the target is confirmed.
- If the start flow misses the target or enters the wrong state, stop or cancel that attempt and restart from the beginning.
- Only after 3 failed retries should you inspect the scripts and attempt a manual fix.
- Prefer window recording when the target window can be identified confidently. Use display recording only when the display match is explicit.

## Canonical Commands

Use these entry points:

- `./scripts/run_action.sh record-window "<query>"`
- `./scripts/run_action.sh record-display "<query>"`
- `./scripts/run_action.sh finish-recording`

Convenience wrappers:

- `./scripts/start-window-recording.sh "<query>"`
- `./scripts/start-display-recording.sh "<display-query>"`
- `./scripts/stop-recording.sh`

Run the scripts with `--help` when you need argument details or matching behavior.

## Decision Rules

1. Launch Screen Studio.
2. Launch or focus the target app.
3. If the target window opened on the wrong display, move that window first.
4. Use window recording when you can identify the target window by query.
5. Use display recording only when the intended display is uniquely identifiable.
6. Drive the target app with a separate tool after recording has actually started.
7. Finish recording with the bundled stop command.

## Multi-Display Guidance

- Do not assume a newly launched app opens on the intended display.
- Re-evaluate the target after any window move or relaunch.
- If window targeting is not reliable, place the target window on the intended display before switching to display recording.

## App-Specific Discovery

If the target app exposes a better way to identify its live window bounds, use that before falling back to generic matching.

Example:

- [get-chrome-window-bounds.js](./skills/screenstudio-macos-automation/scripts/get-chrome-window-bounds.js) is a Chrome-specific helper and a good pattern for app-specific discovery.

## Common Mistakes

- Reaching for shortcuts first instead of the bundled deeplink-based scripts
- Assuming `record-window` or `record-display` means recording already started
- Continuing from a failed picker state instead of restarting cleanly
- Driving the target app before Screen Studio has actually locked onto the target
- Forgetting to correct the target window or display before starting recording
