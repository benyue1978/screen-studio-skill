---
name: screenstudio-macos-automation
description: Use when automating Screen Studio on macOS for screen or window recording, especially when another tool drives the target app and Screen Studio must be controlled through focus changes, global shortcuts, mouse hover, and careful target-window selection.
---

# Screen Studio macOS Automation

## Overview

Use this skill when Screen Studio is the recorder and some other tool drives the app being recorded.

Core principle: prefer Screen Studio URL schemes over shortcuts. Treat Screen Studio and the target app as two separate control loops, and treat target-window selection as the fragile part.

## When to Use

- Recording a browser or app automatically on macOS with Screen Studio
- Another tool drives the app under test, such as Playwright, AppleScript, or a native app controller
- Screen Studio has no stable public API for the task, so automation must use shortcuts, focus changes, mouse movement, and accessibility
- Multi-display setups make display selection or target-window selection brittle

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

Important:

- Do a full restart of the Screen Studio start flow after a missed attempt. Do not try to recover from a half-finished picker state.
- The `hover + Enter` pattern is more reliable than trying to click the transient `Record & Save` button.
- Prefer URL schemes first:
  - `screen-studio://record-window`
  - `screen-studio://record-display`
  - `screen-studio://finish-recording`
- Keep the old shortcut flow only as a fallback if a URL scheme stops working on the current Screen Studio version.

## Focus Rules

Focus still matters, but less than before.

- Before hovering the target window, explicitly activate the target app.
- Before pressing `Enter`, make sure the target app is really frontmost.
- If a URL scheme opens Screen Studio into the wrong state, restart the attempt instead of trying to repair the picker state.
- If a fallback shortcut opens the wrong app or does nothing, assume the shortcut is intercepted on this Mac.

## Helper Scripts

Use the bundled scripts instead of retyping the fragile focus and mouse logic:

- `scripts/start-window-recording.sh "<App Name>" <center-x> <center-y>`
  - Starts Screen Studio window-recording mode with `screen-studio://record-window`
  - Activates the target app
  - Moves the mouse to the provided center point
  - Confirms with `Enter`

- `scripts/start-display-recording.sh`
  - Starts Screen Studio display-recording mode with `screen-studio://record-display`

- `scripts/stop-recording.sh`
  - Stops with `screen-studio://finish-recording`

- `scripts/move-mouse-to-point.sh <x> <y> [settle-seconds]`
  - Moves the pointer with CoreGraphics
  - Useful when a custom selection flow is needed

- `scripts/get-chrome-window-bounds.js [url-substring]`
  - Uses AppleScript plus Chrome JavaScript to find a matching Chrome tab and report the front window bounds
  - This is an example helper for one app, not the preferred universal interface
  - Use it when Chrome is the target and no better window-discovery method is available

Run scripts with `--help` or missing args first to see usage.

## Target Window Strategy

Prefer window recording over display recording when possible, but only if the target window can be identified reliably.

Recommended strategy:

1. Discover the target window through the app's own automation API if available.
2. Read native window bounds.
3. Compute the live center from those bounds.
4. If needed, move the window to a known location on the intended display.
5. Hover the center of that window.
6. Confirm with `Enter`.

Never hardcode center coordinates except for one-off debugging. Always derive them from the current window:

- `center_x = left + width / 2`
- `center_y = top + height / 2`

For browser-based automation, DevTools window bounds are often more reliable than generic macOS accessibility window listings. More generally, prefer app-specific window-discovery methods before falling back to generic Accessibility probing.

Do not fall back to display recording too early. First exhaust app-specific or tool-specific ways to prove that a real desktop window exists and retrieve its live bounds.

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
open 'screen-studio://record-window'
```

Start display recording:

```bash
open 'screen-studio://record-display'
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
open 'screen-studio://finish-recording'
```

## Common Mistakes

- Reaching for shortcuts first when a URL scheme already exists
- Clicking the transient button instead of using `Enter`
- Hardcoding center coordinates instead of computing them from the live target window
- Trusting generic macOS window enumeration when the app's own protocol can provide exact window bounds
- Falling back to display recording before exhausting app-specific window-discovery options
- Continuing from a failed picker state instead of restarting
- Ignoring which display the target window actually opened on

## Success Checklist

- Screen Studio launches
- Target window is known and visible
- The correct URL scheme opens the expected Screen Studio recording mode
- Target app is focused before hover
- Pointer reaches target-window center
- `Enter` confirms window selection
- External tool drives visible activity
- `screen-studio://finish-recording` ends the recording
