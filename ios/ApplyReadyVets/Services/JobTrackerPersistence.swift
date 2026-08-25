import CryptoKit
import Foundation

struct JobTrackerLoadOutcome {
    let records: [JobApplicationRecord]
    let recoveredFromBackup: Bool
}

protocol JobTrackerPersisting {
    func load() throws -> JobTrackerLoadOutcome?
    func save(_ records: [JobApplicationRecord]) throws
    func delete() throws
}

struct ResilientJobTrackerStore: JobTrackerPersisting {
    enum StoreError: LocalizedError {
        case corruptTracker
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .corruptTracker:
                "The application tracker could not be read, and no valid recovery copy was available."
            case .verificationFailed:
                "The application tracker could not be verified after saving."
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

    func load() throws -> JobTrackerLoadOutcome? {
        let urls = try storageURLs()
        if fileManager.fileExists(atPath: urls.primary.path) {
            do {
                return JobTrackerLoadOutcome(
                    records: try decodeRecords(at: urls.primary),
                    recoveredFromBackup: false
                )
            } catch {
                if fileManager.fileExists(atPath: urls.backup.path),
                   let recovered = try? decodeRecords(at: urls.backup) {
                    try quarantineCorruptPrimary(urls.primary, in: urls.directory)
                    let backupData = try Data(contentsOf: urls.backup)
                    try protectedWrite(backupData, to: urls.primary)
                    guard (try? decodeRecords(at: urls.primary)) != nil else {
                        throw StoreError.verificationFailed
                    }
                    return JobTrackerLoadOutcome(records: recovered, recoveredFromBackup: true)
                }
                throw StoreError.corruptTracker
            }
        }

        if fileManager.fileExists(atPath: urls.backup.path) {
            let recovered = try decodeRecords(at: urls.backup)
            let backupData = try Data(contentsOf: urls.backup)
            try protectedWrite(backupData, to: urls.primary)
            return JobTrackerLoadOutcome(records: recovered, recoveredFromBackup: true)
        }
        return nil
    }

    func save(_ records: [JobApplicationRecord]) throws {
        let urls = try storageURLs()
        let payload = try Self.encoder.encode(records)
        let envelope = Envelope(
            schemaVersion: 1,
            savedAt: Date(),
            checksum: Self.checksum(payload),
            payload: payload
        )
        let encoded = try Self.encoder.encode(envelope)

        if fileManager.fileExists(atPath: urls.primary.path),
           (try? decodeRecords(at: urls.primary)) != nil {
            try protectedWrite(Data(contentsOf: urls.primary), to: urls.backup)
        }

        try protectedWrite(encoded, to: urls.primary)
        guard (try? decodeRecords(at: urls.primary)) != nil else {
            throw StoreError.verificationFailed
        }
    }

    func delete() throws {
        let urls = try storageURLs()
        for url in [urls.primary, urls.backup] where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        let contents = try fileManager.contentsOfDirectory(
            at: urls.directory,
            includingPropertiesForKeys: nil
        )
        for url in contents where url.lastPathComponent.hasPrefix("ApplyReadyVetsJobTracker.corrupt.") {
            try fileManager.removeItem(at: url)
        }
    }

    private func storageURLs() throws -> (directory: URL, primary: URL, backup: URL) {
        let directory: URL
        if let explicitDirectory {
            directory = explicitDirectory
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } else {
            directory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        return (
            directory,
            directory.appendingPathComponent("ApplyReadyVetsJobTracker.v1.json"),
            directory.appendingPathComponent("ApplyReadyVetsJobTracker.backup.v1.json")
        )
    }

    private func decodeRecords(at url: URL) throws -> [JobApplicationRecord] {
        let envelope = try Self.decoder.decode(Envelope.self, from: Data(contentsOf: url))
        guard envelope.schemaVersion == 1,
              envelope.checksum == Self.checksum(envelope.payload) else {
            throw StoreError.corruptTracker
        }
        return try Self.decoder.decode([JobApplicationRecord].self, from: envelope.payload)
    }

    private func protectedWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func quarantineCorruptPrimary(_ primary: URL, in directory: URL) throws {
        let quarantine = directory.appendingPathComponent(
            "ApplyReadyVetsJobTracker.corrupt.\(UUID().uuidString).json"
        )
        try fileManager.moveItem(at: primary, to: quarantine)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: quarantine.path
        )
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func checksum(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
