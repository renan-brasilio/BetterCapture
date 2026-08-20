//
//  HandBrakeInstallerServiceTests.swift
//  CapsterTests
//

import Testing
import Foundation
@testable import Capster

struct HandBrakeInstallerServiceTests {

    @Test func missingBrewThrows() async throws {
        let installer = HandBrakeInstallerService(
            processRunner: StubProcessRunnerForInstaller(exitCode: 0),
            fileExists: { _ in false }
        )

        await #expect(throws: HandBrakeInstallError.self) {
            _ = try await installer.install { _ in }
        }
    }

    @Test func successfulInstallReturnsCLIPath() async throws {
        let installer = HandBrakeInstallerService(
            processRunner: StubProcessRunnerForInstaller(exitCode: 0),
            fileExists: { path in path == "/opt/homebrew/bin/brew" || path == "/opt/homebrew/bin/HandBrakeCLI" }
        )

        let url = try await installer.install { _ in }
        #expect(url.path(percentEncoded: false) == "/opt/homebrew/bin/HandBrakeCLI")
    }

    @Test func nonZeroExitThrows() async throws {
        let installer = HandBrakeInstallerService(
            processRunner: StubProcessRunnerForInstaller(exitCode: 1),
            fileExists: { $0 == "/opt/homebrew/bin/brew" }
        )

        await #expect(throws: HandBrakeInstallError.self) {
            _ = try await installer.install { _ in }
        }
    }

    @Test func cliMissingAfterSuccessfulInstallThrows() async throws {
        let installer = HandBrakeInstallerService(
            processRunner: StubProcessRunnerForInstaller(exitCode: 0),
            fileExists: { $0 == "/opt/homebrew/bin/brew" }
        )

        await #expect(throws: HandBrakeInstallError.self) {
            _ = try await installer.install { _ in }
        }
    }
}

private final class StubProcessRunnerForInstaller: ProcessRunning {
    private let exitCode: Int32

    init(exitCode: Int32) {
        self.exitCode = exitCode
    }

    func run(executableURL: URL, arguments: [String], onOutputLine: @escaping (String) -> Void) async throws -> Int32 {
        onOutputLine("==> Installing handbrake")
        return exitCode
    }
}
