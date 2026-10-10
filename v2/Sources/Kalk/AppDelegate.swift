import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = KalkSettings()
    private let model = CalculatorModel()

    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    private var settingsWindow: NSWindow?
    private var hotKey: HotKey?
    private var keyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    /// True while we move or resize the window ourselves, so those changes aren't saved as user preferences.
    private var isUpdatingFrame = false
    private var hasPlacedWindow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu()
        setUpStatusItem()
        setUpWindow()
        bindSettings()
        installKeyMonitor()

        hotKey = HotKey(keyCode: kVK_ANSI_5, modifiers: cmdKey) { [weak self] in
            self?.toggleCalculator()
        }

        // Wait a runloop pass so the status item has a position to anchor the window under.
        DispatchQueue.main.async { self.showCalculator() }
    }

    // MARK: - Status item

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = StatusIcon.make()
        button.toolTip = "Kalk"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            let menu = NSMenu()
            menu.addItem(withTitle: "Show Kalk", action: #selector(showCalculatorAction), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: "").target = self
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit Kalk", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            // Clicking the status item doesn't activate the app, so a visible window is "shown but not focused".
            window.isVisible ? hideCalculator() : showCalculator()
        }
    }

    // MARK: - Calculator window

    private func setUpWindow() {
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: settings.windowSize),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.minSize = KalkSettings.minSize
        window.delegate = self
        window.contentView = NSHostingView(rootView: CalculatorView(model: model, settings: settings) { [weak self] in
            self?.openSettings()
        })
    }

    private func bindSettings() {
        settings.$alwaysOnTop
            .sink { [weak self] onTop in self?.window.level = onTop ? .floating : .normal }
            .store(in: &cancellables)

        settings.$visibleOnAllSpaces
            .sink { [weak self] allSpaces in
                self?.window.collectionBehavior = allSpaces
                    ? [.canJoinAllSpaces, .fullScreenAuxiliary]
                    : [.fullScreenAuxiliary]
            }
            .store(in: &cancellables)

        settings.$backgroundColor
            .sink { [weak self] rgb in self?.window.backgroundColor = rgb.nsColor }
            .store(in: &cancellables)

        settings.$windowSize
            .removeDuplicates()
            .sink { [weak self] size in self?.resizeWindow(to: size) }
            .store(in: &cancellables)
    }

    private func resizeWindow(to size: CGSize) {
        guard window.frame.size != size else { return }
        // Keep the top-left corner in place, like the original app.
        var frame = window.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        isUpdatingFrame = true
        window.setFrame(frame, display: true)
        isUpdatingFrame = false
    }

    private func placeWindow() {
        let origin = settings.windowOrigin.flatMap { origin in
            NSScreen.screens.contains { $0.frame.contains(origin) } ? origin : nil
        } ?? defaultOrigin()
        isUpdatingFrame = true
        window.setFrameOrigin(origin)
        isUpdatingFrame = false
    }

    /// Centers the window under the menubar icon, kept inside the screen.
    private func defaultOrigin() -> CGPoint {
        let size = window.frame.size
        guard let anchor = statusItem.button?.window?.frame,
              let screen = statusItem.button?.window?.screen ?? NSScreen.main
        else {
            let visible = NSScreen.main?.visibleFrame ?? .zero
            return CGPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        }
        let visible = screen.visibleFrame
        let x = min(max(anchor.midX - size.width / 2, visible.minX + 8), visible.maxX - size.width - 8)
        let y = max(min(anchor.minY - 6, visible.maxY) - size.height, visible.minY)
        return CGPoint(x: x, y: y)
    }

    @objc private func showCalculatorAction() {
        showCalculator()
    }

    private func showCalculator() {
        if !hasPlacedWindow {
            placeWindow()
            hasPlacedWindow = true
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        model.requestFocus()
    }

    private func hideCalculator() {
        window.orderOut(nil)
        // Hand focus back to the previous app, unless the settings window is still open.
        if settingsWindow?.isVisible != true {
            NSApp.hide(nil)
        }
    }

    private func toggleCalculator() {
        if window.isVisible && window.isKeyWindow && NSApp.isActive {
            hideCalculator()
        } else {
            showCalculator()
        }
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            if event.type == .keyDown && event.keyCode == UInt16(kVK_Escape) {
                self.hideCalculator()
                return nil
            }
            if event.type == .keyDown && (event.keyCode == UInt16(kVK_UpArrow) || event.keyCode == UInt16(kVK_DownArrow)) {
                self.model.recall(older: event.keyCode == UInt16(kVK_UpArrow))
                return nil
            }
            if event.type == .flagsChanged && event.modifierFlags.contains(.option) {
                self.model.revealError()
            }
            return event
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard !isUpdatingFrame, notification.object as? NSWindow === window else { return }
        settings.windowOrigin = window.frame.origin
    }

    func windowDidResize(_ notification: Notification) {
        guard !isUpdatingFrame, notification.object as? NSWindow === window else { return }
        settings.windowSize = window.frame.size
        settings.windowOrigin = window.frame.origin
    }

    // MARK: - Settings window

    @objc private func openSettings() {
        if settingsWindow == nil {
            let actions = SettingsActions(
                resetSize: { [weak self] in self?.settings.windowSize = KalkSettings.defaultSize },
                resetPosition: { [weak self] in self?.resetPosition() },
                clearHistory: { [weak self] in self?.model.clearHistory() },
                close: { [weak self] in self?.closeSettings() },
                quit: { NSApp.terminate(nil) }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 640),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Kalk Settings"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(settings: settings, actions: actions))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func closeSettings() {
        settingsWindow?.orderOut(nil)
        if window.isVisible {
            window.makeKeyAndOrderFront(nil)
            model.requestFocus()
        }
    }

    private func resetPosition() {
        settings.windowOrigin = nil
        isUpdatingFrame = true
        window.setFrameOrigin(defaultOrigin())
        isUpdatingFrame = false
    }

    // MARK: - Main menu

    /// Accessory apps have no visible menu bar, but the menu still routes ⌘C/⌘V/⌘Z/⌘A to the text field.
    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Kalk", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        mainMenu.addItem(withTitle: "Kalk", action: nil, keyEquivalent: "").submenu = appMenu

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        mainMenu.addItem(withTitle: "Edit", action: nil, keyEquivalent: "").submenu = editMenu

        return mainMenu
    }
}
