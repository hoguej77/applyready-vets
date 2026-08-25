import AppIntents
import Foundation

enum ShortcutDestination: String {
    case startApplication
    case reviewTruthLock
    case buildLinkedIn
    case saveJob
    case prepareIndeed

    static let storageKey = "ApplyReadyVets.pendingShortcut"
    static let pendingJobURLKey = "ApplyReadyVets.pendingJobURL"
}

extension Notification.Name {
    static let applyReadyShortcutRequested = Notification.Name("ApplyReadyVets.shortcutRequested")
}

private enum ShortcutRouter {
    @MainActor
    static func request(
        _ destination: ShortcutDestination,
        normalizedJobURL: String? = nil
    ) {
        UserDefaults.standard.set(destination.rawValue, forKey: ShortcutDestination.storageKey)
        if let normalizedJobURL {
            UserDefaults.standard.set(
                normalizedJobURL,
                forKey: ShortcutDestination.pendingJobURLKey
            )
        }
        NotificationCenter.default.post(name: .applyReadyShortcutRequested, object: nil)
    }
}

struct StartVeteranApplicationIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Veteran Application"
    static let description = IntentDescription("Open ApplyReady Vets and start an evidence-first application packet.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ShortcutRouter.request(.startApplication)
        return .result(dialog: "Continue in ApplyReady Vets to start an application.")
    }
}

struct ReviewTruthLockIntent: AppIntent {
    static let title: LocalizedStringResource = "Review Truth Lock"
    static let description = IntentDescription("Open the evidence review for your current application.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ShortcutRouter.request(.reviewTruthLock)
        return .result(dialog: "Continue in ApplyReady Vets to review the current workspace.")
    }
}

struct BuildLinkedInProfileIntent: AppIntent {
    static let title: LocalizedStringResource = "Build My LinkedIn Profile"
    static let description = IntentDescription("Open the copy-ready LinkedIn profile builder without sharing private resume content with Siri.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ShortcutRouter.request(.buildLinkedIn)
        return .result(dialog: "Continue in ApplyReady Vets to review LinkedIn copy.")
    }
}

struct SaveJobLinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Save a Job Link"
    static let description = IntentDescription("Save a job URL in ApplyReady Vets without sharing resume content with Siri.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Job URL")
    var jobURL: URL

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$jobURL) to ApplyReady Vets")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let normalizedJobURL = JobURLPolicy.normalize(
            jobURL.absoluteString
        ) else {
            return .result(
                dialog: "That link was not saved. Use a public HTTP or HTTPS job link without a username or password."
            )
        }
        ShortcutRouter.request(
            .saveJob,
            normalizedJobURL: normalizedJobURL
        )
        return .result(
            dialog: "Continue in ApplyReady Vets to review this job link."
        )
    }
}

struct PrepareIndeedApplicationIntent: AppIntent {
    static let title: LocalizedStringResource = "Prepare an Indeed Application"
    static let description = IntentDescription("Save an Indeed job link and open ApplyReady Vets to prepare a candidate-reviewed application packet.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Indeed Job URL")
    var jobURL: URL

    static var parameterSummary: some ParameterSummary {
        Summary("Prepare an Indeed application for \(\.$jobURL)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let normalizedJobURL = JobURLPolicy.normalize(jobURL.absoluteString) else {
            return .result(
                dialog: "That link was not saved. Use a public Indeed job link without a username or password."
            )
        }
        guard JobPlatform.detect(from: normalizedJobURL) == .indeed else {
            return .result(
                dialog: "That does not appear to be an Indeed job link. Use Save a Job Link for another job site."
            )
        }
        ShortcutRouter.request(
            .prepareIndeed,
            normalizedJobURL: normalizedJobURL
        )
        return .result(
            dialog: "Continue in ApplyReady Vets to prepare your reviewed Indeed application packet. You will review and submit on Indeed yourself."
        )
    }
}

struct ApplyReadyVetsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartVeteranApplicationIntent(),
            phrases: [
                "Start an application with \(.applicationName)",
                "Build my veteran resume with \(.applicationName)"
            ],
            shortTitle: "Start application",
            systemImageName: "doc.badge.plus"
        )
        AppShortcut(
            intent: ReviewTruthLockIntent(),
            phrases: [
                "Review Truth Lock in \(.applicationName)"
            ],
            shortTitle: "Review Truth Lock",
            systemImageName: "checkmark.shield"
        )
        AppShortcut(
            intent: BuildLinkedInProfileIntent(),
            phrases: [
                "Build my LinkedIn profile with \(.applicationName)"
            ],
            shortTitle: "Build LinkedIn",
            systemImageName: "person.text.rectangle"
        )
        AppShortcut(
            intent: SaveJobLinkIntent(),
            phrases: [
                "Save a job with \(.applicationName)"
            ],
            shortTitle: "Save job link",
            systemImageName: "link.badge.plus"
        )
        AppShortcut(
            intent: PrepareIndeedApplicationIntent(),
            phrases: [
                "Prepare an Indeed application with \(.applicationName)",
                "Save an Indeed job with \(.applicationName)"
            ],
            shortTitle: "Prepare Indeed job",
            systemImageName: "checklist"
        )
    }
}
