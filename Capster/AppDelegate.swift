//
//  AppDelegate.swift
//  Capster
//

import AppKit

/// Ensures the capture stream, camera session, and any in-progress recording are torn
/// down before the app quits.
///
/// Without this, quitting (Quit button, Cmd+Q, Dock, system logout) killed the process
/// immediately, leaving ScreenCaptureKit's `replayd` daemon holding the stream open -
/// screen sharing stayed active system-wide even after the app was gone.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: RecorderViewModel?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let viewModel, viewModel.isRecording || viewModel.hasContentSelected else {
            return .terminateNow
        }

        Task { @MainActor in
            if viewModel.isRecording {
                await viewModel.stopRecording()
            } else {
                await viewModel.resetSelection()
            }
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
