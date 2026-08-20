//
//  PostProcessingPanel.swift
//  Capster
//

import AppKit
import SwiftUI

// MARK: - Panel

/// A small titled, movable utility panel showing post-processing (transcode/upload) status.
private final class PostProcessingNSPanel: NSPanel {
    init(contentRect: CGRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        title = "Post-Processing"
        level = .floating
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
}

// MARK: - Coordinator

/// Manages the lifecycle of the post-processing status panel.
@MainActor
final class PostProcessingPanelCoordinator {

    private var panel: PostProcessingNSPanel?
    private weak var coordinator: PostProcessingCoordinator?
    private var closeObserver: NSObjectProtocol?

    /// Shows the panel, or brings an already-visible one to front.
    func show(coordinator: PostProcessingCoordinator) {
        if let existing = panel {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        self.coordinator = coordinator

        let newPanel = PostProcessingNSPanel(contentRect: CGRect(x: 0, y: 0, width: 360, height: 100))

        // NSHostingController + .intrinsicContentSize keeps the window's height in sync
        // with the SwiftUI content's actual height (2 rows vs. 1, error text wrapping,
        // the Chorus link row appearing) instead of a fixed size that leaves dead space.
        let hostingController = NSHostingController(rootView: PostProcessingPanelView(coordinator: coordinator) { [weak self] in
            self?.dismiss()
        })
        hostingController.sizingOptions = [.intrinsicContentSize]
        newPanel.contentViewController = hostingController
        newPanel.setContentSize(hostingController.view.fittingSize)
        newPanel.center()

        newPanel.makeKeyAndOrderFront(nil)
        panel = newPanel

        // The panel's standard close button closes the window directly rather than
        // going through `dismiss()`, so observe that to keep state in sync.
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.dismiss() }
        }
    }

    /// Dismisses the panel, cancelling the pipeline if it's still running.
    func dismiss() {
        guard let panel else { return }
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
            self.closeObserver = nil
        }
        panel.orderOut(nil)
        self.panel = nil
        coordinator?.cancel()
        coordinator = nil
    }
}
