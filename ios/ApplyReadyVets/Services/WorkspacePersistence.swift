import CryptoKit
import Foundation

struct ApplicationWorkspaceSnapshot: Codable {
    var stepRawValue: Int
    var draft: WorkspaceDraft
    var response: TailorResponse?
    var linkedInKit: LinkedInProfileKit?
    var analysisInputFingerprint: String?
    var importReviewWarnings: [String]
    var hasAcknowledgedImportWarnings: Bool

    init(
        stepRawValue: Int,
        draft: WorkspaceDraft,
        response: TailorResponse?,
        linkedInKit: LinkedInProfileKit?,
        analysisInputFingerprint: String?,
        importReviewWarnings: [String],
        hasAcknowledgedImportWarnings: Bool
    ) {
        self.stepRawValue = stepRawValue
        self.draft = draft
        self.response = response
        self.linkedInKit = linkedInKit
        self.analysisInputFingerprint = analysisInputFingerprint
        self.importReviewWarnings = importReviewWarnings
        self.hasAcknowledgedImportWarnings = hasAcknowledgedImportWarnings
    }
}

struct WorkspacePersistenceState: Codable {
    var hasStarted: Bool
    var stepRawValue: Int
    var draft: WorkspaceDraft
    var response: TailorResponse?
    var linkedInKit: LinkedInProfileKit?
    var analysisInputFingerprint: String?
    var importReviewWarnings: [String]?
    var hasAcknowledgedImportWarnings: Bool?
    var applicationWorkspaces: [String: ApplicationWorkspaceSnapshot]?
    var householdProfiles: [HouseholdProfile]?
    var activeHouseholdProfileID: UUID?
    var householdWorkspaces: [String: HouseholdWorkspaceSnapshot]?

    init(
        hasStarted: Bool,
        stepRawValue: Int,
        draft: WorkspaceDraft,
        response: TailorResponse?,
        linkedInKit: LinkedInProfileKit?,
        analysisInputFingerprint: String? = nil,
        importReviewWarnings: [String]? = nil,
        hasAcknowledgedImportWarnings: Bool? = nil,
        applicationWorkspaces: [String: ApplicationWorkspaceSnapshot]? = nil,
        householdProfiles: [HouseholdProfile]? = nil,
        activeHouseholdProfileID: UUID? = nil,
        householdWorkspaces: [String: HouseholdWorkspaceSnapshot]? = nil
    ) {
        self.hasStarted = hasStarted
        self.stepRawValue = stepRawValue
        self.draft = draft
        self.response = response
        self.linkedInKit = linkedInKit
        self.analysisInputFingerprint = analysisInputFingerprint
        self.importReviewWarnings = importReviewWarnings
        self.hasAcknowledgedImportWarnings = hasAcknowledgedImportWarnings
        self.applicationWorkspaces = applicationWorkspaces
        self.householdProfiles = householdProfiles
        self.activeHouseholdProfileID = activeHouseholdProfileID
        self.householdWorkspaces = householdWorkspaces
    }
}

struct WorkspaceLoadOutcome {
    let state: WorkspacePersistenceState
    let recoveredFromBackup: Bool
}

protocol WorkspacePersisting {
    func load() throws -> WorkspaceLoadOutcome?
    func save(_ state: WorkspacePersistenceState) throws
    func delete() throws
}

struct ResilientWorkspaceStore: WorkspacePersisting {
    enum StoreError: LocalizedError {
        case corruptWorkspace
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .corruptWorkspace:
                "The saved workspace could not be read, and no valid recovery copy was available."
            case .verificationFailed:
                "The workspace could not be verified after saving."
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

    func load() throws -> WorkspaceLoadOutcome? {
        let urls = try storageURLs()
        if fileManager.fileExists(atPath: urls.primary.path) {
            do {
                return WorkspaceLoadOutcome(
                    state: try decodeState(at: urls.primary),
                    recoveredFromBackup: false
                )
            } catch {
                if fileManager.fileExists(atPath: urls.backup.path),
                   let recovered = try? decodeState(at: urls.backup) {
                    try quarantineCorruptPrimary(urls.primary, in: urls.directory)
                    let backupData = try Data(contentsOf: urls.backup)
                    try protectedWrite(backupData, to: urls.primary)
                    guard (try? decodeState(at: urls.primary)) != nil else {
                        throw StoreError.verificationFailed
                    }
                    return WorkspaceLoadOutcome(
                        state: recovered,
                        recoveredFromBackup: true
                    )
                }
                throw StoreError.corruptWorkspace
            }
        }

        if fileManager.fileExists(atPath: urls.backup.path) {
            let recovered = try decodeState(at: urls.backup)
            let backupData = try Data(contentsOf: urls.backup)
            try protectedWrite(backupData, to: urls.primary)
            return WorkspaceLoadOutcome(state: recovered, recoveredFromBackup: true)
        }
        return nil
    }

    func save(_ state: WorkspacePersistenceState) throws {
        let urls = try storageURLs()
        let payload = try JSONEncoder.workspaceEncoder.encode(state)
        let envelope = Envelope(
            schemaVersion: 1,
            savedAt: Date(),
            checksum: Self.checksum(payload),
            payload: payload
        )
        let encoded = try JSONEncoder.workspaceEncoder.encode(envelope)

        if fileManager.fileExists(atPath: urls.primary.path),
           (try? decodeState(at: urls.primary)) != nil {
            let previous = try Data(contentsOf: urls.primary)
            try protectedWrite(previous, to: urls.backup)
        }

        try protectedWrite(encoded, to: urls.primary)
        guard (try? decodeState(at: urls.primary)) != nil else {
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
        for url in contents where url.lastPathComponent.hasPrefix("ApplyReadyVetsWorkspace.corrupt.") {
            try fileManager.removeItem(at: url)
        }
    }

    private func storageURLs() throws -> (directory: URL, primary: URL, backup: URL) {
        let directory: URL
        if let explicitDirectory {
            directory = explicitDirectory
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
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
            directory.appendingPathComponent("ApplyReadyVetsWorkspace.v1.json"),
            directory.appendingPathComponent("ApplyReadyVetsWorkspace.backup.v1.json")
        )
    }

    private func decodeState(at url: URL) throws -> WorkspacePersistenceState {
        let data = try Data(contentsOf: url)
        let envelope = try JSONDecoder.workspaceDecoder.decode(Envelope.self, from: data)
        guard envelope.schemaVersion == 1,
              envelope.checksum == Self.checksum(envelope.payload) else {
            throw StoreError.corruptWorkspace
        }
        return try JSONDecoder.workspaceDecoder.decode(
            WorkspacePersistenceState.self,
            from: envelope.payload
        )
    }

    private func protectedWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func quarantineCorruptPrimary(_ primary: URL, in directory: URL) throws {
        let quarantine = directory.appendingPathComponent(
            "ApplyReadyVetsWorkspace.corrupt.\(UUID().uuidString).json"
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
    static var workspaceEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var workspaceDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
