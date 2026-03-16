#!/usr/bin/env node
const { execFileSync } = require("node:child_process");

const query = process.argv[2] || "";

const script = `
tell application "Google Chrome"
  set winIndex to 0
  repeat with w in windows
    set winIndex to winIndex + 1
    set tabIndex to 0
    repeat with t in tabs of w
      set tabIndex to tabIndex + 1
      set tabUrl to URL of t
      if "${query}" is "" or tabUrl contains "${query}" then
        set winBounds to bounds of w
        return (item 1 of winBounds as text) & "," & (item 2 of winBounds as text) & "," & (item 3 of winBounds as text) & "," & (item 4 of winBounds as text) & "," & winIndex & "," & tabIndex & "," & tabUrl
      end if
    end repeat
  end repeat
end tell
`;

try {
  const result = execFileSync("osascript", ["-e", script], { encoding: "utf8" }).trim();
  const [left, top, right, bottom, windowIndex, tabIndex, url] = result.split(",", 7);
  const width = Number(right) - Number(left);
  const height = Number(bottom) - Number(top);
  const centerX = Number(left) + Math.round(width / 2);
  const centerY = Number(top) + Math.round(height / 2);
  console.log(JSON.stringify({
    left: Number(left),
    top: Number(top),
    right: Number(right),
    bottom: Number(bottom),
    width,
    height,
    centerX,
    centerY,
    windowIndex: Number(windowIndex),
    tabIndex: Number(tabIndex),
    url,
  }, null, 2));
} catch (error) {
  process.stderr.write("Failed to find a matching Google Chrome window.\\n");
  process.exit(1);
}
