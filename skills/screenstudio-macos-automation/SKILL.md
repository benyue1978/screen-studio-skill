---
name: screenstudio-macos-automation
description: Use when automating Screen Studio on macOS for screen or window recording, especially when another tool drives the target app and Screen Studio must be coordinated through deeplinks, target discovery, mouse hover, and explicit target-window selection.
---

# Screen Studio macOS Automation

## Overview

Use this skill when Screen Studio is the recorder and some other tool drives the app being recorded.

Core principle: prefer Screen Studio deeplinks over shortcuts. Treat Screen Studio and the target app as two separate control loops, and make target discovery explicit.

Important correction: both `record-window` and `record-display` enter a selection state first. Neither one guarantees that recording has actually started until the pointer is moved onto the intended target and `Enter` is pressed.

Better strategy: do not treat recording start as a one-off helper call. Treat it as:

1. discover candidate windows or displays
2. for window recording, look across all instances of the application
3. filter out much smaller windows before choosing by global window order
4. for display recording, require exactly one confident match

## When to Use

- Recording a browser or app automatically on macOS with Screen Studio
- Another tool drives the app under test, such as Playwright, AppleScript, or a native app controller
- Screen Studio has no stable public API for the task, so automation must use shortcuts, focus changes, mouse movement, and accessibility
- Multi-display setups require explicit display or window selection rules

Do not use this skill when:

- A different recorder with a real CLI or API is acceptable
- The task requires advanced editing/export automation that has not been validated on the current machine

## Validated Workflow

This workflow was validated against Screen Studio defaults on macOS:

1. Launch Screen Studio.
2. Launch the target application window to record.
3. If the target window appears on the wrong display, move that one window to the intended display before recording starts.
4. Start window-recording mode with `open 'screen-studio://record-window'`.
5. Activate the target app.
6. Move the mouse to the center of the target window.
7. Press `Enter` to confirm the highlighted window.
8. Drive the target app.
9. Stop with `open 'screen-studio://finish-recording'`.

For display recording:

1. Launch Screen Studio.
2. Make sure the intended display is known.
3. Start display-recording mode with `open 'screen-studio://record-display'`.
4. Move the mouse to the center of the intended display.
5. Press `Enter` to confirm the highlighted display.
6. Drive the target app.
7. Stop with `open 'screen-studio://finish-recording'`.

Important:

- Do a full restart of the Screen Studio start flow after a missed attempt. Do not try to recover from a half-finished picker state.
- The `hover + Enter` pattern is more reliable than trying to click the transient `Record & Save` button.
- Prefer deeplinks first:
  - `screen-studio://record-window`
  - `screen-studio://record-display`
  - `screen-studio://finish-recording`
- Keep the old shortcut flow only as a fallback if a deeplink stops working on the current Screen Studio version.
- Do not assume `record-window` or `record-display` starts capture immediately. Both still require target confirmation.

## Focus Rules

Focus still matters, but less than before.

- Before hovering the target window, explicitly activate the target app.
- Before pressing `Enter`, make sure the target app is really frontmost.
- For display recording, move the mouse to the intended display before pressing `Enter`.
- If a deeplink opens Screen Studio into the wrong state, restart the attempt instead of trying to repair the picker state.
- If a fallback shortcut opens the wrong app or does nothing, assume the shortcut is intercepted on this Mac.

## Helper Scripts

Use the bundled scripts instead of retyping the deeplink, focus, matching, and mouse logic:

- `scripts/run_action.sh <action-id> [query]`
  - Preferred entry point
  - Supports `record-window`, `record-display`, and all simple Screen Studio deeplink actions
  - For `record-window`:
    - it looks across all visible windows for the application, including multiple app instances
    - if there are one or more matches, it first filters out much smaller windows using a relative area threshold, then chooses the first matching window in current global window order
    - if there are zero matches, it exits non-zero
  - For `record-display`:
    - it still requires exactly one matching display
    - otherwise it exits non-zero

- `scripts/start-window-recording.sh "<query>"`
  - Convenience wrapper around `scripts/run_action.sh record-window "<query>"`
  - Query can match app name, window title, or both
  - Example:
    - `Google Chrome playwright.dev`
  - If multiple windows match, much smaller windows are filtered out first
  - Then the first matching window in current global window order wins

- `scripts/start-display-recording.sh [display-query]`
  - Convenience wrapper around `scripts/run_action.sh record-display "<query>"`
  - If exactly one display matches, it auto-confirms that display
  - Otherwise it exits non-zero

- `scripts/stop-recording.sh`
  - Stops with `screen-studio://finish-recording`

- `scripts/move-mouse-to-point.sh <x> <y> [settle-seconds] [target-type]`
  - Moves the pointer with CoreGraphics
  - Supports both `window` and `display` coordinate handling
  - Useful when a custom selection flow is needed

- `scripts/get-chrome-window-bounds.js [url-substring]`
  - Uses AppleScript plus Chrome JavaScript to find a matching Chrome tab and report the front window bounds
  - This is an example helper for one app, not the preferred universal interface
  - Use it when Chrome is the target and no better window-discovery method is available

The skill now favors a generic matcher-first workflow over app-specific one-off helpers.

Run scripts with `--help` or missing args first to see usage.

## Target Window Strategy

Prefer window recording over display recording when possible, but only if the target window can be identified reliably.

Recommended strategy:

1. Discover candidate targets through the app's own automation API if available.
2. Fall back to generic macOS window or display enumeration.
3. For window recording, enumerate all visible windows across application instances.
4. Filter out windows whose area is much smaller than the largest candidate.
5. For display recording, require exactly one candidate match and fail otherwise.
6. If needed, move the target window to a known location on the intended display before recomputing the center.
7. Hover the center of the chosen target.
8. Confirm with `Enter`.

Never hardcode center coordinates except for one-off debugging. Always derive them from the current window:

- `center_x = left + width / 2`
- `center_y = top + height / 2`

For browser-based automation, DevTools window bounds are often more reliable than generic macOS accessibility window listings. More generally, prefer app-specific discovery methods before falling back to generic Accessibility probing.

For window recording, use a global window list so multiple app instances are included, filter out much smaller windows, then use global window order as the tiebreaker. The default relative area threshold is `0.1`, configurable through `SCREENSTUDIO_WINDOW_AREA_RATIO_THRESHOLD`. For display recording, do not auto-commit when multiple displays match.

Do not fall back to display recording too early. First exhaust app-specific or tool-specific ways to prove that a real desktop window exists and retrieve its live bounds.

If you do fall back to display recording, apply the same rule: derive the intended target region first, move the mouse into that display's middle area, then confirm with `Enter`.

## Multi-Display Guidance

Multi-display setups are the main source of failure.

- Do not assume a newly launched browser or app opens on the intended display.
- If the target app opens on the wrong monitor, move that one window first and then recompute the center from the new bounds.
- If reliable window targeting is impossible, fall back to display recording only after placing the target window on the intended display.

## Example Tool Split

Screen Studio should only handle recording.

The target app should be driven by a separate tool:

- Playwright for browser automation
- AppleScript for app activation
- Swift/CoreGraphics for mouse movement
- Accessibility APIs for menu and window inspection

Playwright is just one example. The skill is about coordinating Screen Studio with any external controller.

## Practical Commands

Activate Screen Studio:

```applescript
tell application "Screen Studio" to activate
delay 2.5
```

Start recording flow:

```bash
# open the target window with Playwright or another controller
./scripts/run_action.sh record-window "Google Chrome playwright.dev"
```

Start display recording:

```bash
./scripts/run_action.sh record-display "Built-in"
```

Confirm target display:

```text
move mouse to intended display center
press Enter
```

Activate target app:

```applescript
tell application "Google Chrome" to activate
delay 1.5
```

Compute live center from window bounds:

```text
center_x = left + width / 2
center_y = top + height / 2
```

Move mouse to target-window center with Swift/CoreGraphics:

```swift
import Foundation
import CoreGraphics

let p = CGPoint(x: centerX, y: centerY)
if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left) {
  move.post(tap: .cghidEventTap)
}
Thread.sleep(forTimeInterval: 1.2)
```

Confirm selected window:

```applescript
tell application "System Events"
  key code 36
end tell
```

Stop recording:

```bash
./scripts/run_action.sh finish-recording
```

## Common Mistakes

- Reaching for shortcuts first when a deeplink already exists
- Assuming `record-window` or `record-display` means recording has already started
- Treating target selection as a fixed-coordinate problem instead of a discovery-and-match problem
- Assuming display-selection rules and window-selection rules should be identical
- Clicking the transient button instead of using `Enter`
- Hardcoding center coordinates instead of computing them from the live target window
- Forgetting to move the mouse to the intended display center before confirming display recording
- Trusting generic macOS window enumeration when the app's own protocol can provide exact window bounds
- Assuming one process view is enough when the application has multiple instances
- Forgetting that window selection now filters out much smaller windows before using global window order
- Falling back to display recording before exhausting app-specific window-discovery options
- Continuing from a failed picker state instead of restarting
- Ignoring which display the target window actually opened on

## Success Checklist

- Screen Studio launches
- Target window is known and visible
- The correct deeplink opens the expected Screen Studio recording mode
- Target app is focused before hover
- Pointer reaches target-window center
- `Enter` confirms window selection
- For display recording, the pointer reaches the intended display center before `Enter`
- External tool drives visible activity
- `screen-studio://finish-recording` ends the recording
