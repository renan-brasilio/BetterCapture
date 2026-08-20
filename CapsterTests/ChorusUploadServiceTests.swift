//
//  ChorusUploadServiceTests.swift
//  CapsterTests
//

import Testing
import Foundation
@testable import Capster

struct ChorusUploadServiceTests {

    private func tempFileWithData() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try Data("fake video bytes".utf8).write(to: url)
        return url
    }

    @Test func emptyTokenThrowsWithoutCallingNetwork() async throws {
        let stub = StubHTTPUploading(result: .success((Data(), Self.response(status: 200))))
        let service = ChorusUploadService(session: stub)

        await #expect(throws: ChorusUploadError.self) {
            _ = try await service.upload(fileURL: try self.tempFileWithData(), token: "")
        }
        #expect(stub.callCount == 0)
    }

    @Test func successWithLinkParsesResult() async throws {
        let json = #"{"callId": "abc123", "url": "https://chorus.ai/calls/abc123"}"#
        let stub = StubHTTPUploading(result: .success((Data(json.utf8), Self.response(status: 200))))
        let service = ChorusUploadService(session: stub)

        let result = try await service.upload(fileURL: try tempFileWithData(), token: "tok")
        #expect(result.callID == "abc123")
        #expect(result.link == URL(string: "https://chorus.ai/calls/abc123"))
    }

    @Test func successWithoutLinkDoesNotThrow() async throws {
        let json = #"{"callId": "abc123"}"#
        let stub = StubHTTPUploading(result: .success((Data(json.utf8), Self.response(status: 200))))
        let service = ChorusUploadService(session: stub)

        let result = try await service.upload(fileURL: try tempFileWithData(), token: "tok")
        #expect(result.link == nil)
    }

    @Test func httpErrorStatusThrows() async throws {
        let stub = StubHTTPUploading(result: .success((Data(), Self.response(status: 401))))
        let service = ChorusUploadService(session: stub)

        await #expect(throws: ChorusUploadError.self) {
            _ = try await service.upload(fileURL: try self.tempFileWithData(), token: "tok")
        }
    }

    @Test func malformedJSONThrowsDecodingFailed() async throws {
        let stub = StubHTTPUploading(result: .success((Data("not json".utf8), Self.response(status: 200))))
        let service = ChorusUploadService(session: stub)

        await #expect(throws: ChorusUploadError.self) {
            _ = try await service.upload(fileURL: try self.tempFileWithData(), token: "tok")
        }
    }

    private static func response(status: Int) -> URLResponse {
        HTTPURLResponse(url: URL(string: "https://api.chorus.ai/v1/upload")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}

private final class StubHTTPUploading: HTTPUploading {
    private let result: Result<(Data, URLResponse), Error>
    private(set) var callCount = 0

    init(result: Result<(Data, URLResponse), Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1
        return try result.get()
    }
}
