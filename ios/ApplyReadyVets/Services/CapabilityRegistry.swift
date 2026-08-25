import Foundation

enum ServiceEndpointKind: Equatable {
    case notConfigured
    case developmentLocal
    case secureRemote
    case insecureRemote

    var label: String {
        switch self {
        case .notConfigured: "Optional service not configured"
        case .developmentLocal: "Local development service"
        case .secureRemote: "Secure optional service"
        case .insecureRemote: "Insecure service blocked for release"
        }
    }

    var systemImage: String {
        switch self {
        case .notConfigured: "network.slash"
        case .developmentLocal: "desktopcomputer"
        case .secureRemote: "lock.shield.fill"
        case .insecureRemote: "exclamationmark.triangle.fill"
        }
    }
}

enum ServiceEndpointPolicy {
    static func classify(_ rawValue: String) -> ServiceEndpointKind {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .notConfigured
        }
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let rawHost = components.host,
              !rawHost.isEmpty,
              components.user == nil,
              components.password == nil,
              components.query == nil,
              components.fragment == nil else {
            return .insecureRemote
        }
        let host = rawHost.lowercased()
        if isDevelopmentHost(host) {
            return .developmentLocal
        }
        return scheme == "https" ? .secureRemote : .insecureRemote
    }

    private static func isDevelopmentHost(_ host: String) -> Bool {
        if ["localhost", "::1"].contains(host) || host.hasSuffix(".local") {
            return true
        }
        let octets = host.split(separator: ".").compactMap { Int($0) }
        if octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) {
            return octets[0] == 127 ||
                octets[0] == 10 ||
                (octets[0] == 172 && (16...31).contains(octets[1])) ||
                (octets[0] == 192 && octets[1] == 168) ||
                (octets[0] == 169 && octets[1] == 254) ||
                (octets[0] == 100 && (64...127).contains(octets[1]))
        }
        let normalizedIPv6 = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).lowercased()
        return normalizedIPv6 == "::1" ||
            normalizedIPv6.hasPrefix("fe80:") ||
            normalizedIPv6.hasPrefix("fc") && normalizedIPv6.contains(":") ||
            normalizedIPv6.hasPrefix("fd") && normalizedIPv6.contains(":") ||
            normalizedIPv6.hasPrefix("::ffff:127.")
    }
}

enum JobURLPolicy {
    static let maximumCharacters =
        CareerInputPolicy.Field.jobURL.maximumCharacters
    static let validationMessage =
        "Enter a valid HTTP or HTTPS job link without an embedded username or password."

    static func normalize(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maximumCharacters else {
            return nil
        }
        if !trimmed.contains("://"),
           trimmed.range(
               of: #"^[A-Za-z][A-Za-z0-9+.-]*:"#,
               options: .regularExpression
           ) != nil {
            return nil
        }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: candidate),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host?.isEmpty == false,
              components.user == nil,
              components.password == nil,
              let url = components.url else {
            return nil
        }
        let normalized = url.absoluteString
        guard normalized.count <= maximumCharacters else {
            return nil
        }
        return normalized
    }
}

struct CapabilitySnapshot {
    let serviceEndpoint: ServiceEndpointKind
    let deviceIntelligence: DeviceIntelligence

    static func current(serviceURL: String) -> CapabilitySnapshot {
        CapabilitySnapshot(
            serviceEndpoint: ServiceEndpointPolicy.classify(serviceURL),
            deviceIntelligence: DeviceIntelligence.current
        )
    }
}
