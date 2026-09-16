import AppKit
import Combine
import CoreMotion

final class AirPods {
    private let tracker = HeadTracker()
    private var subscriptions = Set<AnyCancellable>()
    var onSample: ((Double?, Double?) -> Void)?
    var onStatus: ((String) -> Void)?
    var diagnosticText: String { tracker.diagnosticText }
    var isReconnecting: Bool { tracker.isReconnecting }
    private var latestStatus = "等待连接 AirPods"
    init() {
        tracker.samples.sink { [weak self] pose in
            self?.onSample?(pose.yaw, pose.pitch)
        }.store(in: &subscriptions)
        tracker.$status.removeDuplicates().sink { [weak self] status in
            let text: String
            switch status {
            case .unsupported: text = "当前设备未提供头部追踪，请连接兼容的 AirPods"
            case .denied: text = "请在系统设置 → 隐私与安全 → 运动与健身允许回望"
            case .restricted: text = "运动与健身权限受系统限制"
            case .waitingForPermission: text = "等待运动与健身授权"
            case .waitingForHeadphones: text = "等待 AirPods 数据，请佩戴并连接到这台 Mac"
            case .tracking: text = "AirPods 已连接，请正对屏幕并校准"
            }
            self?.latestStatus = text
            self?.onStatus?(text)
        }.store(in: &subscriptions)
    }
    func start() { tracker.start(); onStatus?(latestStatus) }
    func reconnect() { tracker.reconnect(); onStatus?(latestStatus) }
    func recenter() { tracker.recenter() }
    func stop() { tracker.stop() }
}

final class Overlay {
    private var windows: [NSWindow] = []
    private(set) var active = false
    var blurAvailable = WindowBlur.isAvailable
    init() {
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.active else { return }
            self.set(false); self.set(true)
        }
    }
    func set(_ value: Bool) {
        guard value != active else { return }
        active = value
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        guard value else { return }
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.18)
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 2)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            let applied = WindowBlur.apply(to: window, radius: 64)
            blurAvailable = blurAvailable && applied
            if !applied { window.backgroundColor = NSColor.black.withAlphaComponent(0.65) }
            window.orderFrontRegardless()
            windows.append(window)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let airpods = AirPods()
    let overlay = Overlay()
    let diagnostics = NSTextField(labelWithString: "")
    let status = NSTextField(wrappingLabelWithString: "准备就绪 · 请先连接 AirPods")
    let angles = NSTextField(labelWithString: "左右 —°     上下 —°")
    let thresholdLabel = NSTextField(labelWithString: "30°")
    let delayLabel = NSTextField(labelWithString: "0.6 秒")
    var toggle: NSButton!
    var calibrateButton: NSButton!
    var connectButton: NSButton!
    var window: NSWindow!
    var reference: (Double, Double)?
    var latest: (Double, Double)?
    var lastSample = 0.0
    var enabled = false
    var suspendedUntil = 0.0
    var trigger = DwellTrigger(threshold: 30, enterDwell: 0.6)
    var timer: Timer?
    var previewTimer: Timer?
    var started = false
    var previewing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        airpods.onSample = { [weak self] yaw, pitch in self?.sample(yaw, pitch) }
        airpods.onStatus = { [weak self] text in
            guard let self else { return }
            self.status.stringValue = text
            self.latest = nil; self.reference = nil; self.lastSample = 0
            self.calibrateButton.isEnabled = false
            self.angles.stringValue = "左右 —°     上下 —°"
            self.clear()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.diagnostics.stringValue = self.airpods.diagnosticText
            self.connectButton.isEnabled = !self.airpods.isReconnecting
            if self.lastSample > 0 && ProcessInfo.processInfo.systemUptime - self.lastSample > 2 {
                self.latest = nil; self.reference = nil; self.lastSample = 0
                self.calibrateButton.isEnabled = false
                self.clear(); self.status.stringValue = "AirPods 数据中断，已恢复清晰。重连后请重新校准。"
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.snooze(); return nil }; return event
        }
    }
    func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 650), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "LookBack · 回望"
        window.isReleasedWhenClosed = false; window.delegate = self
        // Keep controls readable above our blur overlay, so recovery never needs a menu bar.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 650))
        window.contentView = root
        func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ size: CGFloat = 14, _ weight: NSFont.Weight = .regular) {
            let l = NSTextField(wrappingLabelWithString: text)
            l.frame = NSRect(x: x, y: y, width: width, height: height)
            l.font = .systemFont(ofSize: size, weight: weight); root.addSubview(l)
        }
        label("LOOKBACK / AIRPODS", 32, 605, 500, 18, 11, .semibold)
        label("回望", 32, 550, 400, 48, 36, .bold)
        label("转开头，让屏幕模糊。看回来，继续专注。", 32, 518, 576, 24, 16)
        status.frame = NSRect(x: 32, y: 477, width: 576, height: 36)
        status.font = .systemFont(ofSize: 14, weight: .medium)
        status.textColor = .secondaryLabelColor; root.addSubview(status)
        diagnostics.frame = NSRect(x: 32, y: 447, width: 576, height: 22)
        diagnostics.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        diagnostics.textColor = .secondaryLabelColor; root.addSubview(diagnostics)
        connectButton = button("1  连接 AirPods", #selector(start), x: 32, y: 399, width: 276)
        calibrateButton = button("2  校准当前朝向", #selector(calibrate), x: 324, y: 399, width: 284)
        calibrateButton.isEnabled = false
        angles.frame = NSRect(x: 32, y: 341, width: 576, height: 40)
        angles.font = .monospacedDigitSystemFont(ofSize: 27, weight: .medium); root.addSubview(angles)
        label("佩戴耳机并正对屏幕后校准。重新连接或移动座位后，请再次校准。", 32, 310, 576, 24, 12)
        label("转头触发角度", 32, 263, 240, 22, 14, .semibold)
        thresholdLabel.frame = NSRect(x: 526, y: 263, width: 82, height: 22)
        thresholdLabel.alignment = .right; root.addSubview(thresholdLabel)
        let threshold = NSSlider(value: 30, minValue: 15, maxValue: 60, target: self, action: #selector(changeThreshold(_:)))
        threshold.frame = NSRect(x: 32, y: 230, width: 576, height: 24)
        threshold.setAccessibilityLabel("转头触发角度"); root.addSubview(threshold)
        label("持续多久后模糊", 32, 194, 240, 22, 14, .semibold)
        delayLabel.frame = NSRect(x: 506, y: 194, width: 102, height: 22)
        delayLabel.alignment = .right; root.addSubview(delayLabel)
        let delay = NSSlider(value: 0.6, minValue: 0.2, maxValue: 2, target: self, action: #selector(changeDelay(_:)))
        delay.frame = NSRect(x: 32, y: 163, width: 576, height: 24)
        delay.setAccessibilityLabel("模糊触发延迟"); root.addSubview(delay)
        toggle = button("暂停检测", #selector(toggleEnabled), x: 32, y: 103, width: 180)
        toggle.isEnabled = false
        _ = button("暂停 1 分钟", #selector(snooze), x: 224, y: 103, width: 180)
        _ = button("预览模糊 2 秒", #selector(preview), x: 416, y: 103, width: 192)
        label("仅使用 AirPods 运动数据 · 不用摄像头 · 数据留在本机\nEsc 暂停一分钟；× 隐藏窗口，Dock 图标重新打开，⌘Q 退出。", 32, 30, 576, 52, 12)
        let menu = NSMenu(); let appMenu = NSMenu(); let item = NSMenuItem()
        item.submenu = appMenu; menu.addItem(item)
        let quitItem = NSMenuItem(title: "退出回望", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self; appMenu.addItem(quitItem); NSApp.mainMenu = menu
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func button(_ title: String, _ action: Selector, x: CGFloat, y: CGFloat, width: CGFloat) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .rounded; b.controlSize = .large
        b.frame = NSRect(x: x, y: y, width: width, height: 42)
        window.contentView?.addSubview(b); return b
    }
    @objc func start() {
        clear(); reference = nil; latest = nil; calibrateButton.isEnabled = false
        enabled = true; toggle.isEnabled = true; toggle.title = "暂停检测"
        status.stringValue = "正在连接 AirPods…请佩戴耳机并允许运动与健身权限。"
        connectButton.title = "重新连接 AirPods"
        if started { airpods.reconnect() } else { started = true; airpods.start() }
    }
    @objc func calibrate() {
        guard latest != nil, ProcessInfo.processInfo.systemUptime - lastSample < 1 else {
            status.stringValue = "请先连接并佩戴支持头部追踪的 AirPods"; return
        }
        airpods.recenter(); reference = (0, 0); enabled = true; suspendedUntil = 0
        toggle.title = "暂停检测"; clear(); status.stringValue = "已校准 · 正在检测，屏幕清晰"
    }
    func clear() {
        previewTimer?.invalidate(); previewing = false
        trigger.reset(); overlay.set(false)
    }
    @objc func toggleEnabled() {
        enabled.toggle(); toggle.title = enabled ? "暂停检测" : "恢复检测"
        suspendedUntil = 0; clear()
        status.stringValue = enabled ? "检测已恢复" : "检测已暂停 · 屏幕清晰"
    }
    @objc func snooze() {
        suspendedUntil = ProcessInfo.processInfo.systemUptime + 60; clear()
        status.stringValue = "已暂停 1 分钟 · 屏幕清晰"
    }
    @objc func changeThreshold(_ slider: NSSlider) {
        trigger.threshold = slider.doubleValue.rounded()
        thresholdLabel.stringValue = String(format: "%.0f°", trigger.threshold); clear()
    }
    @objc func changeDelay(_ slider: NSSlider) {
        trigger.enterDwell = (slider.doubleValue * 10).rounded() / 10
        delayLabel.stringValue = String(format: "%.1f 秒", trigger.enterDwell); clear()
    }
    @objc func preview() {
        clear(); previewing = true; overlay.set(true)
        status.stringValue = overlay.blurAvailable ? "正在预览模糊 · 2 秒后恢复" : "当前系统不支持模糊 · 正在预览压暗"
        previewTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.clear(); self?.status.stringValue = "预览结束 · 屏幕清晰"
        }
    }
    func sample(_ yaw: Double?, _ pitch: Double?) {
        let now = ProcessInfo.processInfo.systemUptime
        lastSample = now
        latest = yaw.flatMap { y in pitch.map { (y, $0) } }
        calibrateButton.isEnabled = latest != nil
        if let latest { angles.stringValue = String(format: "左右 %+.0f°     上下 %+.0f°", latest.0, latest.1) }
        guard !previewing else { return }
        guard now >= suspendedUntil else {
            status.stringValue = "已暂停 · \(Int(ceil(suspendedUntil - now))) 秒后恢复"; return
        }
        guard enabled else { status.stringValue = "检测已暂停 · 屏幕清晰"; clear(); return }
        guard reference != nil else { status.stringValue = "AirPods 已连接 · 请正对屏幕，点击校准"; clear(); return }
        guard let latest else { clear(); return }
        if trigger.update(max(abs(latest.0), abs(latest.1)), at: now) { overlay.set(trigger.isActive) }
        status.stringValue = overlay.active ? (overlay.blurAvailable ? "已转开 · 屏幕模糊" : "已转开 · 屏幕压暗") : "正在检测 · 屏幕清晰"
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        sender.activate(ignoringOtherApps: true)
        return true
    }
    func applicationWillTerminate(_ notification: Notification) { airpods.stop(); clear() }
    @objc func quit() { NSApp.terminate(nil) }
}
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
