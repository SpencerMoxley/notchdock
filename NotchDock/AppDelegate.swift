import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchWindowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent the app from appearing in the Dock or App Switcher
        NSApp.setActivationPolicy(.accessory)

        notchWindowController = NotchWindowController()
        notchWindowController?.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
