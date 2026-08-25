import Foundation

enum AppReviewLinks {
    static var supportURL: URL? {
        validatedHTTPSURL(forInfoDictionaryKey: "APPLYREADYVETS_SUPPORT_URL")
    }

    static var privacyPolicyURL: URL? {
        validatedHTTPSURL(forInfoDictionaryKey: "APPLYREADYVETS_PRIVACY_POLICY_URL")
    }

    static func validatedHTTPSURL(
        forInfoDictionaryKey key: String,
        bundle: Bundle = .main
    ) -> URL? {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        return validatedHTTPSURL(rawValue)
    }

    static func validatedHTTPSURL(_ rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              components.user == nil,
              components.password == nil,
              let host = components.host?.lowercased(),
              !host.isEmpty,
              !Self.isDisallowedHost(host),
              components.fragment == nil,
              let url = components.url else {
            return nil
        }
        return url
    }

    private static func isDisallowedHost(_ host: String) -> Bool {
        if host == "localhost"
            || host == "0.0.0.0"
            || host == "::1"
            || host.hasPrefix("127.")
            || host.hasPrefix("10.")
            || host.hasPrefix("192.168.")
            || host.hasPrefix("169.254.")
            || host.hasPrefix("fc")
            || host.hasPrefix("fd")
            || host.hasPrefix("fe80:")
            || host.hasSuffix(".local")
            || host.hasSuffix(".internal")
            || host.hasSuffix(".example")
            || host.hasSuffix(".invalid")
            || host.hasSuffix(".test")
            || ["example.com", "example.org", "example.net"].contains(host) {
            return true
        }

        let octets = host.split(separator: ".").compactMap { Int($0) }
        if octets.count == 4, octets[0] == 172, (16...31).contains(octets[1]) {
            return true
        }
        return false
    }
}
