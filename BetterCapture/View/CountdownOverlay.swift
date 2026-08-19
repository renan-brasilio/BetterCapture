//
//  CountdownOverlay.swift
//  BetterCapture
//

import AppKit
import SwiftUI

/// A borderless, click-through panel covering a single screen for the countdown overlay.
private final class CountdownPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
    }
}

/// Drives the number shown by the countdown overlay.
@MainActor
@Observable
final class CountdownState {
    var secondsRemaining: Int
    init(secondsRemaining: Int) {
        self.secondsRemaining = secondsRemaining
    }
}

/// Shows a full-screen countdown before a recording starts, so the user has a moment to
/// get ready before the capture actually begins.
@MainActor
final class CountdownOverlay {

    private var panel: CountdownPanel?

    /// Shows the countdown on the given screen and suspends until it finishes.
    /// - Parameters:
    ///   - seconds: How many whole seconds to count down from.
    ///   - screen: The screen to display the countdown on.
    func run(seconds: Int, on screen: NSScreen) async {
        guard seconds > 0 else { return }

        let state = CountdownState(secondsRemaining: seconds)
        let panel = CountdownPanel(screen: screen)
        panel.contentView = NSHostingView(rootView: CountdownOverlayView(state: state))
        panel.orderFrontRegardless()
        self.panel = panel

        for remaining in stride(from: seconds, through: 1, by: -1) {
            state.secondsRemaining = remaining
            try? await Task.sleep(for: .seconds(1))
        }

        dismiss()
    }

    /// Dismisses the countdown early.
    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}

// MARK: - View

private struct CountdownOverlayView: View {
    let state: CountdownState

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)

            VStack(spacing: 12) {
                Text("\(state.secondsRemaining)")
                    .font(.system(size: 180, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 20)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeOut(duration: 0.3), value: state.secondsRemaining)

                Text("Recording starting, get ready")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
        }
        .ignoresSafeArea()
    }
}
