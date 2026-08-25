import Foundation

public enum ResumeMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case auto
    case civilian
    case federal
    case healthcare
    case education

    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

public enum JobPlatform: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case indeed
    case workday
    case linkedin
    case usajobs
    case handshake
    case jofdav
    case employerSite

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .indeed: "Indeed"
        case .workday: "Workday"
        case .linkedin: "LinkedIn"
        case .usajobs: "USAJOBS"
        case .handshake: "Handshake"
        case .jofdav: "JOFDAV"
        case .employerSite: "Employer site"
        }
    }

    public var systemImage: String {
        switch self {
        case .indeed: "magnifyingglass"
        case .workday: "building.2"
        case .linkedin: "person.text.rectangle"
        case .usajobs: "building.columns"
        case .handshake: "graduationcap"
        case .jofdav: "accessibility"
        case .employerSite: "safari"
        }
    }

    public static func detect(from urlString: String) -> JobPlatform {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let host = URLComponents(string: candidate)?.host?.lowercased() else {
            return .employerSite
        }

        func isDomain(_ domain: String) -> Bool {
            host == domain || host.hasSuffix(".\(domain)")
        }

        if isDomain("indeed.com") { return .indeed }
        if isDomain("myworkdayjobs.com") || isDomain("workday.com") { return .workday }
        if isDomain("linkedin.com") { return .linkedin }
        if isDomain("usajobs.gov") { return .usajobs }
        if isDomain("joinhandshake.com") { return .handshake }
        if isDomain("jofdav.com") { return .jofdav }
        return .employerSite
    }
}

public enum ProposalStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case approved
    case rejected
    case edited
}

public enum Severity: String, Codable, Sendable {
    case info
    case warning
    case critical
}

public struct MilitaryService: Codable, Hashable, Sendable, Identifiable {
    public var id = UUID()
    public var branch = ""
    public var component = ""
    public var rank = ""
    public var payGrade = ""
    public var occupationCode = ""
    public var occupationTitle = ""
    public var serviceStart = ""
    public var serviceEnd = ""

    enum CodingKeys: String, CodingKey {
        case branch, component, rank, payGrade, occupationCode, occupationTitle, serviceStart, serviceEnd
    }

    public init() {}
}

public struct CandidateProfile: Codable, Hashable, Sendable {
    public var fullName = ""
    public var email = ""
    public var phone = ""
    public var location = ""
    public var linkedin = ""
    public var targetRole = ""
    public var militaryService: [MilitaryService] = []
    public var militarySpouse = false

    public init(
        fullName: String = "",
        email: String = "",
        phone: String = "",
        location: String = "",
        linkedin: String = "",
        targetRole: String = "",
        militaryService: [MilitaryService] = [],
        militarySpouse: Bool = false
    ) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.location = location
        self.linkedin = linkedin
        self.targetRole = targetRole
        self.militaryService = militaryService
        self.militarySpouse = militarySpouse
    }
}

public struct EvidenceItem: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let source: String
    public let section: String
    public let text: String
    public let redactedForAI: Bool

    public init(id: String, source: String, section: String, text: String, redactedForAI: Bool = false) {
        self.id = id
        self.source = source
        self.section = section
        self.text = text
        self.redactedForAI = redactedForAI
    }

    enum CodingKeys: String, CodingKey {
        case id, source, section, text
        case redactedForAI = "redactedForAi"
    }
}

public struct SafetyFinding: Codable, Hashable, Sendable, Identifiable {
    public var id: String { "\(code):\(evidenceID ?? "general")" }
    public let code: String
    public let severity: Severity
    public let title: String
    public let detail: String
    public let evidenceID: String?

    public init(code: String, severity: Severity, title: String, detail: String, evidenceID: String? = nil) {
        self.code = code
        self.severity = severity
        self.title = title
        self.detail = detail
        self.evidenceID = evidenceID
    }

    enum CodingKeys: String, CodingKey {
        case code, severity, title, detail
        case evidenceID = "evidenceId"
    }
}

public struct ProposedEdit: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let section: String
    public let originalText: String
    public let proposedText: String
    public let rationale: String
    public let evidenceIDs: [String]
    public let confidence: Double
    public var status: ProposalStatus
    public var editedText: String?
    public let source: String

    public init(
        id: String,
        section: String,
        originalText: String,
        proposedText: String,
        rationale: String,
        evidenceIDs: [String],
        confidence: Double,
        status: ProposalStatus = .pending,
        editedText: String? = nil,
        source: String = "deterministic"
    ) {
        self.id = id
        self.section = section
        self.originalText = originalText
        self.proposedText = proposedText
        self.rationale = rationale
        self.evidenceIDs = evidenceIDs
        self.confidence = confidence
        self.status = status
        self.editedText = editedText
        self.source = source
    }

    public var effectiveText: String {
        status == .edited ? (editedText ?? proposedText) : proposedText
    }

    enum CodingKeys: String, CodingKey {
        case id, section, originalText, proposedText, rationale, confidence, status, editedText, source
        case evidenceIDs = "evidenceIds"
    }
}

public struct GapQuestion: Codable, Hashable, Sendable, Identifiable {
    public var id: String { requirement }
    public let requirement: String
    public let question: String
    public let priority: String
}

public struct JobAnalysis: Codable, Hashable, Sendable {
    public let company: String
    public let title: String
    public let keywords: [String]
    public let requiredQualifications: [String]
    public let missingKeywords: [String]
    public let federal: Bool
    public let openToVeterans: Bool
    public let riskFlags: [String]
}

public struct ReadinessScores: Codable, Hashable, Sendable {
    public let qualificationCoverage: Int
    public let evidenceStrength: Int
    public let acronymClarity: Int
    public let applicationReadiness: Int
    public let disclaimer: String
}

public struct TailorRequest: Codable, Sendable {
    public let resumeText: String
    public let jobText: String
    public let profile: CandidateProfile
    public let mode: ResumeMode
    public let useAI: Bool
    public let aiConsent: Bool

    public init(
        resumeText: String,
        jobText: String,
        profile: CandidateProfile,
        mode: ResumeMode,
        useAI: Bool,
        aiConsent: Bool
    ) {
        self.resumeText = resumeText
        self.jobText = jobText
        self.profile = profile
        self.mode = mode
        self.useAI = useAI
        self.aiConsent = aiConsent
    }
}

public struct TailorResponse: Codable, Sendable {
    public let analysisID: String
    public let engine: String
    public let evidence: [EvidenceItem]
    public let job: JobAnalysis
    public var proposals: [ProposedEdit]
    public let gapQuestions: [GapQuestion]
    public let safetyFindings: [SafetyFinding]
    public let integrityWarnings: [String]
    public let scores: ReadinessScores

    enum CodingKeys: String, CodingKey {
        case engine, evidence, job, proposals, gapQuestions, safetyFindings, integrityWarnings, scores
        case analysisID = "analysisId"
    }
}

public struct HealthResponse: Codable, Sendable {
    public let status: String
    public let version: String
    public let aiConfigured: Bool
    public let aiModel: String?
    public let aiProvider: String?
    public let onDeviceAIAvailable: Bool?
    public let openaiFallbackAvailable: Bool?
    public let truthLock: Bool
    public let features: [String]

    enum CodingKeys: String, CodingKey {
        case status, version, aiConfigured, aiModel, aiProvider, openaiFallbackAvailable, truthLock, features
        case onDeviceAIAvailable = "onDeviceAiAvailable"
    }
}

public struct DocumentExtraction: Codable, Sendable {
    public let filename: String
    public let text: String
    public let warnings: [String]
}

public struct ExportRequest: Codable, Sendable {
    public let resumeText: String
    public let response: TailorResponse
    public let candidateName: String
    public let includeWorkday: Bool
    public let profile: CandidateProfile
    public let mode: ResumeMode
    public let federalDetails: FederalApplicationDetails?

    public init(
        resumeText: String,
        response: TailorResponse,
        candidateName: String,
        includeWorkday: Bool = true,
        profile: CandidateProfile = CandidateProfile(),
        mode: ResumeMode = .auto,
        federalDetails: FederalApplicationDetails? = nil
    ) {
        self.resumeText = resumeText
        self.response = response
        self.candidateName = candidateName
        self.includeWorkday = includeWorkday
        self.profile = profile
        self.mode = mode
        self.federalDetails = federalDetails
    }
}

public struct LinkedInProfileKit: Codable, Sendable {
    public let headlineOptions: [String]
    public let aboutText: String
    public let skills: [String]
    public let experienceHighlights: [String]
    public let featuredIdeas: [String]
    public let connectionMessage: String
    public let recruiterMessage: String
    public let checklist: [String]
    public let disclaimer: String
}

public struct WorkspaceDraft: Codable, Sendable {
    public var profile = CandidateProfile()
    public var resumeText = ""
    public var jobText = ""
    public var resumeFilename = ""
    public var jobFilename = ""
    public var jobURL: String? = nil
    public var trackerRecordID: UUID? = nil
    public var federalDetails: FederalApplicationDetails? = nil
    public var mode = ResumeMode.auto
    public var useAI = true
    public var aiConsent = false
    public var serviceConsent: Bool? = nil

    public init() {}
}
