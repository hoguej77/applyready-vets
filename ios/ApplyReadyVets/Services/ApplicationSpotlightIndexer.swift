@preconcurrency import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

enum ApplicationSpotlightIndexer {
    enum ReplacementResult: Equatable {
        case completed
        case indexingUnavailable
        case deletionFailed
        case indexingFailed

        var succeeded: Bool {
            self == .completed
        }
    }

    static let preferenceKey = "ApplyReadyVets.spotlightApplicationsEnabled"
    static let pendingDeletionPreferenceKey =
        "ApplyReadyVets.spotlightApplicationDeletionPending.v1"
    static let domainIdentifier = "com.jonathanhogue.applyreadyvets.applications"
    static let indexName = "ApplyReadyVets.Applications"
    static let indexProtectionClass = FileProtectionType.complete
    private static let identifierPrefix = "application:"
    @MainActor private static let index = CSSearchableIndex(
        name: indexName,
        protectionClass: indexProtectionClass
    )
    @MainActor private static var replacementGeneration = 0
    @MainActor private static var replacementTask: Task<Void, Never>?

    static func searchableIdentifier(for id: UUID) -> String {
        identifierPrefix + id.uuidString.lowercased()
    }

    static func applicationID(from searchableIdentifier: String) -> UUID? {
        guard searchableIdentifier.hasPrefix(identifierPrefix) else { return nil }
        return UUID(uuidString: String(searchableIdentifier.dropFirst(identifierPrefix.count)))
    }

    static func isDeletionPending(
        userDefaults: UserDefaults = .standard
    ) -> Bool {
        userDefaults.bool(forKey: pendingDeletionPreferenceKey)
    }

    static func markDeletionPending(
        userDefaults: UserDefaults = .standard
    ) {
        userDefaults.set(
            true,
            forKey: pendingDeletionPreferenceKey
        )
    }

    static func clearDeletionPending(
        userDefaults: UserDefaults = .standard
    ) {
        userDefaults.removeObject(
            forKey: pendingDeletionPreferenceKey
        )
    }

    static func deletionIsComplete(
        legacyIndexDeleted: Bool,
        protectedIndexDeleted: Bool
    ) -> Bool {
        legacyIndexDeleted && protectedIndexDeleted
    }

    @MainActor
    static func replace(
        with records: [JobApplicationRecord],
        enabled: Bool,
        completion: (@MainActor (ReplacementResult) -> Void)? = nil
    ) {
        replacementGeneration += 1
        let generation = replacementGeneration
        let previousTask = replacementTask

        // Persist intent before any asynchronous work. If the app exits or
        // Spotlight is unavailable, the next launch can retry deletion rather
        // than assuming previously indexed application details are gone.
        markDeletionPending()

        // Chain updates because Apple requires a custom index to be modified
        // from only one task at a time. A generation check prevents an older
        // queued update from adding stale application details.
        replacementTask = Task { @MainActor in
            await previousTask?.value
            guard CSSearchableIndex.isIndexingAvailable() else {
                if generation == replacementGeneration {
                    completion?(.indexingUnavailable)
                }
                return
            }

            // Builds before the protected custom index used Spotlight's
            // unprotected default index. Both legacy and protected deletion
            // must succeed before the persistent revocation marker is cleared.
            // No new content is ever written to the default index.
            let legacyIndexDeleted: Bool
            do {
                try await CSSearchableIndex.default().deleteSearchableItems(
                    withDomainIdentifiers: [domainIdentifier]
                )
                legacyIndexDeleted = true
            } catch {
                legacyIndexDeleted = false
            }

            let protectedIndexDeleted: Bool
            do {
                try await index.deleteSearchableItems(
                    withDomainIdentifiers: [domainIdentifier]
                )
                protectedIndexDeleted = true
            } catch {
                protectedIndexDeleted = false
            }

            guard deletionIsComplete(
                legacyIndexDeleted: legacyIndexDeleted,
                protectedIndexDeleted: protectedIndexDeleted
            ) else {
                if generation == replacementGeneration {
                    completion?(.deletionFailed)
                }
                return
            }

            // A newer queued replacement already wrote its own pending marker.
            // The older operation must not clear that newer privacy state.
            guard generation == replacementGeneration else {
                return
            }
            clearDeletionPending()

            guard enabled, !records.isEmpty else {
                completion?(.completed)
                return
            }

            do {
                try await index.indexSearchableItems(
                    records.map(searchableItem)
                )
                guard generation == replacementGeneration else {
                    return
                }
                completion?(.completed)
            } catch {
                // Spotlight is an optional convenience. The protected tracker
                // remains authoritative and must never fail because indexing
                // is unavailable or an index operation is interrupted.
                if generation == replacementGeneration {
                    completion?(.indexingFailed)
                }
            }
        }
    }

    private static func searchableItem(_ record: JobApplicationRecord) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        let title = bounded(record.displayTitle, maximumCharacters: 160)
        let employer = bounded(
            record.displayEmployer,
            maximumCharacters: 160
        )
        attributes.title = title
        attributes.displayName = title
        attributes.contentDescription = summary(for: record)
        attributes.keywords = [
            "ApplyReady Vets",
            record.platform.label,
            record.status.label,
            employer,
        ]
        return CSSearchableItem(
            uniqueIdentifier: searchableIdentifier(for: record.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    private static func summary(for record: JobApplicationRecord) -> String {
        var parts = [
            bounded(record.displayEmployer, maximumCharacters: 160),
            record.platform.label,
            record.status.label,
        ]
        if let deadline = record.deadline {
            parts.append("Deadline \(deadline.formatted(date: .abbreviated, time: .omitted))")
        }
        return parts.joined(separator: " · ")
    }

    private static func bounded(
        _ value: String,
        maximumCharacters: Int
    ) -> String {
        String(value.prefix(maximumCharacters))
    }
}
