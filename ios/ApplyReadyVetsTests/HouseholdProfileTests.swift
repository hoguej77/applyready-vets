import XCTest
@testable import ApplyReadyVets

final class HouseholdProfileTests: XCTestCase {
    @MainActor
    func testProfileAndAssistanceChoicePersistAcrossLaunches() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        var model: AppModel? = makeModel(directory: directory)
        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "  Jordan\n ",
            relationship: .transitioningServiceMember,
            branch: "Air Force",
            careerGoal: "Cybersecurity",
            assistanceLevel: .appleOnDevice
        ) == true)
        XCTAssertEqual(model?.activePreferredName, "Jordan")
        XCTAssertEqual(model?.activeAssistanceLevel, .appleOnDevice)
        XCTAssertEqual(model?.draft.profile.militaryService.first?.branch, "Air Force")
        XCTAssertTrue(model?.draft.useAI == true)
        XCTAssertTrue(model?.draft.aiConsent == true)
        XCTAssertEqual(model?.draft.serviceConsent, false)
        model?.saveForSceneTransition()
        model = nil

        let restored = makeModel(directory: directory)
        XCTAssertEqual(restored.activePreferredName, "Jordan")
        XCTAssertEqual(
            restored.activeHouseholdProfile?.relationship,
            .transitioningServiceMember
        )
        XCTAssertEqual(restored.activeAssistanceLevel, .appleOnDevice)
        XCTAssertTrue(restored.hasActiveHouseholdProfile)
    }

    @MainActor
    func testSwitchingPeopleIsolatesCareerWorkspacesAndApplications() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(directory: directory)

        XCTAssertTrue(model.createHouseholdProfile(
            preferredName: "Jordan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ))
        let jordanID = try XCTUnwrap(model.activeHouseholdProfileID)
        model.draft.resumeText = "Jordan private resume evidence"
        XCTAssertTrue(model.upsertJobApplication(JobApplicationRecord(
            employer: "Jordan Employer",
            roleTitle: "Operations Manager"
        )))
        model.saveForSceneTransition()

        XCTAssertTrue(model.createHouseholdProfile(
            preferredName: "Casey",
            relationship: .militarySpouse,
            branch: "",
            careerGoal: "Project management",
            assistanceLevel: .externalByApproval
        ))
        let caseyID = try XCTUnwrap(model.activeHouseholdProfileID)
        XCTAssertNotEqual(caseyID, jordanID)
        XCTAssertTrue(model.jobApplications.isEmpty)
        XCTAssertFalse(model.draft.resumeText.contains("Jordan"))
        model.draft.resumeText = "Casey private resume evidence"
        model.saveForSceneTransition()

        model.switchHouseholdProfile(to: jordanID)
        XCTAssertEqual(model.activePreferredName, "Jordan")
        XCTAssertEqual(model.draft.resumeText, "Jordan private resume evidence")
        XCTAssertEqual(model.jobApplications.map(\.employer), ["Jordan Employer"])

        model.switchHouseholdProfile(to: caseyID)
        XCTAssertEqual(model.activePreferredName, "Casey")
        XCTAssertEqual(model.draft.resumeText, "Casey private resume evidence")
        XCTAssertTrue(model.jobApplications.isEmpty)
        XCTAssertEqual(model.activeAssistanceLevel, .externalByApproval)
        XCTAssertEqual(model.draft.serviceConsent, false)
    }

    @MainActor
    func testInvalidActiveProfileFailsClosedUntilJonathanOrDeniseIsExplicitlySelected() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var model: AppModel? = makeModel(directory: directory, hasComplete: true)

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Jonathan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ) == true)
        let jonathanID = try XCTUnwrap(model?.activeHouseholdProfileID)
        model?.draft.resumeText = "Jonathan private resume evidence"
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Jonathan Employer",
            roleTitle: "Operations Manager"
        )) == true)
        model?.saveForSceneTransition()

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Denise",
            relationship: .militarySpouse,
            branch: "",
            careerGoal: "Project management",
            assistanceLevel: .privateCore
        ) == true)
        let deniseID = try XCTUnwrap(model?.activeHouseholdProfileID)
        model?.draft.resumeText = "Denise private resume evidence"
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Denise Employer",
            roleTitle: "Project Manager"
        )) == true)
        model?.saveForSceneTransition()

        let store = ResilientWorkspaceStore(directory: directory)
        var malformedState = try XCTUnwrap(store.load()).state
        malformedState.activeHouseholdProfileID = UUID()
        try store.save(malformedState)
        model = nil

        let restored = makeModel(directory: directory, hasComplete: true)
        XCTAssertNil(restored.activeHouseholdProfileID)
        XCTAssertTrue(restored.requiresHouseholdProfileSelection)
        XCTAssertTrue(restored.jobApplications.isEmpty)
        XCTAssertTrue(restored.draft.resumeText.isEmpty)
        XCTAssertEqual(
            restored.errorMessage,
            "Your saved active profile could not be verified. Choose a local profile before reopening career work."
        )
        restored.loadDemo()
        XCTAssertNil(restored.activeHouseholdProfileID)
        XCTAssertEqual(Set(restored.householdProfiles.map(\.id)), Set([jonathanID, deniseID]))
        XCTAssertTrue(restored.draft.resumeText.isEmpty)

        restored.switchHouseholdProfile(to: deniseID)
        XCTAssertEqual(restored.activePreferredName, "Denise")
        XCTAssertEqual(restored.draft.resumeText, "Denise private resume evidence")
        XCTAssertEqual(restored.jobApplications.map(\.employer), ["Denise Employer"])

        restored.switchHouseholdProfile(to: jonathanID)
        XCTAssertEqual(restored.activePreferredName, "Jonathan")
        XCTAssertEqual(restored.draft.resumeText, "Jonathan private resume evidence")
        XCTAssertEqual(restored.jobApplications.map(\.employer), ["Jonathan Employer"])
    }

    @MainActor
    func testRestoreUsesActiveProfileSnapshotInsteadOfRedundantRootDraft() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var model: AppModel? = makeModel(directory: directory, hasComplete: true)

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Jonathan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ) == true)
        let jonathanID = try XCTUnwrap(model?.activeHouseholdProfileID)
        model?.draft.resumeText = "Jonathan private resume evidence"
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Jonathan Employer",
            roleTitle: "Operations Manager"
        )) == true)
        model?.saveForSceneTransition()

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Denise",
            relationship: .militarySpouse,
            branch: "",
            careerGoal: "Project management",
            assistanceLevel: .privateCore
        ) == true)
        model?.draft.resumeText = "Denise private resume evidence"
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Denise Employer",
            roleTitle: "Project Manager"
        )) == true)
        model?.saveForSceneTransition()

        let store = ResilientWorkspaceStore(directory: directory)
        var state = try XCTUnwrap(store.load()).state
        state.activeHouseholdProfileID = jonathanID
        state.draft.resumeText = "Denise root draft that must not open for Jonathan"
        try store.save(state)
        model = nil

        let restored = makeModel(directory: directory, hasComplete: true)
        XCTAssertEqual(restored.activeHouseholdProfileID, jonathanID)
        XCTAssertEqual(restored.draft.resumeText, "Jonathan private resume evidence")
        XCTAssertEqual(restored.jobApplications.map(\.employer), ["Jonathan Employer"])
    }

    @MainActor
    func testMismatchedSnapshotOwnerFailsClosed() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var model: AppModel? = makeModel(directory: directory, hasComplete: true)

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Jonathan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ) == true)
        let jonathanID = try XCTUnwrap(model?.activeHouseholdProfileID)
        model?.draft.resumeText = "Jonathan private resume evidence"
        model?.saveForSceneTransition()

        let store = ResilientWorkspaceStore(directory: directory)
        var state = try XCTUnwrap(store.load()).state
        var snapshots = try XCTUnwrap(state.householdWorkspaces)
        var snapshot = try XCTUnwrap(snapshots[jonathanID.uuidString])
        snapshot.ownerProfileID = UUID()
        snapshots[jonathanID.uuidString] = snapshot
        state.householdWorkspaces = snapshots
        try store.save(state)
        model = nil

        let restored = makeModel(directory: directory, hasComplete: true)
        XCTAssertNil(restored.activeHouseholdProfileID)
        XCTAssertTrue(restored.requiresHouseholdProfileSelection)
        XCTAssertTrue(restored.draft.resumeText.isEmpty)
    }

    @MainActor
    func testPrivateCoreDisablesGenerativeAndExternalServiceUse() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(directory: directory)

        XCTAssertTrue(model.createHouseholdProfile(
            preferredName: "Alex",
            relationship: .caregiver,
            branch: "",
            careerGoal: "",
            assistanceLevel: .externalByApproval
        ))
        model.setAssistanceLevel(.privateCore)

        XCTAssertFalse(model.draft.useAI)
        XCTAssertFalse(model.draft.aiConsent)
        XCTAssertEqual(model.draft.serviceConsent, false)
        XCTAssertFalse(model.activeAssistanceLevel.allowsExternalHandoff)
    }

    @MainActor
    func testRemovingPersonDeletesOwnedWorkspaceAndPreservesOtherPerson() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var model: AppModel? = makeModel(
            directory: directory,
            hasComplete: true
        )

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Jordan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ) == true)
        let jordanID = try XCTUnwrap(model?.activeHouseholdProfileID)
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Jordan Employer",
            roleTitle: "Operations Manager"
        )) == true)

        XCTAssertTrue(model?.createHouseholdProfile(
            preferredName: "Casey",
            relationship: .militarySpouse,
            branch: "",
            careerGoal: "Project management",
            assistanceLevel: .appleOnDevice
        ) == true)
        let caseyID = try XCTUnwrap(model?.activeHouseholdProfileID)
        XCTAssertTrue(model?.upsertJobApplication(JobApplicationRecord(
            employer: "Casey Employer",
            roleTitle: "Project Manager"
        )) == true)

        XCTAssertTrue(model?.removeActiveHouseholdProfile() == true)
        XCTAssertEqual(model?.activeHouseholdProfileID, jordanID)
        XCTAssertEqual(model?.householdProfiles.map(\.id), [jordanID])
        XCTAssertEqual(model?.jobApplications.map(\.employer), ["Jordan Employer"])
        XCTAssertFalse(model?.householdProfiles.contains { $0.id == caseyID } ?? true)
        model?.saveForSceneTransition()
        model = nil

        let restored = makeModel(directory: directory, hasComplete: true)
        XCTAssertEqual(restored.activeHouseholdProfileID, jordanID)
        XCTAssertEqual(restored.householdProfiles.map(\.displayName), ["Jordan"])
        XCTAssertEqual(restored.jobApplications.map(\.employer), ["Jordan Employer"])
    }

    @MainActor
    func testRemovingOnlyProfileIsRefusedWithoutChangingItsWork() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(directory: directory)

        XCTAssertTrue(model.createHouseholdProfile(
            preferredName: "Jordan",
            relationship: .veteran,
            branch: "Army",
            careerGoal: "Operations",
            assistanceLevel: .privateCore
        ))
        model.draft.resumeText = "Keep this protected evidence"

        XCTAssertFalse(model.removeActiveHouseholdProfile())
        XCTAssertEqual(model.householdProfiles.map(\.displayName), ["Jordan"])
        XCTAssertEqual(model.draft.resumeText, "Keep this protected evidence")
        XCTAssertEqual(
            model.errorMessage,
            "Keep at least one local profile. To remove the last profile, use Delete local workspace."
        )
    }

    @MainActor
    private func makeModel(
        directory: URL,
        hasComplete: Bool = false
    ) -> AppModel {
        AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            applicationWorkspaceStore: ResilientApplicationWorkspaceStore(
                directory: directory
            ),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory),
            entitlement: HouseholdTestEntitlement(hasComplete: hasComplete)
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("HouseholdProfileTests-\(UUID().uuidString)")
    }
}

@MainActor
private final class HouseholdTestEntitlement: AccessEntitling {
    let hasComplete: Bool

    init(hasComplete: Bool) {
        self.hasComplete = hasComplete
    }
}
