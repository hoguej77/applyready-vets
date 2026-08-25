import Foundation
import XCTest
@testable import ApplyReadyVets

final class APIClientSecurityTests: XCTestCase {
    override func tearDown() {
        APIClientStubURLProtocol.reset()
        super.tearDown()
    }

    func testDefaultConfigurationDoesNotPersistServiceData() {
        let configuration = APIClient.ephemeralConfiguration()

        XCTAssertNil(configuration.urlCache)
        XCTAssertNil(configuration.httpCookieStorage)
        XCTAssertFalse(configuration.httpShouldSetCookies)
        XCTAssertNil(configuration.urlCredentialStorage)
        XCTAssertEqual(configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertFalse(configuration.waitsForConnectivity)
    }

    func testRedirectPolicyAllowsOnlySameOriginWithoutCredentials() throws {
        let origin = try XCTUnwrap(URL(string: "https://service.applyready.example/v1/health"))

        XCTAssertTrue(APIClient.isAllowedRedirect(
            from: origin,
            to: try XCTUnwrap(URL(string: "https://service.applyready.example:443/v2/health"))
        ))
        XCTAssertFalse(APIClient.isAllowedRedirect(
            from: origin,
            to: try XCTUnwrap(URL(string: "http://service.applyready.example/v2/health"))
        ))
        XCTAssertFalse(APIClient.isAllowedRedirect(
            from: origin,
            to: try XCTUnwrap(URL(string: "https://other.example/v2/health"))
        ))
        XCTAssertFalse(APIClient.isAllowedRedirect(
            from: origin,
            to: try XCTUnwrap(URL(string: "https://user:password@service.applyready.example/v2/health"))
        ))
        XCTAssertFalse(APIClient.isAllowedRedirect(
            from: origin,
            to: try XCTUnwrap(URL(string: "https://service.applyready.example:8443/v2/health"))
        ))
    }

    func testServerMessagesAreRedactedNormalizedAndBounded() throws {
        let secret = "super-secret-bearer-token"
        let detail = """
        <strong>Remote failure</strong>
        \(secret) \u{202E}\(String(repeating: "x", count: 400))
        """
        let body = try JSONSerialization.data(withJSONObject: ["detail": detail])

        let message = APIClient.sanitizedServerMessage(
            from: body,
            contentType: "application/json",
            secrets: [secret]
        )

        XCTAssertTrue(message.contains("Remote failure"))
        XCTAssertTrue(message.contains("[redacted]"))
        XCTAssertFalse(message.contains(secret))
        XCTAssertFalse(message.contains("<strong>"))
        XCTAssertFalse(message.contains("\n"))
        XCTAssertFalse(message.contains("\u{202E}"))
        XCTAssertLessThanOrEqual(message.count, APIClient.maximumServerMessageCharacters)
        XCTAssertTrue(message.hasSuffix("…"))
    }

    func testUnstructuredHTMLServerBodyIsNotShownToTheUser() {
        let message = APIClient.sanitizedServerMessage(
            from: Data("<html><body>proxy internals</body></html>".utf8),
            contentType: "text/html"
        )

        XCTAssertEqual(message, "The service returned an error.")
    }

    func testInjectedSessionHandlesValidJSONWithoutSharedSession() async throws {
        APIClientStubURLProtocol.install(
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            data: Data(Self.healthJSON.utf8)
        )
        let client = makeStubbedClient()

        let response = try await client.health()

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.version, "test")
        XCTAssertTrue(response.truthLock)
    }

    func testDeclaredOversizedResponseIsRejectedBeforeDecode() async {
        APIClientStubURLProtocol.install(
            statusCode: 200,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(APIClient.maximumJSONResponseBytes + 1)",
            ],
            data: Data()
        )
        let client = makeStubbedClient()

        do {
            _ = try await client.health()
            XCTFail("Expected responseTooLarge")
        } catch APIClient.ClientError.responseTooLarge {
            // Expected.
        } catch {
            XCTFail("Expected responseTooLarge, got \(error)")
        }
    }

    func testServerErrorUsesSanitizedMessage() async throws {
        let token = "token-that-must-not-be-shown"
        let body = try JSONSerialization.data(withJSONObject: [
            "detail": "<b>Invalid request</b>\n\(token)",
        ])
        APIClientStubURLProtocol.install(
            statusCode: 422,
            headers: ["Content-Type": "application/json"],
            data: body
        )
        let client = makeStubbedClient(bearerToken: token)

        do {
            _ = try await client.health()
            XCTFail("Expected server error")
        } catch let APIClient.ClientError.server(code, message) {
            XCTAssertEqual(code, 422)
            XCTAssertEqual(message, "Invalid request [redacted]")
            XCTAssertFalse(message.contains(token))
        } catch {
            XCTFail("Expected sanitized server error, got \(error)")
        }
    }

    func testCancellingCallerCancelsServiceRequest() async {
        let started = expectation(description: "URL loading started")
        APIClientStubURLProtocol.install(
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            data: Data(Self.healthJSON.utf8),
            delay: 5,
            onStart: { started.fulfill() }
        )
        let client = makeStubbedClient()
        let requestTask = Task {
            try await client.health()
        }
        await fulfillment(of: [started], timeout: 1)

        requestTask.cancel()

        do {
            _ = try await requestTask.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    private func makeStubbedClient(bearerToken: String = "") -> APIClient {
        let configuration = APIClient.ephemeralConfiguration()
        configuration.protocolClasses = [APIClientStubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return APIClient(
            baseURL: "https://service.applyready.example",
            bearerToken: bearerToken,
            session: session
        )
    }

    private static let healthJSON = """
    {
      "status": "ok",
      "version": "test",
      "ai_configured": false,
      "ai_model": null,
      "ai_provider": null,
      "on_device_ai_available": true,
      "openai_fallback_available": false,
      "truth_lock": true,
      "features": []
    }
    """
}

private final class APIClientStubURLProtocol: URLProtocol, @unchecked Sendable {
    private struct Stub {
        let statusCode: Int
        let headers: [String: String]
        let data: Data
        let delay: TimeInterval
        let onStart: (() -> Void)?
    }

    nonisolated(unsafe) private static var stub: Stub?
    private static let lock = NSLock()
    private var delivery: DispatchWorkItem?

    static func install(
        statusCode: Int,
        headers: [String: String],
        data: Data,
        delay: TimeInterval = 0,
        onStart: (() -> Void)? = nil
    ) {
        lock.withLock {
            stub = Stub(
                statusCode: statusCode,
                headers: headers,
                data: data,
                delay: delay,
                onStart: onStart
            )
        }
    }

    static func reset() {
        lock.withLock {
            stub = nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let stub = Self.lock.withLock({ Self.stub }),
              let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: stub.statusCode,
                  httpVersion: "HTTP/1.1",
                  headerFields: stub.headers
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        stub.onStart?()
        let delivery = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
            if !stub.data.isEmpty {
                self.client?.urlProtocol(self, didLoad: stub.data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        self.delivery = delivery
        if stub.delay > 0 {
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + stub.delay,
                execute: delivery
            )
        } else {
            delivery.perform()
        }
    }

    override func stopLoading() {
        delivery?.cancel()
        delivery = nil
    }
}
