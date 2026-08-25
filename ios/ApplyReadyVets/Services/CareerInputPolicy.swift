import Foundation

enum CareerInputPolicy {
    enum Kind {
        case resume
        case job

        var label: String {
            switch self {
            case .resume: "resume"
            case .job: "job posting"
            }
        }

        var maximumCharacters: Int {
            switch self {
            case .resume: 250_000
            case .job: 100_000
            }
        }

        var maximumUTF8Bytes: Int {
            switch self {
            case .resume: 2 * 1_024 * 1_024
            case .job: 1 * 1_024 * 1_024
            }
        }
    }

    enum Field {
        case name
        case email
        case phone
        case location
        case linkedInURL
        case targetRole
        case militaryBranch
        case militaryComponent
        case militaryRank
        case militaryPayGrade
        case militaryOccupationCode
        case militaryOccupationTitle
        case militaryServiceDate
        case federalAnnouncement
        case federalSeriesAndGrade
        case employer
        case roleTitle
        case jobID
        case jobURL
        case trackerNotes
        case requiredDocument
        case proposalEdit

        var label: String {
            switch self {
            case .name: "name"
            case .email: "email"
            case .phone: "phone"
            case .location: "location"
            case .linkedInURL: "LinkedIn URL"
            case .targetRole: "target role"
            case .militaryBranch: "military branch"
            case .militaryComponent: "military component"
            case .militaryRank: "military rank"
            case .militaryPayGrade: "military pay grade"
            case .militaryOccupationCode: "military occupation code"
            case .militaryOccupationTitle: "military occupation title"
            case .militaryServiceDate: "military service date"
            case .federalAnnouncement: "federal announcement number"
            case .federalSeriesAndGrade: "federal series and grade"
            case .employer: "employer"
            case .roleTitle: "role title"
            case .jobID: "job ID"
            case .jobURL: "job URL"
            case .trackerNotes: "application notes"
            case .requiredDocument: "required document"
            case .proposalEdit: "verified résumé edit"
            }
        }

        var maximumCharacters: Int {
            switch self {
            case .name: 160
            case .email: 254
            case .phone: 64
            case .location: 200
            case .linkedInURL, .jobURL: 2_048
            case .targetRole, .militaryOccupationTitle: 240
            case .militaryBranch, .militaryComponent: 120
            case .militaryRank, .militaryPayGrade, .militaryOccupationCode,
                 .militaryServiceDate: 80
            case .federalAnnouncement, .federalSeriesAndGrade, .jobID: 200
            case .employer, .roleTitle: 300
            case .trackerNotes: 20_000
            case .requiredDocument: 500
            case .proposalEdit: 20_000
            }
        }

        var maximumUTF8Bytes: Int {
            maximumCharacters * 4
        }
    }

    struct InputTooLarge: LocalizedError {
        let kind: Kind

        var errorDescription: String? {
            "The \(kind.label) is too long to process safely. Keep it under \(kind.maximumCharacters.formatted()) characters and \(kind.maximumUTF8Bytes.formatted()) encoded bytes."
        }
    }

    struct FieldTooLarge: LocalizedError {
        let field: Field

        var errorDescription: String? {
            "The \(field.label) is too long. Keep it under \(field.maximumCharacters.formatted()) characters."
        }
    }

    struct TooManyItems: LocalizedError {
        let label: String
        let maximum: Int

        var errorDescription: String? {
            "There are too many \(label). Keep the list to \(maximum.formatted()) or fewer."
        }
    }

    struct InvalidStatusEvidence: LocalizedError {
        var errorDescription: String? {
            "One or more saved status-image references are invalid."
        }
    }

    @discardableResult
    static func validate(_ text: String, as kind: Kind) throws -> String {
        guard text.count <= kind.maximumCharacters,
              text.utf8.count <= kind.maximumUTF8Bytes else {
            throw InputTooLarge(kind: kind)
        }
        return text
    }

    @discardableResult
    static func validate(_ text: String, as field: Field) throws -> String {
        guard text.count <= field.maximumCharacters,
              text.utf8.count <= field.maximumUTF8Bytes else {
            throw FieldTooLarge(field: field)
        }
        return text
    }

    static func validate(_ profile: CandidateProfile) throws {
        try validate(profile.fullName, as: .name)
        try validate(profile.email, as: .email)
        try validate(profile.phone, as: .phone)
        try validate(profile.location, as: .location)
        try validate(profile.linkedin, as: .linkedInURL)
        try validate(profile.targetRole, as: .targetRole)
        guard profile.militaryService.count <= maximumMilitaryServiceEntries else {
            throw TooManyItems(
                label: "military service entries",
                maximum: maximumMilitaryServiceEntries
            )
        }
        for service in profile.militaryService {
            try validate(service.branch, as: .militaryBranch)
            try validate(service.component, as: .militaryComponent)
            try validate(service.rank, as: .militaryRank)
            try validate(service.payGrade, as: .militaryPayGrade)
            try validate(service.occupationCode, as: .militaryOccupationCode)
            try validate(service.occupationTitle, as: .militaryOccupationTitle)
            try validate(service.serviceStart, as: .militaryServiceDate)
            try validate(service.serviceEnd, as: .militaryServiceDate)
        }
    }

    static func validate(_ details: FederalApplicationDetails) throws {
        try validate(details.announcementNumber, as: .federalAnnouncement)
        try validate(details.targetSeriesAndGrade, as: .federalSeriesAndGrade)
    }

    static func validate(_ draft: WorkspaceDraft) throws {
        try validate(draft.profile)
        try validate(draft.resumeText, as: .resume)
        try validate(draft.jobText, as: .job)
        if let jobURL = draft.jobURL {
            try validate(jobURL, as: .jobURL)
        }
        if let federalDetails = draft.federalDetails {
            try validate(federalDetails)
        }
    }

    static func validate(_ record: JobApplicationRecord) throws {
        try validate(record.employer, as: .employer)
        try validate(record.roleTitle, as: .roleTitle)
        try validate(record.jobID, as: .jobID)
        try validate(record.sourceURL, as: .jobURL)
        try validate(record.notes, as: .trackerNotes)
        guard record.requiredDocuments.count <= maximumRequiredDocuments else {
            throw TooManyItems(
                label: "required documents",
                maximum: maximumRequiredDocuments
            )
        }
        for document in record.requiredDocuments {
            try validate(document, as: .requiredDocument)
        }
        guard record.packetVersions.count <= maximumPacketVersionsPerApplication else {
            throw TooManyItems(
                label: "saved packet versions for one application",
                maximum: maximumPacketVersionsPerApplication
            )
        }
        guard record.statusEvidence.count <= PrivateImageStore.maximumStatusEvidencePerApplication,
              Set(record.statusEvidence.map(\.id)).count == record.statusEvidence.count,
              record.statusEvidence.allSatisfy(\.hasSafeLocalFilename) else {
            throw InvalidStatusEvidence()
        }
    }

    static let maximumMilitaryServiceEntries = 25
    static let maximumRequiredDocuments = 100
    static let maximumPacketVersionsPerApplication = 500
}
