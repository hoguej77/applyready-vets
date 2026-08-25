import Foundation

struct ApplicationWidgetSnapshot: Codable, Equatable {
    struct ApplicationDetails: Codable, Equatable {
        var roleTitle: String
        var employer: String
        var status: String
        var deadline: Date?
    }

    var updatedAt: Date
    var activeCount: Int
    var details: ApplicationDetails?

    static let empty = ApplicationWidgetSnapshot(
        updatedAt: Date(),
        activeCount: 0,
        details: nil
    )
}

enum ApplicationWidgetSnapshotStore {
    enum ReadResult: Equatable {
        case loaded(ApplicationWidgetSnapshot)
        case missing
        case unavailable

        var snapshot: ApplicationWidgetSnapshot {
            switch self {
            case .loaded(let snapshot):
                snapshot
            case .missing, .unavailable:
                .empty
            }
        }

        var needsShortRetry: Bool {
            self == .unavailable
        }
    }

    static let suiteName = "group.com.jonathanhogue.applyreadyvets"
    static let widgetKind = "ApplyReadyVetsNextApplication"
    static let filename = "ApplyReadyVetsWidgetSnapshot.v2.json"
    static let maximumSnapshotBytes = 32 * 1_024

    // Version 1 stored private application fields in shared UserDefaults.
    // Version 2 never reads that value and removes it during every access.
    private static let legacyStorageKey =
        "ApplyReadyVets.widget.applicationSnapshot"

    static func load(
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) -> ApplicationWidgetSnapshot {
        read(
            directoryOverride: directoryOverride,
            fileManager: fileManager
        ).snapshot
    }

    static func read(
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) -> ReadResult {
        purgeLegacySnapshot()
        guard let url = storageURL(
            directoryOverride: directoryOverride,
            fileManager: fileManager
        ) else {
            return .unavailable
        }
        guard fileManager.fileExists(atPath: url.path) else {
            return .missing
        }
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            guard let size = values.fileSize,
                  size <= maximumSnapshotBytes else {
                return .unavailable
            }
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(
                ApplicationWidgetSnapshot.self,
                from: data
            )
            return .loaded(snapshot)
        } catch {
            // Complete file protection can make a valid snapshot temporarily
            // unreadable while the device is locked. Corruption is also
            // treated as unavailable until the app replaces the projection.
            return .unavailable
        }
    }

    @discardableResult
    static func save(
        _ snapshot: ApplicationWidgetSnapshot,
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) -> Bool {
        purgeLegacySnapshot()
        guard let url = storageURL(
            directoryOverride: directoryOverride,
            fileManager: fileManager
        ),
        let data = try? JSONEncoder().encode(snapshot),
        data.count <= maximumSnapshotBytes else {
            return false
        }

        do {
            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(
                to: url,
                options: [.atomic, .completeFileProtection]
            )
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    static func clear(
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) -> Bool {
        purgeLegacySnapshot()
        guard let url = storageURL(
            directoryOverride: directoryOverride,
            fileManager: fileManager
        ) else {
            return false
        }

        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            // A successful remove call is not enough for a privacy revocation:
            // confirm that no snapshot remains at the shared location.
            return !fileManager.fileExists(atPath: url.path)
        } catch {
            return false
        }
    }

    static func storageURL(
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        let directory = directoryOverride
            ?? fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: suiteName
            )
        return directory?.appendingPathComponent(
            filename,
            isDirectory: false
        )
    }

    static func purgeLegacySnapshot() {
        UserDefaults(suiteName: suiteName)?.removeObject(
            forKey: legacyStorageKey
        )
    }
}
