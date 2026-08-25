import Foundation

struct SharedJobPayload: Codable, Identifiable, Sendable, Equatable {
    static let schemaVersion = 1
    static let maximumTextCharacters = 60_000
    static let maximumURLCharacters = 2_048

    let version: Int
    let id: UUID
    let createdAt: Date
    let sourceURL: String?
    let text: String?

    init(sourceURL: String?, text: String?) throws {
        try self.init(
            version: Self.schemaVersion,
            id: UUID(),
            createdAt: Date(),
            sourceURL: sourceURL,
            text: text
        )
    }

    private init(
        version: Int,
        id: UUID,
        createdAt: Date,
        sourceURL: String?,
        text: String?
    ) throws {
        guard version == Self.schemaVersion else {
            throw SharedJobInbox.InboxError.unsupportedPayload
        }

        let normalizedURL = try Self.normalizedURL(sourceURL)
        let normalizedText = try Self.normalizedText(text)
        guard normalizedURL != nil || normalizedText != nil else {
            throw SharedJobInbox.InboxError.emptyPayload
        }

        self.version = version
        self.id = id
        self.createdAt = createdAt
        self.sourceURL = normalizedURL
        self.text = normalizedText
    }

    func validated() throws -> SharedJobPayload {
        try SharedJobPayload(
            version: version,
            id: id,
            createdAt: createdAt,
            sourceURL: sourceURL,
            text: text
        )
    }

    private static func normalizedURL(_ rawValue: String?) throws -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= maximumURLCharacters,
              let components = URLComponents(string: trimmed),
              ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              components.host?.isEmpty == false,
              components.user == nil,
              components.password == nil,
              let url = components.url else {
            throw SharedJobInbox.InboxError.unsafeURL
        }
        let normalized = url.absoluteString
        guard normalized.count <= maximumURLCharacters else {
            throw SharedJobInbox.InboxError.unsafeURL
        }
        return normalized
    }

    private static func normalizedText(_ rawValue: String?) throws -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= maximumTextCharacters else {
            throw SharedJobInbox.InboxError.payloadTooLarge
        }
        return trimmed
    }
}

enum SharedJobInbox {
    static let appGroupIdentifier = "group.com.jonathanhogue.applyreadyvets"
    static let maximumPendingItems = 20
    static let maximumPayloadBytes = 300_000

    enum InboxError: LocalizedError, Equatable {
        case appGroupUnavailable
        case emptyPayload
        case unsafeURL
        case unsupportedPayload
        case payloadTooLarge
        case inboxFull

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                "The shared ApplyReady Vets inbox is unavailable. Confirm the App Group signing capability."
            case .emptyPayload:
                "No readable job URL or text was shared."
            case .unsafeURL:
                "The shared link must be a normal HTTP or HTTPS address without embedded credentials."
            case .unsupportedPayload:
                "The shared item uses an unsupported format."
            case .payloadTooLarge:
                "The shared job item is too large. Copy only the job posting text or link."
            case .inboxFull:
                "The shared inbox is full. Open ApplyReady Vets before saving more job postings."
            }
        }
    }

    static func enqueue(
        _ payload: SharedJobPayload,
        directoryOverride: URL? = nil
    ) throws {
        let payload = try payload.validated()
        let directory = try inboxDirectory(override: directoryOverride)
        let existing = try payloadFiles(in: directory)
        guard existing.count < maximumPendingItems else {
            throw InboxError.inboxFull
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(payload)
        guard data.count <= maximumPayloadBytes else {
            throw InboxError.payloadTooLarge
        }

        let destination = directory.appendingPathComponent(
            "SharedJob-\(payload.id.uuidString).json"
        )
        try data.write(to: destination, options: [.atomic, .completeFileProtection])
    }

    static func pending(
        directoryOverride: URL? = nil
    ) throws -> [SharedJobPayload] {
        let directory = try inboxDirectory(override: directoryOverride)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var result: [SharedJobPayload] = []

        for file in try payloadFiles(in: directory) {
            do {
                let data = try Data(contentsOf: file)
                guard data.count <= maximumPayloadBytes else {
                    throw InboxError.payloadTooLarge
                }
                let payload = try decoder.decode(SharedJobPayload.self, from: data)
                result.append(try payload.validated())
            } catch {
                try quarantine(file, in: directory)
            }
        }
        return result.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.createdAt < $1.createdAt
        }
    }

    static func acknowledge(
        _ id: UUID,
        directoryOverride: URL? = nil
    ) throws {
        let directory = try inboxDirectory(override: directoryOverride)
        let file = directory.appendingPathComponent("SharedJob-\(id.uuidString).json")
        if FileManager.default.fileExists(atPath: file.path) {
            try FileManager.default.removeItem(at: file)
        }
    }

    static func deleteAll(directoryOverride: URL? = nil) throws {
        let directory = try inboxDirectory(override: directoryOverride)
        for file in try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            try FileManager.default.removeItem(at: file)
        }
    }

    private static func inboxDirectory(override: URL?) throws -> URL {
        let root: URL
        if let override {
            root = override
        } else {
            guard let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            ) else {
                throw InboxError.appGroupUnavailable
            }
            root = container.appendingPathComponent("IncomingJobs", isDirectory: true)
        }
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        return root
    }

    private static func payloadFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter {
            $0.lastPathComponent.hasPrefix("SharedJob-") &&
                $0.pathExtension.lowercased() == "json"
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func quarantine(_ file: URL, in directory: URL) throws {
        let quarantine = directory.appendingPathComponent(
            "CorruptSharedJob-\(UUID().uuidString).quarantine"
        )
        try FileManager.default.moveItem(at: file, to: quarantine)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: quarantine.path
        )
    }
}
