import Foundation
import Combine
import CryptoKit

struct GeneratedApplicationPacket: Sendable {
    let pdfURL: URL
    let richTextURL: URL
    let plainTextURL: URL
    let privateReviewURL: URL

    var candidateBundle: LocalExportService.CandidateExportBundle {
        LocalExportService.CandidateExportBundle(
            pdfURL: pdfURL,
            richTextURL: richTextURL,
            plainTextURL: plainTextURL
        )
    }

    var allURLs: [URL] {
        [pdfURL, richTextURL, plainTextURL, privateReviewURL]
    }

    func removeFromDisk() {
        for url in allURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

protocol ApplicationPacketGenerating: Sendable {
    func generate(
        from request: ExportRequest,
        applicationID: UUID?,
        packetVersion: Int
    ) throws -> GeneratedApplicationPacket
}

struct LocalApplicationPacketGenerator: ApplicationPacketGenerating {
    func generate(
        from request: ExportRequest,
        applicationID: UUID?,
        packetVersion: Int
    ) throws -> GeneratedApplicationPacket {
        try Task.checkCancellation()
        let candidateBundle = try LocalExportService.createCandidateReviewedBundle(
            from: request,
            applicationID: applicationID,
            packetVersion: packetVersion
        )
        var generatedURLs = candidateBundle.allURLs
        do {
            try Task.checkCancellation()
            let privateReviewURL = try LocalExportService.createPrivateReviewReport(
                from: request,
                applicationID: applicationID,
                packetVersion: packetVersion
            )
            generatedURLs.append(privateReviewURL)
            try Task.checkCancellation()
            return GeneratedApplicationPacket(
                pdfURL: candidateBundle.pdfURL,
                richTextURL: candidateBundle.richTextURL,
                plainTextURL: candidateBundle.plainTextURL,
                privateReviewURL: privateReviewURL
            )
        } catch {
            for url in generatedURLs {
                try? FileManager.default.removeItem(at: url)
            }
            throw error
        }
    }
}

private enum HouseholdProfileRemovalError: LocalizedError {
    case protectedSaveFailed

    var errorDescription: String? {
        "The remaining household workspace could not be verified after removal."
    }
}

@MainActor
final class AppModel: ObservableObject {
    private var draftRevision: UInt64 = 0
    private var responseDraftRevision: UInt64?
    private var responseRevision: UInt64 = 0

    enum MainSection: Hashable {
        case home
        case builder
        case tracker
        case toolkit
    }

    enum FlowStep: Int, CaseIterable, Identifiable {
        case importDocuments
        case serviceProfile
        case analyze
        case review
        case export

        var id: Int { rawValue }
        var title: String {
            switch self {
            case .importDocuments: "Import"
            case .serviceProfile: "Profile"
            case .analyze: "Analysis"
            case .review: "Truth Lock"
            case .export: "Export"
            }
        }
    }

    @Published var hasStarted = false
    @Published var selectedMainSection: MainSection = .home
    @Published var step: FlowStep = .importDocuments
    @Published var draft = WorkspaceDraft() {
        didSet {
            // A cheap revision makes stale results unavailable synchronously.
            // Hashing the full bounded résumé in a view-facing getter caused
            // avoidable work during typing and navigation.
            draftRevision &+= 1
        }
    }
    @Published var response: TailorResponse? {
        didSet {
            responseRevision &+= 1
            if response == nil {
                responseDraftRevision = nil
            }
        }
    }
    @Published var health: HealthResponse?
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var exportURL: URL?
    @Published var exportPDFURL: URL?
    @Published var exportRichTextURL: URL?
    @Published var privateReviewURL: URL?
    @Published var linkedInKit: LinkedInProfileKit?
    @Published var apiBaseURL: String
    @Published var apiToken = ""
    @Published var jobURL = ""
    @Published var pendingSharedJobText: String?
    @Published var pendingSharedJobSourceLabel = "another app"
    @Published var isSharedJobDecisionPresented = false
    @Published var importReviewWarnings: [String] = []
    @Published var hasAcknowledgedImportWarnings = true
    @Published private(set) var jobApplications: [JobApplicationRecord] = []
    @Published private(set) var householdProfiles: [HouseholdProfile] = []
    @Published private(set) var activeHouseholdProfileID: UUID?
    @Published var showsCompletePaywall = false
    @Published var selectedTrackedApplicationID: UUID?
    @Published private(set) var spotlightApplicationsEnabled: Bool
    @Published private(set) var widgetApplicationDetailsEnabled: Bool
    @Published private(set) var truthLockEnabled: Bool
    @Published private(set) var isLocalErasePending = false

    private let draftStore = DraftStore()
    private let workspaceStore: any WorkspacePersisting
    private let applicationWorkspaceStore: any ApplicationWorkspacePersisting
    private let jobTrackerStore: any JobTrackerPersisting
    private let entitlement: any AccessEntitling
    private let packetGenerator: any ApplicationPacketGenerating
    private let sharedInboxDirectoryOverride: URL?
    private let keychain = KeychainStore(service: "com.jonathanhogue.applyreadyvets")
    private let legacyMusterForwardKeychain = KeychainStore(service: "com.jonathanhogue.musterforward")
    private let legacyKeychain = KeychainStore(service: "com.hogueresmaster.app")
    private var draftAutosave: AnyCancellable?
    private var draftInvalidation: AnyCancellable?
    private var pendingSharedJobID: UUID?
    private var pendingSharedJobSourceURL: String?
    private var analysisInputFingerprint: String?
    private var exportTask: Task<GeneratedApplicationPacket, Error>?
    private var applicationWorkspaces: [UUID: ApplicationWorkspaceSnapshot] = [:]
    private var householdWorkspaces: [UUID: HouseholdWorkspaceSnapshot] = [:]
    private var storedJobApplications: [JobApplicationRecord] = []
    private static let localErasePendingPreferenceKey =
        "ApplyReadyVets.localErasePending.v1"
    static let truthLockPreferenceKey =
        "ApplyReadyVets.truthLockEnabled.v1"

    init(
        workspaceStore: any WorkspacePersisting = ResilientWorkspaceStore(),
        applicationWorkspaceStore: any ApplicationWorkspacePersisting =
            ResilientApplicationWorkspaceStore(),
        jobTrackerStore: any JobTrackerPersisting = ResilientJobTrackerStore(),
        entitlement: any AccessEntitling = FreeAccessEntitlement(),
        sharedInboxDirectoryOverride: URL? = nil,
        packetGenerator: any ApplicationPacketGenerating =
            LocalApplicationPacketGenerator()
    ) {
        self.workspaceStore = workspaceStore
        self.applicationWorkspaceStore = applicationWorkspaceStore
        self.jobTrackerStore = jobTrackerStore
        self.entitlement = entitlement
        self.packetGenerator = packetGenerator
        self.sharedInboxDirectoryOverride = sharedInboxDirectoryOverride
        spotlightApplicationsEnabled = UserDefaults.standard.bool(
            forKey: ApplicationSpotlightIndexer.preferenceKey
        )
        widgetApplicationDetailsEnabled = UserDefaults.standard.bool(
            forKey: ApplicationWidgetBridge.detailPreferenceKey
        )
        truthLockEnabled = ProcessInfo.processInfo.arguments.contains("-UI_TESTING")
            ? true
            : (UserDefaults.standard.object(
                forKey: Self.truthLockPreferenceKey
            ) as? Bool ?? true)
        ApplicationWidgetSnapshotStore.purgeLegacySnapshot()
        // UI automation must start from a deterministic screen even when the
        // Simulator retains an earlier developer workspace. This argument is
        // supplied only by the UI-test target and is never used in production.
        if ProcessInfo.processInfo.arguments.contains("-UI_TESTING") {
            try? workspaceStore.delete()
            try? applicationWorkspaceStore.deleteAll()
            try? jobTrackerStore.delete()
            spotlightApplicationsEnabled = false
            widgetApplicationDetailsEnabled = false
            UserDefaults.standard.removeObject(
                forKey: ApplicationSpotlightIndexer.preferenceKey
            )
            ApplicationSpotlightIndexer.clearDeletionPending()
            UserDefaults.standard.removeObject(
                forKey: ApplicationWidgetBridge.detailPreferenceKey
            )
            UserDefaults.standard.removeObject(
                forKey: Self.truthLockPreferenceKey
            )
            UserDefaults.standard.removeObject(
                forKey: Self.localErasePendingPreferenceKey
            )
            UserDefaults.standard.removeObject(forKey: ShortcutDestination.storageKey)
            UserDefaults.standard.removeObject(forKey: ShortcutDestination.pendingJobURLKey)
        }
        #if DEBUG
        apiBaseURL = UserDefaults.standard.string(forKey: "apiBaseURL")
            ?? (Bundle.main.object(
                forInfoDictionaryKey: "HOGUE_API_BASE_URL"
            ) as? String)
            ?? "http://127.0.0.1:8000"
        apiToken = keychain.read(account: "apiToken")
            ?? legacyMusterForwardKeychain.read(account: "apiToken")
            ?? legacyKeychain.read(account: "apiToken")
            ?? ""
        #else
        // Release builds accept only the endpoint signed into the app bundle.
        // A development override from UserDefaults or a legacy Keychain entry
        // must never redirect veteran documents after an upgrade.
        apiBaseURL = (Bundle.main.object(
            forInfoDictionaryKey: "HOGUE_API_BASE_URL"
        ) as? String) ?? ""
        apiToken = ""
        UserDefaults.standard.removeObject(forKey: "apiBaseURL")
        keychain.delete(account: "apiToken")
        legacyMusterForwardKeychain.delete(account: "apiToken")
        legacyKeychain.delete(account: "apiToken")
        #endif

        let hadPendingLocalErase = UserDefaults.standard.bool(
            forKey: Self.localErasePendingPreferenceKey
        )
        isLocalErasePending = hadPendingLocalErase
        let pendingLocalEraseFailures: [String]
        if hadPendingLocalErase {
            spotlightApplicationsEnabled = false
            widgetApplicationDetailsEnabled = false
            UserDefaults.standard.set(
                false,
                forKey: ApplicationSpotlightIndexer.preferenceKey
            )
            UserDefaults.standard.set(
                false,
                forKey: ApplicationWidgetBridge.detailPreferenceKey
            )
            pendingLocalEraseFailures = deleteAllLocalDataFilesAndCredentials()
            apiToken = ""
            #if DEBUG
            apiBaseURL = (Bundle.main.object(
                forInfoDictionaryKey: "HOGUE_API_BASE_URL"
            ) as? String) ?? "http://127.0.0.1:8000"
            #else
            apiBaseURL = ""
            #endif
            if pendingLocalEraseFailures.isEmpty {
                UserDefaults.standard.removeObject(
                    forKey: Self.localErasePendingPreferenceKey
                )
                isLocalErasePending = false
                statusMessage = "A previously interrupted local deletion was completed before restoring any workspace."
            } else {
                errorMessage = "Local deletion is still incomplete: \(pendingLocalEraseFailures.joined(separator: "; ")). Saved work will stay closed until cleanup succeeds."
            }
        } else {
            pendingLocalEraseFailures = []
        }

        if pendingLocalEraseFailures.isEmpty {
            do {
                if let outcome = try workspaceStore.load() {
                    try CareerInputPolicy.validate(outcome.state.draft)
                    for snapshot in (outcome.state.applicationWorkspaces ?? [:]).values {
                        try CareerInputPolicy.validate(snapshot.draft)
                    }
                    for snapshot in (outcome.state.householdWorkspaces ?? [:]).values {
                        try CareerInputPolicy.validate(snapshot.draft)
                    }
                    restore(outcome.state)
                    try migrateLegacyApplicationWorkspaces()
                    if !(outcome.state.applicationWorkspaces ?? [:]).isEmpty {
                        try workspaceStore.save(persistenceState())
                    }
                    if outcome.recoveredFromBackup {
                        statusMessage = "Your workspace was restored from its protected recovery copy."
                    }
                } else if let saved = draftStore.load() {
                    try CareerInputPolicy.validate(saved)
                    draft = saved
                    jobURL = saved.jobURL ?? ""
                    hasStarted = true
                    try workspaceStore.save(persistenceState())
                    draftStore.delete()
                    statusMessage = "Your earlier ApplyReady Vets draft was upgraded safely."
                }
                ensureLegacyHouseholdProfileIfNeeded()
                if hasActiveHouseholdProfile {
                    try workspaceStore.save(persistenceState())
                }
            } catch {
                errorMessage = "Your saved workspace needs attention: \(error.localizedDescription)"
            }
        }

        #if !DEBUG
        draft.serviceConsent = false
        #endif

        if pendingLocalEraseFailures.isEmpty {
            do {
                if let outcome = try jobTrackerStore.load() {
                    for record in outcome.records {
                        try CareerInputPolicy.validate(record)
                    }
                    storedJobApplications = outcome.records.sorted {
                        $0.updatedAt > $1.updatedAt
                    }
                    let migratedOwnership = assignLegacyApplicationsToActiveProfile()
                    refreshVisibleJobApplications()
                    if migratedOwnership {
                        try jobTrackerStore.save(storedJobApplications)
                    }
                    if outcome.recoveredFromBackup {
                        statusMessage = "Your application tracker was restored from its protected recovery copy."
                    }
                }
            } catch {
                errorMessage = "Your application tracker needs attention: \(error.localizedDescription)"
            }
        }
        // This also retries any privacy revocation that could not finish
        // before a previous process exit, including an empty tracker.
        refreshApplicationSpotlightIndex()

        if !isLocalErasePending {
            purgeAppTemporaryExports()
            do {
                try UserDocumentWorkspace.prepareSimulatorDocuments()
            } catch {
                errorMessage = "Simulator sample files could not be prepared: \(error.localizedDescription)"
            }
            startDraftObservation()
        }
    }

    private func startDraftObservation() {
        draftInvalidation?.cancel()
        draftAutosave?.cancel()
        draftInvalidation = $draft
            .dropFirst()
            .sink { [weak self] newDraft in
                Task { @MainActor [weak self] in
                    self?.invalidateDerivedResults(for: newDraft)
                }
            }
        draftAutosave = $draft
            .dropFirst()
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.persistWorkspace()
                }
            }
    }

    var canContinueFromImport: Bool {
        !draft.resumeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !draft.jobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            hasAcknowledgedImportWarnings
    }

    var effectiveResumeMode: ResumeMode {
        Self.resolvedResumeMode(for: draft)
    }

    var approvedCount: Int {
        currentResponse?.proposals.filter { [.approved, .edited].contains($0.status) }.count ?? 0
    }

    var currentResponse: TailorResponse? {
        guard analysisInputFingerprint != nil,
              responseDraftRevision == draftRevision else { return nil }
        return response
    }

    var candidateReviewedResumeText: String? {
        guard let response = currentResponse else { return nil }
        return try? LocalExportService.validatedResumeText(
            from: exportRequest(for: response)
        )
    }

    var pendingSharedJobDescription: String {
        pendingSharedJobSourceLabel == "another app"
            ? "job item from another app"
            : "\(pendingSharedJobSourceLabel) job item"
    }

    var activeHouseholdProfile: HouseholdProfile? {
        guard let activeHouseholdProfileID else { return nil }
        return householdProfiles.first { $0.id == activeHouseholdProfileID }
    }

    var activePreferredName: String? {
        activeHouseholdProfile?.displayName
    }

    var activeAssistanceLevel: AssistanceLevel {
        activeHouseholdProfile?.assistanceLevel ?? .privateCore
    }

    var hasActiveHouseholdProfile: Bool {
        activeHouseholdProfile != nil
    }

    func start() {
        guard hasActiveHouseholdProfile else {
            statusMessage = "Create a private profile first so this workspace belongs to the right person."
            return
        }
        hasStarted = true
        selectedMainSection = .builder
        step = .importDocuments
    }

    @discardableResult
    func createHouseholdProfile(
        preferredName: String,
        relationship: HouseholdRelationship,
        branch: String,
        careerGoal: String,
        assistanceLevel: AssistanceLevel
    ) -> Bool {
        guard householdProfiles.count < 8 else {
            errorMessage = "This device already has eight local profiles. Remove an unused profile before adding another."
            return false
        }
        let name = Self.normalizedHouseholdField(preferredName, limit: 60)
        guard !name.isEmpty else {
            errorMessage = "Enter the name you want ApplyReady Vets to use."
            return false
        }
        let safeBranch = Self.normalizedHouseholdField(branch, limit: 60)
        let safeGoal = Self.normalizedHouseholdField(careerGoal, limit: 120)

        if activeHouseholdProfileID != nil, !saveWorkspace() {
            return false
        }

        let profile = HouseholdProfile(
            preferredName: name,
            relationship: relationship,
            branch: safeBranch,
            careerGoal: safeGoal,
            assistanceLevel: assistanceLevel
        )
        householdProfiles.append(profile)
        householdProfiles.sort {
            $0.createdAt < $1.createdAt
        }
        activeHouseholdProfileID = profile.id
        resetWorkspace(for: profile)
        hasStarted = true
        selectedMainSection = .home
        step = .importDocuments
        refreshVisibleJobApplications()
        guard saveWorkspace() else { return false }
        refreshApplicationSpotlightIndex()
        statusMessage = "Welcome, \(profile.displayName). Your protected workspace is ready."
        return true
    }

    func switchHouseholdProfile(to profileID: UUID) {
        guard profileID != activeHouseholdProfileID,
              let profile = householdProfiles.first(where: { $0.id == profileID }) else {
            return
        }
        guard saveWorkspace() else { return }
        deleteGeneratedFiles()
        activeHouseholdProfileID = profileID
        if let snapshot = householdWorkspaces[profileID] {
            restoreHouseholdWorkspace(snapshot)
        } else {
            resetWorkspace(for: profile)
        }
        hasStarted = true
        selectedMainSection = .home
        selectedTrackedApplicationID = nil
        refreshVisibleJobApplications()
        persistWorkspace()
        refreshApplicationSpotlightIndex()
        statusMessage = "\(profile.displayName)’s private workspace is open."
    }

    @discardableResult
    func removeActiveHouseholdProfile() -> Bool {
        guard householdProfiles.count > 1,
              let profileID = activeHouseholdProfileID,
              let profile = activeHouseholdProfile else {
            errorMessage = "Keep at least one local profile. To remove the last profile, use Delete local workspace."
            return false
        }
        guard saveWorkspace() else { return false }

        let previousRoot = persistenceState()
        let previousApplications = storedJobApplications
        let previousSection = selectedMainSection
        let previousSelectedApplicationID = selectedTrackedApplicationID
        let ownedApplications = previousApplications.filter {
            $0.ownerProfileID == profileID
        }
        let ownedApplicationIDs = Set(ownedApplications.map(\.id))
        var recoverableSnapshots: [UUID: ApplicationWorkspaceSnapshot] = [:]

        do {
            for record in ownedApplications {
                if let outcome = try applicationWorkspaceStore.load(id: record.id) {
                    recoverableSnapshots[record.id] = outcome.snapshot
                }
            }

            for record in ownedApplications {
                try applicationWorkspaceStore.delete(id: record.id)
            }
            let remainingApplications = previousApplications.filter {
                $0.ownerProfileID != profileID
            }
            try jobTrackerStore.save(remainingApplications)

            householdProfiles.removeAll { $0.id == profileID }
            householdWorkspaces[profileID] = nil
            storedJobApplications = remainingApplications
            applicationWorkspaces = applicationWorkspaces.filter {
                !ownedApplicationIDs.contains($0.key)
            }
            let nextProfile = householdProfiles[0]
            activeHouseholdProfileID = nextProfile.id
            deleteGeneratedFiles()
            if let snapshot = householdWorkspaces[nextProfile.id] {
                restoreHouseholdWorkspace(snapshot)
            } else {
                resetWorkspace(for: nextProfile)
            }
            hasStarted = true
            selectedMainSection = .home
            selectedTrackedApplicationID = nil
            refreshVisibleJobApplications()

            // Remove both the primary and recovery root before committing the
            // new profile list so the deleted person cannot return from an
            // older recovery copy.
            try workspaceStore.delete()
            guard saveWorkspace() else {
                throw HouseholdProfileRemovalError.protectedSaveFailed
            }
        } catch {
            var rollbackFailures: [String] = []
            storedJobApplications = previousApplications
            restore(previousRoot)
            selectedMainSection = previousSection
            selectedTrackedApplicationID = previousSelectedApplicationID
            refreshVisibleJobApplications()
            do {
                try workspaceStore.delete()
                try workspaceStore.save(previousRoot)
            } catch {
                rollbackFailures.append("root workspace")
            }
            do {
                try jobTrackerStore.save(previousApplications)
            } catch {
                rollbackFailures.append("application tracker")
            }
            for (id, snapshot) in recoverableSnapshots {
                do {
                    try applicationWorkspaceStore.save(snapshot, id: id)
                } catch {
                    rollbackFailures.append("application workspace")
                }
            }
            refreshApplicationSpotlightIndex()
            if rollbackFailures.isEmpty {
                errorMessage = "\(profile.displayName)’s profile could not be removed. Its protected app data was restored. \(error.localizedDescription)"
            } else {
                errorMessage = "Profile removal did not finish and some protected data could not be restored (\(Set(rollbackFailures).sorted().joined(separator: ", "))). Use Delete local workspace if you need to remove every local copy."
            }
            return false
        }

        refreshApplicationSpotlightIndex()
        statusMessage = "\(profile.displayName)’s profile, tracker records, and protected app workspaces were removed. Files previously exported to Files were left for you to manage."
        return true
    }

    func updateActiveHouseholdProfile(
        preferredName: String,
        relationship: HouseholdRelationship,
        branch: String,
        careerGoal: String
    ) {
        guard let id = activeHouseholdProfileID,
              let index = householdProfiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        let name = Self.normalizedHouseholdField(preferredName, limit: 60)
        guard !name.isEmpty else {
            errorMessage = "Enter the name you want ApplyReady Vets to use."
            return
        }
        householdProfiles[index].preferredName = name
        householdProfiles[index].relationship = relationship
        householdProfiles[index].branch = Self.normalizedHouseholdField(
            branch,
            limit: 60
        )
        householdProfiles[index].careerGoal = Self.normalizedHouseholdField(
            careerGoal,
            limit: 120
        )
        householdProfiles[index].updatedAt = Date()
        applyIdentity(householdProfiles[index], to: &draft)
        persistWorkspace()
    }

    func setAssistanceLevel(_ level: AssistanceLevel) {
        guard let id = activeHouseholdProfileID,
              let index = householdProfiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        householdProfiles[index].assistanceLevel = level
        householdProfiles[index].updatedAt = Date()
        applyAssistance(level, to: &draft)
        persistWorkspace()
        statusMessage = "Assistance is set to \(level.title)."
    }

    func handlePendingShortcut() {
        guard let rawValue = UserDefaults.standard.string(forKey: ShortcutDestination.storageKey),
              let destination = ShortcutDestination(rawValue: rawValue) else { return }
        UserDefaults.standard.removeObject(forKey: ShortcutDestination.storageKey)
        if case .startApplication = destination {
            _ = beginNewApplication()
            return
        }
        hasStarted = true
        selectedMainSection = .builder
        switch destination {
        case .startApplication:
            break
        case .reviewTruthLock:
            step = currentResponse == nil ? .analyze : .review
        case .buildLinkedIn:
            step = currentResponse == nil ? .importDocuments : .export
        case .saveJob:
            let pendingURL = UserDefaults.standard.string(forKey: ShortcutDestination.pendingJobURLKey) ?? ""
            UserDefaults.standard.removeObject(forKey: ShortcutDestination.pendingJobURLKey)
            if let normalizedURL = JobURLPolicy.normalize(pendingURL) {
                jobURL = normalizedURL
                draft.jobURL = normalizedURL
                statusMessage = "\(JobPlatform.detect(from: normalizedURL).label) job link saved. Paste or import the posting text to analyze it."
                persistDraft()
            } else if !pendingURL.isEmpty {
                errorMessage = AppInputError.invalidJobURL.localizedDescription
            }
            step = .importDocuments
        case .prepareIndeed:
            let pendingURL = UserDefaults.standard.string(forKey: ShortcutDestination.pendingJobURLKey) ?? ""
            UserDefaults.standard.removeObject(forKey: ShortcutDestination.pendingJobURLKey)
            guard let normalizedURL = JobURLPolicy.normalize(pendingURL),
                  JobPlatform.detect(from: normalizedURL) == .indeed else {
                errorMessage = "Use a public Indeed job link without a username or password."
                step = .importDocuments
                return
            }
            jobURL = normalizedURL
            draft.jobURL = normalizedURL
            statusMessage = "Indeed job link saved. Paste or import the posting text, then review your evidence-backed packet before opening Indeed to submit."
            persistDraft()
            step = .importDocuments
        }
    }

    func openSpotlightApplication(searchableIdentifier: String) {
        guard let id = ApplicationSpotlightIndexer.applicationID(
            from: searchableIdentifier
        ),
        jobApplications.contains(where: { $0.id == id }) else {
            return
        }
        hasStarted = true
        selectedMainSection = .tracker
        selectedTrackedApplicationID = id
    }

    func openDeepLink(_ url: URL) {
        guard let route = AppDeepLink(url: url) else { return }
        hasStarted = true
        switch route {
        case .applications:
            selectedMainSection = .tracker
        case .workspace:
            selectedMainSection = .builder
        case .toolkit:
            selectedMainSection = .toolkit
        }
    }

    func setSpotlightApplicationsEnabled(_ enabled: Bool) {
        spotlightApplicationsEnabled = enabled
        UserDefaults.standard.set(
            enabled,
            forKey: ApplicationSpotlightIndexer.preferenceKey
        )
        refreshApplicationSpotlightIndex(reportSpotlightFailure: true)
    }

    func setWidgetApplicationDetailsEnabled(_ enabled: Bool) {
        widgetApplicationDetailsEnabled = enabled
        UserDefaults.standard.set(
            enabled,
            forKey: ApplicationWidgetBridge.detailPreferenceKey
        )
        refreshApplicationSpotlightIndex(reportWidgetFailure: true)
    }

    func setTruthLockEnabled(_ enabled: Bool) {
        truthLockEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.truthLockPreferenceKey)
        statusMessage = enabled
            ? "Truth Lock will verify AI suggestions before they appear."
            : "AI suggestions may appear as unverified drafts. Sensitive-content blocking and verified export remain active."
    }

    func resumePlatformPrivacyWork() {
        if isLocalErasePending {
            retryLocalEraseCleanup()
        }
        refreshApplicationSpotlightIndex()
    }

    func retryLocalEraseCleanup() {
        guard isLocalErasePending else { return }
        let failures = deleteAllLocalDataFilesAndCredentials()
        if failures.isEmpty {
            UserDefaults.standard.removeObject(
                forKey: Self.localErasePendingPreferenceKey
            )
            isLocalErasePending = false
            errorMessage = nil
            statusMessage = "The interrupted local deletion is complete. No saved workspace was reopened."
            startDraftObservation()
        } else {
            errorMessage = "Local deletion is still incomplete: \(failures.joined(separator: "; ")). Saved work remains closed; unlock the device or free storage, then retry."
        }
    }

    func handleIncomingShare() {
        if pendingSharedJobID != nil {
            if pendingSharedJobText != nil || pendingSharedJobSourceURL != nil {
                isSharedJobDecisionPresented = true
            }
            return
        }
        do {
            guard let payload = try SharedJobInbox.pending(
                directoryOverride: sharedInboxDirectoryOverride
            ).first else { return }
            hasStarted = true
            selectedMainSection = .builder
            step = .importDocuments
            pendingSharedJobID = payload.id
            pendingSharedJobText = payload.text
            pendingSharedJobSourceURL = payload.sourceURL

            if let sourceURL = payload.sourceURL {
                pendingSharedJobSourceLabel = JobPlatform.detect(from: sourceURL).label
            } else {
                pendingSharedJobSourceLabel = "another app"
            }

            let hasCurrentJob = !draft.jobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !(draft.jobURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if hasCurrentJob {
                guard saveWorkspace() else { return }
                isSharedJobDecisionPresented = true
                statusMessage = "A shared \(pendingSharedJobDescription) is waiting for your decision."
                return
            }

            applyPendingSharedJob()
            guard saveWorkspace() else { return }
            try acknowledgeIncomingShare()
            statusMessage = payload.text == nil
                ? "The shared job link is saved. Paste the posting text when ready."
                : "The shared job posting is ready to review."
        } catch {
            if let inboxError = error as? SharedJobInbox.InboxError,
               inboxError == .appGroupUnavailable,
               sharedInboxDirectoryOverride == nil {
                // An unsigned Simulator build has no signed App Group container.
                // This is expected during local visual testing and should not
                // interrupt the user before anything has actually been shared.
                return
            }
            errorMessage = "The shared job item could not be opened safely: \(error.localizedDescription)"
        }
    }

    func replaceCurrentJobWithSharedItem() {
        guard pendingSharedJobID != nil else { return }
        applyPendingSharedJob()
        guard saveWorkspace() else { return }
        do {
            try acknowledgeIncomingShare()
            statusMessage = "The shared job item replaced the earlier job text and link."
        } catch {
            errorMessage = "The posting was saved, but the shared inbox could not be cleared: \(error.localizedDescription)"
        }
    }

    func keepCurrentJob() {
        guard pendingSharedJobID != nil else { return }
        guard saveWorkspace() else { return }
        do {
            try acknowledgeIncomingShare()
            statusMessage = "Your existing job text and link were kept."
        } catch {
            errorMessage = "Your choice was saved, but the shared inbox could not be cleared: \(error.localizedDescription)"
        }
    }

    func loadDemo() {
        deleteGeneratedFiles()
        if activeHouseholdProfileID == nil {
            let demoName = DemoData.draft.profile.fullName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
                .first
                .map(String.init) ?? "Taylor"
            let demoProfile = HouseholdProfile(
                preferredName: demoName,
                relationship: .veteran,
                branch: DemoData.draft.profile.militaryService.first?.branch ?? "",
                careerGoal: DemoData.draft.profile.targetRole,
                assistanceLevel: .appleOnDevice
            )
            householdProfiles = [demoProfile]
            activeHouseholdProfileID = demoProfile.id
        }
        draft = DemoData.draft
        response = nil
        analysisInputFingerprint = nil
        linkedInKit = nil
        exportURL = nil
        exportPDFURL = nil
        exportRichTextURL = nil
        privateReviewURL = nil
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        hasStarted = true
        selectedMainSection = .builder
        step = .importDocuments
        persistDraft()
    }

    @discardableResult
    func saveCurrentJobToTracker() -> UUID? {
        let responseWasCurrent = currentResponse != nil
        let previousDraftURL = draft.jobURL.flatMap(JobURLPolicy.normalize)
        let enteredURL = jobURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedURL: String
        if enteredURL.isEmpty {
            normalizedURL = ""
        } else if let validURL = JobURLPolicy.normalize(enteredURL) {
            normalizedURL = validURL
        } else {
            errorMessage =
                "\(JobURLPolicy.validationMessage) Your tracker was not changed."
            return nil
        }
        let analysis = currentResponse?.job
        let recordID = draft.trackerRecordID ?? UUID()
        var record = jobApplications.first(where: { $0.id == recordID })
            ?? JobApplicationRecord(id: recordID)

        let detectedPlatform = normalizedURL.isEmpty
            ? record.platform
            : JobPlatform.detect(from: normalizedURL)
        let analyzedEmployer = analysis?.company.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let analyzedRole = analysis?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let targetRole = draft.profile.targetRole.trimmingCharacters(in: .whitespacesAndNewlines)

        record.platform = detectedPlatform
        record.sourceURL = normalizedURL
        if !analyzedEmployer.isEmpty, analyzedEmployer.lowercased() != "unknown" {
            record.employer = analyzedEmployer
        }
        if !analyzedRole.isEmpty, analyzedRole.lowercased() != "unknown" {
            record.roleTitle = analyzedRole
        } else if !targetRole.isEmpty {
            record.roleTitle = targetRole
        }
        if record.status == .saved,
           !draft.resumeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !draft.jobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            record.status = .preparing
        }
        record.updatedAt = Date()

        guard upsertJobApplication(record) else { return nil }
        let nextDraftURL = normalizedURL.isEmpty ? nil : normalizedURL
        if draft.trackerRecordID != record.id {
            draft.trackerRecordID = record.id
        }
        if draft.jobURL != nextDraftURL {
            draft.jobURL = nextDraftURL
        }
        if responseWasCurrent, previousDraftURL == nextDraftURL {
            // Tracker identity is administrative metadata and is intentionally
            // excluded from the analysis fingerprint. Keep a valid analysis
            // current when that is the only draft change.
            responseDraftRevision = draftRevision
        }
        jobURL = normalizedURL
        persistWorkspace()
        statusMessage = "\(record.displayTitle) is saved in your application tracker."
        return record.id
    }

    @discardableResult
    func upsertJobApplication(_ record: JobApplicationRecord) -> Bool {
        let createsNewWorkspace = !storedJobApplications.contains {
            $0.id == record.id
        }
        if createsNewWorkspace,
           !entitlement.hasComplete,
           !storedJobApplications.isEmpty {
            showsCompletePaywall = true
            return false
        }
        var updated = record
        updated.ownerProfileID = activeHouseholdProfileID
        updated.employer = updated.employer.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.roleTitle = updated.roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.jobID = updated.jobID.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredURL = updated.sourceURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if enteredURL.isEmpty {
            updated.sourceURL = ""
        } else if let validURL = JobURLPolicy.normalize(enteredURL) {
            updated.sourceURL = validURL
        } else {
            errorMessage =
                "\(JobURLPolicy.validationMessage) Your tracker changes were not saved."
            return false
        }
        updated.requiredDocuments = Array(
            Set(updated.requiredDocuments.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty })
        ).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        updated.updatedAt = Date()
        do {
            try CareerInputPolicy.validate(updated)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        var next = storedJobApplications
        if let index = next.firstIndex(where: { $0.id == updated.id }) {
            next[index] = updated
        } else {
            next.append(updated)
        }
        next.sort { $0.updatedAt > $1.updatedAt }

        do {
            try jobTrackerStore.save(next)
            storedJobApplications = next
            refreshVisibleJobApplications()
            refreshApplicationSpotlightIndex()
            return true
        } catch {
            errorMessage = "The application is still on screen, but the protected tracker save failed: \(error.localizedDescription)"
            return false
        }
    }

    func requestNewApplicationWorkspace() -> Bool {
        guard entitlement.hasComplete || !hasExistingApplicationWorkspace else {
            showsCompletePaywall = true
            return false
        }
        return true
    }

    /// Starts a distinct application workspace without allowing an App Intent
    /// or toolkit shortcut to reuse the current job's identity. Candidate
    /// profile and base-resume inputs carry forward; job-specific state does
    /// not. The free boundary is checked before any state is mutated.
    @discardableResult
    func beginNewApplication(mode: ResumeMode = .auto) -> Bool {
        guard requestNewApplicationWorkspace() else { return false }
        if draft.trackerRecordID == nil,
           hasSubstantiveUntrackedApplication,
           saveCurrentJobToTracker() == nil {
            return false
        }
        guard saveWorkspace() else { return false }

        let previousState = persistenceState()
        let previousSection = selectedMainSection
        let previousSelectedApplicationID = selectedTrackedApplicationID
        let previousExportURL = exportURL
        let previousExportPDFURL = exportPDFURL
        let previousExportRichTextURL = exportRichTextURL
        let previousPrivateReviewURL = privateReviewURL
        let previousStatusMessage = statusMessage
        let newApplicationID = UUID()
        let previousDraft = draft

        var nextDraft = WorkspaceDraft()
        nextDraft.profile = previousDraft.profile
        nextDraft.profile.targetRole = ""
        nextDraft.resumeText = previousDraft.resumeText
        nextDraft.resumeFilename = previousDraft.resumeFilename
        nextDraft.mode = mode
        nextDraft.useAI = previousDraft.useAI
        // Consent is scoped to one application workspace. Carry the user's
        // feature preference, but require a fresh choice before any new job's
        // material is processed.
        nextDraft.aiConsent = false
        nextDraft.serviceConsent = false
        nextDraft.trackerRecordID = newApplicationID

        deleteGeneratedFiles()
        draft = nextDraft
        jobURL = ""
        response = nil
        linkedInKit = nil
        analysisInputFingerprint = nil
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        hasStarted = true
        selectedMainSection = .builder
        selectedTrackedApplicationID = nil
        step = .importDocuments

        guard saveWorkspace() else {
            let saveFailure = errorMessage
            try? applicationWorkspaceStore.delete(id: newApplicationID)
            restore(previousState)
            selectedMainSection = previousSection
            selectedTrackedApplicationID = previousSelectedApplicationID
            exportURL = previousExportURL
            exportPDFURL = previousExportPDFURL
            exportRichTextURL = previousExportRichTextURL
            privateReviewURL = previousPrivateReviewURL
            statusMessage = previousStatusMessage
            errorMessage = saveFailure
            return false
        }

        statusMessage = mode == .federal
            ? "A new Federal application workspace is ready. Add one USAJOBS announcement."
            : "A new application workspace is ready. Add one job posting."
        return true
    }

    func updateJobApplicationStatus(id: UUID, status: JobApplicationStatus) {
        guard var record = jobApplications.first(where: { $0.id == id }) else { return }
        record.status = status
        if upsertJobApplication(record) {
            statusMessage = "\(record.displayTitle) moved to \(status.label)."
        }
    }

    @discardableResult
    func addJobStatusEvidence(
        _ evidence: JobStatusEvidence,
        to applicationID: UUID
    ) -> Bool {
        guard var record = jobApplications.first(where: { $0.id == applicationID }) else {
            errorMessage = "The application is no longer available to attach that image."
            return false
        }
        guard record.statusEvidence.count < PrivateImageStore.maximumStatusEvidencePerApplication else {
            errorMessage = "Keep up to \(PrivateImageStore.maximumStatusEvidencePerApplication) status images per application. Remove one before adding another."
            return false
        }
        guard !record.statusEvidence.contains(where: { $0.id == evidence.id }) else {
            return false
        }
        record.statusEvidence.append(evidence)
        if upsertJobApplication(record) {
            statusMessage = "Status image saved privately on this device."
            return true
        }
        return false
    }

    @discardableResult
    func removeJobStatusEvidence(
        _ evidence: JobStatusEvidence,
        from applicationID: UUID
    ) -> Bool {
        guard var record = jobApplications.first(where: { $0.id == applicationID }),
              let index = record.statusEvidence.firstIndex(where: { $0.id == evidence.id }) else {
            return false
        }
        record.statusEvidence.remove(at: index)
        guard upsertJobApplication(record) else { return false }
        do {
            try PrivateImageStore.removeStatusEvidence(evidence, applicationID: applicationID)
            statusMessage = "Status image removed from this device."
            return true
        } catch {
            errorMessage = "The image was removed from the tracker, but its protected file could not be removed: \(error.localizedDescription)"
            return false
        }
    }

    func deleteJobApplication(id: UUID) {
        let previous = storedJobApplications
        let next = previous.filter { $0.id != id }
        let wasActiveApplication = draft.trackerRecordID == id
        do {
            try jobTrackerStore.save(next)
            do {
                try applicationWorkspaceStore.delete(id: id)
            } catch {
                try? jobTrackerStore.save(previous)
                throw error
            }
        } catch {
            storedJobApplications = previous
            refreshVisibleJobApplications()
            errorMessage = "The tracked application could not be deleted: \(error.localizedDescription)"
            return
        }

        storedJobApplications = next
        refreshVisibleJobApplications()
        applicationWorkspaces[id] = nil
        let statusEvidenceCleanupError: Error?
        do {
            try PrivateImageStore.removeAllStatusEvidence(for: id)
            statusEvidenceCleanupError = nil
        } catch {
            statusEvidenceCleanupError = error
        }
        if selectedTrackedApplicationID == id {
            selectedTrackedApplicationID = nil
        }
        // Remove Apple search/widget projections as soon as the authoritative
        // tracker deletion succeeds, even if later root-workspace cleanup
        // encounters a filesystem error.
        refreshApplicationSpotlightIndex()
        if wasActiveApplication {
            resetActiveApplicationAfterDeletion()
            do {
                // A normal save rotates the earlier root workspace into its
                // recovery copy. Remove both root copies first so deletion
                // cannot leave the active job recoverable from that backup.
                try workspaceStore.delete()
            } catch {
                errorMessage = "The application was deleted, but its earlier root recovery copy could not be removed: \(error.localizedDescription)"
                return
            }
        }
        guard saveWorkspace() else {
            if wasActiveApplication {
                // Never leave the deleted job's earlier root snapshot available
                // for restoration when even the safe reset cannot be saved.
                try? workspaceStore.delete()
                errorMessage = "The application was deleted, but the reusable profile could not be saved. The earlier job workspace was removed to keep its data from returning."
            }
            return
        }
        if let statusEvidenceCleanupError {
            errorMessage = "The application was deleted, but its status-image cleanup needs attention: \(statusEvidenceCleanupError.localizedDescription)"
        } else {
            statusMessage = "The tracked application and its local workspace were deleted from this device."
        }
    }

    func startWorkspace(for applicationID: UUID) {
        guard let record = jobApplications.first(where: { $0.id == applicationID }) else { return }
        guard saveWorkspace() else { return }
        deleteGeneratedFiles()

        let savedOutcome: ApplicationWorkspaceLoadOutcome?
        do {
            savedOutcome = try applicationWorkspaceStore.load(
                id: applicationID
            )
        } catch {
            errorMessage = "This saved application needs attention: \(error.localizedDescription)"
            return
        }

        if let savedOutcome {
            do {
                try CareerInputPolicy.validate(savedOutcome.snapshot.draft)
            } catch {
                errorMessage = "This saved application exceeds safe input limits and was not opened: \(error.localizedDescription)"
                return
            }
            restoreApplicationWorkspace(
                savedOutcome.snapshot,
                applicationID: applicationID
            )
            applicationWorkspaces = [applicationID: savedOutcome.snapshot]
            hasStarted = true
            selectedMainSection = .builder
            persistWorkspace()
            statusMessage = savedOutcome.recoveredFromBackup
                ? "The recovery copy for \(record.displayTitle) was restored and opened."
                : "Your saved workspace for \(record.displayTitle) is ready."
            return
        }

        let reusableProfile = draft.profile
        let reusableResumeText = draft.resumeText
        let reusableResumeFilename = draft.resumeFilename
        var nextDraft = WorkspaceDraft()
        nextDraft.profile = reusableProfile
        nextDraft.resumeText = reusableResumeText
        nextDraft.resumeFilename = reusableResumeFilename
        nextDraft.profile.targetRole = record.roleTitle
        nextDraft.jobURL = record.sourceURL.isEmpty ? nil : record.sourceURL
        nextDraft.trackerRecordID = record.id
        nextDraft.mode = record.platform == .usajobs ? .federal : .auto
        draft = nextDraft
        jobURL = record.sourceURL
        response = nil
        linkedInKit = nil
        analysisInputFingerprint = nil
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        hasStarted = true
        selectedMainSection = .builder
        step = .importDocuments
        persistWorkspace()
        statusMessage = "The workspace is ready for \(record.displayTitle). Add the résumé and posting text."
    }

    func next() {
        guard let next = FlowStep(rawValue: step.rawValue + 1) else { return }
        step = next
        persistDraft()
    }

    func back() {
        guard let previous = FlowStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func configure(apiBaseURL: String, token: String) {
        #if DEBUG
        self.apiBaseURL = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        apiToken = token
        UserDefaults.standard.set(self.apiBaseURL, forKey: "apiBaseURL")
        if token.isEmpty {
            keychain.delete(account: "apiToken")
            legacyMusterForwardKeychain.delete(account: "apiToken")
            legacyKeychain.delete(account: "apiToken")
        } else {
            do {
                try keychain.save(token, account: "apiToken")
            } catch {
                errorMessage = "The optional service token could not be saved securely: \(error.localizedDescription)"
            }
        }
        #else
        self.apiBaseURL = (Bundle.main.object(
            forInfoDictionaryKey: "HOGUE_API_BASE_URL"
        ) as? String) ?? ""
        apiToken = ""
        #endif
    }

    func checkService() async {
        await perform {
            do {
                self.health = try await self.client().health()
                self.statusMessage = self.health?.aiConfigured == true
                    ? "Optional service connected. The private core and AI enhancements are ready."
                    : "Optional service connected. The private core is ready; cloud AI is not required."
            } catch {
                self.health = nil
                self.statusMessage = "The optional service is offline. Private import, analysis, Truth Lock, LinkedIn drafting, and export remain ready."
            }
        }
    }

    func importDocument(url: URL, kind: DocumentKind) async {
        await perform {
            let extraction: DocumentExtraction
            if let local = try await DocumentImportService.extractLocally(from: url) {
                extraction = local
            } else {
                guard self.draft.serviceConsent == true else {
                    throw DocumentImportService.ImportError.serviceConsentRequired
                }
                let data = try DocumentImportService.readSecurityScopedData(from: url)
                extraction = try await self.client().extract(
                    data: data,
                    filename: url.lastPathComponent
                )
            }
            switch kind {
            case .resume:
                self.draft.resumeText = try CareerInputPolicy.validate(
                    extraction.text,
                    as: .resume
                )
                self.draft.resumeFilename = extraction.filename
            case .job:
                self.draft.jobText = try CareerInputPolicy.validate(
                    extraction.text,
                    as: .job
                )
                self.draft.jobFilename = extraction.filename
            }
            self.recordImportWarnings(extraction.warnings, for: kind)
            let actionable = extraction.warnings.filter {
                $0 != "Imported privately on this device."
            }
            self.statusMessage = actionable.isEmpty
                ? "Imported \(extraction.filename) privately on this device."
                : "Imported \(extraction.filename) with \(actionable.count) warning\(actionable.count == 1 ? "" : "s") that must be reviewed below."
            self.persistDraft()
        }
    }

    func importJobURL() async {
        await perform {
            guard let normalizedURL = self.normalizedJobURL() else {
                throw AppInputError.invalidJobURL
            }
            self.jobURL = normalizedURL
            self.draft.jobURL = normalizedURL
            if JobPlatform.detect(from: normalizedURL) == .usajobs,
               self.draft.mode == .auto {
                self.draft.mode = .federal
            }
            self.persistDraft()
            guard self.draft.serviceConsent == true else {
                self.statusMessage = "The job link is saved. Paste the posting text, or allow the optional service in Profile before requesting page retrieval."
                return
            }
            do {
                let extraction = try await self.client().extractURL(normalizedURL)
                self.draft.jobText = try CareerInputPolicy.validate(
                    extraction.text,
                    as: .job
                )
                self.draft.jobFilename = extraction.filename
                self.statusMessage = "Imported the \(JobPlatform.detect(from: normalizedURL).label) job posting from \(extraction.filename)."
            } catch let error as CareerInputPolicy.InputTooLarge {
                throw error
            } catch {
                self.statusMessage = "The job link is saved. That site blocked automatic import, so paste the posting text below; none of your existing work was lost."
            }
            self.persistDraft()
        }
    }

    func saveJobLink() {
        guard let normalizedURL = normalizedJobURL() else {
            errorMessage = AppInputError.invalidJobURL.localizedDescription
            return
        }
        jobURL = normalizedURL
        draft.jobURL = normalizedURL
        if JobPlatform.detect(from: normalizedURL) == .usajobs,
           draft.mode == .auto {
            draft.mode = .federal
        }
        statusMessage = "\(JobPlatform.detect(from: normalizedURL).label) job link saved for a user-controlled application handoff."
        persistDraft()
    }

    func analyze() async {
        await perform {
            let currentDraft = self.draft
            guard !currentDraft.resumeText
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppInputError.missingResume
            }
            guard !currentDraft.jobText
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppInputError.missingJobPosting
            }
            let resolvedMode = Self.resolvedResumeMode(for: currentDraft)
            var normalizedDraft = currentDraft
            normalizedDraft.mode = resolvedMode
            let inputDraft = normalizedDraft
            if resolvedMode != currentDraft.mode {
                self.draft.mode = resolvedMode
            }
            let inputRevision = self.draftRevision
            guard let inputFingerprint = await Task.detached(
                priority: .userInitiated,
                operation: {
                    Self.fingerprint(for: inputDraft)
                }
            ).value else {
                throw AppInputError.analysisFingerprintUnavailable
            }
            try CareerInputPolicy.validate(inputDraft)
            let request = TailorRequest(
                resumeText: inputDraft.resumeText,
                jobText: inputDraft.jobText,
                profile: inputDraft.profile,
                mode: inputDraft.mode,
                useAI: inputDraft.useAI,
                aiConsent: inputDraft.useAI && inputDraft.aiConsent
            )
            var analysis = await Task.detached(
                priority: .userInitiated,
                operation: {
                    LocalCareerEngine.analyze(request)
                }
            ).value
            var analysisStatus = "Private on-device rules completed the analysis and Truth Lock checks."
            let shouldPauseAI = !analysis.safetyFindings.isEmpty
            var onDeviceAISucceeded = false

            if inputDraft.useAI &&
                inputDraft.aiConsent &&
                !shouldPauseAI &&
                OnDeviceProposalService.isAvailable {
                do {
                    let deviceProposals = try await OnDeviceProposalService.propose(
                        resumeText: inputDraft.resumeText,
                        response: analysis,
                        mode: inputDraft.mode,
                        enforceTruthLock: self.truthLockEnabled
                    )
                    let existing = Set(analysis.proposals.map {
                        "\($0.originalText)\u{001F}\($0.proposedText)"
                    })
                    let unique = deviceProposals.filter {
                        !existing.contains("\($0.originalText)\u{001F}\($0.proposedText)")
                    }
                    analysis.proposals.append(contentsOf: unique)
                    onDeviceAISucceeded = true
                    if !unique.isEmpty {
                        analysisStatus = self.truthLockEnabled
                            ? "Private Apple Intelligence suggestions were added after citation and Truth Lock checks. Candidate review is still required."
                            : "Private Apple Intelligence drafts were added with exact citations. They remain unverified until Truth Lock accepts them."
                    } else {
                        analysisStatus = "Private Apple Intelligence completed; the local analysis is ready for candidate review."
                    }
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    analysisStatus = OnDeviceProposalService.safeFallbackStatus(
                        for: error
                    )
                }
            }

            if inputDraft.useAI &&
                inputDraft.aiConsent &&
                inputDraft.serviceConsent == true &&
                !shouldPauseAI &&
                !onDeviceAISucceeded {
                do {
                    let serviceResponse = try await self.client().analyze(request)
                    let originalCount = analysis.proposals.count
                    analysis = ServiceProposalGate.merge(
                        serviceResponse,
                        into: analysis,
                        resumeText: inputDraft.resumeText,
                        enforceTruthLock: self.truthLockEnabled
                    )
                    let addedCount = analysis.proposals.count - originalCount
                    if addedCount > 0 {
                        analysisStatus = self.truthLockEnabled
                            ? "The optional service added \(addedCount) suggestion\(addedCount == 1 ? "" : "s") that passed local citation, wording, and safety checks."
                            : "The optional service added \(addedCount) exact-cited unverified draft\(addedCount == 1 ? "" : "s"). Truth Lock approval is still required before export."
                    } else {
                        analysisStatus = "The optional service added no suggestions that passed the phone's evidence checks; the private analysis is ready."
                    }
                } catch {
                    analysisStatus = "The optional service was unavailable; the private local analysis is ready."
                }
            } else if shouldPauseAI && inputDraft.useAI {
                analysisStatus = "AI was paused because sensitive information needs your review. Private safety checks are ready."
            }
            guard self.draftRevision == inputRevision else {
                self.statusMessage = "Your inputs changed while analysis was running, so the older result was discarded. Run Analysis again for the current workspace."
                return
            }
            self.deleteGeneratedFiles()
            self.analysisInputFingerprint = inputFingerprint
            self.responseDraftRevision = inputRevision
            self.response = analysis
            self.linkedInKit = nil
            self.exportURL = nil
            self.exportPDFURL = nil
            self.exportRichTextURL = nil
            self.privateReviewURL = nil
            self.step = .review
            self.statusMessage = analysisStatus
            self.persistDraft()
        }
    }

    private func refreshApplicationSpotlightIndex(
        reportSpotlightFailure: Bool = false,
        reportWidgetFailure: Bool = false,
        completion: ((
            ApplicationSpotlightIndexer.ReplacementResult,
            Bool
        ) -> Void)? = nil
    ) {
        let spotlightDeletionWasPending =
            ApplicationSpotlightIndexer.isDeletionPending()
        let widgetUpdated = ApplicationWidgetBridge.update(
            with: jobApplications,
            includeApplicationDetails: widgetApplicationDetailsEnabled
        )
        if !widgetUpdated,
           reportWidgetFailure ||
            widgetApplicationDetailsEnabled {
            presentPlatformPrivacyError(
                "Widget privacy settings could not be verified. Application details were not republished, and Apply Ready Vets will retry."
            )
        }
        ApplicationSpotlightIndexer.replace(
            with: jobApplications,
            enabled: spotlightApplicationsEnabled
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .completed:
                break
            case .indexingUnavailable, .deletionFailed:
                if reportSpotlightFailure || spotlightDeletionWasPending {
                    self.presentPlatformPrivacyError(
                        "Spotlight application search could not be safely refreshed. Apply Ready Vets will retry; your protected tracker remains available inside the app."
                    )
                }
            case .indexingFailed:
                if reportSpotlightFailure {
                    self.statusMessage = "Spotlight removed the earlier index, but could not add the updated application search entries. The protected tracker is unaffected."
                }
            }
            completion?(result, widgetUpdated)
        }
    }

    private func presentPlatformPrivacyError(_ message: String) {
        if errorMessage == nil {
            errorMessage = message
        }
    }

    func setProposal(id: String, status: ProposalStatus, editedText: String? = nil) {
        if let editedText {
            do {
                try CareerInputPolicy.validate(editedText, as: .proposalEdit)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        guard var current = currentResponse,
              let index = current.proposals.firstIndex(where: { $0.id == id }) else { return }
        if status == .approved,
           editedText == nil,
           current.proposals[index].editedText != nil {
            current.proposals[index].status = .edited
        } else {
            current.proposals[index].status = status
            current.proposals[index].editedText = editedText
        }
        response = current
        linkedInKit = nil
        deleteGeneratedFiles()
        persistWorkspace()
    }

    func useSuggestedProposal(id: String) {
        guard var current = currentResponse,
              let index = current.proposals.firstIndex(where: { $0.id == id }) else {
            return
        }
        current.proposals[index].status = .approved
        current.proposals[index].editedText = nil
        response = current
        linkedInKit = nil
        deleteGeneratedFiles()
        persistWorkspace()
    }

    func buildLinkedInKit() async {
        guard let response = currentResponse else {
            errorMessage = "Your inputs changed. Run Analysis again before creating LinkedIn copy."
            return
        }
        await perform {
            let request = self.exportRequest(for: response)
            let reviewedResume = try LocalExportService.validatedResumeText(from: request)
            self.linkedInKit = LocalCareerEngine.linkedInKit(
                for: request,
                reviewedResumeText: reviewedResume
            )
            self.statusMessage = "LinkedIn candidate copy was created privately. Verify every line before publishing."
            self.persistWorkspace()
        }
    }

    func exportPacket() async {
        guard exportTask == nil, !isWorking else {
            statusMessage = "Another secure operation is already in progress."
            return
        }
        guard let response = currentResponse else {
            errorMessage = "Your inputs changed. Run Analysis again before creating an application file."
            return
        }
        guard enteredJobURLMatchesAnalyzedDraft else {
            errorMessage = "Save the edited job link, then run Analysis again before creating application files."
            return
        }

        let request = exportRequest(for: response)
        let inputApplicationID = draft.trackerRecordID
        let packetVersion = nextPacketVersionNumber
        let inputDraftRevision = draftRevision
        let inputResponseRevision = responseRevision
        let generator = packetGenerator

        deleteGeneratedFiles()
        isWorking = true
        errorMessage = nil
        statusMessage = nil
        let task = Task.detached(priority: .userInitiated) {
            try generator.generate(
                from: request,
                applicationID: inputApplicationID,
                packetVersion: packetVersion
            )
        }
        exportTask = task
        defer {
            exportTask = nil
            isWorking = false
        }

        do {
            let generated = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            guard !Task.isCancelled else {
                generated.removeFromDisk()
                return
            }
            guard draftRevision == inputDraftRevision,
                  responseRevision == inputResponseRevision,
                  currentResponse != nil else {
                generated.removeFromDisk()
                statusMessage = "Your inputs or review decisions changed while the files were being created. The outdated files were discarded; create them again after reviewing the latest analysis."
                return
            }

            let candidateBundle = generated.candidateBundle
            exportURL = generated.plainTextURL
            exportPDFURL = generated.pdfURL
            exportRichTextURL = generated.richTextURL
            privateReviewURL = generated.privateReviewURL
            let versionHistoryWasSaved = recordExportedPacket(
                candidateBundle: candidateBundle,
                privateReviewURL: generated.privateReviewURL,
                versionNumber: packetVersion
            )
            if versionHistoryWasSaved {
                statusMessage = "PDF, editable RTF, and parser-safe TXT resumes were created locally with a separate private review, and this packet version was saved in your tracker."
            } else {
                statusMessage = "The files were created locally, but their version history could not be saved. Keep or share the files, then retry saving the application."
            }
        } catch is CancellationError {
            // A canceled generation cleans up its own partial files. Cancellation
            // is intentionally silent so a privacy reset or navigation change
            // can present its more relevant status.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func eraseLocalData() {
        exportTask?.cancel()
        draftInvalidation?.cancel()
        draftAutosave?.cancel()
        draft = WorkspaceDraft()
        hasStarted = false
        selectedMainSection = .home
        jobURL = ""
        response = nil
        analysisInputFingerprint = nil
        exportURL = nil
        exportPDFURL = nil
        exportRichTextURL = nil
        privateReviewURL = nil
        linkedInKit = nil
        pendingSharedJobText = nil
        pendingSharedJobID = nil
        pendingSharedJobSourceURL = nil
        isSharedJobDecisionPresented = false
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        jobApplications = []
        storedJobApplications = []
        applicationWorkspaces = [:]
        householdProfiles = []
        activeHouseholdProfileID = nil
        householdWorkspaces = [:]
        spotlightApplicationsEnabled = false
        widgetApplicationDetailsEnabled = false
        UserDefaults.standard.set(
            false,
            forKey: ApplicationSpotlightIndexer.preferenceKey
        )
        UserDefaults.standard.set(
            false,
            forKey: ApplicationWidgetBridge.detailPreferenceKey
        )
        step = .importDocuments
        apiToken = ""

        UserDefaults.standard.set(
            true,
            forKey: Self.localErasePendingPreferenceKey
        )
        isLocalErasePending = true
        let localFailures = deleteAllLocalDataFilesAndCredentials()
        if localFailures.isEmpty {
            UserDefaults.standard.removeObject(
                forKey: Self.localErasePendingPreferenceKey
            )
            isLocalErasePending = false
            statusMessage = "Local data was deleted. Apple search and widget privacy cleanup is being verified."
        } else {
            errorMessage = "Local deletion is incomplete: \(localFailures.joined(separator: "; ")). Apply Ready Vets will retry before restoring saved work."
            statusMessage = "Local deletion completed with items that still need attention."
        }

        refreshApplicationSpotlightIndex(
            reportSpotlightFailure: true,
            reportWidgetFailure: true
        ) { [weak self] spotlightResult, widgetUpdated in
            guard let self else { return }
            var platformFailures: [String] = []
            if !widgetUpdated {
                platformFailures.append(
                    "widget snapshot removal could not be verified"
                )
            }
            switch spotlightResult {
            case .completed:
                break
            case .indexingUnavailable:
                platformFailures.append("Spotlight indexing is unavailable")
            case .deletionFailed:
                platformFailures.append(
                    "Spotlight removal could not be verified"
                )
            case .indexingFailed:
                platformFailures.append(
                    "Spotlight refresh failed after removal"
                )
            }
            if localFailures.isEmpty, platformFailures.isEmpty {
                self.statusMessage = "Local workspace, tracker, recovery copies, service tokens, app-managed files, and Apple search/widget projections were deleted."
            } else if !platformFailures.isEmpty {
                self.presentPlatformPrivacyError(
                    "Apple privacy cleanup still needs attention: \(platformFailures.joined(separator: "; ")). Apply Ready Vets will retry when the app becomes active."
                )
            }
        }
        if !isLocalErasePending {
            startDraftObservation()
        }
    }

    private func deleteAllLocalDataFilesAndCredentials() -> [String] {
        var failures: [String] = []
        func attempt(
            _ label: String,
            operation: () throws -> Void
        ) {
            do {
                try operation()
            } catch {
                failures.append("\(label): \(error.localizedDescription)")
            }
        }

        attempt("workspace") { try workspaceStore.delete() }
        attempt("application workspaces") {
            try applicationWorkspaceStore.deleteAll()
        }
        attempt("application tracker") { try jobTrackerStore.delete() }
        attempt("private status and headshot images") {
            try PrivateImageStore.removeAll()
        }
        attempt("legacy draft") { try draftStore.deleteVerified() }
        attempt("shared-job inbox") {
            try SharedJobInbox.deleteAll(
                directoryOverride: sharedInboxDirectoryOverride
            )
        }
        attempt("Samples and Output folders") {
            try UserDocumentWorkspace.deleteManagedDocuments()
        }
        attempt("temporary exports") { try deleteAppTemporaryExports() }
        attempt("current service token") {
            try keychain.deleteVerified(account: "apiToken")
        }
        attempt("earlier service token") {
            try legacyMusterForwardKeychain.deleteVerified(account: "apiToken")
        }
        attempt("legacy service token") {
            try legacyKeychain.deleteVerified(account: "apiToken")
        }
        UserDefaults.standard.removeObject(forKey: "apiBaseURL")
        UserDefaults.standard.removeObject(
            forKey: ShortcutDestination.storageKey
        )
        UserDefaults.standard.removeObject(
            forKey: ShortcutDestination.pendingJobURLKey
        )
        return failures
    }

    private func client() -> APIClient {
        APIClient(baseURL: apiBaseURL, bearerToken: apiToken)
    }

    private func exportRequest(for response: TailorResponse) -> ExportRequest {
        ExportRequest(
            resumeText: draft.resumeText,
            response: response,
            candidateName: draft.profile.fullName.isEmpty ? "Veteran" : draft.profile.fullName,
            includeWorkday: true,
            profile: draft.profile,
            mode: effectiveResumeMode,
            federalDetails: draft.federalDetails
        )
    }

    nonisolated static func resolvedResumeMode(
        for draft: WorkspaceDraft
    ) -> ResumeMode {
        guard draft.mode == .auto else { return draft.mode }
        if let jobURL = draft.jobURL,
           JobPlatform.detect(from: jobURL) == .usajobs {
            return .federal
        }
        return LocalCareerEngine.postingAppearsFederal(draft.jobText)
            ? .federal
            : .auto
    }

    private var hasExistingApplicationWorkspace: Bool {
        draft.trackerRecordID != nil ||
            !storedJobApplications.isEmpty ||
            hasSubstantiveUntrackedApplication
    }

    private var hasSubstantiveUntrackedApplication: Bool {
        let details = draft.federalDetails
        return !draft.jobText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty ||
            !(draft.jobURL ?? "").trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty ||
            !jobURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !draft.profile.targetRole.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty ||
            !(details?.announcementNumber ?? "").trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty ||
            !(details?.targetSeriesAndGrade ?? "").trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty ||
            response != nil ||
            linkedInKit != nil
    }

    private func persistDraft() {
        persistWorkspace()
    }

    func saveForSceneTransition() {
        guard !isLocalErasePending else { return }
        persistWorkspace()
    }

    private func persistWorkspace() {
        guard !isLocalErasePending else { return }
        _ = saveWorkspace()
    }

    @discardableResult
    private func saveWorkspace() -> Bool {
        do {
            try CareerInputPolicy.validate(draft)
            if let activeHouseholdProfileID {
                householdWorkspaces[activeHouseholdProfileID] =
                    currentHouseholdWorkspaceSnapshot()
            }
            try workspaceStore.save(persistenceState())
            // Commit the authoritative root workspace first. If this second,
            // per-application projection fails, the root snapshot can rebuild
            // it on the next launch without allowing stale data to overwrite
            // newer edits.
            try captureCurrentApplicationWorkspace()
            return true
        } catch {
            errorMessage = "Your latest changes are still on screen, but the protected save failed: \(error.localizedDescription)"
            return false
        }
    }

    private func acknowledgeIncomingShare() throws {
        guard let id = pendingSharedJobID else { return }
        try SharedJobInbox.acknowledge(
            id,
            directoryOverride: sharedInboxDirectoryOverride
        )
        pendingSharedJobID = nil
        pendingSharedJobText = nil
        pendingSharedJobSourceURL = nil
        isSharedJobDecisionPresented = false
    }

    private func applyPendingSharedJob() {
        if let sharedText = pendingSharedJobText {
            draft.jobText = sharedText
            draft.jobFilename = "Shared job posting"
        } else {
            draft.jobText = ""
            draft.jobFilename = ""
        }

        if let sourceURL = pendingSharedJobSourceURL {
            jobURL = sourceURL
            draft.jobURL = sourceURL
        } else {
            jobURL = ""
            draft.jobURL = nil
        }
    }

    private func persistenceState() -> WorkspacePersistenceState {
        let activeResponse = currentResponse
        return WorkspacePersistenceState(
            hasStarted: hasStarted,
            stepRawValue: step.rawValue,
            draft: draft,
            response: activeResponse,
            linkedInKit: activeResponse == nil ? nil : linkedInKit,
            analysisInputFingerprint: activeResponse == nil ? nil : analysisInputFingerprint,
            importReviewWarnings: importReviewWarnings,
            hasAcknowledgedImportWarnings: hasAcknowledgedImportWarnings,
            applicationWorkspaces: nil,
            householdProfiles: householdProfiles,
            activeHouseholdProfileID: activeHouseholdProfileID,
            householdWorkspaces: Dictionary(
                uniqueKeysWithValues: householdWorkspaces.map {
                    ($0.key.uuidString, $0.value)
                }
            )
        )
    }

    private func restore(_ state: WorkspacePersistenceState) {
        applicationWorkspaces = Dictionary(
            uniqueKeysWithValues: (state.applicationWorkspaces ?? [:]).compactMap {
                guard let id = UUID(uuidString: $0.key) else { return nil }
                return (id, $0.value)
            }
        )
        householdProfiles = state.householdProfiles ?? []
        activeHouseholdProfileID = state.activeHouseholdProfileID
        householdWorkspaces = Dictionary(
            uniqueKeysWithValues: (state.householdWorkspaces ?? [:]).compactMap {
                guard let id = UUID(uuidString: $0.key) else { return nil }
                return (id, $0.value)
            }
        )
        hasStarted = state.hasStarted
        draft = state.draft
        jobURL = state.draft.jobURL ?? ""
        importReviewWarnings = state.importReviewWarnings ?? []
        hasAcknowledgedImportWarnings = state.hasAcknowledgedImportWarnings
            ?? importReviewWarnings.isEmpty
        let currentFingerprint = Self.fingerprint(for: state.draft)
        if state.response != nil, state.analysisInputFingerprint == currentFingerprint {
            analysisInputFingerprint = currentFingerprint
            responseDraftRevision = draftRevision
            response = state.response
            linkedInKit = state.linkedInKit
            step = FlowStep(rawValue: state.stepRawValue) ?? .importDocuments
        } else {
            response = nil
            linkedInKit = nil
            analysisInputFingerprint = nil
            let restoredStep = FlowStep(rawValue: state.stepRawValue) ?? .importDocuments
            step = restoredStep.rawValue > FlowStep.analyze.rawValue ? .analyze : restoredStep
            if state.response != nil {
                statusMessage = "Your saved inputs changed or came from an earlier build. Run Analysis again before using results."
            }
        }
    }

    private func currentHouseholdWorkspaceSnapshot() -> HouseholdWorkspaceSnapshot {
        let activeResponse = currentResponse
        return HouseholdWorkspaceSnapshot(
            stepRawValue: step.rawValue,
            draft: draft,
            response: activeResponse,
            linkedInKit: activeResponse == nil ? nil : linkedInKit,
            analysisInputFingerprint: activeResponse == nil
                ? nil
                : analysisInputFingerprint,
            importReviewWarnings: importReviewWarnings,
            hasAcknowledgedImportWarnings: hasAcknowledgedImportWarnings
        )
    }

    private func restoreHouseholdWorkspace(_ snapshot: HouseholdWorkspaceSnapshot) {
        draft = snapshot.draft
        jobURL = draft.jobURL ?? ""
        importReviewWarnings = snapshot.importReviewWarnings
        hasAcknowledgedImportWarnings = snapshot.hasAcknowledgedImportWarnings
        let currentFingerprint = Self.fingerprint(for: draft)
        if snapshot.response != nil,
           snapshot.analysisInputFingerprint == currentFingerprint {
            analysisInputFingerprint = currentFingerprint
            responseDraftRevision = draftRevision
            response = snapshot.response
            linkedInKit = snapshot.linkedInKit
            step = FlowStep(rawValue: snapshot.stepRawValue) ?? .importDocuments
        } else {
            response = nil
            linkedInKit = nil
            analysisInputFingerprint = nil
            let savedStep = FlowStep(rawValue: snapshot.stepRawValue)
                ?? .importDocuments
            step = savedStep.rawValue > FlowStep.analyze.rawValue
                ? .analyze
                : savedStep
        }
    }

    private func resetWorkspace(for profile: HouseholdProfile) {
        deleteGeneratedFiles()
        var nextDraft = WorkspaceDraft()
        applyIdentity(profile, to: &nextDraft)
        applyAssistance(profile.assistanceLevel, to: &nextDraft)
        draft = nextDraft
        jobURL = ""
        response = nil
        linkedInKit = nil
        analysisInputFingerprint = nil
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        selectedTrackedApplicationID = nil
        step = .importDocuments
    }

    private func applyIdentity(
        _ profile: HouseholdProfile,
        to workspace: inout WorkspaceDraft
    ) {
        if workspace.profile.fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            workspace.profile.fullName = profile.displayName
        }
        if workspace.profile.targetRole.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            workspace.profile.targetRole = profile.careerGoal
        }
        workspace.profile.militarySpouse =
            profile.relationship == .militarySpouse
        if !profile.branch.isEmpty,
           workspace.profile.militaryService.isEmpty {
            var service = MilitaryService()
            service.branch = profile.branch
            workspace.profile.militaryService = [service]
        }
    }

    private func applyAssistance(
        _ level: AssistanceLevel,
        to workspace: inout WorkspaceDraft
    ) {
        workspace.useAI = level.usesGenerativeAssistance
        workspace.aiConsent = level.usesGenerativeAssistance
        // External providers are never activated by a profile preference.
        // A separate preview-first handoff is the only external route here.
        workspace.serviceConsent = false
    }

    private func ensureLegacyHouseholdProfileIfNeeded() {
        guard householdProfiles.isEmpty, hasStarted else { return }
        let preferredName = draft.profile.fullName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .first
            .map(String.init) ?? "My profile"
        let relationship: HouseholdRelationship
        if draft.profile.militarySpouse {
            relationship = .militarySpouse
        } else if draft.profile.militaryService.isEmpty {
            relationship = .civilianSupporter
        } else {
            relationship = .veteran
        }
        let assistance: AssistanceLevel = draft.useAI
            ? .appleOnDevice
            : .privateCore
        let profile = HouseholdProfile(
            preferredName: preferredName,
            relationship: relationship,
            branch: draft.profile.militaryService.first?.branch ?? "",
            careerGoal: draft.profile.targetRole,
            assistanceLevel: assistance
        )
        householdProfiles = [profile]
        activeHouseholdProfileID = profile.id
        householdWorkspaces[profile.id] = currentHouseholdWorkspaceSnapshot()
    }

    @discardableResult
    private func assignLegacyApplicationsToActiveProfile() -> Bool {
        guard let activeHouseholdProfileID else { return false }
        var changed = false
        for index in storedJobApplications.indices
        where storedJobApplications[index].ownerProfileID == nil {
            storedJobApplications[index].ownerProfileID = activeHouseholdProfileID
            changed = true
        }
        return changed
    }

    private func refreshVisibleJobApplications() {
        guard let activeHouseholdProfileID else {
            jobApplications = storedJobApplications
            return
        }
        jobApplications = storedJobApplications.filter {
            $0.ownerProfileID == activeHouseholdProfileID
        }
    }

    private static func normalizedHouseholdField(
        _ value: String,
        limit: Int
    ) -> String {
        let singleLine = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .components(separatedBy: .controlCharacters)
            .joined()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return String(singleLine.prefix(limit))
    }

    private func migrateLegacyApplicationWorkspaces() throws {
        for (id, snapshot) in applicationWorkspaces {
            try applicationWorkspaceStore.save(snapshot, id: id)
        }
        if let currentID = draft.trackerRecordID {
            let activeResponse = currentResponse
            let currentSnapshot = ApplicationWorkspaceSnapshot(
                stepRawValue: step.rawValue,
                draft: draft,
                response: activeResponse,
                linkedInKit: activeResponse == nil ? nil : linkedInKit,
                analysisInputFingerprint: activeResponse == nil
                    ? nil
                    : analysisInputFingerprint,
                importReviewWarnings: importReviewWarnings,
                hasAcknowledgedImportWarnings: hasAcknowledgedImportWarnings
            )
            try applicationWorkspaceStore.save(
                currentSnapshot,
                id: currentID
            )
            applicationWorkspaces = [currentID: currentSnapshot]
        } else {
            applicationWorkspaces = [:]
        }
    }

    private func captureCurrentApplicationWorkspace() throws {
        guard let applicationID = draft.trackerRecordID else { return }
        let activeResponse = currentResponse
        let snapshot = ApplicationWorkspaceSnapshot(
            stepRawValue: step.rawValue,
            draft: draft,
            response: activeResponse,
            linkedInKit: activeResponse == nil ? nil : linkedInKit,
            analysisInputFingerprint: activeResponse == nil
                ? nil
                : analysisInputFingerprint,
            importReviewWarnings: importReviewWarnings,
            hasAcknowledgedImportWarnings: hasAcknowledgedImportWarnings
        )
        try applicationWorkspaceStore.save(snapshot, id: applicationID)
        applicationWorkspaces = [applicationID: snapshot]
    }

    private func restoreApplicationWorkspace(
        _ snapshot: ApplicationWorkspaceSnapshot,
        applicationID: UUID
    ) {
        draft = snapshot.draft
        draft.trackerRecordID = applicationID
        jobURL = draft.jobURL ?? ""
        importReviewWarnings = snapshot.importReviewWarnings
        hasAcknowledgedImportWarnings = snapshot.hasAcknowledgedImportWarnings

        let currentFingerprint = Self.fingerprint(for: draft)
        if snapshot.response != nil,
           snapshot.analysisInputFingerprint == currentFingerprint {
            analysisInputFingerprint = currentFingerprint
            responseDraftRevision = draftRevision
            response = snapshot.response
            linkedInKit = snapshot.linkedInKit
            step = FlowStep(rawValue: snapshot.stepRawValue) ?? .importDocuments
        } else {
            response = nil
            linkedInKit = nil
            analysisInputFingerprint = nil
            let savedStep = FlowStep(rawValue: snapshot.stepRawValue)
                ?? .importDocuments
            step = savedStep.rawValue > FlowStep.analyze.rawValue
                ? .analyze
                : savedStep
        }
    }

    private func invalidateDerivedResults(for _: WorkspaceDraft) {
        guard response != nil,
              responseDraftRevision != draftRevision else { return }
        response = nil
        linkedInKit = nil
        deleteGeneratedFiles()
        analysisInputFingerprint = nil
        if step.rawValue > FlowStep.analyze.rawValue {
            step = .analyze
        }
        statusMessage = "Your resume, job, or profile changed. Run Analysis again so every result matches the current inputs."
    }

    nonisolated private static func fingerprint(
        for draft: WorkspaceDraft
    ) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var analysisDraft = draft
        analysisDraft.trackerRecordID = nil
        guard let data = try? encoder.encode(analysisDraft) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private var nextPacketVersionNumber: Int {
        guard let recordID = draft.trackerRecordID,
              let record = jobApplications.first(where: { $0.id == recordID }) else {
            return 1
        }
        return record.nextPacketVersionNumber
    }

    private func recordExportedPacket(
        candidateBundle: LocalExportService.CandidateExportBundle,
        privateReviewURL: URL,
        versionNumber: Int
    ) -> Bool {
        guard let recordID = saveCurrentJobToTracker(),
              var record = jobApplications.first(where: { $0.id == recordID }) else {
            return false
        }
        let version = ApplicationPacketVersion(
            number: versionNumber,
            resumeFilename: candidateBundle.pdfURL.lastPathComponent,
            richTextFilename: candidateBundle.richTextURL.lastPathComponent,
            plainTextFilename: candidateBundle.plainTextURL.lastPathComponent,
            privateReviewFilename: privateReviewURL.lastPathComponent,
            notes: "Created from candidate-reviewed Truth Lock decisions."
        )
        record.packetVersions.insert(version, at: 0)
        if record.status == .saved {
            record.status = .preparing
        }
        return upsertJobApplication(record)
    }

    func acknowledgeImportWarnings() {
        hasAcknowledgedImportWarnings = true
        statusMessage = "Import warnings acknowledged. Verify the imported text itself before continuing."
        persistWorkspace()
    }

    private func recordImportWarnings(_ warnings: [String], for kind: DocumentKind) {
        let label = kind == .resume ? "Resume" : "Job"
        importReviewWarnings.removeAll { $0.hasPrefix("\(label): ") }
        let actionable = warnings.filter {
            $0 != "Imported privately on this device."
        }
        importReviewWarnings.append(contentsOf: actionable.map { "\(label): \($0)" })
        if !actionable.isEmpty {
            hasAcknowledgedImportWarnings = false
        } else if importReviewWarnings.isEmpty {
            hasAcknowledgedImportWarnings = true
        }
    }

    private func deleteGeneratedFiles() {
        let urls = [
            exportURL,
            exportPDFURL,
            exportRichTextURL,
            privateReviewURL,
        ].compactMap(\.self)
        exportURL = nil
        exportPDFURL = nil
        exportRichTextURL = nil
        privateReviewURL = nil
        for url in urls where isAppTemporaryFile(url) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func resetActiveApplicationAfterDeletion() {
        let previousDraft = draft
        var reusableProfile = previousDraft.profile
        reusableProfile.targetRole = ""

        var safeDraft = WorkspaceDraft()
        safeDraft.profile = reusableProfile
        safeDraft.resumeText = previousDraft.resumeText
        safeDraft.resumeFilename = previousDraft.resumeFilename
        safeDraft.useAI = previousDraft.useAI
        // Deleting an application removes that posting and its derived
        // material, not the person's explicit feature-level consent. A new
        // job still cannot be analyzed until the user supplies it and starts
        // that workflow, but an unrelated delete must not silently alter a
        // privacy preference.
        safeDraft.aiConsent = previousDraft.aiConsent
        safeDraft.serviceConsent = false

        deleteGeneratedFiles()
        draft = safeDraft
        jobURL = ""
        response = nil
        linkedInKit = nil
        analysisInputFingerprint = nil
        importReviewWarnings = []
        hasAcknowledgedImportWarnings = true
        pendingSharedJobText = nil
        pendingSharedJobSourceLabel = "another app"
        pendingSharedJobID = nil
        pendingSharedJobSourceURL = nil
        isSharedJobDecisionPresented = false
        step = .importDocuments
    }

    private func isAppTemporaryFile(_ url: URL) -> Bool {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .standardizedFileURL
        return url.standardizedFileURL.deletingLastPathComponent() == temporaryDirectory &&
            url.lastPathComponent.hasPrefix("ApplyReadyVets_")
    }

    private func purgeAppTemporaryExports() {
        try? deleteAppTemporaryExports()
    }

    private func deleteAppTemporaryExports() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.standardizedFileURL
        let contents = try FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil
        )
        for fileURL in contents where fileURL.lastPathComponent.hasPrefix("ApplyReadyVets_") {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func normalizedJobURL() -> String? {
        JobURLPolicy.normalize(jobURL)
    }

    private var enteredJobURLMatchesAnalyzedDraft: Bool {
        let entered = jobURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let analyzed = draft.jobURL.flatMap(JobURLPolicy.normalize)
        if entered.isEmpty {
            return analyzed == nil
        }
        return JobURLPolicy.normalize(entered) == analyzed
    }

    private func perform(_ operation: @escaping @MainActor () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        statusMessage = nil
        defer { isWorking = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum DocumentKind {
    case resume
    case job
}

private enum AppInputError: LocalizedError {
    case invalidJobURL
    case analysisFingerprintUnavailable
    case missingResume
    case missingJobPosting

    var errorDescription: String? {
        switch self {
        case .invalidJobURL:
            JobURLPolicy.validationMessage
        case .analysisFingerprintUnavailable:
            "The current workspace could not be verified for analysis. Save the documents again and retry."
        case .missingResume:
            "Add or import your resume before running analysis."
        case .missingJobPosting:
            "Add or import one job posting before running analysis."
        }
    }
}
