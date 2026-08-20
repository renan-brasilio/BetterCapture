//
//  HandBrakeInstallerService.swift
//  Capster
//

import Foundation
import OSLog

enum HandBrakeInstallError: LocalizedError {
    case brewNotFound
    case installFailed(Int32)
    case cliNotFoundAfterInstall

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew isn't installed. Install it from https://brew.sh, then try again."
        case .installFailed(let code):
            return "\"brew install handbrake\" exited with code \(code)."
        case .cliNotFoundAfterInstall:
            return "Homebrew finished, but HandBrakeCLI wasn't found afterward."
        }
    }
}

/// Runs `brew install handbrake` to get HandBrakeCLI onto the machine, so the user
/// doesn't have to leave Capster and use Terminal for first-time setup.
final class HandBrakeInstallerService {
    /// The two locations Homebrew installs `brew` itself to, depending on chip
    /// architecture. HandBrakeCLI ends up as a sibling in the same `bin/` directory.
    static let candidateBrewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    private let processRunner: ProcessRunning
    private let fileExists: (String) -> Bool
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Capster", category: "HandBrakeInstallerService")

    init(
        processRunner: ProcessRunning = SystemProcessRunner(),
        fileExists: @escaping (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) {
        self.processRunner = processRunner
        self.fileExists = fileExists
    }

    func locateBrew() -> URL? {
        Self.candidateBrewPaths.first(where: fileExists).map(URL.init(fileURLWithPath:))
    }

    /// Runs the install, streaming brew's output lines via `onOutputLine`, and returns
    /// the resulting HandBrakeCLI binary's URL on success.
    func install(onOutputLine: @escaping (String) -> Void) async throws -> URL {
        guard let brewURL = locateBrew() else { throw HandBrakeInstallError.brewNotFound }

        let exitCode = try await processRunner.run(
            executableURL: brewURL,
            arguments: ["install", "handbrake"],
            onOutputLine: onOutputLine
        )
        logger.info("brew install handbrake exited with code \(exitCode)")
        guard exitCode == 0 else { throw HandBrakeInstallError.installFailed(exitCode) }

        let cliURL = brewURL.deletingLastPathComponent().appending(path: "HandBrakeCLI")
        guard fileExists(cliURL.path(percentEncoded: false)) else {
            throw HandBrakeInstallError.cliNotFoundAfterInstall
        }
        return cliURL
    }
}
