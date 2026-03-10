import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    static let panelWidth:      CGFloat = 480
    static let panelHeight:     CGFloat = 182
    static let collapsedWidth:  CGFloat = 162
    static let collapsedHeight: CGFloat = 32

    private let collapseDelay: TimeInterval = 0.3
    private var collapseTask: DispatchWorkItem?

    let notchState = NotchState()

    /// Custom NSView that lets clicks pass through the transparent areas when
    /// the panel is collapsed, so menu-bar items are still reachable.
    private final class PassthroughView: NSView {
        var isExpanded = false

        private let pillW = NotchWindowController.collapsedWidth
        private let pillH = NotchWindowController.collapsedHeight

        override func hitTest(_ point: NSPoint) -> NSView? {
            // When expanded, behave normally.
            guard !isExpanded else { return super.hitTest(point) }
            // When collapsed, only accept hits inside the pill.
            // AppKit uses y-up; the pill sits at the TOP of the view frame.
            let pillX = (bounds.width  - pillW) / 2
            let pillY =  bounds.height - pillH        // top of view in y-up coords
            let pillRect = NSRect(x: pillX, y: pillY, width: pillW, height: pillH)
            return pillRect.contains(point) ? super.hitTest(point) : nil
        }
    }

    private weak var passthroughView: PassthroughView?

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

        // PassthroughView is the real contentView; NSHostingView sits inside it.
        let pv = PassthroughView()
        pv.wantsLayer = true
        pv.layer?.backgroundColor = .clear
        window.contentView = pv
        passthroughView = pv

        let hostingView = NSHostingView(rootView: NotchContainerView(state: notchState).ignoresSafeArea())
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.frame = pv.bounds
        hostingView.autoresizingMask = [.width, .height]
        pv.addSubview(hostingView)

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
        let y = sh - panelHeight + 7   // 7 pt above screen edge → blends into bezel
        return NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
    }

    // MARK: - Tracking area

    private func setupTrackingArea() {
        guard let pv = passthroughView else { return }
        let area = NSTrackingArea(
            rect: pv.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        pv.addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        collapseTask?.cancel()
        collapseTask = nil
        notchState.isExpanded    = true
        passthroughView?.isExpanded = true
    }

    override func mouseExited(with event: NSEvent) {
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.notchState.isExpanded    = false
            self?.passthroughView?.isExpanded = false
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
