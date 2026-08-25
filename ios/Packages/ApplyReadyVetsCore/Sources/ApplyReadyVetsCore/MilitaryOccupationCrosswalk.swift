import Foundation

public enum MilitaryBranch: String, Codable, CaseIterable, Sendable, Identifiable {
    case army
    case marineCorps = "marine_corps"
    case navy
    case airForce = "air_force"
    case spaceForce = "space_force"
    case coastGuard = "coast_guard"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .army: "Army"
        case .marineCorps: "Marine Corps"
        case .navy: "Navy"
        case .airForce: "Air Force"
        case .spaceForce: "Space Force"
        case .coastGuard: "Coast Guard"
        }
    }

    public static func parse(_ value: String) -> MilitaryBranch? {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return switch normalized {
        case "army", "us army", "united states army": .army
        case "marine corps", "marines", "usmc": .marineCorps
        case "navy", "us navy", "united states navy": .navy
        case "air force", "usaf": .airForce
        case "space force", "ussf": .spaceForce
        case "coast guard", "uscg": .coastGuard
        default: nil
        }
    }
}

public struct ONETOccupationMatch: Codable, Hashable, Sendable, Identifiable {
    public let code: String
    public let title: String

    public var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code = "c"
        case title = "t"
    }
}

public struct MilitaryOccupationMapping: Codable, Hashable, Sendable, Identifiable {
    public let branch: MilitaryBranch
    public let militaryCode: String
    public let militaryTitle: String
    public let personnelCategory: String
    public let occupations: [ONETOccupationMatch]

    public var id: String {
        "\(branch.rawValue):\(militaryCode):\(militaryTitle):\(personnelCategory)"
    }

    public var personnelLabel: String {
        switch personnelCategory {
        case "E": "Enlisted"
        case "O": "Commissioned officer"
        case "W": "Warrant officer"
        default: "Military"
        }
    }

    enum CodingKeys: String, CodingKey {
        case branch = "b"
        case militaryCode = "c"
        case militaryTitle = "t"
        case personnelCategory = "p"
        case occupations = "o"
    }
}

public struct MilitaryCrosswalkMetadata: Codable, Hashable, Sendable {
    public let dataset: String
    public let sourceAgency: String
    public let publisher: String
    public let sourceURL: String
    public let sourceRelease: String
    public let sourceSHA256: String
    public let sourceRows: Int
    public let includedRecords: Int
    public let rules: String
    public let attribution: String
}

public struct MilitaryCrosswalkDataset: Codable, Sendable {
    public let metadata: MilitaryCrosswalkMetadata
    public let records: [MilitaryOccupationMapping]
}

public enum MilitaryOccupationSearch {
    public static let maximumQueryCharacters = 120
    public static let maximumResultLimit = 100

    public static func search(
        _ records: [MilitaryOccupationMapping],
        branch: MilitaryBranch?,
        query: String,
        limit: Int = 30
    ) -> [MilitaryOccupationMapping] {
        // Bound Unicode scalars before normalization so a single grapheme made
        // from thousands of combining marks cannot force unbounded work.
        let boundedQuery = String(
            query.unicodeScalars.prefix(maximumQueryCharacters)
        )
        let normalizedQuery = normalize(boundedQuery)
        guard !normalizedQuery.isEmpty, limit > 0 else { return [] }
        let boundedLimit = min(limit, maximumResultLimit)

        return records
            .lazy
            .filter { branch == nil || $0.branch == branch }
            .compactMap { record -> (Int, MilitaryOccupationMapping)? in
                let code = normalize(record.militaryCode)
                let title = normalize(record.militaryTitle)
                let score: Int
                if code == normalizedQuery {
                    score = 0
                } else if code.hasPrefix(normalizedQuery) {
                    score = 1
                } else if title.hasPrefix(normalizedQuery) {
                    score = 2
                } else if title.contains(normalizedQuery) || code.contains(normalizedQuery) {
                    score = 3
                } else {
                    return nil
                }
                return (score, record)
            }
            .sorted {
                if $0.0 != $1.0 { return $0.0 < $1.0 }
                if $0.1.militaryCode != $1.1.militaryCode {
                    return $0.1.militaryCode.localizedStandardCompare($1.1.militaryCode) == .orderedAscending
                }
                return $0.1.militaryTitle.localizedStandardCompare($1.1.militaryTitle) == .orderedAscending
            }
            .prefix(boundedLimit)
            .map(\.1)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .uppercased()
            .replacingOccurrences(of: #"[^A-Z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
