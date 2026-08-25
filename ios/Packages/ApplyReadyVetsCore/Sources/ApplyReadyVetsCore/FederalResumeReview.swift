import Foundation

public struct FederalApplicationDetails: Codable, Hashable, Sendable {
    public var announcementNumber: String
    public var targetSeriesAndGrade: String

    public init(
        announcementNumber: String = "",
        targetSeriesAndGrade: String = ""
    ) {
        self.announcementNumber = announcementNumber
        self.targetSeriesAndGrade = targetSeriesAndGrade
    }
}

public enum FederalCheckState: String, Codable, Hashable, Sendable {
    case ready
    case attention
    case verify
}

public struct FederalResumeCheck: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let state: FederalCheckState

    public init(id: String, title: String, detail: String, state: FederalCheckState) {
        self.id = id
        self.title = title
        self.detail = detail
        self.state = state
    }
}

public enum FederalResumeReview {
    public static let sourceURL =
        "https://help.usajobs.gov/faq/application/documents/resume/what-to-include"
    public static let sourceReviewedDate = "July 29, 2026"

    public static func checks(
        resumeText: String,
        profile: CandidateProfile,
        details: FederalApplicationDetails?
    ) -> [FederalResumeCheck] {
        let contactReady = [
            profile.fullName,
            profile.email,
            profile.phone,
        ].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let hasMonthYear = contains(
            resumeText,
            #"\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{4}\b|\b(?:0?[1-9]|1[0-2])[/.-]\d{4}\b"#
        )
        let hasHours = contains(
            resumeText,
            #"\b\d{1,3}(?:\.\d+)?\s*(?:hours?|hrs?)\s*(?:/|per)\s*week\b"#
        )
        let announcement = details?.announcementNumber
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return [
            FederalResumeCheck(
                id: "contact",
                title: "Current contact information",
                detail: contactReady
                    ? "Name, email, and phone are present in the profile."
                    : "Add your name, email, and phone. Confirm any other contact fields required by the announcement.",
                state: contactReady ? .ready : .attention
            ),
            FederalResumeCheck(
                id: "dates",
                title: "Month and year for relevant experience",
                detail: hasMonthYear
                    ? "At least one month-and-year date pattern was found. Verify every relevant position."
                    : "No clear month-and-year pattern was found. Add start and end month/year for every relevant position.",
                state: hasMonthYear ? .verify : .attention
            ),
            FederalResumeCheck(
                id: "hours",
                title: "Hours worked per week",
                detail: hasHours
                    ? "At least one hours-per-week entry was found. Verify every relevant position."
                    : "No hours-per-week entry was found. USAJOBS asks for this for each relevant work experience.",
                state: hasHours ? .verify : .attention
            ),
            FederalResumeCheck(
                id: "announcement",
                title: "Announcement identity",
                detail: announcement.isEmpty
                    ? "Add the announcement number so this version remains tied to the correct posting."
                    : "Announcement \(announcement) is attached to this workspace.",
                state: announcement.isEmpty ? .attention : .ready
            ),
            FederalResumeCheck(
                id: "pages",
                title: "Two-page maximum",
                detail: "Plain text cannot prove pagination. Save the final résumé as an 8.5×11-inch PDF and confirm it is two pages or less before upload.",
                state: .verify
            ),
            FederalResumeCheck(
                id: "sensitive",
                title: "Sensitive-information review",
                detail: SensitiveContentPolicy.hasCriticalFinding(in: resumeText)
                    ? "Remove the critical sensitive-information finding before export."
                    : "No configured critical SSN, banking, classified, or operational pattern was detected. Review manually too.",
                state: SensitiveContentPolicy.hasCriticalFinding(in: resumeText)
                    ? .attention
                    : .verify
            ),
        ]
    }

    private static func contains(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
