# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

- Open `ForceRest.xcodeproj` in Xcode, build with `Cmd+B`, run with `Cmd+R`
- No external dependencies — uses only Cocoa and CoreGraphics frameworks
- macOS deployment target is 11.0

## Architecture

This is a minimal macOS "force rest" app (~210 lines of Swift). It enforces scheduled screen breaks by capturing all displays and drawing a countdown overlay. The only escape during a break is to force-shutdown the Mac.

Entry point is `ForceRest/main.swift` — creates `NSApplication.shared`, wires the `AppDelegate`, and calls `app.run()`.

All business logic lives in `ForceRest/AppDelegate.swift`, which uses an explicit state machine:

```
working ──(minute matches schedule)──▶ resting(seconds)
resting ──(countdown reaches 0)──────▶ working
resting ──(system sleep)─────────────▶ working  (timer invalidated)
```

- `applicationDidFinishLaunching(_:)` — registers for `NSWorkspace.willSleepNotification` / `didWakeNotification` and starts a 1-second repeating timer. Contains commented-out debug code for testing the overlay.
- `handleTimer()` — if resting, decrements the countdown and calls `updateRest()`; if working, checks the current wall-clock minute against `lastRestedMinute` to avoid re-triggering. Break schedule (based on actual code, not README):
  - Minute **57** → 3 minutes (180s)
  - Minute **15, 45** → 30 seconds
  - Minute **28** → 2 minutes (120s)
- `gotoRest()` — captures **all** displays via `CGCaptureAllDisplays()`, then grabs the main display's `CGContext` for drawing. Returns early if either call fails.
- `updateRest(_:)` — clears the captured display, then renders two CoreText lines (Chinese hint text in 27pt system font + `MM:SS` countdown in 75pt monospaced digit font) positioned at the bottom-right corner with 80px padding. Text color is a semi-transparent red (`#D32029` at 80% alpha). Antialiasing and subpixel rendering are explicitly enabled.
- `gotoWork()` — calls `CGReleaseAllDisplays()`, clears internal state.

Key behaviors:
- `LSUIElement = true` in `Info.plist` — the app has no Dock icon (background/status-bar style)
- On system sleep during a break, the app exits break mode (`gotoWork()`); on wake, the timer restarts regardless
- `lastRestedMinute` prevents triggering a break more than once in the same clock minute
- Many `NSLog` calls are commented out; they can be re-enabled for debugging
