import Foundation
import Testing
@testable import ApplyReadyVetsCore

@Test func localEngineWorksWithoutAService() {
    let request = TailorRequest(
        resumeText: """
        EXPERIENCE
        Led 12 Soldiers as NCOIC and maintained 98% equipment readiness.
        MOS 88M
        """,
        jobText: """
        Company: Example Logistics
        Job Title: Fleet Operations Manager
        Requirements: fleet operations, safety, scheduling, and team leadership.
        """,
        profile: CandidateProfile(targetRole: "Fleet Operations Manager"),
        mode: .civilian,
        useAI: false,
        aiConsent: false
    )

    let result = LocalCareerEngine.analyze(request)

    #expect(result.engine == "private-local-rules+truth-lock")
    #expect(!result.evidence.isEmpty)
    #expect(!result.proposals.isEmpty)
    #expect(result.proposals.allSatisfy {
        TruthLock.validate($0, evidence: result.evidence, targetTitle: result.job.title).accepted
    })
    #expect(result.job.company == "Example Logistics")
}

@Test func localEngineFlagsSensitiveResumeContent() {
    let request = TailorRequest(
        resumeText: "EXPERIENCE\nSSN 123-45-6789\nLed a team.",
        jobText: "Operations Manager\nRequirements: leadership",
        profile: CandidateProfile(),
        mode: .auto,
        useAI: false,
        aiConsent: false
    )

    let result = LocalCareerEngine.analyze(request)

    #expect(result.safetyFindings.contains { $0.code == "ssn" })
    #expect(result.scores.applicationReadiness == 0)
}

@Test func medicalDetailPausesAIWithoutBecomingAHardExportBlocker() {
    let text = "Includes a service-connected disability rating."

    #expect(SensitiveContentPolicy.shouldPauseAI(in: text))
    #expect(!SensitiveContentPolicy.hasCriticalFinding(in: text))
    #expect(
        SensitiveContentPolicy.findings(in: text).contains {
            $0.code == "medical" && $0.severity == .warning
        }
    )
}

@Test func federalPostingClassifierMatchesAnalyzer() {
    let posting = """
    USAJOBS Program Analyst
    GS-0343-11
    Specialized experience is required.
    """

    #expect(LocalCareerEngine.postingAppearsFederal(posting))
    let response = LocalCareerEngine.analyze(TailorRequest(
        resumeText: "Led verified program support.",
        jobText: posting,
        profile: CandidateProfile(),
        mode: .auto,
        useAI: false,
        aiConsent: false
    ))
    #expect(response.job.federal)
}

@Test func militaryOccupationSearchBoundsQueryAndRequestedResultCount() {
    let records = (0..<150).map { index in
        MilitaryOccupationMapping(
            branch: .army,
            militaryCode: "88M-\(index)",
            militaryTitle: "Motor Transport Operator \(index)",
            personnelCategory: "E",
            occupations: []
        )
    }

    let cappedResults = MilitaryOccupationSearch.search(
        records,
        branch: .army,
        query: "88M",
        limit: .max
    )
    #expect(cappedResults.count == MilitaryOccupationSearch.maximumResultLimit)
    #expect(
        MilitaryOccupationSearch.search(
            records,
            branch: .army,
            query: "88M",
            limit: 0
        ).isEmpty
    )

    let suffixOnlyQuery = String(
        repeating: "🤖",
        count: MilitaryOccupationSearch.maximumQueryCharacters
    ) + "88M"
    #expect(
        MilitaryOccupationSearch.search(
            records,
            branch: .army,
            query: suffixOnlyQuery
        ).isEmpty
    )
}

@Test func localLinkedInKitUsesVerifiedContent() {
    let request = TailorRequest(
        resumeText: "EXPERIENCE\nLed 12 people and improved readiness by 20%.",
        jobText: "Company: Example\nJob Title: Operations Manager\nRequirements: leadership",
        profile: CandidateProfile(targetRole: "Operations Manager"),
        mode: .civilian,
        useAI: false,
        aiConsent: false
    )
    let response = LocalCareerEngine.analyze(request)
    let kit = LocalCareerEngine.linkedInKit(for: ExportRequest(
        resumeText: request.resumeText,
        response: response,
        candidateName: "Veteran",
        profile: request.profile
    ), reviewedResumeText: request.resumeText)

    #expect(kit.headlineOptions.contains("Operations Manager"))
    #expect(kit.aboutText.contains("Led 12 people"))
    #expect(kit.disclaimer.lowercased().contains("verify every line"))
}

@Test func completeResumeSafetyScanFindsSpacedSSNAfterEvidenceLimit() {
    let ordinaryLines = (1...320).map { "Completed documented task \($0)." }
    let resume = (ordinaryLines + ["SSN 123 45 6789"]).joined(separator: "\n")
    let result = LocalCareerEngine.analyze(TailorRequest(
        resumeText: resume,
        jobText: "Operations role\nRequirements: documentation",
        profile: CandidateProfile(),
        mode: .civilian,
        useAI: false,
        aiConsent: false
    ))

    #expect(result.safetyFindings.contains { $0.code == "ssn" && $0.severity == .critical })
}

@Test func linkedInKitExcludesSensitiveNumericLines() {
    let resume = """
    Taylor Veteran | taylor@example.com | 555-010-2026
    EXPERIENCE
    Led 12 people.
    SSN 123-45-6789
    """
    let request = TailorRequest(
        resumeText: resume,
        jobText: "Job Title: Manager\nRequirements: leadership",
        profile: CandidateProfile(targetRole: "Manager"),
        mode: .civilian,
        useAI: false,
        aiConsent: false
    )
    let response = LocalCareerEngine.analyze(request)
    let kit = LocalCareerEngine.linkedInKit(
        for: ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Candidate",
            profile: request.profile
        ),
        reviewedResumeText: resume
    )

    #expect(!kit.aboutText.contains("123-45-6789"))
    #expect(!kit.aboutText.contains("taylor@example.com"))
    #expect(!kit.aboutText.contains("555-010-2026"))
    #expect(!kit.experienceHighlights.contains { $0.contains("123-45-6789") })
}

@Test func linkedInSkillsDoNotTreatNegatedKeywordsAsSkills() {
    let resume = "EXPERIENCE\nNo experience with AWS."
    let request = TailorRequest(
        resumeText: resume,
        jobText: "Job Title: Engineer\nRequirements: AWS cloud infrastructure",
        profile: CandidateProfile(targetRole: "Engineer"),
        mode: .civilian,
        useAI: false,
        aiConsent: false
    )
    let response = LocalCareerEngine.analyze(request)
    let kit = LocalCareerEngine.linkedInKit(
        for: ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Candidate",
            profile: request.profile
        ),
        reviewedResumeText: resume
    )

    #expect(!kit.skills.contains { $0.caseInsensitiveCompare("AWS") == .orderedSame })
}

@Test func statusEvidenceKeepsLegacyTrackerFilesReadableAndRejectsUnsafeNames() throws {
    let validEvidence = JobStatusEvidence(
        filename: "550E8400-E29B-41D4-A716-446655440000.jpg"
    )
    #expect(validEvidence.hasSafeLocalFilename)
    #expect(!JobStatusEvidence(filename: "../portal.jpg").hasSafeLocalFilename)

    let record = JobApplicationRecord(
        employer: "Example employer",
        roleTitle: "Program Analyst",
        statusEvidence: [validEvidence]
    )
    let encoded = try JSONEncoder().encode(record)
    var legacyRecord = try #require(
        JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    )
    legacyRecord.removeValue(forKey: "statusEvidence")
    let legacyData = try JSONSerialization.data(withJSONObject: legacyRecord)
    let decoded = try JSONDecoder().decode(
        JobApplicationRecord.self,
        from: legacyData
    )

    #expect(decoded.statusEvidence.isEmpty)
    #expect(decoded.id == record.id)
}
