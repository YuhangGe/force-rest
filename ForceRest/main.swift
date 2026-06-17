//
//  main.swift
//  ForceRest
//

import Cocoa

// 确保只有一个实例在运行
let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.xiaoge.ForceRest"
let runningInstances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
if runningInstances.count > 1 {
    // 已有实例在运行，退出当前实例
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
