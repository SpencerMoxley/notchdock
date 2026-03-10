import AppKit

final class NotchWindow: NSWindow {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        configure()
    }

    private func configure() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        // Float above menu bar
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        // Visible on all spaces, doesn't disrupt Mission Control
        collectionBehavior = [.canJoinAllSpaces, .stationary, .transient]
        // Don't appear in the window list or CMD+Tab
        isExcludedFromWindowsMenu = true
    }

    // Let the window become key so hover/click works without app activation
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
