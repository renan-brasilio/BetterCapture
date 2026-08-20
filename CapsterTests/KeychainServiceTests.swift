//
//  KeychainServiceTests.swift
//  CapsterTests
//

import Testing
import Foundation
@testable import Capster

/// Tests against the real Keychain, using a unique `service` string per test so runs
/// never collide with each other or with the app's real stored token.
struct KeychainServiceTests {

    private func makeService() -> KeychainService {
        KeychainService(service: "com.renanfamous.CapsterTests.\(UUID().uuidString)")
    }

    @Test func readingMissingKeyReturnsNil() {
        let keychain = makeService()
        #expect(keychain.readString(key: "missing") == nil)
    }

    @Test func saveThenReadRoundTrips() throws {
        let keychain = makeService()
        try keychain.saveString("secret-value", key: "token")
        #expect(keychain.readString(key: "token") == "secret-value")
    }

    @Test func savingTwiceOverwritesRatherThanDuplicating() throws {
        let keychain = makeService()
        try keychain.saveString("first", key: "token")
        try keychain.saveString("second", key: "token")
        #expect(keychain.readString(key: "token") == "second")
    }

    @Test func deleteThenReadReturnsNil() throws {
        let keychain = makeService()
        try keychain.saveString("secret-value", key: "token")
        try keychain.deleteString(key: "token")
        #expect(keychain.readString(key: "token") == nil)
    }

    @Test func deletingMissingKeyDoesNotThrow() throws {
        let keychain = makeService()
        try keychain.deleteString(key: "never-existed")
    }
}
