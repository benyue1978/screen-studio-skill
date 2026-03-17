#!/bin/zsh
set -euo pipefail

windows_lib_dir="$(cd "$(dirname "${(%):-%N}")" && pwd)"
source "$windows_lib_dir/common.sh"

read_window_records() {
  swift -e '
import CoreGraphics
import Foundation
import ApplicationServices

// Use the global window list so multiple app instances participate in one z-order.
let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
  exit(0)
}

func sanitize(_ value: Any?) -> String {
  String(describing: value ?? "").replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
}

struct AXWindowInfo {
  let title: String
  let bounds: CGRect
}

// Match a CG window back to its Accessibility window so we can recover titles
// for instances that do not expose useful names in CGWindowList.
func axWindowBounds(_ element: AXUIElement) -> CGRect? {
  var positionValue: CFTypeRef?
  var sizeValue: CFTypeRef?

  guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
        positionValue != nil,
        sizeValue != nil else {
    return nil
  }

  let positionAX = positionValue as! AXValue
  let sizeAX = sizeValue as! AXValue

  var point = CGPoint.zero
  var size = CGSize.zero
  guard AXValueGetValue(positionAX, .cgPoint, &point),
        AXValueGetValue(sizeAX, .cgSize, &size) else {
    return nil
  }

  return CGRect(origin: point, size: size)
}

func axWindowTitle(_ element: AXUIElement) -> String {
  var titleValue: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue) == .success else {
    return ""
  }
  return sanitize(titleValue)
}

func axWindows(for pid: pid_t) -> [AXWindowInfo] {
  let app = AXUIElementCreateApplication(pid)
  var value: CFTypeRef?
  guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
        let elements = value as? [AXUIElement] else {
    return []
  }

  var result: [AXWindowInfo] = []
  for element in elements {
    guard let bounds = axWindowBounds(element) else { continue }
    result.append(AXWindowInfo(title: axWindowTitle(element), bounds: bounds))
  }
  return result
}

// Prefer the CG title when present. Otherwise find the closest AX window by bounds
// and use its title as a best-effort label for filtering.
func resolvedTitle(ownerPID: pid_t, bounds: CGRect, fallback: String, cache: inout [pid_t: [AXWindowInfo]]) -> String {
  if !fallback.isEmpty {
    return fallback
  }

  let windows: [AXWindowInfo]
  if let cached = cache[ownerPID] {
    windows = cached
  } else {
    let fetched = axWindows(for: ownerPID)
    cache[ownerPID] = fetched
    windows = fetched
  }

  var bestTitle = ""
  var bestScore = Double.greatestFiniteMagnitude

  for window in windows {
    let score =
      abs(window.bounds.origin.x - bounds.origin.x) +
      abs(window.bounds.origin.y - bounds.origin.y) +
      abs(window.bounds.size.width - bounds.size.width) +
      abs(window.bounds.size.height - bounds.size.height)

    if score < bestScore {
      bestScore = score
      bestTitle = window.title
    }
  }

  return sanitize(bestTitle)
}

var axCache: [pid_t: [AXWindowInfo]] = [:]

for info in windowList {
  let ownerName = sanitize(info[kCGWindowOwnerName as String])
  let cgTitle = sanitize(info[kCGWindowName as String])
  let ownerPID = pid_t(info[kCGWindowOwnerPID as String] as? Int32 ?? 0)
  let windowNumber = info[kCGWindowNumber as String] as? Int ?? 0
  let layer = info[kCGWindowLayer as String] as? Int ?? 0
  let alpha = info[kCGWindowAlpha as String] as? Double ?? 1

  guard layer == 0, alpha > 0, !ownerName.isEmpty else { continue }
  guard let boundsDict = info[kCGWindowBounds as String] as? NSDictionary,
        let bounds = CGRect(dictionaryRepresentation: boundsDict) else { continue }

  let x = Int(bounds.origin.x)
  let y = Int(bounds.origin.y)
  let width = Int(bounds.size.width)
  let height = Int(bounds.size.height)
  guard width > 0, height > 0 else { continue }

  let title = resolvedTitle(ownerPID: ownerPID, bounds: bounds, fallback: cgTitle, cache: &axCache)
  let centerX = Int(bounds.origin.x + bounds.size.width / 2.0)
  let centerY = Int(bounds.origin.y + bounds.size.height / 2.0)
  let id = "\(ownerPID)-\(windowNumber)"
  let fields = [id, ownerName, title, String(x), String(y), String(width), String(height), String(centerX), String(centerY)]
  print(fields.joined(separator: "\t"))
}
'
}

matching_window_records() {
  local query="${1-}"
  local query_lc="${query:l}"
  local record id app_name title x y width height center_x center_y
  local combined
  local -a records

  records=("${(@f)$(read_window_records)}")

  for record in "${records[@]}"; do
    IFS=$'\t' read -r id app_name title x y width height center_x center_y <<< "$record"
    [[ -z "$id" ]] && continue
    # Query matching stays simple: app name plus resolved window title.
    combined="${app_name:l} ${title:l}"
    if [[ -z "$query_lc" || "$combined" == *${query_lc}* ]]; then
      print -r -- "$record"
    fi
  done
}

match_windows() {
  local query="${1-}"
  local record id app_name title x y width height center_x center_y
  local -a records

  records=("${(@f)$(matching_window_records "$query")}")

  for record in "${records[@]}"; do
    IFS=$'\t' read -r id app_name title x y width height center_x center_y <<< "$record"
    [[ -z "$id" ]] && continue
    print -r -- "$id"$'\t'"$app_name"$'\t'"$title"$'\t'"$center_x"$'\t'"$center_y"
  done
}
