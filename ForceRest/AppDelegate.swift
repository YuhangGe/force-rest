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
//        updateRest(5)
//        state = .resting(secondsRemaining: 5)
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
        let hintFont = CTFontCreateUIFontForLanguage(.system, 27, nil)
        let countdownFont = NSFont.monospacedSystemFont(ofSize: 75, weight: .regular)

        // Build attributed strings
        let hintAttrs: [CFString: Any] = [
            kCTFontAttributeName: hintFont!,
            kCTForegroundColorFromContextAttributeName: true,
        ]
        let countdownAttrs: [CFString: Any] = [
            kCTFontAttributeName: countdownFont,
            kCTForegroundColorFromContextAttributeName: true,
        ]
        guard let hintAttrStr = CFAttributedStringCreate(nil, hintText as CFString, hintAttrs as CFDictionary),
              let countdownAttrStr = CFAttributedStringCreate(nil, countdownText as CFString, countdownAttrs as CFDictionary)
        else { return }

        let hintLine = CTLineCreateWithAttributedString(hintAttrStr)
        let countdownLine = CTLineCreateWithAttributedString(countdownAttrStr)

        // Measure typographic bounds
        var hintAscent: CGFloat = 0, hintDescent: CGFloat = 0, hintLeading: CGFloat = 0
        let hintWidth = CTLineGetTypographicBounds(hintLine, &hintAscent, &hintDescent, &hintLeading)

        var cdAscent: CGFloat = 0, cdDescent: CGFloat = 0, cdLeading: CGFloat = 0
        let cdWidth = CTLineGetTypographicBounds(countdownLine, &cdAscent, &cdDescent, &cdLeading)

        // Position at bottom-right corner
        let padding: CGFloat = 80
        let gap: CGFloat = 0
        let cdY = padding + cdDescent
        let hintY = cdY + cdAscent + gap + hintDescent

        // Draw first line (hint), right-aligned (round to pixel)
        ctx.textPosition = CGPoint(
            x: (screenSize.width - hintWidth - padding).rounded(),
            y: hintY.rounded()
        )
        CTLineDraw(hintLine, ctx)

        // Draw second line (countdown), right-aligned (round to pixel)
        ctx.textPosition = CGPoint(
            x: (screenSize.width - cdWidth - padding).rounded(),
            y: cdY.rounded()
        )
        CTLineDraw(countdownLine, ctx)

        ctx.flush()
    }
}
