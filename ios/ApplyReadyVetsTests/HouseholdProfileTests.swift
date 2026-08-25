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
