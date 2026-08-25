import Foundation

enum AppDeepLink: Equatable {
    static let scheme = "applyreadyvets"

    case applications
    case workspace
    case toolkit

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              url.user == nil,
              url.password == nil,
              url.query == nil,
              url.fragment == nil else {
            return nil
        }

        switch url.host?.lowercased() {
        case "applications":
            self = .applications
        case "workspace":
            self = .workspace
        case "toolkit":
            self = .toolkit
        default:
            return nil
        }
    }

}
