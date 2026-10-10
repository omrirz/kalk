import AppKit

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    // Menubar-only: no Dock icon (LSUIElement also sets this when running from the .app bundle).
    app.setActivationPolicy(.accessory)
    app.run()
}
