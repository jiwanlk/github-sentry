import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    convenience init(onSave: @escaping () -> Void) {
        let settingsView = SettingsView(onSave: onSave)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "GitHub Sentry — Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 440, height: 480))
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
    }
}
