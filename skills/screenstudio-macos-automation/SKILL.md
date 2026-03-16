---
name: screenstudio-macos-automation
description: Use when automating Screen Studio on macOS for screen or window recording, especially when another tool drives the target app and Screen Studio must be controlled through focus changes, global shortcuts, mouse hover, and careful target-window selection.
---

# Screen Studio macOS Automation

## Overview

Use this skill when Screen Studio is the recorder and some other tool drives the app being recorded.

Core principle: treat Screen Studio and the target app as two separate control loops. Screen Studio needs explicit focus before its shortcuts, and target-window selection is often the fragile part.

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
4. Activate Screen Studio and wait before sending its global shortcut.
5. Start recording mode with `Command + Control + Return`.
6. Re-activate Screen Studio and wait again.
7. Switch to window recording with `Command + Option + 4`.
8. Activate the target app.
9. Move the mouse to the center of the target window.
10. Press `Enter` to confirm the highlighted window.
11. Drive the target app.
12. Activate Screen Studio and stop with `Command + Control + Return`.

Important:

- Do a full restart of the Screen Studio start flow after a missed attempt. Do not try to recover from a half-finished picker state.
- On some setups, `Record single window` alone is not enough. The sequence must begin with the global `Start new Recording / Finish recording` shortcut first.
- The `hover + Enter` pattern is more reliable than trying to click the transient `Record & Save` button.

## Focus Rules

Focus is critical.

- Before `Command + Control + Return`, explicitly activate Screen Studio and wait about 2 to 3 seconds.
- Before `Command + Option + 4`, explicitly activate Screen Studio again and wait about 1 to 2 seconds.
- Before hovering the target window, explicitly activate the target app.
- Before stopping, activate Screen Studio again.

If the start shortcut opens the wrong app or does nothing, assume the shortcut was intercepted or sent before Screen Studio was truly frontmost.

## Helper Scripts

Use the bundled scripts instead of retyping the fragile focus and mouse logic:

- `scripts/start-window-recording.sh "<App Name>" <center-x> <center-y>`
  - Activates Screen Studio
  - Starts recording flow
  - Switches to window mode
  - Activates the target app
  - Moves the mouse to the provided center point
  - Confirms with `Enter`

- `scripts/stop-recording.sh`
  - Activates Screen Studio
  - Stops with the default finish shortcut

- `scripts/move-mouse-to-point.sh <x> <y> [settle-seconds]`
  - Moves the pointer with CoreGraphics
  - Useful when a custom selection flow is needed

- `scripts/get-chrome-window-bounds.js [url-substring]`
  - Uses AppleScript plus Chrome JavaScript to find a matching Chrome tab and report the front window bounds
  - Useful for turning a browser target into center coordinates without relying on generic Accessibility window enumeration

Run scripts with `--help` or missing args first to see usage.

## Target Window Strategy

Prefer window recording over display recording when possible, but only if the target window can be identified reliably.

Recommended strategy:

1. Discover the target window through the app's own automation API if available.
2. Read native window bounds.
3. If needed, move the window to a known location on the intended display.
4. Hover the center of that window.
5. Confirm with `Enter`.

For browser-based automation, DevTools window bounds are often more reliable than generic macOS accessibility window listings. If those are not available, use targeted app-specific helpers before falling back to generic APIs.

## Multi-Display Guidance

Multi-display setups are the main source of failure.

- Do not assume a newly launched browser or app opens on the intended display.
- If the target app opens on the wrong monitor, move that one window first.
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

```applescript
tell application "System Events"
  keystroke return using {command down, control down}
end tell
```

Switch to window recording:

```applescript
tell application "System Events"
  keystroke "4" using {command down, option down}
end tell
```

Activate target app:

```applescript
tell application "Google Chrome" to activate
delay 1.5
```

Move mouse to target-window center with Swift/CoreGraphics:

```swift
import Foundation
import CoreGraphics

let p = CGPoint(x: 720, y: 530)
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

```applescript
tell application "Screen Studio" to activate
delay 1.5
tell application "System Events"
  keystroke return using {command down, control down}
end tell
```

## Common Mistakes

- Sending Screen Studio shortcuts before Screen Studio is truly frontmost
- Trying to use `Record single window` without first entering the global start flow
- Clicking the transient button instead of using `Enter`
- Trusting generic macOS window enumeration when the app's own protocol can provide exact window bounds
- Continuing from a failed picker state instead of restarting
- Ignoring which display the target window actually opened on

## Success Checklist

- Screen Studio launches
- Target window is known and visible
- Screen Studio is focused before each of its shortcuts
- Target app is focused before hover
- Pointer reaches target-window center
- `Enter` confirms window selection
- External tool drives visible activity
- Screen Studio is focused before stop
