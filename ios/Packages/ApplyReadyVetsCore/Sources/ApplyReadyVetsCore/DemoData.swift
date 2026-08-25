import Foundation

public enum DemoData {
    public static let resume = """
    Taylor Veteran
    San Diego, CA | taylor@example.com | 555-010-2026

    MILITARY EXPERIENCE
    Operations NCOIC | 2020–2024
    Led 12 personnel and maintained 98% equipment readiness.
    MOS 88M

    EDUCATION
    Associate Degree, Logistics Management
    """

    public static let job = """
    Company: Acme Logistics
    Title: Fleet Operations Manager
    Required: logistics, fleet readiness, team leadership, and safety compliance.
    This job is open to Veterans under VRA.
    """

    public static var draft: WorkspaceDraft {
        var draft = WorkspaceDraft()
        draft.profile = CandidateProfile(fullName: "Taylor Veteran", targetRole: "Fleet Operations Manager")
        draft.resumeText = resume
        draft.jobText = job
        draft.resumeFilename = "Taylor_Veteran_Resume.txt"
        draft.jobFilename = "Acme_Fleet_Manager.txt"
        draft.jobURL = "https://www.usajobs.gov/job/000000000"
        return draft
    }
}
