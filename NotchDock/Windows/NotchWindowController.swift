import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    // Collapsed pill dimensions (matches 14"/16" MBP notch)
    static let collapsedWidth: CGFloat = 162
    static let collapsedHeight: CGFloat = 32

    // Expanded panel dimensions
    static let expandedWidth: CGFloat = 500
    static let expandedHeight: CGFloat = 340

    private let expandDelay: TimeInterval = 0.05
    private let collapseDelay: TimeInterval = 0.3

    private var collapseTask: DispatchWorkItem?

    // Shared state passed into SwiftUI
    private let notchState = NotchState()

    convenience init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = NotchWindowController.collapsedFrame(for: screen)

        let window = NotchWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)

        let rootView = NotchContainerView(state: notchState)
            .ignoresSafeArea()
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        window.contentView = hostingView

        setupTrackingArea()

        // Re-position if the screen configuration changes (external display connect, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Geometry

    static func collapsedFrame(for screen: NSScreen) -> NSRect {
        let sw = screen.frame.width
        let sh = screen.frame.height
        let x = (sw - collapsedWidth) / 2
        let y = sh - collapsedHeight
        return NSRect(x: x, y: y, width: collapsedWidth, height: collapsedHeight)
    }

    static func expandedFrame(for screen: NSScreen) -> NSRect {
        let sw = screen.frame.width
        let sh = screen.frame.height
        let x = (sw - expandedWidth) / 2
        let y = sh - expandedHeight
        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
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
        expand()
    }

    override func mouseExited(with event: NSEvent) {
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.collapse()
        }
        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + collapseDelay, execute: task)
    }

    // MARK: - Expand / Collapse

    private func expand() {
        guard let window, let screen = NSScreen.main else { return }
        let target = NotchWindowController.expandedFrame(for: screen)
        notchState.isExpanded = true
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(target, display: true)
        }
    }

    private func collapse() {
        guard let window, let screen = NSScreen.main else { return }
        let target = NotchWindowController.collapsedFrame(for: screen)
        notchState.isExpanded = false
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(target, display: true)
        }
    }

    // MARK: - Screen change

    @objc private func screenConfigChanged() {
        guard let screen = NSScreen.main, let window else { return }
        let frame = notchState.isExpanded
            ? NotchWindowController.expandedFrame(for: screen)
            : NotchWindowController.collapsedFrame(for: screen)
        window.setFrame(frame, display: true)
    }
}
