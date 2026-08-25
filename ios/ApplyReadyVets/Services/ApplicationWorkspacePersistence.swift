import CryptoKit
import Foundation

struct ApplicationWorkspaceLoadOutcome {
    let snapshot: ApplicationWorkspaceSnapshot
    let recoveredFromBackup: Bool
}

protocol ApplicationWorkspacePersisting {
    func load(id: UUID) throws -> ApplicationWorkspaceLoadOutcome?
    func save(_ snapshot: ApplicationWorkspaceSnapshot, id: UUID) throws
    func delete(id: UUID) throws
    func deleteAll() throws
}

struct ResilientApplicationWorkspaceStore: ApplicationWorkspacePersisting {
    enum StoreError: LocalizedError {
        case corruptWorkspace
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .corruptWorkspace:
                "This application workspace could not be read, and no valid recovery copy was available."
            case .verificationFailed:
                "This application workspace could not be verified after saving."
            }
        }
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let savedAt: Date
        let checksum: String
        let payload: Data
    }

    private let explicitDirectory: URL?
    private let fileManager: FileManager

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        explicitDirectory = directory
        self.fileManager = fileManager
    }

    func load(id: UUID) throws -> ApplicationWorkspaceLoadOutcome? {
        let urls = try storageURLs(for: id)
        if fileManager.fileExists(atPath: urls.primary.path) {
            do {
                return ApplicationWorkspaceLoadOutcome(
                    snapshot: try decodeSnapshot(at: urls.primary),
                    recoveredFromBackup: false
                )
            } catch {
                if fileManager.fileExists(atPath: urls.backup.path),
                   let recovered = try? decodeSnapshot(at: urls.backup) {
                    try quarantineCorruptPrimary(
                        urls.primary,
                        id: id,
                        in: urls.directory
                    )
                    let backupData = try Data(contentsOf: urls.backup)
                    try protectedWrite(backupData, to: urls.primary)
                    guard (try? decodeSnapshot(at: urls.primary)) != nil else {
                        throw StoreError.verificationFailed
                    }
                    return ApplicationWorkspaceLoadOutcome(
                        snapshot: recovered,
                        recoveredFromBackup: true
                    )
                }
                throw StoreError.corruptWorkspace
            }
        }

        if fileManager.fileExists(atPath: urls.backup.path) {
            let recovered = try decodeSnapshot(at: urls.backup)
            let backupData = try Data(contentsOf: urls.backup)
            try protectedWrite(backupData, to: urls.primary)
            return ApplicationWorkspaceLoadOutcome(
                snapshot: recovered,
                recoveredFromBackup: true
            )
        }
        return nil
    }

    func save(_ snapshot: ApplicationWorkspaceSnapshot, id: UUID) throws {
        let urls = try storageURLs(for: id)
        let payload = try JSONEncoder.applicationWorkspaceEncoder.encode(
            snapshot
        )
        let envelope = Envelope(
            schemaVersion: 1,
            savedAt: Date(),
            checksum: Self.checksum(payload),
            payload: payload
        )
        let encoded = try JSONEncoder.applicationWorkspaceEncoder.encode(
            envelope
        )

        if fileManager.fileExists(atPath: urls.primary.path),
           (try? decodeSnapshot(at: urls.primary)) != nil {
            let previous = try Data(contentsOf: urls.primary)
            try protectedWrite(previous, to: urls.backup)
        }

        try protectedWrite(encoded, to: urls.primary)
        guard (try? decodeSnapshot(at: urls.primary)) != nil else {
            throw StoreError.verificationFailed
        }
    }

    func delete(id: UUID) throws {
        let urls = try storageURLs(for: id)
        for url in [urls.primary, urls.backup]
        where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        let quarantinePrefix =
            "ApplyReadyVetsApplication.\(id.uuidString).corrupt."
        let contents = try fileManager.contentsOfDirectory(
            at: urls.directory,
            includingPropertiesForKeys: nil
        )
        for url in contents
        where url.lastPathComponent.hasPrefix(quarantinePrefix) {
            try fileManager.removeItem(at: url)
        }
    }

    func deleteAll() throws {
        let directory = try storageDirectory()
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for url in contents where
            url.lastPathComponent.hasPrefix("ApplyReadyVetsApplication.") {
            try fileManager.removeItem(at: url)
        }
    }

    private func storageURLs(
        for id: UUID
    ) throws -> (directory: URL, primary: URL, backup: URL) {
        let directory = try storageDirectory()
        let stem = "ApplyReadyVetsApplication.\(id.uuidString)"
        return (
            directory,
            directory.appendingPathComponent("\(stem).v1.json"),
            directory.appendingPathComponent("\(stem).backup.v1.json")
        )
    }

    private func storageDirectory() throws -> URL {
        if let explicitDirectory {
            try fileManager.createDirectory(
                at: explicitDirectory,
                withIntermediateDirectories: true
            )
            return explicitDirectory
        }
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(
            "ApplicationWorkspaces",
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func decodeSnapshot(
        at url: URL
    ) throws -> ApplicationWorkspaceSnapshot {
        let data = try Data(contentsOf: url)
        let envelope = try JSONDecoder.applicationWorkspaceDecoder.decode(
            Envelope.self,
            from: data
        )
        guard envelope.schemaVersion == 1,
              envelope.checksum == Self.checksum(envelope.payload) else {
            throw StoreError.corruptWorkspace
        }
        return try JSONDecoder.applicationWorkspaceDecoder.decode(
            ApplicationWorkspaceSnapshot.self,
            from: envelope.payload
        )
    }

    private func protectedWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func quarantineCorruptPrimary(
        _ primary: URL,
        id: UUID,
        in directory: URL
    ) throws {
        let quarantine = directory.appendingPathComponent(
            "ApplyReadyVetsApplication.\(id.uuidString).corrupt.\(UUID().uuidString).json"
        )
        try fileManager.moveItem(at: primary, to: quarantine)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: quarantine.path
        )
    }

    private static func checksum(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

private extension JSONEncoder {
    static var applicationWorkspaceEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var applicationWorkspaceDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
