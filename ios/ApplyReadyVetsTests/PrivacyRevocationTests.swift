import XCTest
@testable import ApplyReadyVets

final class PrivacyRevocationTests: XCTestCase {
    func testWidgetDetailOptOutDeletesBeforeWritingCountOnlySnapshot() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let record = JobApplicationRecord(
            employer: "Private Employer",
            roleTitle: "Sensitive Role",
            status: .interviewing,
            deadline: now.addingTimeInterval(86_400),
            updatedAt: now
        )

        XCTAssertTrue(
            ApplicationWidgetBridge.persist(
                records: [record],
                includeApplicationDetails: true,
                now: now,
                directoryOverride: directory
            )
        )
        XCTAssertNotNil(
            ApplicationWidgetSnapshotStore.load(
                directoryOverride: directory
            ).details
        )

        XCTAssertTrue(
            ApplicationWidgetBridge.persist(
                records: [record],
                includeApplicationDetails: false,
                now: now.addingTimeInterval(1),
                directoryOverride: directory
            )
        )
        let revoked = ApplicationWidgetSnapshotStore.load(
            directoryOverride: directory
        )
        XCTAssertEqual(revoked.activeCount, 1)
        XCTAssertNil(revoked.details)
    }

    func testWidgetDetailOptOutCannotLeaveOldDetailsWhenReplacementFails() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let record = JobApplicationRecord(
            employer: "Private Employer",
            roleTitle: "Sensitive Role",
            status: .interviewing,
            updatedAt: now
        )

        XCTAssertTrue(
            ApplicationWidgetBridge.persist(
                records: [record],
                includeApplicationDetails: true,
                now: now,
                directoryOverride: directory
            )
        )

        let persisted = ApplicationWidgetBridge.persist(
            records: [record],
            includeApplicationDetails: false,
            now: now.addingTimeInterval(1),
            directoryOverride: directory,
            saveOverride: { _, _, _ in false }
        )

        XCTAssertFalse(persisted)
        let url = try XCTUnwrap(
            ApplicationWidgetSnapshotStore.storageURL(
                directoryOverride: directory
            )
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNil(
            ApplicationWidgetSnapshotStore.load(
                directoryOverride: directory
            ).details
        )
    }

    func testRemovingLastApplicationClearsDetailsEvenWhenDetailPreferenceStaysOn() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let record = JobApplicationRecord(
            employer: "Private Employer",
            roleTitle: "Sensitive Role",
            status: .interviewing,
            updatedAt: now
        )

        XCTAssertTrue(
            ApplicationWidgetBridge.persist(
                records: [record],
                includeApplicationDetails: true,
                now: now,
                directoryOverride: directory
            )
        )
        XCTAssertNotNil(
            ApplicationWidgetSnapshotStore.load(
                directoryOverride: directory
            ).details
        )

        XCTAssertFalse(
            ApplicationWidgetBridge.persist(
                records: [],
                includeApplicationDetails: true,
                now: now.addingTimeInterval(1),
                directoryOverride: directory,
                saveOverride: { _, _, _ in false }
            )
        )
        let url = try XCTUnwrap(
            ApplicationWidgetSnapshotStore.storageURL(
                directoryOverride: directory
            )
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNil(
            ApplicationWidgetSnapshotStore.load(
                directoryOverride: directory
            ).details
        )
    }

    func testWidgetReadDistinguishesMissingFromTemporarilyUnavailableData() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        XCTAssertEqual(
            ApplicationWidgetSnapshotStore.read(
                directoryOverride: directory
            ),
            .missing
        )

        let url = try XCTUnwrap(
            ApplicationWidgetSnapshotStore.storageURL(
                directoryOverride: directory
            )
        )
        try Data("not-json".utf8).write(to: url, options: .atomic)
        XCTAssertEqual(
            ApplicationWidgetSnapshotStore.read(
                directoryOverride: directory
            ),
            .unavailable
        )
        XCTAssertTrue(
            ApplicationWidgetSnapshotStore.read(
                directoryOverride: directory
            ).needsShortRetry
        )
    }

    func testSpotlightPendingDeletionMarkerPersistsUntilExplicitSuccess() throws {
        let suiteName = "PrivacyRevocationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertFalse(
            ApplicationSpotlightIndexer.isDeletionPending(
                userDefaults: defaults
            )
        )
        ApplicationSpotlightIndexer.markDeletionPending(
            userDefaults: defaults
        )
        XCTAssertTrue(
            ApplicationSpotlightIndexer.isDeletionPending(
                userDefaults: defaults
            )
        )

        let reloaded = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        XCTAssertTrue(
            ApplicationSpotlightIndexer.isDeletionPending(
                userDefaults: reloaded
            )
        )

        ApplicationSpotlightIndexer.clearDeletionPending(
            userDefaults: reloaded
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.isDeletionPending(
                userDefaults: defaults
            )
        )
    }

    func testSpotlightReplacementResultSeparatesDeletionFromIndexFailure() {
        XCTAssertTrue(
            ApplicationSpotlightIndexer.ReplacementResult.completed.succeeded
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.ReplacementResult
                .indexingUnavailable
                .succeeded
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.ReplacementResult
                .deletionFailed
                .succeeded
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.ReplacementResult
                .indexingFailed
                .succeeded
        )
    }

    func testSpotlightDeletionCompletesOnlyAfterBothIndexesAreCleared() {
        XCTAssertTrue(
            ApplicationSpotlightIndexer.deletionIsComplete(
                legacyIndexDeleted: true,
                protectedIndexDeleted: true
            )
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.deletionIsComplete(
                legacyIndexDeleted: false,
                protectedIndexDeleted: true
            )
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.deletionIsComplete(
                legacyIndexDeleted: true,
                protectedIndexDeleted: false
            )
        )
        XCTAssertFalse(
            ApplicationSpotlightIndexer.deletionIsComplete(
                legacyIndexDeleted: false,
                protectedIndexDeleted: false
            )
        )
    }
}
