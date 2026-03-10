import AppKit
import SwiftUI

final class NotchWindowController: NSWindowController {

    static let panelWidth:      CGFloat = 480
    static let panelHeight:     CGFloat = 182
    static let collapsedWidth:  CGFloat = 162
    static let collapsedHeight: CGFloat = 32

    private let collapseDelay: TimeInterval = 0.4

    let notchState = NotchState()

    // MARK: - PassthroughView

    /// Wraps NSHostingView so that clicks outside the pill pass through to the
    /// menu bar when the panel is not expanded.  Also handles the pill click
    /// that triggers the full expansion.
    private final class PassthroughView: NSView {
        var isExpanded = false
        var onPillClick: (() -> Void)?

        private let pillW = NotchWindowController.collapsedWidth
        private let pillH = NotchWindowController.collapsedHeight

        /// Pill rect in this view's coordinate space (AppKit, y-up).
        var pillRect: NSRect {
            NSRect(
                x: (bounds.width  - pillW) / 2,
                y:  bounds.height - pillH,
                width:  pillW,
                height: pillH
            )
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard !isExpanded else { return super.hitTest(point) }
            return pillRect.contains(point) ? super.hitTest(point) : nil
        }

        override func mouseDown(with event: NSEvent) {
            if !isExpanded {
                onPillClick?()
            } else {
                super.mouseDown(with: event)
            }
        }
    }

    private weak var passthroughView: PassthroughView?

    // MARK: - Tracking areas

    private var pillTrackingArea:  NSTrackingArea?
    private var panelTrackingArea: NSTrackingArea?

    // MARK: - Global click monitor (collapse on outside click)

    private var globalClickMonitor: Any?
    private var collapseTask: DispatchWorkItem?

    // MARK: - Init

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

        let pv = PassthroughView()
        pv.wantsLayer = true
        pv.layer?.backgroundColor = .clear
        window.contentView = pv
        passthroughView = pv

        let hostingView = NSHostingView(
            rootView: NotchContainerView(state: notchState).ignoresSafeArea()
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        hostingView.frame = pv.bounds
        hostingView.autoresizingMask = [.width, .height]
        pv.addSubview(hostingView)

        pv.onPillClick = { [weak self] in self?.expand() }

        setupPillTrackingArea()

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
        let y = sh - panelHeight + 7
        return NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
    }

    // MARK: - Tracking areas

    private func setupPillTrackingArea() {
        guard let pv = passthroughView else { return }
        if let old = pillTrackingArea { pv.removeTrackingArea(old) }

        let area = NSTrackingArea(
            rect: pv.pillRect,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: ["zone": "pill"]
        )
        pv.addTrackingArea(area)
        pillTrackingArea = area
    }

    private func addPanelTrackingArea() {
        guard let pv = passthroughView, panelTrackingArea == nil else { return }
        let rect = NSRect(x: 0, y: 0, width: NotchWindowController.panelWidth,
                                          height: NotchWindowController.panelHeight)
        let area = NSTrackingArea(
            rect: rect,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: ["zone": "panel"]
        )
        pv.addTrackingArea(area)
        panelTrackingArea = area
    }

    private func removePanelTrackingArea() {
        guard let pv = passthroughView, let area = panelTrackingArea else { return }
        pv.removeTrackingArea(area)
        panelTrackingArea = nil
    }

    // MARK: - Mouse events

    override func mouseEntered(with event: NSEvent) {
        let zone = event.trackingArea?.userInfo?["zone"] as? String
        if zone == "pill", notchState.display != .expanded {
            notchState.display = .hovered
        }
        // Entering the panel area while expanded — cancel any pending collapse
        if zone == "panel" {
            collapseTask?.cancel()
            collapseTask = nil
        }
    }

    override func mouseExited(with event: NSEvent) {
        let zone = event.trackingArea?.userInfo?["zone"] as? String
        if zone == "pill", notchState.display == .hovered {
            notchState.display = .collapsed
        }
        if zone == "panel", notchState.display == .expanded {
            scheduleCollapse()
        }
    }

    // MARK: - Expand / Collapse

    private func expand() {
        collapseTask?.cancel()
        collapseTask = nil
        notchState.display = .expanded
        passthroughView?.isExpanded = true
        addPanelTrackingArea()
        startGlobalClickMonitor()
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.collapse() }
        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + collapseDelay, execute: task)
    }

    private func collapse() {
        collapseTask?.cancel()
        collapseTask = nil
        notchState.display = .collapsed
        passthroughView?.isExpanded = false
        removePanelTrackingArea()
        stopGlobalClickMonitor()
        // Restore pill hover tracking in case mouse is still near the notch
        setupPillTrackingArea()
    }

    // MARK: - Global click monitor

    private func startGlobalClickMonitor() {
        guard globalClickMonitor == nil else { return }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self, self.notchState.display == .expanded else { return }
            DispatchQueue.main.async { self.collapse() }
        }
    }

    private func stopGlobalClickMonitor() {
        if let m = globalClickMonitor { NSEvent.removeMonitor(m) }
        globalClickMonitor = nil
    }

    // MARK: - Screen change

    @objc private func screenConfigChanged() {
        guard let screen = NSScreen.main, let window else { return }
        window.setFrame(NotchWindowController.panelFrame(for: screen), display: true)
        setupPillTrackingArea()
    }
}
