import Foundation
import WidgetKit

enum ApplicationWidgetBridge {
    typealias SnapshotWriter = (
        ApplicationWidgetSnapshot,
        URL?,
        FileManager
    ) -> Bool

    static let detailPreferenceKey =
        "ApplyReadyVets.widgetApplicationDetailsEnabled"

    @discardableResult
    @MainActor
    static func update(
        with records: [JobApplicationRecord],
        includeApplicationDetails: Bool
    ) -> Bool {
        let didPersist = persist(
            records: records,
            includeApplicationDetails: includeApplicationDetails
        )
        WidgetCenter.shared.reloadTimelines(
            ofKind: ApplicationWidgetSnapshotStore.widgetKind
        )
        return didPersist
    }

    /// Persists the widget projection without allowing a failed privacy
    /// downgrade to preserve an older detailed snapshot.
    ///
    /// `saveOverride` exists only so the failure path can be tested without
    /// depending on filesystem permission behavior. Production callers use
    /// the protected snapshot store.
    @discardableResult
    static func persist(
        records: [JobApplicationRecord],
        includeApplicationDetails: Bool,
        now: Date = Date(),
        directoryOverride: URL? = nil,
        fileManager: FileManager = .default,
        saveOverride: SnapshotWriter? = nil
    ) -> Bool {
        let nextSnapshot = snapshot(
            from: records,
            includeApplicationDetails: includeApplicationDetails,
            now: now
        )
        let save = saveOverride ?? { snapshot, directory, manager in
            ApplicationWidgetSnapshotStore.save(
                snapshot,
                directoryOverride: directory,
                fileManager: manager
            )
        }

        if nextSnapshot.details == nil {
            // Privacy revocation is intentionally delete-before-write. If the
            // count-only write then fails, no prior employer, role, status, or
            // deadline can remain in the App Group.
            guard ApplicationWidgetSnapshotStore.clear(
                directoryOverride: directoryOverride,
                fileManager: fileManager
            ) else {
                return false
            }
        }

        guard save(nextSnapshot, directoryOverride, fileManager) else {
            // Do not leave a stale prior projection after any failed update.
            // If detailed projection remains enabled, AppModel reports the
            // failure and retries when the app next becomes active.
            _ = ApplicationWidgetSnapshotStore.clear(
                directoryOverride: directoryOverride,
                fileManager: fileManager
            )
            return false
        }

        // Verify the persisted projection. A writer that reports success but
        // leaves stale or malformed data is treated as a failure and removed.
        guard ApplicationWidgetSnapshotStore.load(
            directoryOverride: directoryOverride,
            fileManager: fileManager
        ) == nextSnapshot else {
            _ = ApplicationWidgetSnapshotStore.clear(
                directoryOverride: directoryOverride,
                fileManager: fileManager
            )
            return false
        }
        return true
    }

    static func snapshot(
        from records: [JobApplicationRecord],
        includeApplicationDetails: Bool,
        now: Date = Date()
    ) -> ApplicationWidgetSnapshot {
        let active = records.filter(\.status.isActive)
        let next = active.sorted { lhs, rhs in
            switch (lhs.deadline, rhs.deadline) {
            case let (lhsDate?, rhsDate?):
                lhsDate == rhsDate ? lhs.updatedAt > rhs.updatedAt : lhsDate < rhsDate
            case (_?, nil):
                true
            case (nil, _?):
                false
            case (nil, nil):
                lhs.updatedAt > rhs.updatedAt
            }
        }.first

        let details: ApplicationWidgetSnapshot.ApplicationDetails?
        if includeApplicationDetails, let next {
            details = ApplicationWidgetSnapshot.ApplicationDetails(
                roleTitle: bounded(next.displayTitle, maximumCharacters: 160),
                employer: bounded(
                    next.displayEmployer,
                    maximumCharacters: 160
                ),
                status: next.status.label,
                deadline: next.deadline
            )
        } else {
            // Employer, role, status, and deadline never enter the App Group
            // snapshot until the veteran separately opts in to widget details.
            details = nil
        }

        return ApplicationWidgetSnapshot(
            updatedAt: now,
            activeCount: active.count,
            details: details
        )
    }

    private static func bounded(
        _ value: String,
        maximumCharacters: Int
    ) -> String {
        String(value.prefix(maximumCharacters))
    }
}
