//
//  ChorusUploadService.swift
//  Capster
//

import Foundation
import OSLog

enum ChorusUploadError: LocalizedError {
    case tokenNotConfigured
    case requestBuildFailed(Error)
    case networkError(Error)
    case httpError(statusCode: Int, body: String?)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .tokenNotConfigured:
            return "No Chorus.ai API token is configured. Set it in Settings > Automation."
        case .requestBuildFailed(let error):
            return "Failed to build the Chorus upload request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error while uploading to Chorus: \(error.localizedDescription)"
        case .httpError(let statusCode, let body):
            return "Chorus returned HTTP \(statusCode)\(body.map { ": \($0)" } ?? "")"
        case .decodingFailed(let error):
            return "Couldn't parse Chorus's response: \(error.localizedDescription)"
        }
    }
}

/// Abstracts the network call so tests can stub responses without hitting a real
/// network or requiring a real Chorus token.
protocol HTTPUploading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPUploading {}

struct ChorusUploadResult {
    /// The shareable Chorus link to show/copy, if the (guessed) response included one.
    let link: URL?
    /// Chorus's own call identifier, if present.
    let callID: String?
}

// MARK: - ⚠️ UNVERIFIED API CONTRACT ⚠️
//
// Chorus.ai's public upload endpoint could not be confirmed against real docs or a real
// token as of 2026-08-19 (api-docs.chorus.ai is JS-rendered and inaccessible in this
// environment). Everything below this line is a best-guess REST contract:
// `POST {baseURL}/upload` with `Authorization: Bearer <token>` and a multipart/form-data
// body containing the recording file. Replace `ChorusUploadRequestBuilder` and
// `ChorusUploadResponse` together, in this one place, once verified against a real
// token/response - nothing else in `ChorusUploadService` should need to change unless a
// new failure mode shows up (in which case add a `ChorusUploadError` case for it).

private enum ChorusUploadRequestBuilder {
    static let baseURL = URL(string: "https://api.chorus.ai/v1")!
    static let uploadPath = "/upload"

    static func buildRequest(fileURL: URL, token: String) throws -> URLRequest {
        let fileData = try Data(contentsOf: fileURL)

        var request = URLRequest(url: baseURL.appending(path: uploadPath))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(fileURL: fileURL, fileData: fileData, boundary: boundary)
        return request
    }

    private static func buildMultipartBody(fileURL: URL, fileData: Data, boundary: String) -> Data {
        var body = Data()
        func append(_ string: String) {
            body.append(string.data(using: .utf8) ?? Data())
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n")
        append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(fileData)
        append("\r\n--\(boundary)--\r\n")
        return body
    }
}

/// GUESS at Chorus's JSON response shape for a successful upload.
private struct ChorusUploadResponse: Decodable {
    let callId: String?
    let url: String?
}

final class ChorusUploadService {
    private let session: HTTPUploading
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Capster", category: "ChorusUploadService")

    init(session: HTTPUploading = URLSession.shared) {
        self.session = session
    }

    func upload(fileURL: URL, token: String) async throws -> ChorusUploadResult {
        guard !token.isEmpty else { throw ChorusUploadError.tokenNotConfigured }

        let request: URLRequest
        do {
            request = try ChorusUploadRequestBuilder.buildRequest(fileURL: fileURL, token: token)
        } catch {
            throw ChorusUploadError.requestBuildFailed(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ChorusUploadError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ChorusUploadError.httpError(statusCode: statusCode, body: String(data: data, encoding: .utf8))
        }

        let decoded: ChorusUploadResponse
        do {
            decoded = try JSONDecoder().decode(ChorusUploadResponse.self, from: data)
        } catch {
            throw ChorusUploadError.decodingFailed(error)
        }

        logger.info("Chorus upload succeeded")
        return ChorusUploadResult(link: decoded.url.flatMap(URL.init(string:)), callID: decoded.callId)
    }
}
