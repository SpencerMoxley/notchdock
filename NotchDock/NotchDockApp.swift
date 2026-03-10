import SwiftUI
import AppKit

@main
struct NotchDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window — the app runs as a menu-bar / notch agent
        Settings {
            EmptyView()
        }
    }
}
