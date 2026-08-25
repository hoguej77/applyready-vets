import Foundation

public enum JobApplicationStatus: String, Codable, CaseIterable, Sendable, Identifiable {
    case saved
    case preparing
    case applied
    case interviewing
    case offer
    case accepted
    case notSelected
    case withdrawn

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .saved: "Saved"
        case .preparing: "Preparing"
        case .applied: "Applied"
        case .interviewing: "Interviewing"
        case .offer: "Offer"
        case .accepted: "Accepted"
        case .notSelected: "Not selected"
        case .withdrawn: "Withdrawn"
        }
    }

    public var systemImage: String {
        switch self {
        case .saved: "bookmark"
        case .preparing: "doc.badge.ellipsis"
        case .applied: "paperplane"
        case .interviewing: "person.2"
        case .offer: "envelope.open"
        case .accepted: "checkmark.seal"
        case .notSelected: "xmark.circle"
        case .withdrawn: "arrow.uturn.backward.circle"
        }
    }

    public var isActive: Bool {
        switch self {
        case .saved, .preparing, .applied, .interviewing, .offer:
            true
        case .accepted, .notSelected, .withdrawn:
            false
        }
    }
}

public struct ApplicationPacketVersion: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var number: Int
    public var createdAt: Date
    public var resumeFilename: String
    public var richTextFilename: String?
    public var plainTextFilename: String?
    public var privateReviewFilename: String?
    public var notes: String

    public init(
        id: UUID = UUID(),
        number: Int,
        createdAt: Date = Date(),
        resumeFilename: String,
        richTextFilename: String? = nil,
        plainTextFilename: String? = nil,
        privateReviewFilename: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.number = number
        self.createdAt = createdAt
        self.resumeFilename = resumeFilename
        self.richTextFilename = richTextFilename
        self.plainTextFilename = plainTextFilename
        self.privateReviewFilename = privateReviewFilename
        self.notes = notes
    }
}

/// A locally stored screenshot or photo that documents an application's
/// current state, such as a portal confirmation or interview invitation.
/// The image bytes live outside the tracker JSON; this value is deliberately
/// limited to the private-file reference and its audit timestamp.
public struct JobStatusEvidence: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var filename: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        filename: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
    }

    public var hasSafeLocalFilename: Bool {
        guard filename.hasSuffix(".jpg"), filename.count <= 64 else {
            return false
        }
        return UUID(uuidString: String(filename.dropLast(4))) != nil
    }
}

public struct JobApplicationRecord: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var ownerProfileID: UUID?
    public var employer: String
    public var roleTitle: String
    public var jobID: String
    public var platform: JobPlatform
    public var sourceURL: String
    public var status: JobApplicationStatus
    public var notes: String
    public var deadline: Date?
    public var requiredDocuments: [String]
    public var packetVersions: [ApplicationPacketVersion]
    public var statusEvidence: [JobStatusEvidence]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        ownerProfileID: UUID? = nil,
        employer: String = "",
        roleTitle: String = "",
        jobID: String = "",
        platform: JobPlatform = .employerSite,
        sourceURL: String = "",
        status: JobApplicationStatus = .saved,
        notes: String = "",
        deadline: Date? = nil,
        requiredDocuments: [String] = [],
        packetVersions: [ApplicationPacketVersion] = [],
        statusEvidence: [JobStatusEvidence] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerProfileID = ownerProfileID
        self.employer = employer
        self.roleTitle = roleTitle
        self.jobID = jobID
        self.platform = platform
        self.sourceURL = sourceURL
        self.status = status
        self.notes = notes
        self.deadline = deadline
        self.requiredDocuments = requiredDocuments
        self.packetVersions = packetVersions
        self.statusEvidence = statusEvidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerProfileID
        case employer
        case roleTitle
        case jobID
        case platform
        case sourceURL
        case status
        case notes
        case deadline
        case requiredDocuments
        case packetVersions
        case statusEvidence
        case createdAt
        case updatedAt
    }

    /// Tracker files from earlier releases do not contain status evidence.
    /// Decode those files as an empty collection so adding this feature never
    /// makes a person’s existing private tracker unreadable.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        ownerProfileID = try values.decodeIfPresent(UUID.self, forKey: .ownerProfileID)
        employer = try values.decode(String.self, forKey: .employer)
        roleTitle = try values.decode(String.self, forKey: .roleTitle)
        jobID = try values.decode(String.self, forKey: .jobID)
        platform = try values.decode(JobPlatform.self, forKey: .platform)
        sourceURL = try values.decode(String.self, forKey: .sourceURL)
        status = try values.decode(JobApplicationStatus.self, forKey: .status)
        notes = try values.decode(String.self, forKey: .notes)
        deadline = try values.decodeIfPresent(Date.self, forKey: .deadline)
        requiredDocuments = try values.decode([String].self, forKey: .requiredDocuments)
        packetVersions = try values.decode([ApplicationPacketVersion].self, forKey: .packetVersions)
        statusEvidence = try values.decodeIfPresent(
            [JobStatusEvidence].self,
            forKey: .statusEvidence
        ) ?? []
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
    }

    public var displayTitle: String {
        let trimmed = roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled opportunity" : trimmed
    }

    public var displayEmployer: String {
        let trimmed = employer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? platform.label : trimmed
    }

    public var nextPacketVersionNumber: Int {
        (packetVersions.map(\.number).max() ?? 0) + 1
    }
}
