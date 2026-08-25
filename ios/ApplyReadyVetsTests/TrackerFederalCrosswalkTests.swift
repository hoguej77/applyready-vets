import Dispatch
import XCTest
@testable import ApplyReadyVets

final class TrackerFederalCrosswalkTests: XCTestCase {
    func testTrackerStoreRoundTripsApplicationAndPacketHistory() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientJobTrackerStore(directory: directory)
        let deadline = Date(timeIntervalSince1970: 1_800_000_000)
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let record = JobApplicationRecord(
            employer: "Department of Transportation",
            roleTitle: "Program Analyst",
            jobID: "DE-123",
            platform: .usajobs,
            sourceURL: "https://www.usajobs.gov/job/123",
            status: .applied,
            notes: "Submitted through the official site.",
            deadline: deadline,
            requiredDocuments: ["Résumé", "Transcript"],
            packetVersions: [
                ApplicationPacketVersion(
                    number: 1,
                    createdAt: createdAt,
                    resumeFilename: "Federal_Resume.txt",
                    privateReviewFilename: "Private_Review.txt"
                ),
            ],
            createdAt: createdAt,
            updatedAt: createdAt
        )

        try store.save([record])
        let loaded = try XCTUnwrap(store.load())

        XCTAssertFalse(loaded.recoveredFromBackup)
        XCTAssertEqual(loaded.records, [record])
        XCTAssertEqual(loaded.records.first?.packetVersions.first?.number, 1)
    }

    func testLegacyTrackerRecordWithoutStatusEvidenceStillDecodes() throws {
        let record = JobApplicationRecord(
            employer: "Example employer",
            roleTitle: "Program Analyst"
        )
        let encoded = try JSONEncoder().encode(record)
        var legacy = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        legacy.removeValue(forKey: "statusEvidence")
        let legacyData = try JSONSerialization.data(
            withJSONObject: legacy,
            options: [.sortedKeys]
        )

        let decoded = try JSONDecoder().decode(
            JobApplicationRecord.self,
            from: legacyData
        )

        XCTAssertEqual(decoded.id, record.id)
        XCTAssertTrue(decoded.statusEvidence.isEmpty)
    }

    func testTrackerStoreRecoversLastKnownGoodCopy() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientJobTrackerStore(directory: directory)
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let first = JobApplicationRecord(
            employer: "First employer",
            roleTitle: "Analyst",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let second = JobApplicationRecord(
            employer: "Second employer",
            roleTitle: "Manager",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        try store.save([first])
        try store.save([first, second])
        let primary = directory.appendingPathComponent("ApplyReadyVetsJobTracker.v1.json")
        try Data("damaged".utf8).write(to: primary, options: .atomic)

        let loaded = try XCTUnwrap(store.load())

        XCTAssertTrue(loaded.recoveredFromBackup)
        XCTAssertEqual(loaded.records, [first])
    }

    func testApplicationWorkspaceCorruptionIsIsolatedByApplication() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientApplicationWorkspaceStore(directory: directory)
        let firstID = UUID()
        let secondID = UUID()
        var firstDraft = WorkspaceDraft()
        firstDraft.jobText = "First verified posting"
        var firstUpdatedDraft = firstDraft
        firstUpdatedDraft.jobText = "Newer first posting"
        var secondDraft = WorkspaceDraft()
        secondDraft.jobText = "Second application remains readable"

        try store.save(snapshot(firstDraft), id: firstID)
        try store.save(snapshot(firstUpdatedDraft), id: firstID)
        try store.save(snapshot(secondDraft), id: secondID)
        let firstPrimary = directory.appendingPathComponent(
            "ApplyReadyVetsApplication.\(firstID.uuidString).v1.json"
        )
        try Data("damaged".utf8).write(to: firstPrimary, options: .atomic)

        let recovered = try XCTUnwrap(store.load(id: firstID))
        let unaffected = try XCTUnwrap(store.load(id: secondID))

        XCTAssertTrue(recovered.recoveredFromBackup)
        XCTAssertEqual(
            recovered.snapshot.draft.jobText,
            "First verified posting"
        )
        XCTAssertFalse(unaffected.recoveredFromBackup)
        XCTAssertEqual(
            unaffected.snapshot.draft.jobText,
            "Second application remains readable"
        )
    }

    func testDeletingApplicationWorkspaceRemovesOnlyItsRecoveryCopiesAndQuarantines() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientApplicationWorkspaceStore(directory: directory)
        let deletedID = UUID()
        let retainedID = UUID()

        for (id, label) in [
            (deletedID, "Deleted application"),
            (retainedID, "Retained application"),
        ] {
            var firstDraft = WorkspaceDraft()
            firstDraft.jobText = "\(label) first verified posting"
            var secondDraft = firstDraft
            secondDraft.jobText = "\(label) newer posting"
            try store.save(snapshot(firstDraft), id: id)
            try store.save(snapshot(secondDraft), id: id)
            let primary = directory.appendingPathComponent(
                "ApplyReadyVetsApplication.\(id.uuidString).v1.json"
            )
            try Data("damaged".utf8).write(to: primary, options: .atomic)
            XCTAssertTrue(try XCTUnwrap(store.load(id: id)).recoveredFromBackup)
        }

        let namesBeforeDelete = try FileManager.default.contentsOfDirectory(
            atPath: directory.path
        )
        XCTAssertTrue(namesBeforeDelete.contains {
            $0.hasPrefix(
                "ApplyReadyVetsApplication.\(deletedID.uuidString).corrupt."
            )
        })
        XCTAssertTrue(namesBeforeDelete.contains {
            $0.hasPrefix(
                "ApplyReadyVetsApplication.\(retainedID.uuidString).corrupt."
            )
        })

        try store.delete(id: deletedID)

        let namesAfterDelete = try FileManager.default.contentsOfDirectory(
            atPath: directory.path
        )
        XCTAssertFalse(namesAfterDelete.contains {
            $0.hasPrefix("ApplyReadyVetsApplication.\(deletedID.uuidString).")
        })
        XCTAssertTrue(namesAfterDelete.contains {
            $0.hasPrefix("ApplyReadyVetsApplication.\(retainedID.uuidString).")
        })
        XCTAssertNil(try store.load(id: deletedID))
        XCTAssertEqual(
            try XCTUnwrap(store.load(id: retainedID))
                .snapshot.draft.jobText,
            "Retained application first verified posting"
        )
    }

    @MainActor
    func testDeletingActiveApplicationPersistsOnlyReusableCandidateState() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let workspaceStore = ResilientWorkspaceStore(directory: directory)
        let applicationStore = ResilientApplicationWorkspaceStore(
            directory: directory
        )
        let trackerStore = ResilientJobTrackerStore(directory: directory)
        let record = JobApplicationRecord(
            employer: "Department of Transportation",
            roleTitle: "Program Analyst",
            jobID: "DE-123",
            platform: .usajobs,
            sourceURL: "https://www.usajobs.gov/job/123"
        )
        let model = AppModel(
            workspaceStore: workspaceStore,
            applicationWorkspaceStore: applicationStore,
            jobTrackerStore: trackerStore,
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(model.upsertJobApplication(record))
        model.startWorkspace(for: record.id)

        var service = MilitaryService()
        service.branch = "Army"
        service.occupationCode = "88M"
        model.draft.profile = CandidateProfile(
            fullName: "Taylor Veteran",
            email: "taylor@example.com",
            phone: "555-0100",
            location: "San Diego, CA",
            linkedin: "https://www.linkedin.com/in/taylor",
            targetRole: "Program Analyst",
            militaryService: [service]
        )
        model.draft.resumeText = """
        TAYLOR VETERAN
        Program support specialist
        January 2023 - Present, 40 hours per week
        Led verified program operations.
        """
        model.draft.resumeFilename = "Taylor_Base_Resume.txt"
        model.draft.jobText = """
        USAJOBS announcement DE-123
        GS-0343-11 Program Analyst
        Specialized experience is required.
        """
        model.draft.jobFilename = "DE-123.txt"
        model.draft.jobURL = record.sourceURL
        model.jobURL = record.sourceURL
        model.draft.federalDetails = FederalApplicationDetails(
            announcementNumber: "DE-123",
            targetSeriesAndGrade: "GS-0343-11"
        )
        model.draft.mode = .federal
        model.draft.useAI = false
        model.draft.aiConsent = true
        model.draft.serviceConsent = false
        model.selectedTrackedApplicationID = record.id
        await model.analyze()
        await model.buildLinkedInKit()
        XCTAssertNotNil(model.response)
        XCTAssertNotNil(model.linkedInKit)

        let generatedURLs = ["resume.txt", "resume.pdf", "resume.rtf", "review.txt"]
            .map {
                FileManager.default.temporaryDirectory.appendingPathComponent(
                    "ApplyReadyVets_DeleteTest_\(UUID().uuidString)_\($0)"
                )
            }
        for url in generatedURLs {
            try Data("generated".utf8).write(to: url, options: .atomic)
        }
        model.exportURL = generatedURLs[0]
        model.exportPDFURL = generatedURLs[1]
        model.exportRichTextURL = generatedURLs[2]
        model.privateReviewURL = generatedURLs[3]
        model.importReviewWarnings = ["Job: Review imported formatting."]
        model.hasAcknowledgedImportWarnings = false
        model.saveForSceneTransition()

        model.deleteJobApplication(id: record.id)

        XCTAssertTrue(model.jobApplications.isEmpty)
        XCTAssertNil(model.selectedTrackedApplicationID)
        XCTAssertNil(model.draft.trackerRecordID)
        XCTAssertEqual(model.draft.profile.fullName, "Taylor Veteran")
        XCTAssertEqual(model.draft.profile.email, "taylor@example.com")
        XCTAssertEqual(model.draft.profile.militaryService.first?.occupationCode, "88M")
        XCTAssertTrue(model.draft.profile.targetRole.isEmpty)
        XCTAssertEqual(model.draft.resumeText, """
        TAYLOR VETERAN
        Program support specialist
        January 2023 - Present, 40 hours per week
        Led verified program operations.
        """)
        XCTAssertEqual(model.draft.resumeFilename, "Taylor_Base_Resume.txt")
        XCTAssertTrue(model.draft.jobText.isEmpty)
        XCTAssertTrue(model.draft.jobFilename.isEmpty)
        XCTAssertNil(model.draft.jobURL)
        XCTAssertTrue(model.jobURL.isEmpty)
        XCTAssertNil(model.draft.federalDetails)
        XCTAssertEqual(model.draft.mode, .auto)
        XCTAssertFalse(model.draft.useAI)
        XCTAssertTrue(model.draft.aiConsent)
        XCTAssertEqual(model.draft.serviceConsent, false)
        XCTAssertNil(model.response)
        XCTAssertNil(model.linkedInKit)
        XCTAssertNil(model.exportURL)
        XCTAssertNil(model.exportPDFURL)
        XCTAssertNil(model.exportRichTextURL)
        XCTAssertNil(model.privateReviewURL)
        XCTAssertTrue(model.importReviewWarnings.isEmpty)
        XCTAssertTrue(model.hasAcknowledgedImportWarnings)
        XCTAssertEqual(model.step, .importDocuments)
        XCTAssertTrue(generatedURLs.allSatisfy {
            !FileManager.default.fileExists(atPath: $0.path)
        })
        XCTAssertNil(try applicationStore.load(id: record.id))
        XCTAssertEqual(try trackerStore.load()?.records, [])

        let persisted = try XCTUnwrap(workspaceStore.load()).state
        XCTAssertNil(persisted.draft.trackerRecordID)
        XCTAssertEqual(persisted.draft.profile.fullName, "Taylor Veteran")
        XCTAssertTrue(persisted.draft.profile.targetRole.isEmpty)
        XCTAssertEqual(
            persisted.draft.resumeFilename,
            "Taylor_Base_Resume.txt"
        )
        XCTAssertTrue(persisted.draft.jobText.isEmpty)
        XCTAssertTrue(persisted.draft.jobFilename.isEmpty)
        XCTAssertNil(persisted.draft.jobURL)
        XCTAssertNil(persisted.draft.federalDetails)
        XCTAssertEqual(persisted.draft.mode, .auto)
        XCTAssertFalse(persisted.draft.useAI)
        XCTAssertTrue(persisted.draft.aiConsent)
        XCTAssertEqual(persisted.draft.serviceConsent, false)
        XCTAssertNil(persisted.response)
        XCTAssertNil(persisted.linkedInKit)
    }

    @MainActor
    func testFreeAccessAllowsOneWorkspaceAndCompleteAllowsUnlimited() {
        let freeDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: freeDirectory) }
        let freeEntitlement = TestEntitlement(hasComplete: false)
        let freeModel = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: freeDirectory),
            jobTrackerStore: ResilientJobTrackerStore(directory: freeDirectory),
            entitlement: freeEntitlement
        )

        XCTAssertTrue(freeModel.upsertJobApplication(
            JobApplicationRecord(employer: "First", roleTitle: "Role one")
        ))
        XCTAssertFalse(freeModel.upsertJobApplication(
            JobApplicationRecord(employer: "Second", roleTitle: "Role two")
        ))
        XCTAssertTrue(freeModel.showsCompletePaywall)
        XCTAssertEqual(freeModel.jobApplications.count, 1)

        let completeDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: completeDirectory) }
        let completeModel = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: completeDirectory),
            jobTrackerStore: ResilientJobTrackerStore(directory: completeDirectory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(completeModel.upsertJobApplication(
            JobApplicationRecord(employer: "First", roleTitle: "Role one")
        ))
        XCTAssertTrue(completeModel.upsertJobApplication(
            JobApplicationRecord(employer: "Second", roleTitle: "Role two")
        ))
        XCTAssertEqual(completeModel.jobApplications.count, 2)
    }

    @MainActor
    func testStartApplicationShortcutCreatesDistinctWorkspaceWithoutMutatingCurrentJob() throws {
        let directory = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
            UserDefaults.standard.removeObject(
                forKey: ShortcutDestination.storageKey
            )
        }
        let first = JobApplicationRecord(
            employer: "First Employer",
            roleTitle: "Operations Manager"
        )
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(model.upsertJobApplication(first))
        model.startWorkspace(for: first.id)
        model.draft.profile.fullName = "Taylor Veteran"
        model.draft.resumeText = "Reusable verified base resume"
        model.draft.resumeFilename = "Base Resume.txt"
        model.draft.jobText = "First employer posting"
        model.draft.jobFilename = "First Posting.txt"
        model.saveForSceneTransition()

        UserDefaults.standard.set(
            ShortcutDestination.startApplication.rawValue,
            forKey: ShortcutDestination.storageKey
        )
        model.handlePendingShortcut()

        let secondID = try XCTUnwrap(model.draft.trackerRecordID)
        XCTAssertNotEqual(secondID, first.id)
        XCTAssertEqual(model.draft.profile.fullName, "Taylor Veteran")
        XCTAssertEqual(model.draft.resumeText, "Reusable verified base resume")
        XCTAssertTrue(model.draft.jobText.isEmpty)
        XCTAssertTrue(model.draft.jobFilename.isEmpty)

        model.draft.jobText = "Second employer posting"
        XCTAssertEqual(model.saveCurrentJobToTracker(), secondID)
        XCTAssertEqual(Set(model.jobApplications.map(\.id)), Set([first.id, secondID]))

        model.startWorkspace(for: first.id)
        XCTAssertEqual(model.draft.jobText, "First employer posting")
        XCTAssertEqual(model.draft.jobFilename, "First Posting.txt")
    }

    @MainActor
    func testFreeStartApplicationBoundaryDoesNotMutateExistingWorkspace() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = JobApplicationRecord(
            employer: "First Employer",
            roleTitle: "Operations Manager"
        )
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: false)
        )
        XCTAssertTrue(model.upsertJobApplication(first))
        model.startWorkspace(for: first.id)
        model.draft.jobText = "Original job remains intact"

        XCTAssertFalse(model.beginNewApplication())
        XCTAssertTrue(model.showsCompletePaywall)
        XCTAssertEqual(model.draft.trackerRecordID, first.id)
        XCTAssertEqual(model.draft.jobText, "Original job remains intact")
    }

    @MainActor
    func testFreeStartApplicationBoundaryProtectsSubstantiveUntrackedDraft() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: false)
        )
        model.draft.resumeText = "Reusable base resume"
        model.draft.jobText = "Untracked posting that must not be overwritten"
        model.draft.profile.targetRole = "Operations Manager"

        XCTAssertFalse(model.beginNewApplication())
        XCTAssertTrue(model.showsCompletePaywall)
        XCTAssertNil(model.draft.trackerRecordID)
        XCTAssertEqual(
            model.draft.jobText,
            "Untracked posting that must not be overwritten"
        )
        XCTAssertEqual(model.draft.profile.targetRole, "Operations Manager")
        XCTAssertTrue(model.jobApplications.isEmpty)
    }

    @MainActor
    func testCompletePreservesSubstantiveUntrackedDraftBeforeStartingNextApplication() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let applicationStore = ResilientApplicationWorkspaceStore(
            directory: directory
        )
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: applicationStore,
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.draft.resumeText = "Reusable base resume"
        model.draft.resumeFilename = "Base Resume.txt"
        model.draft.jobText = "First untracked employer posting"
        model.draft.jobFilename = "First Posting.txt"
        model.draft.profile.targetRole = "Operations Manager"

        XCTAssertTrue(model.beginNewApplication())

        let retained = try XCTUnwrap(model.jobApplications.first)
        let nextID = try XCTUnwrap(model.draft.trackerRecordID)
        XCTAssertNotEqual(retained.id, nextID)
        XCTAssertEqual(retained.roleTitle, "Operations Manager")
        XCTAssertEqual(
            try XCTUnwrap(applicationStore.load(id: retained.id))
                .snapshot.draft.jobText,
            "First untracked employer posting"
        )
        XCTAssertEqual(model.draft.resumeText, "Reusable base resume")
        XCTAssertTrue(model.draft.jobText.isEmpty)
        XCTAssertTrue(model.draft.profile.targetRole.isEmpty)
    }

    @MainActor
    func testAnalysisRequiresBothResumeAndJobPosting() async {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )

        await model.analyze()
        XCTAssertEqual(
            model.errorMessage,
            "Add or import your resume before running analysis."
        )
        XCTAssertNil(model.response)

        model.draft.resumeText = "Verified experience"
        await model.analyze()
        XCTAssertEqual(
            model.errorMessage,
            "Add or import one job posting before running analysis."
        )
        XCTAssertNil(model.response)
    }

    @MainActor
    func testAutoFederalPostingResolvesBeforeAnalysisAndPersistsFederalMode() async {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.draft.resumeText = "PROGRAM ANALYST\nLed verified program support."
        model.draft.jobText = """
        USAJOBS announcement
        GS-0343-11 Program Analyst
        Specialized experience is required.
        """
        model.draft.mode = .auto
        model.draft.useAI = false

        XCTAssertEqual(model.effectiveResumeMode, .federal)
        await model.analyze()

        XCTAssertEqual(model.draft.mode, .federal)
        XCTAssertEqual(model.effectiveResumeMode, .federal)
        XCTAssertTrue(model.currentResponse?.job.federal == true)
    }

    @MainActor
    func testTrackerRejectsOversizedPrivateNotesWithoutPersistingRecord() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        let record = JobApplicationRecord(
            employer: "Example employer",
            roleTitle: "Operations Manager",
            notes: String(
                repeating: "n",
                count: CareerInputPolicy.Field.trackerNotes.maximumCharacters + 1
            )
        )

        XCTAssertFalse(model.upsertJobApplication(record))
        XCTAssertTrue(model.jobApplications.isEmpty)
        XCTAssertNotNil(model.errorMessage)
    }

    @MainActor
    func testInvalidCurrentJobURLEditDoesNotReusePreviouslySavedLink() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let originalURL = "https://www.usajobs.gov/job/123"
        let record = JobApplicationRecord(
            employer: "Example employer",
            roleTitle: "Operations Manager",
            sourceURL: originalURL
        )
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(model.upsertJobApplication(record))
        model.startWorkspace(for: record.id)

        let invalidEdit = "javascript:alert('apply')"
        model.jobURL = invalidEdit

        XCTAssertNil(model.saveCurrentJobToTracker())
        XCTAssertEqual(model.jobURL, invalidEdit)
        XCTAssertEqual(model.draft.jobURL, originalURL)
        XCTAssertEqual(model.jobApplications.first?.sourceURL, originalURL)
        XCTAssertTrue(model.errorMessage?.contains("not changed") == true)
    }

    @MainActor
    func testInvalidTrackerURLEditDoesNotBecomeBlankOrPersist() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let originalURL = "https://jobs.example.gov/posting/42"
        let original = JobApplicationRecord(
            employer: "Example employer",
            roleTitle: "Program Analyst",
            sourceURL: originalURL
        )
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(model.upsertJobApplication(original))
        var invalidEdit = original
        invalidEdit.sourceURL = "file:///private/job-posting.html"

        XCTAssertFalse(model.upsertJobApplication(invalidEdit))
        XCTAssertEqual(invalidEdit.sourceURL, "file:///private/job-posting.html")
        XCTAssertEqual(model.jobApplications.first?.sourceURL, originalURL)
        XCTAssertFalse(model.jobApplications.first?.sourceURL.isEmpty ?? true)
        XCTAssertTrue(model.errorMessage?.contains("not saved") == true)
    }

    @MainActor
    func testCompleteWorkspacesRemainIndependentAcrossSwitchAndRelaunch() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let workspaceStore = ResilientWorkspaceStore(directory: directory)
        let trackerStore = ResilientJobTrackerStore(directory: directory)
        let first = JobApplicationRecord(
            employer: "First Employer",
            roleTitle: "Operations Manager"
        )
        let second = JobApplicationRecord(
            employer: "Second Employer",
            roleTitle: "Program Analyst"
        )
        var model = AppModel(
            workspaceStore: workspaceStore,
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: trackerStore,
            entitlement: TestEntitlement(hasComplete: true)
        )
        XCTAssertTrue(model.upsertJobApplication(first))
        XCTAssertTrue(model.upsertJobApplication(second))

        model.startWorkspace(for: first.id)
        model.draft.profile.fullName = "Taylor Veteran"
        model.draft.resumeText = "Shared base resume"
        model.draft.resumeFilename = "Base_Resume.txt"
        model.draft.jobText = "First job posting"
        model.draft.jobFilename = "First posting"
        model.step = .serviceProfile

        model.startWorkspace(for: second.id)
        XCTAssertEqual(model.draft.trackerRecordID, second.id)
        XCTAssertEqual(model.draft.profile.fullName, "Taylor Veteran")
        XCTAssertEqual(model.draft.resumeText, "Shared base resume")
        XCTAssertTrue(model.draft.jobText.isEmpty)
        model.draft.jobText = "Second job posting"
        model.draft.jobFilename = "Second posting"
        model.step = .analyze

        model.startWorkspace(for: first.id)
        XCTAssertEqual(model.draft.trackerRecordID, first.id)
        XCTAssertEqual(model.draft.jobText, "First job posting")
        XCTAssertEqual(model.step, .serviceProfile)

        model.startWorkspace(for: second.id)
        XCTAssertEqual(model.draft.jobText, "Second job posting")
        XCTAssertEqual(model.step, .analyze)

        model = AppModel(
            workspaceStore: workspaceStore,
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: trackerStore,
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.startWorkspace(for: first.id)
        XCTAssertEqual(model.draft.jobText, "First job posting")
        XCTAssertEqual(model.draft.resumeText, "Shared base resume")
        XCTAssertEqual(model.draft.profile.fullName, "Taylor Veteran")
    }

    @MainActor
    func testRootSaveFailureCannotOverwriteNewerApplicationWorkspace() {
        let recorder = PersistenceOrderRecorder()
        let workspaceStore = FailingRootWorkspaceStore(recorder: recorder)
        let applicationStore = RecordingApplicationWorkspaceStore(
            recorder: recorder
        )
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: workspaceStore,
            applicationWorkspaceStore: applicationStore,
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.draft.trackerRecordID = UUID()
        model.draft.resumeText = "Newest verified resume content"
        model.draft.jobText = "Newest verified job posting"

        model.saveForSceneTransition()

        XCTAssertEqual(recorder.events, ["root-save"])
        XCTAssertEqual(applicationStore.saveCount, 0)
        XCTAssertTrue(
            model.errorMessage?.contains("protected save failed") == true
        )
    }

    @MainActor
    func testExportKeepsFilesAndReportsFailedVersionHistorySave() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: FailingJobTrackerStore(),
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.draft = DemoData.draft
        // The UI keeps the editable job-link field in sync with the analyzed
        // draft. Direct model setup must do the same so this test exercises
        // export behavior rather than the deliberate unsaved-link safeguard.
        model.jobURL = model.draft.jobURL ?? ""

        await model.analyze()
        XCTAssertNotNil(model.currentResponse)
        await model.exportPacket()

        let createdURLs = [
            model.exportURL,
            model.exportPDFURL,
            model.exportRichTextURL,
            model.privateReviewURL,
        ].compactMap { $0 }
        defer {
            for url in createdURLs {
                try? FileManager.default.removeItem(at: url)
            }
        }

        XCTAssertEqual(createdURLs.count, 4)
        XCTAssertTrue(
            createdURLs.allSatisfy {
                FileManager.default.fileExists(atPath: $0.path)
            }
        )
        XCTAssertTrue(
            model.statusMessage?.contains(
                "version history could not be saved"
            ) == true
        )
        XCTAssertTrue(
            model.errorMessage?.contains(
                "protected tracker save failed"
            ) == true
        )
        XCTAssertTrue(model.jobApplications.isEmpty)
    }

    @MainActor
    func testExportGenerationLeavesMainActorResponsiveAndDiscardsStaleOutput() async throws {
        let directory = temporaryDirectory()
        let generator = BlockingPacketGenerator(directory: directory)
        defer {
            generator.allowFinish()
            try? FileManager.default.removeItem(at: directory)
        }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true),
            packetGenerator: generator
        )
        model.draft = DemoData.draft
        // Match the user-facing editor state; see the related export history
        // test above.
        model.jobURL = model.draft.jobURL ?? ""
        await model.analyze()
        XCTAssertNotNil(model.currentResponse)

        let exportWork = Task { @MainActor in
            await model.exportPacket()
        }
        let generatorStarted = await Task.detached {
            generator.waitUntilStarted()
        }.value

        XCTAssertTrue(generatorStarted)
        XCTAssertTrue(model.isWorking)
        model.draft.jobText += "\nNew requirement added during generation."
        XCTAssertNil(model.currentResponse)

        generator.allowFinish()
        await exportWork.value

        XCTAssertFalse(model.isWorking)
        XCTAssertNil(model.exportURL)
        XCTAssertNil(model.exportPDFURL)
        XCTAssertNil(model.exportRichTextURL)
        XCTAssertNil(model.privateReviewURL)
        XCTAssertTrue(
            generator.allURLs.allSatisfy {
                !FileManager.default.fileExists(atPath: $0.path)
            }
        )
    }

    @MainActor
    func testTrackerIdentityAloneKeepsCurrentAnalysisAvailable() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true)
        )
        model.draft = DemoData.draft
        model.jobURL = model.draft.jobURL ?? ""

        await model.analyze()
        let analyzedID = try XCTUnwrap(model.currentResponse).analysisID
        let recordID = try XCTUnwrap(model.saveCurrentJobToTracker())

        XCTAssertEqual(model.draft.trackerRecordID, recordID)
        XCTAssertEqual(model.currentResponse?.analysisID, analyzedID)
    }

    @MainActor
    func testUnsavedJobURLChangeBlocksPacketGeneration() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: TestEntitlement(hasComplete: true),
            packetGenerator: UnexpectedPacketGenerator()
        )
        model.draft = DemoData.draft
        await model.analyze()
        XCTAssertNotNil(model.currentResponse)

        model.jobURL = "https://www.usajobs.gov/job/999999"
        await model.exportPacket()

        XCTAssertTrue(
            model.errorMessage?.contains("Save the edited job link") == true
        )
        XCTAssertNil(model.exportURL)
        XCTAssertNil(model.exportPDFURL)
        XCTAssertNil(model.exportRichTextURL)
        XCTAssertNil(model.privateReviewURL)
    }

    func testFederalReviewUsesRequirementSpecificChecksNotOverallScore() throws {
        let profile = CandidateProfile(
            fullName: "Taylor Veteran",
            email: "taylor@example.com",
            phone: "555-0100"
        )
        let resume = """
        Program Analyst
        January 2023 - Present
        40 hours per week
        Improved documented fleet operations.
        """

        let checks = FederalResumeReview.checks(
            resumeText: resume,
            profile: profile,
            details: FederalApplicationDetails(
                announcementNumber: "DE-123",
                targetSeriesAndGrade: "GS-0343-11"
            )
        )

        XCTAssertEqual(checks.first { $0.id == "contact" }?.state, .ready)
        XCTAssertEqual(checks.first { $0.id == "hours" }?.state, .verify)
        XCTAssertEqual(checks.first { $0.id == "announcement" }?.state, .ready)
        XCTAssertEqual(checks.first { $0.id == "pages" }?.state, .verify)
    }

    func testMilitaryOccupationSearchPrioritizesExactCodeWithinBranch() {
        let records = [
            MilitaryOccupationMapping(
                branch: .army,
                militaryCode: "88M",
                militaryTitle: "Motor Transport Operator",
                personnelCategory: "E",
                occupations: [
                    ONETOccupationMatch(
                        code: "53-3032.00",
                        title: "Heavy and Tractor-Trailer Truck Drivers"
                    ),
                ]
            ),
            MilitaryOccupationMapping(
                branch: .marineCorps,
                militaryCode: "88M",
                militaryTitle: "Unrelated test record",
                personnelCategory: "E",
                occupations: []
            ),
            MilitaryOccupationMapping(
                branch: .army,
                militaryCode: "88Z",
                militaryTitle: "Transportation Senior Sergeant",
                personnelCategory: "E",
                occupations: []
            ),
        ]

        let results = MilitaryOccupationSearch.search(
            records,
            branch: .army,
            query: "88M"
        )

        XCTAssertEqual(results.map(\.militaryCode), ["88M"])
        XCTAssertEqual(results.first?.occupations.first?.code, "53-3032.00")

        let titleResults = MilitaryOccupationSearch.search(
            records,
            branch: .army,
            query: "motor transport"
        )
        XCTAssertEqual(titleResults.first?.militaryCode, "88M")
    }

    func testBundledOfficialCrosswalkHasExpectedReleaseAndKnownMapping() async throws {
        let result = try await MilitaryCrosswalkStore.shared.search(
            branch: .army,
            query: "88M"
        )

        XCTAssertEqual(result.metadata.sourceRelease, "August 2024")
        XCTAssertEqual(result.metadata.includedRecords, 12_921)
        XCTAssertEqual(result.matches.first?.militaryTitle, "Motor Transport Operator")
        XCTAssertEqual(result.matches.first?.occupations.first?.code, "53-3032.00")
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ApplyReadyVetsTrackerTests-\(UUID().uuidString)")
    }

    private func snapshot(
        _ draft: WorkspaceDraft
    ) -> ApplicationWorkspaceSnapshot {
        ApplicationWorkspaceSnapshot(
            stepRawValue: AppModel.FlowStep.importDocuments.rawValue,
            draft: draft,
            response: nil,
            linkedInKit: nil,
            analysisInputFingerprint: nil,
            importReviewWarnings: [],
            hasAcknowledgedImportWarnings: true
        )
    }
}

@MainActor
private final class TestEntitlement: AccessEntitling {
    let hasComplete: Bool

    init(hasComplete: Bool) {
        self.hasComplete = hasComplete
    }
}

private final class PersistenceOrderRecorder {
    var events: [String] = []
}

private struct InjectedRootSaveError: LocalizedError {
    var errorDescription: String? {
        "Injected root workspace write failure."
    }
}

private struct InjectedJobTrackerSaveError: LocalizedError {
    var errorDescription: String? {
        "Injected tracker write failure."
    }
}

private final class BlockingPacketGenerator:
    ApplicationPacketGenerating,
    @unchecked Sendable {
    private let didStart = DispatchSemaphore(value: 0)
    private let mayFinish = DispatchSemaphore(value: 0)
    let allURLs: [URL]

    init(directory: URL) {
        allURLs = [
            directory.appendingPathComponent("background-export.pdf"),
            directory.appendingPathComponent("background-export.rtf"),
            directory.appendingPathComponent("background-export.txt"),
            directory.appendingPathComponent("background-private-review.txt"),
        ]
    }

    func waitUntilStarted() -> Bool {
        didStart.wait(timeout: .now() + 5) == .success
    }

    func allowFinish() {
        mayFinish.signal()
    }

    func generate(
        from _: ExportRequest,
        applicationID _: UUID?,
        packetVersion _: Int
    ) throws -> GeneratedApplicationPacket {
        didStart.signal()
        guard mayFinish.wait(timeout: .now() + 5) == .success else {
            throw BlockingPacketGeneratorError.timedOut
        }
        try Task.checkCancellation()
        let directory = allURLs[0].deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        for url in allURLs {
            try Data("candidate-reviewed test output".utf8).write(
                to: url,
                options: .atomic
            )
        }
        return GeneratedApplicationPacket(
            pdfURL: allURLs[0],
            richTextURL: allURLs[1],
            plainTextURL: allURLs[2],
            privateReviewURL: allURLs[3]
        )
    }
}

private enum BlockingPacketGeneratorError: Error {
    case timedOut
}

private struct UnexpectedPacketGenerator: ApplicationPacketGenerating {
    func generate(
        from _: ExportRequest,
        applicationID _: UUID?,
        packetVersion _: Int
    ) throws -> GeneratedApplicationPacket {
        throw UnexpectedPacketGeneratorError.called
    }
}

private enum UnexpectedPacketGeneratorError: Error {
    case called
}

private final class FailingJobTrackerStore: JobTrackerPersisting {
    func load() throws -> JobTrackerLoadOutcome? {
        nil
    }

    func save(_ records: [JobApplicationRecord]) throws {
        throw InjectedJobTrackerSaveError()
    }

    func delete() throws {}
}

private final class FailingRootWorkspaceStore: WorkspacePersisting {
    private let recorder: PersistenceOrderRecorder

    init(recorder: PersistenceOrderRecorder) {
        self.recorder = recorder
    }

    func load() throws -> WorkspaceLoadOutcome? {
        nil
    }

    func save(_ state: WorkspacePersistenceState) throws {
        recorder.events.append("root-save")
        throw InjectedRootSaveError()
    }

    func delete() throws {}
}

private final class RecordingApplicationWorkspaceStore:
    ApplicationWorkspacePersisting {
    private let recorder: PersistenceOrderRecorder
    private(set) var saveCount = 0

    init(recorder: PersistenceOrderRecorder) {
        self.recorder = recorder
    }

    func load(id: UUID) throws -> ApplicationWorkspaceLoadOutcome? {
        nil
    }

    func save(_ snapshot: ApplicationWorkspaceSnapshot, id: UUID) throws {
        saveCount += 1
        recorder.events.append("application-save")
    }

    func delete(id: UUID) throws {}
    func deleteAll() throws {}
}
