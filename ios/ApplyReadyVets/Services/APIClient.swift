import Foundation

struct APIClient: Sendable {
    enum ClientError: LocalizedError {
        case invalidBaseURL
        case developmentEndpointBlocked
        case insecureEndpointBlocked
        case redirectBlocked
        case requestTooLarge
        case responseTooLarge
        case invalidResponse
        case server(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL: "The service address is invalid. Check Settings."
            case .developmentEndpointBlocked:
                "A local development service cannot be used in the App Store build."
            case .insecureEndpointBlocked:
                "The optional service was blocked because it does not use a secure HTTPS address."
            case .redirectBlocked:
                "The optional service tried to redirect the request to a different or less secure address."
            case .requestTooLarge:
                "The request is larger than the app's safe processing limit."
            case .responseTooLarge:
                "The optional service returned more data than the app can process safely."
            case .invalidResponse: "The service returned an unreadable response."
            case let .server(code, message): "Service error \(code): \(message)"
            }
        }
    }

    let baseURL: String
    let bearerToken: String
    private let session: URLSession
    static let maximumJSONResponseBytes = 2 * 1_024 * 1_024
    static let maximumExportResponseBytes = 50 * 1_024 * 1_024
    static let maximumUploadBytes = 20 * 1_024 * 1_024
    static let maximumMultipartOverheadBytes = 64 * 1_024
    static let maximumJSONRequestBytes = 8 * 1_024 * 1_024
    static let maximumServerMessageCharacters = 240

    init(
        baseURL: String,
        bearerToken: String,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.session = session ?? URLSession(configuration: Self.ephemeralConfiguration())
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func health() async throws -> HealthResponse {
        try await send(path: "/v1/health", method: "GET", body: Optional<String>.none)
    }

    func analyze(_ request: TailorRequest) async throws -> TailorResponse {
        try await send(path: "/v1/analyze", method: "POST", body: request)
    }

    func linkedin(_ request: ExportRequest) async throws -> LinkedInProfileKit {
        try await send(path: "/v1/linkedin", method: "POST", body: request)
    }

    func extractURL(_ url: String) async throws -> DocumentExtraction {
        try await send(path: "/v1/extract-url", method: "POST", body: ["url": url])
    }

    func extract(data: Data, filename: String) async throws -> DocumentExtraction {
        guard data.count <= Self.maximumUploadBytes else {
            throw ClientError.requestTooLarge
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        let safeFilename = Self.sanitizedUploadFilename(filename)
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeFilename)\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")
        guard body.count <= Self.maximumUploadBytes + Self.maximumMultipartOverheadBytes else {
            throw ClientError.requestTooLarge
        }

        var request = try request(path: "/v1/extract", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (responseData, response) = try await boundedData(
            for: request,
            maximumBytes: Self.maximumJSONResponseBytes
        )
        try check(response, data: responseData)
        return try decoder.decode(DocumentExtraction.self, from: responseData)
    }

    func export(_ exportRequest: ExportRequest) async throws -> URL {
        var request = try request(path: "/v1/export", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encodedJSONBody(exportRequest)
        let (data, response) = try await boundedData(
            for: request,
            maximumBytes: Self.maximumExportResponseBytes
        )
        try check(response, data: data)
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("ApplyReadyVets_Application_Packet_\(UUID().uuidString.prefix(8)).zip")
        try data.write(to: destination, options: [.atomic, .completeFileProtection])
        return destination
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body?
    ) async throws -> Response {
        var request = try request(path: path, method: method)
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encodedJSONBody(body)
        }
        let (data, response) = try await boundedData(
            for: request,
            maximumBytes: Self.maximumJSONResponseBytes
        )
        try check(response, data: data)
        return try decoder.decode(Response.self, from: data)
    }

    private func request(path: String, method: String) throws -> URLRequest {
        switch ServiceEndpointPolicy.classify(baseURL) {
        case .secureRemote:
            break
        case .developmentLocal:
#if DEBUG
            break
#else
            throw ClientError.developmentEndpointBlocked
#endif
        case .notConfigured:
            throw ClientError.invalidBaseURL
        case .insecureRemote:
            throw ClientError.insecureEndpointBlocked
        }
        guard let base = URL(string: baseURL), let url = URL(string: path, relativeTo: base) else {
            throw ClientError.invalidBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func encodedJSONBody<Body: Encodable>(_ body: Body) throws -> Data {
        let data = try encoder.encode(body)
        guard data.count <= Self.maximumJSONRequestBytes else {
            throw ClientError.requestTooLarge
        }
        return data
    }

    static func ephemeralConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        return configuration
    }

    static func isAllowedRedirect(from sourceURL: URL, to destinationURL: URL) -> Bool {
        guard destinationURL.user == nil,
              destinationURL.password == nil,
              let sourceScheme = sourceURL.scheme?.lowercased(),
              let destinationScheme = destinationURL.scheme?.lowercased(),
              ["http", "https"].contains(sourceScheme),
              sourceScheme == destinationScheme,
              sourceURL.host?.lowercased() == destinationURL.host?.lowercased(),
              effectivePort(for: sourceURL) == effectivePort(for: destinationURL) else {
            return false
        }
        return true
    }

    static func sanitizedServerMessage(
        from data: Data,
        contentType: String?,
        secrets: [String] = []
    ) -> String {
        var candidate: String?
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            candidate = object["detail"] as? String ?? object["message"] as? String
        }
        if candidate == nil,
           contentType?.lowercased().hasPrefix("text/plain") == true {
            candidate = String(data: data, encoding: .utf8)
        }

        var redacted = candidate ?? ""
        for secret in secrets where secret.count >= 4 {
            redacted = redacted.replacingOccurrences(of: secret, with: "[redacted]")
        }

        var output = ""
        var insideMarkup = false
        var needsSpace = false
        for scalar in redacted.unicodeScalars {
            if scalar == "<" {
                insideMarkup = true
                needsSpace = !output.isEmpty
                continue
            }
            if scalar == ">", insideMarkup {
                insideMarkup = false
                continue
            }
            guard !insideMarkup else { continue }

            let shouldCollapse: Bool
            switch scalar.properties.generalCategory {
            case .control, .format, .lineSeparator, .paragraphSeparator:
                shouldCollapse = true
            default:
                shouldCollapse = CharacterSet.whitespacesAndNewlines.contains(scalar)
            }
            if shouldCollapse {
                needsSpace = !output.isEmpty
                continue
            }
            if needsSpace {
                output.append(" ")
                needsSpace = false
            }
            output.append(Character(scalar))
        }

        let normalized = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return "The service returned an error."
        }
        guard normalized.count > maximumServerMessageCharacters else {
            return normalized
        }
        return String(normalized.prefix(maximumServerMessageCharacters - 1)) + "…"
    }

    private func boundedData(
        for request: URLRequest,
        maximumBytes: Int
    ) async throws -> (Data, URLResponse) {
        try Task.checkCancellation()
        guard let originalURL = request.url else {
            throw ClientError.invalidBaseURL
        }

        do {
            let redirectDelegate = RestrictedRedirectDelegate(originalURL: originalURL)
            let (bytes, response) = try await session.bytes(
                for: request,
                delegate: redirectDelegate
            )
            let expectedLength = response.expectedContentLength
            if expectedLength > Int64(maximumBytes) {
                throw ClientError.responseTooLarge
            }

            var result = Data()
            if expectedLength > 0 {
                result.reserveCapacity(Int(expectedLength))
            }
            var pending = [UInt8]()
            pending.reserveCapacity(16 * 1_024)
            var receivedBytes = 0

            for try await byte in bytes {
                if receivedBytes >= maximumBytes {
                    throw ClientError.responseTooLarge
                }
                if receivedBytes.isMultiple(of: 4_096) {
                    try Task.checkCancellation()
                }
                pending.append(byte)
                receivedBytes += 1
                if pending.count == 16 * 1_024 {
                    result.append(contentsOf: pending)
                    pending.removeAll(keepingCapacity: true)
                }
            }
            result.append(contentsOf: pending)
            try Task.checkCancellation()
            return (result, response)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
    }

    private func check(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        if (300..<400).contains(http.statusCode) {
            throw ClientError.redirectBlocked
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = Self.sanitizedServerMessage(
                from: data,
                contentType: http.value(forHTTPHeaderField: "Content-Type"),
                secrets: [bearerToken]
            )
            throw ClientError.server(http.statusCode, message)
        }
    }

    private static func effectivePort(for url: URL) -> Int? {
        if let port = url.port {
            return port
        }
        switch url.scheme?.lowercased() {
        case "http": return 80
        case "https": return 443
        default: return nil
        }
    }

    private static func sanitizedUploadFilename(_ filename: String) -> String {
        let lastComponent = URL(fileURLWithPath: filename).lastPathComponent
        let sanitized = lastComponent
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "\r", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
        let bounded = String(sanitized.prefix(200))
        return bounded.isEmpty ? "document" : bounded
    }
}

private final class RestrictedRedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let originalURL: URL

    init(originalURL: URL) {
        self.originalURL = originalURL
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let destinationURL = request.url,
              APIClient.isAllowedRedirect(from: originalURL, to: destinationURL) else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8) ?? Data())
    }
}
