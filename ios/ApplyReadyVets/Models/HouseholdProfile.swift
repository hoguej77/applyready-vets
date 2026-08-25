import Foundation

enum HouseholdRelationship: String, Codable, CaseIterable, Identifiable {
    case veteran
    case transitioningServiceMember
    case guardOrReserve
    case militarySpouse
    case caregiver
    case civilianSupporter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .veteran: "Veteran"
        case .transitioningServiceMember: "Transitioning service member"
        case .guardOrReserve: "Guard or Reserve"
        case .militarySpouse: "Military spouse"
        case .caregiver: "Caregiver"
        case .civilianSupporter: "Civilian supporter"
        }
    }

    var systemImage: String {
        switch self {
        case .veteran: "medal"
        case .transitioningServiceMember: "arrow.forward.circle"
        case .guardOrReserve: "shield"
        case .militarySpouse: "person.2"
        case .caregiver: "heart"
        case .civilianSupporter: "person.crop.circle.badge.checkmark"
        }
    }
}

enum AssistanceLevel: String, Codable, CaseIterable, Identifiable {
    case privateCore
    case appleOnDevice
    case externalByApproval

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privateCore: "Private core"
        case .appleOnDevice: "Apple on-device assistance"
        case .externalByApproval: "External help by approval"
        }
    }

    var shortTitle: String {
        switch self {
        case .privateCore: "Private"
        case .appleOnDevice: "On-device"
        case .externalByApproval: "Approve sharing"
        }
    }

    var detail: String {
        switch self {
        case .privateCore:
            "Use the local career engine without generative writing. Nothing leaves the app."
        case .appleOnDevice:
            "Add private Apple Intelligence suggestions on eligible devices. Truth Lock still checks every suggestion."
        case .externalByApproval:
            "Keep on-device help and allow a manual, preview-first handoff through Apple’s share sheet. Nothing is sent automatically."
        }
    }

    var systemImage: String {
        switch self {
        case .privateCore: "lock.shield"
        case .appleOnDevice: "iphone.gen3"
        case .externalByApproval: "square.and.arrow.up"
        }
    }

    var usesGenerativeAssistance: Bool { self != .privateCore }
    var allowsExternalHandoff: Bool { self == .externalByApproval }
}

struct HouseholdProfile: Codable, Hashable, Identifiable {
    var id: UUID
    var preferredName: String
    var relationship: HouseholdRelationship
    var branch: String
    var careerGoal: String
    var assistanceLevel: AssistanceLevel
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        preferredName: String,
        relationship: HouseholdRelationship,
        branch: String = "",
        careerGoal: String = "",
        assistanceLevel: AssistanceLevel = .privateCore,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.preferredName = preferredName
        self.relationship = relationship
        self.branch = branch
        self.careerGoal = careerGoal
        self.assistanceLevel = assistanceLevel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        let trimmed = preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "My profile" : trimmed
    }
}

struct HouseholdWorkspaceSnapshot: Codable {
    var stepRawValue: Int
    var draft: WorkspaceDraft
    var response: TailorResponse?
    var linkedInKit: LinkedInProfileKit?
    var analysisInputFingerprint: String?
    var importReviewWarnings: [String]
    var hasAcknowledgedImportWarnings: Bool
}
