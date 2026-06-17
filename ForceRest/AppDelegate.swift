//
//  AppDelegate.swift
//  ForceRest
//
//  Created by me.xiaoge on 2016/12/28, updated to swift on 2026/06/17.
//  Copyright © 2026 me.xiaoge. All rights reserved.
//

import Cocoa
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - State

    private enum AppState {
        case working
        case resting(secondsRemaining: Int)
    }

    private var state: AppState = .working
    private var timer: Timer?
    private var displayContext: CGContext?
    private var screenSize: CGSize = .zero
    private var lastRestedMinute: Int?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self,
                       selector: #selector(receiveSleep),
                       name: NSWorkspace.willSleepNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(receiveWake),
                       name: NSWorkspace.didWakeNotification,
                       object: nil)
        startTimer()
        
//        gotoRest()
//        updateRest(150)
//        state = .resting(secondsRemaining: 150)
//        updateRest(3)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
//            self?.updateRest(1)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
//            self?.gotoWork()
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            exit(0)
//        }
    }

    // MARK: - Sleep / Wake

    @objc private func receiveSleep() {
        if case .resting = state {
            gotoWork()
        }
        timer?.invalidate()
    }

    @objc private func receiveWake() {
        if case .resting = state {
            gotoWork()
        }
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimer()
        }
    }

    private func handleTimer() {
        if case .resting(let seconds) = state {
            let remaining = seconds - 1
            if remaining <= 0 {
                gotoWork()
            } else {
                state = .resting(secondsRemaining: remaining)
                updateRest(remaining)
            }
            return
        }
       
//        NSLog("xxx handle timer")
        let minute = Calendar.current.component(.minute, from: Date())
        guard minute != lastRestedMinute else { return }
        let duration: Int
        switch minute {
        case 57:
            duration = 180  // 3 minutes at X:57
        case 15, 45:
            duration = 30   // 30 seconds at X:15 and X:45
        case 28:
            duration = 120  // 2 minutes at X:28
        default:
            return
        }
        lastRestedMinute = minute
        state = .resting(secondsRemaining: duration)
        gotoRest()
        updateRest(duration)
    }

    // MARK: - Rest / Work

    private func gotoRest() {
        guard CGCaptureAllDisplays() == .success else { return }
        guard let ctx = CGDisplayGetDrawingContext(CGMainDisplayID()) else { return }
        displayContext = ctx
        screenSize = CGDisplayBounds(CGMainDisplayID()).size
//        NSLog("display context: \(displayContext == nil), screenSize: \(screenSize)")
    }

    private func gotoWork() {
//        NSLog("goto work")
        state = .working
        CGReleaseAllDisplays()
        displayContext = nil
        screenSize = .zero
    }

    // MARK: - Display Update

    private func updateRest(_ seconds: Int) {
//        NSLog("try update rest \(seconds), \(displayContext == nil)")
        guard let ctx = displayContext else { return }
        
//        NSLog("try render rest \(seconds)")
        let minutes = seconds / 60
        let secs = seconds % 60
        let countdownText = String(format: "%02d:%02d", minutes, secs)
        let hintText = "～该休息下眼睛啦～"

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        ctx.setAllowsFontSubpixelPositioning(true)
        ctx.setShouldSubpixelPositionFonts(true)

        ctx.setAllowsFontSubpixelQuantization(true)
        ctx.setShouldSubpixelQuantizeFonts(true)
        // Clear screen and fill black background for readability
        ctx.clear(CGRect(origin: .zero, size: screenSize))
//        ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
//        ctx.fill(CGRect(origin: .zero, size: screenSize))

        // White text via kCTForegroundColorFromContextAttributeName
        ctx.setFillColor(red: 0xD3/255.0, green: 0x20/255.0, blue: 0x29/255.0, alpha: 0.8)

        

        // White glow shadow for text readability
//        ctx.setShadow(offset: .zero, blur: 1, color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))

        // System fonts
        let hintFont = CTFontCreateUIFontForLanguage(.system, 26, nil)
        let countdownFont = CTFontCreateUIFontForLanguage(.system, 76, nil)

        // Build attributed strings
        let hintAttrs: [CFString: Any] = [
            kCTFontAttributeName: hintFont!,
            kCTForegroundColorFromContextAttributeName: true,
        ]
        let countdownAttrs: [CFString: Any] = [
            kCTFontAttributeName: countdownFont!,
            kCTForegroundColorFromContextAttributeName: true,
        ]
        guard let hintAttrStr = CFAttributedStringCreate(nil, hintText as CFString, hintAttrs as CFDictionary)
        else { return }

        let hintLine = CTLineCreateWithAttributedString(hintAttrStr)

        // Measure hint typographic bounds
        var hintAscent: CGFloat = 0, hintDescent: CGFloat = 0, hintLeading: CGFloat = 0
        let hintWidth = CTLineGetTypographicBounds(hintLine, &hintAscent, &hintDescent, &hintLeading)

        // Countdown format is always "MM:SS" — exactly 5 characters.
        let charCount = 5
        var charLines: [CTLine] = []
        charLines.reserveCapacity(charCount)
        var charWidths = [CGFloat](repeating: 0, count: charCount)
        var charAscents = [CGFloat](repeating: 0, count: charCount)
        var charDescents = [CGFloat](repeating: 0, count: charCount)

        for (i, ch) in countdownText.enumerated() {
            guard let attrStr = CFAttributedStringCreate(nil, String(ch) as CFString, countdownAttrs as CFDictionary)
            else { return }
            let line = CTLineCreateWithAttributedString(attrStr)
            charLines.append(line)
            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            charWidths[i] = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            charAscents[i] = ascent
            charDescents[i] = descent
        }
        
        // ── Layout ──────────────────────────────────────────────
        // Anchors are px from bottom-right corner; tweak freely.
        let anchorX = screenSize.width - 200
        let anchorY: CGFloat = 136
        let digitSlotWidth: CGFloat = 48   // spacing between adjacent digits
        let colonGap: CGFloat = 40         // spacing between colon and adjacent digit

        // Hint: center-aligned at (screenWidth-200, 100)
        let hintVisualCenterY: CGFloat = 200
        let hintBaselineY = hintVisualCenterY - (hintAscent - hintDescent) / 2
        ctx.textPosition = CGPoint(
            x: (anchorX - hintWidth / 2).rounded(),
            y: hintBaselineY.rounded()
        )
        CTLineDraw(hintLine, ctx)

        // Countdown: colon at anchor, digits left/right with separate gaps
        for (i, line) in charLines.enumerated() {
            let slotCenterX: CGFloat
            if i == 2 {
                slotCenterX = anchorX
            } else if i < 2 {
                slotCenterX = anchorX - colonGap - CGFloat(1 - i) * digitSlotWidth
            } else {
                slotCenterX = anchorX + colonGap + CGFloat(i - 3) * digitSlotWidth
            }
            let charX = slotCenterX - charWidths[i] / 2
            // Center each character vertically on anchorY; nudge colon up
            let colonNudge: CGFloat = i == 2 ? 7 : 0
            let visualCenterOffset = (charAscents[i] - charDescents[i]) / 2
            let charY = anchorY - visualCenterOffset + colonNudge
            ctx.textPosition = CGPoint(x: charX.rounded(), y: charY.rounded())
            CTLineDraw(line, ctx)
        }

        ctx.flush()
    }
}
