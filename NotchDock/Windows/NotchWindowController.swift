import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    // Window is always this size — it never resizes on hover.
    static let panelWidth:  CGFloat = 480
    static let panelHeight: CGFloat = 182

    // Visual pill size (used by CollapsedView)
    static let collapsedWidth:  CGFloat = 162
    static let collapsedHeight: CGFloat = 32

    private let collapseDelay: TimeInterval = 0.3
    private var collapseTask: DispatchWorkItem?

    let notchState = NotchState()

    convenience init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame  = NotchWindowController.panelFrame(for: screen)

        let window = NotchWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)

        let hostingView = NSHostingView(rootView: NotchContainerView(state: notchState).ignoresSafeArea())
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        window.contentView = hostingView

        setupTrackingArea()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Geometry

    static func panelFrame(for screen: NSScreen) -> NSRect {
        let sw = screen.frame.width
        let sh = screen.frame.height
        let x = (sw - panelWidth) / 2
        // Nudge 7 pt above the screen edge so the panel's top corners are
        // clipped by the physical display bezel, creating the Dynamic Island
        // "grows from the bezel" look.
        let y = sh - panelHeight + 7
        return NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
    }

    // MARK: - Tracking area

    private func setupTrackingArea() {
        guard let contentView = window?.contentView else { return }
        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        collapseTask?.cancel()
        collapseTask = nil
        notchState.isExpanded = true
    }

    override func mouseExited(with event: NSEvent) {
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.notchState.isExpanded = false
        }
        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + collapseDelay, execute: task)
    }

    // MARK: - Screen change

    @objc private func screenConfigChanged() {
        guard let screen = NSScreen.main, let window else { return }
        window.setFrame(NotchWindowController.panelFrame(for: screen), display: true)
    }
}
