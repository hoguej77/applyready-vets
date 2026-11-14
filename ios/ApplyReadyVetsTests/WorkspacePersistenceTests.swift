import XCTest
@testable import ApplyReadyVets

final class WorkspacePersistenceTests: XCTestCase {
    func testAppReviewLinksAcceptOnlyPublicHTTPSURLs() {
        XCTAssertEqual(
            AppReviewLinks.validatedHTTPSURL("https://support.apple.com/contact")?.absoluteString,
            "https://support.apple.com/contact"
        )
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL(""))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("http://applyreadyvets.example/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://localhost/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://127.0.0.1/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://10.0.0.8/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://172.16.0.8/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://192.168.1.8/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://example.com/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://applyreadyvets.example/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://user:secret@example.com/support"))
        XCTAssertNil(AppReviewLinks.validatedHTTPSURL("https://example.com/support#private"))
    }

    func testProtectedWorkspaceRoundTripsReviewState() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientWorkspaceStore(directory: directory)
        var response = localResponse()
        response.proposals[0].status = .approved
        let state = WorkspacePersistenceState(
            hasStarted: true,
            stepRawValue: AppModel.FlowStep.review.rawValue,
            draft: DemoData.draft,
            response: response,
            linkedInKit: nil
        )

        try store.save(state)
        let loaded = try XCTUnwrap(store.load())

        XCTAssertFalse(loaded.recoveredFromBackup)
        XCTAssertEqual(loaded.state.stepRawValue, AppModel.FlowStep.review.rawValue)
        XCTAssertEqual(loaded.state.response?.proposals.first?.status, .approved)
        XCTAssertEqual(loaded.state.draft.profile.targetRole, "Fleet Operations Manager")
    }

    func testCorruptPrimaryRecoversLastKnownGoodCopy() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ResilientWorkspaceStore(directory: directory)
        var firstDraft = DemoData.draft
        firstDraft.profile.targetRole = "First verified role"
        var secondDraft = firstDraft
        secondDraft.profile.targetRole = "Second verified role"

        try store.save(state(with: firstDraft))
        try store.save(state(with: secondDraft))
        let primary = directory.appendingPathComponent("ApplyReadyVetsWorkspace.v1.json")
        try Data("damaged".utf8).write(to: primary, options: .atomic)

        let recovered = try XCTUnwrap(store.load())

        XCTAssertTrue(recovered.recoveredFromBackup)
        XCTAssertEqual(recovered.state.draft.profile.targetRole, "First verified role")
        XCTAssertEqual(
            try XCTUnwrap(store.load()).state.draft.profile.targetRole,
            "First verified role"
        )
    }

    func testServiceEndpointPolicyRejectsInsecureRemoteURL() {
        XCTAssertEqual(ServiceEndpointPolicy.classify(""), .notConfigured)
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("http://127.0.0.1:8000"),
            .developmentLocal
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("https://service.applyready.example"),
            .secureRemote
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("http://service.applyready.example"),
            .insecureRemote
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("http://192.168.1.25:8000"),
            .developmentLocal
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("not a URL"),
            .insecureRemote
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("https://user:password@service.applyready.example"),
            .insecureRemote
        )
        XCTAssertEqual(
            ServiceEndpointPolicy.classify("https://service.applyready.example?token=secret"),
            .insecureRemote
        )
        XCTAssertEqual(ServiceEndpointPolicy.classify("http://127.0.0.2:8000"), .developmentLocal)
        XCTAssertEqual(ServiceEndpointPolicy.classify("http://169.254.169.254"), .developmentLocal)
        XCTAssertEqual(ServiceEndpointPolicy.classify("http://100.64.0.1:8000"), .developmentLocal)
        XCTAssertEqual(ServiceEndpointPolicy.classify("http://[fe80::1]:8000"), .developmentLocal)
        XCTAssertEqual(ServiceEndpointPolicy.classify("https://fc-example.com"), .secureRemote)
    }

    func testJobURLPolicyAcceptsOnlySafeWebLinks() {
        XCTAssertEqual(
            JobURLPolicy.normalize("jobs.example.gov/posting/42"),
            "https://jobs.example.gov/posting/42"
        )
        XCTAssertEqual(
            JobURLPolicy.normalize("https://jobs.example.gov/posting/42?source=app"),
            "https://jobs.example.gov/posting/42?source=app"
        )
        XCTAssertNil(JobURLPolicy.normalize("javascript:alert(1)"))
        XCTAssertNil(JobURLPolicy.normalize("file:///private/resume.txt"))
        XCTAssertNil(JobURLPolicy.normalize("https://user:password@jobs.example.gov/42"))
        XCTAssertEqual(
            JobURLPolicy.maximumCharacters,
            CareerInputPolicy.Field.jobURL.maximumCharacters
        )
        XCTAssertNil(JobURLPolicy.normalize(
            "https://jobs.example.gov/" + String(
                repeating: "a",
                count: JobURLPolicy.maximumCharacters
            )
        ))
    }

    func testCareerInputPolicyBoundsPastedAndImportedText() {
        XCTAssertNoThrow(try CareerInputPolicy.validate(
            String(repeating: "r", count: CareerInputPolicy.Kind.resume.maximumCharacters),
            as: .resume
        ))
        XCTAssertThrowsError(try CareerInputPolicy.validate(
            String(repeating: "j", count: CareerInputPolicy.Kind.job.maximumCharacters + 1),
            as: .job
        ))
    }

    func testCareerInputPolicyBoundsProfileAndTrackerCollections() {
        let oversizedName = String(
            repeating: "n",
            count: CareerInputPolicy.Field.name.maximumCharacters + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(
            CandidateProfile(fullName: oversizedName)
        ))

        let tooManyServiceEntries = Array(
            repeating: MilitaryService(),
            count: CareerInputPolicy.maximumMilitaryServiceEntries + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(
            CandidateProfile(militaryService: tooManyServiceEntries)
        ))

        let tooManyDocuments = Array(
            repeating: "Résumé",
            count: CareerInputPolicy.maximumRequiredDocuments + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(
            JobApplicationRecord(requiredDocuments: tooManyDocuments)
        ))
    }

    func testCareerInputPolicyValidatesEveryJobFacingDraftField() {
        var draft = DemoData.draft
        XCTAssertNoThrow(try CareerInputPolicy.validate(draft))

        draft.profile.targetRole = String(
            repeating: "R",
            count: CareerInputPolicy.Field.targetRole.maximumCharacters + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft))

        draft = DemoData.draft
        draft.resumeText = String(
            repeating: "r",
            count: CareerInputPolicy.Kind.resume.maximumCharacters + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft))

        draft = DemoData.draft
        draft.federalDetails = FederalApplicationDetails(
            announcementNumber: String(
                repeating: "A",
                count: CareerInputPolicy.Field.federalAnnouncement.maximumCharacters + 1
            ),
            targetSeriesAndGrade: "GS-0343-11"
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft)) { error in
            guard let fieldError = error as? CareerInputPolicy.FieldTooLarge else {
                return XCTFail("Expected FieldTooLarge, got \(error)")
            }
            XCTAssertEqual(fieldError.field.label, "federal announcement number")
        }

        draft.federalDetails = FederalApplicationDetails(
            announcementNumber: "DE-123",
            targetSeriesAndGrade: String(
                repeating: "G",
                count: CareerInputPolicy.Field.federalSeriesAndGrade.maximumCharacters + 1
            )
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft))

        draft = DemoData.draft
        draft.federalDetails = nil
        draft.jobURL = String(
            repeating: "u",
            count: CareerInputPolicy.Field.jobURL.maximumCharacters + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft))

        draft = DemoData.draft
        draft.jobURL = nil
        draft.jobText = String(
            repeating: "j",
            count: CareerInputPolicy.Kind.job.maximumCharacters + 1
        )
        XCTAssertThrowsError(try CareerInputPolicy.validate(draft))
    }

    func testAPIClientRejectsOversizedEncodedJSONBeforeNetworkUse() {
        let client = APIClient(
            baseURL: "https://service.applyready.example",
            bearerToken: ""
        )
        let oversized = [
            "payload": String(
                repeating: "x",
                count: APIClient.maximumJSONRequestBytes + 1
            ),
        ]

        XCTAssertThrowsError(try client.encodedJSONBody(oversized)) { error in
            guard case APIClient.ClientError.requestTooLarge = error else {
                return XCTFail("Expected requestTooLarge, got \(error)")
            }
        }
    }

    func testLegacyDraftWithoutServiceConsentStillDecodes() throws {
        let json = """
        {
          "profile": {
            "fullName": "",
            "email": "",
            "phone": "",
            "location": "",
            "linkedin": "",
            "targetRole": "",
            "militaryService": [],
            "militarySpouse": false
          },
          "resumeText": "Verified experience",
          "jobText": "Target job",
          "resumeFilename": "",
          "jobFilename": "",
          "jobURL": null,
          "mode": "auto",
          "useAI": false,
          "aiConsent": false
        }
        """

        let draft = try JSONDecoder().decode(WorkspaceDraft.self, from: Data(json.utf8))

        XCTAssertNil(draft.serviceConsent)
        XCTAssertEqual(draft.resumeText, "Verified experience")
    }

    func testOnDeviceProposalRequiresItsExactCitedResumeLine() {
        let evidence = [
            EvidenceItem(
                id: "resume:001",
                source: "resume",
                section: "experience",
                text: "Led 12 personnel."
            ),
            EvidenceItem(
                id: "resume:002",
                source: "resume",
                section: "experience",
                text: "Managed vehicle readiness."
            ),
        ]

        XCTAssertTrue(OnDeviceProposalService.hasExactResumeEvidence(
            originalText: "Led 12 personnel.",
            evidenceIDs: ["resume:001"],
            evidence: evidence
        ))
        XCTAssertFalse(OnDeviceProposalService.hasExactResumeEvidence(
            originalText: "Led 12 personnel.",
            evidenceIDs: ["resume:002"],
            evidence: evidence
        ))
    }

    func testOptionalServiceCanOnlyAddLocallyVerifiedPendingProposals() throws {
        let baseline = localResponse()
        let exactEvidence = try XCTUnwrap(baseline.evidence.first {
            $0.source == "resume" && $0.text == "Led 12 personnel."
        })
        let forgedEvidence = EvidenceItem(
            id: "remote:forged",
            source: "resume",
            section: "experience",
            text: "Led 12 personnel."
        )
        let forged = ProposedEdit(
            id: "remote-forged",
            section: "experience",
            originalText: "Led 12 personnel.",
            proposedText: "Led 12 personnel and increased output by 999%.",
            rationale: "Remote-only claim",
            evidenceIDs: [forgedEvidence.id],
            confidence: 1,
            status: .approved,
            source: "remote"
        )
        let supported = ProposedEdit(
            id: "remote-supported",
            section: "experience",
            originalText: "Led 12 personnel.",
            proposedText: "Managed 12 personnel.",
            rationale: "Use civilian leadership language without adding a new claim.",
            evidenceIDs: [exactEvidence.id],
            confidence: 0.8,
            status: .approved,
            editedText: "Untrusted preapproval",
            source: "remote"
        )
        let serviceResponse = TailorResponse(
            analysisID: "remote",
            engine: "untrusted-service",
            evidence: [forgedEvidence],
            job: baseline.job,
            proposals: [forged, supported],
            gapQuestions: [],
            safetyFindings: [],
            integrityWarnings: [],
            scores: baseline.scores
        )

        let merged = ServiceProposalGate.merge(
            serviceResponse,
            into: baseline,
            resumeText: "EXPERIENCE\nMOS 88M\nLed 12 personnel."
        )

        XCTAssertEqual(merged.evidence, baseline.evidence)
        XCTAssertEqual(merged.safetyFindings, baseline.safetyFindings)
        XCTAssertEqual(merged.scores, baseline.scores)
        XCTAssertEqual(merged.proposals.count, baseline.proposals.count + 1)
        XCTAssertEqual(merged.proposals.last?.source, "optional-service")
        XCTAssertEqual(merged.proposals.last?.status, .pending)
        XCTAssertNil(merged.proposals.last?.editedText)
        XCTAssertFalse(merged.proposals.contains { $0.proposedText.contains("999%") })
    }

    func testLocalExportRevalidatesUserEditedWording() throws {
        let resume = "EXPERIENCE\nMOS 88M\nLed 12 personnel."
        var response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "Title: Operations Manager\nRequirements: logistics leadership",
            profile: CandidateProfile(targetRole: "Operations Manager"),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let proposal = try XCTUnwrap(response.proposals.first)
        response.proposals[0].status = .edited
        response.proposals[0].editedText = proposal.proposedText + " and increased output by 999%."
        let request = ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Test Veteran"
        )

        XCTAssertThrowsError(try LocalExportService.createCandidateReviewedResume(from: request))
    }

    func testLocalExportRebuildsEvidenceInsteadOfTrustingPersistedResponseEvidence() throws {
        let resume = "EXPERIENCE\nManaged logistics operations."
        let baseline = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "Title: Operations Manager\nRequirements: logistics",
            profile: CandidateProfile(),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let forged = ProposedEdit(
            id: "forged-local-rule",
            section: "experience",
            originalText: "Managed logistics operations.",
            proposedText: "Managed logistics operations and built vendor relationships.",
            rationale: "Forged claim",
            evidenceIDs: ["resume:001"],
            confidence: 1,
            status: .approved,
            source: "private-local-rules"
        )
        let forgedResponse = TailorResponse(
            analysisID: baseline.analysisID,
            engine: baseline.engine,
            evidence: [
                EvidenceItem(
                    id: "resume:001",
                    source: "resume",
                    section: "experience",
                    text: "Managed logistics operations and built vendor relationships."
                ),
            ],
            job: baseline.job,
            proposals: [forged],
            gapQuestions: baseline.gapQuestions,
            safetyFindings: baseline.safetyFindings,
            integrityWarnings: baseline.integrityWarnings,
            scores: baseline.scores
        )

        XCTAssertThrowsError(try LocalExportService.validatedResumeText(from: ExportRequest(
            resumeText: resume,
            response: forgedResponse,
            candidateName: "Test Candidate"
        )))
    }

    func testEmployerFacingResumeExcludesPrivateReviewMaterial() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let resume = "EXPERIENCE\nLed 12 personnel."
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "Title: Operations Manager\nRequirements: leadership",
            profile: CandidateProfile(),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let request = ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Test Candidate"
        )

        let employerURL = try LocalExportService.createCandidateReviewedResume(
            from: request,
            directoryOverride: outputDirectory
        )
        let privateURL = try LocalExportService.createPrivateReviewReport(
            from: request,
            directoryOverride: outputDirectory
        )
        let employerText = try String(contentsOf: employerURL, encoding: .utf8)
        let privateText = try String(contentsOf: privateURL, encoding: .utf8)

        XCTAssertEqual(
            employerURL.deletingLastPathComponent().standardizedFileURL.path,
            outputDirectory.standardizedFileURL.path
        )
        XCTAssertEqual(
            privateURL.deletingLastPathComponent().standardizedFileURL.path,
            outputDirectory.standardizedFileURL.path
        )
        XCTAssertEqual(employerText, resume + "\n")
        XCTAssertFalse(employerText.contains("APPLICATION READINESS"))
        XCTAssertFalse(employerText.contains("QUESTIONS TO VERIFY"))
        XCTAssertTrue(privateText.contains("PRIVATE CANDIDATE REVIEW"))
        XCTAssertTrue(privateText.contains("Do not upload it as a resume"))
    }

    func testCandidateReviewedBundleCreatesPDFRTFAndParserSafeText() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let resume = """
        TEST CANDIDATE
        EXPERIENCE
        Led 12 personnel across logistics operations.
        """
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "Title: Operations Manager\nRequirements: logistics leadership",
            profile: CandidateProfile(),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let request = ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Test Candidate"
        )

        let bundle = try LocalExportService.createCandidateReviewedBundle(
            from: request,
            directoryOverride: outputDirectory
        )
        let plainText = try String(
            contentsOf: bundle.plainTextURL,
            encoding: .utf8
        )
        let richText = try String(
            contentsOf: bundle.richTextURL,
            encoding: .utf8
        )
        let pdfData = try Data(contentsOf: bundle.pdfURL)

        XCTAssertEqual(plainText, resume + "\n")
        XCTAssertTrue(richText.hasPrefix("{\\rtf1"))
        XCTAssertTrue(richText.contains("Led 12 personnel"))
        XCTAssertEqual(String(data: pdfData.prefix(4), encoding: .ascii), "%PDF")
        XCTAssertEqual(Set(bundle.allURLs.map(\.pathExtension)), ["pdf", "rtf", "txt"])
        XCTAssertFalse(plainText.contains("PRIVATE CANDIDATE REVIEW"))
        XCTAssertFalse(richText.contains("QUESTIONS TO VERIFY"))
    }

    func testCandidateExportRejectsBlankResumeEvenWithAResponse() {
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: "",
            jobText: "Operations Manager",
            profile: CandidateProfile(),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let request = ExportRequest(
            resumeText: " \n ",
            response: response,
            candidateName: "Test Candidate"
        )

        XCTAssertThrowsError(
            try LocalExportService.validatedResumeText(from: request)
        ) { error in
            guard case LocalExportService.ExportError.emptyResume = error else {
                return XCTFail("Expected emptyResume, got \(error)")
            }
        }
    }

    func testFederalBundleStopsWhenRenderedPDFExceedsTwoPages() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let longResume = (1...500)
            .map { "Verified program support responsibility \($0)." }
            .joined(separator: "\n")
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: longResume,
            jobText: "Program Analyst\nRequirements: program support",
            profile: CandidateProfile(),
            mode: .federal,
            useAI: false,
            aiConsent: false
        ))
        let request = ExportRequest(
            resumeText: longResume,
            response: response,
            candidateName: "Test Candidate",
            profile: CandidateProfile(fullName: "Test Candidate"),
            mode: .federal,
            federalDetails: FederalApplicationDetails(
                announcementNumber: "DE-123",
                targetSeriesAndGrade: "GS-0343-11"
            )
        )

        XCTAssertThrowsError(
            try LocalExportService.createCandidateReviewedBundle(
                from: request,
                directoryOverride: outputDirectory
            )
        ) { error in
            guard case let LocalExportService.ExportError
                .federalPageLimitExceeded(pageCount) = error else {
                return XCTFail(
                    "Expected federal page-limit error, got \(error)"
                )
            }
            XCTAssertGreaterThan(pageCount, 2)
        }
        XCTAssertTrue(
            (try? FileManager.default.contentsOfDirectory(
                at: outputDirectory,
                includingPropertiesForKeys: nil
            ).isEmpty) == true
        )
    }

    func testRejectedFederalPDFPreservesExistingBundleAndCleansStagingFile() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let candidateName = "Protected Candidate"
        let shortResume = """
        PROTECTED CANDIDATE
        EXPERIENCE
        Led verified program support.
        """
        let shortResponse = LocalCareerEngine.analyze(TailorRequest(
            resumeText: shortResume,
            jobText: "USAJOBS Program Analyst\nGS-0343-11\nProgram support",
            profile: CandidateProfile(),
            mode: .federal,
            useAI: false,
            aiConsent: false
        ))
        let existingBundle = try LocalExportService.createCandidateReviewedBundle(
            from: ExportRequest(
                resumeText: shortResume,
                response: shortResponse,
                candidateName: candidateName,
                mode: .federal
            ),
            directoryOverride: outputDirectory
        )
        let originalData = try Dictionary(
            uniqueKeysWithValues: existingBundle.allURLs.map {
                ($0.lastPathComponent, try Data(contentsOf: $0))
            }
        )
        let longResume = (1...500)
            .map { "Verified federal program responsibility \($0)." }
            .joined(separator: "\n")
        let longResponse = LocalCareerEngine.analyze(TailorRequest(
            resumeText: longResume,
            jobText: "USAJOBS Program Analyst\nGS-0343-11\nProgram support",
            profile: CandidateProfile(),
            mode: .federal,
            useAI: false,
            aiConsent: false
        ))

        XCTAssertThrowsError(
            try LocalExportService.createCandidateReviewedBundle(
                from: ExportRequest(
                    resumeText: longResume,
                    response: longResponse,
                    candidateName: candidateName,
                    mode: .federal
                ),
                directoryOverride: outputDirectory
            )
        ) { error in
            guard case LocalExportService.ExportError
                .federalPageLimitExceeded = error else {
                return XCTFail("Expected a federal page-limit error, got \(error)")
            }
        }

        for url in existingBundle.allURLs {
            let expectedData = try XCTUnwrap(
                originalData[url.lastPathComponent]
            )
            XCTAssertEqual(
                try Data(contentsOf: url),
                expectedData
            )
        }
        let remainingNames = try FileManager.default.contentsOfDirectory(
            atPath: outputDirectory.path
        )
        XCTAssertFalse(remainingNames.contains { $0.hasSuffix(".tmp") })
    }

    func testAutoDetectedFederalBundleStillEnforcesPageLimit() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let longResume = (1...500)
            .map { "Verified federal program responsibility \($0)." }
            .joined(separator: "\n")
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: longResume,
            jobText: """
            USAJOBS Program Analyst
            GS-0343-11
            Specialized experience is required.
            """,
            profile: CandidateProfile(),
            mode: .auto,
            useAI: false,
            aiConsent: false
        ))
        XCTAssertTrue(response.job.federal)
        let request = ExportRequest(
            resumeText: longResume,
            response: response,
            candidateName: "Test Candidate",
            profile: CandidateProfile(fullName: "Test Candidate"),
            mode: .auto
        )

        XCTAssertThrowsError(
            try LocalExportService.createCandidateReviewedBundle(
                from: request,
                directoryOverride: outputDirectory
            )
        ) { error in
            guard case LocalExportService.ExportError
                .federalPageLimitExceeded = error else {
                return XCTFail("Expected an auto-detected federal page-limit error.")
            }
        }
    }

    func testFederalExportDoesNotDuplicateExistingContactHeader() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let resume = """
        TEST CANDIDATE
        test@example.com | (555) 010-1000 | San Diego, CA

        EXPERIENCE
        Led verified program support.
        """
        let profile = CandidateProfile(
            fullName: "Test Candidate",
            email: "test@example.com",
            phone: "555-010-1000",
            location: "San Diego, CA"
        )
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "USAJOBS\nGS-0343-11\nSpecialized experience",
            profile: profile,
            mode: .federal,
            useAI: false,
            aiConsent: false
        ))
        let bundle = try LocalExportService.createCandidateReviewedBundle(
            from: ExportRequest(
                resumeText: resume,
                response: response,
                candidateName: "Test Candidate",
                profile: profile,
                mode: .federal
            ),
            directoryOverride: outputDirectory
        )
        let exported = try String(
            contentsOf: bundle.plainTextURL,
            encoding: .utf8
        )

        XCTAssertEqual(
            exported.components(separatedBy: "test@example.com").count - 1,
            1
        )
        XCTAssertEqual(
            exported.components(separatedBy: "TEST CANDIDATE").count - 1,
            1
        )
    }

    func testVersionedBundlesFromDifferentApplicationsNeverOverwrite() throws {
        let outputDirectory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let resume = "TEST CANDIDATE\nEXPERIENCE\nLed logistics operations."
        let response = LocalCareerEngine.analyze(TailorRequest(
            resumeText: resume,
            jobText: "Title: Operations Manager\nRequirements: logistics",
            profile: CandidateProfile(),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
        let request = ExportRequest(
            resumeText: resume,
            response: response,
            candidateName: "Test Candidate"
        )
        let firstApplication = UUID()
        let secondApplication = UUID()

        let firstV1 = try LocalExportService.createCandidateReviewedBundle(
            from: request,
            applicationID: firstApplication,
            packetVersion: 1,
            directoryOverride: outputDirectory
        )
        let secondV1 = try LocalExportService.createCandidateReviewedBundle(
            from: request,
            applicationID: secondApplication,
            packetVersion: 1,
            directoryOverride: outputDirectory
        )
        let firstV2 = try LocalExportService.createCandidateReviewedBundle(
            from: request,
            applicationID: firstApplication,
            packetVersion: 2,
            directoryOverride: outputDirectory
        )
        let allURLs = firstV1.allURLs + secondV1.allURLs + firstV2.allURLs

        XCTAssertEqual(Set(allURLs.map(\.lastPathComponent)).count, 9)
        XCTAssertTrue(allURLs.allSatisfy {
            FileManager.default.fileExists(atPath: $0.path)
        })
    }

    func testOutputFileResolverRejectsTraversalAndFindsExistingFile() throws {
        let outputDirectory = try UserDocumentWorkspace.outputDirectory()
        let filename = "ApplyReadyVets_Test_\(UUID().uuidString).txt"
        let file = outputDirectory.appendingPathComponent(filename)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("verified".utf8).write(
            to: file,
            options: [.atomic, .completeFileProtection]
        )

        XCTAssertEqual(
            UserDocumentWorkspace.existingOutputFile(named: filename),
            file.standardizedFileURL
        )
        XCTAssertNil(
            UserDocumentWorkspace.existingOutputFile(
                named: "../Private/secret.txt"
            )
        )
        XCTAssertNil(
            UserDocumentWorkspace.existingOutputFile(
                named: "missing-\(UUID().uuidString).txt"
            )
        )
    }

    func testExportRejectsAmbiguousOrCompetingEdits() throws {
        let repeatedResume = "EXPERIENCE\nManaged operations.\nManaged operations."
        let baseline = localResponse()
        let evidence = [
            EvidenceItem(
                id: "resume:001",
                source: "resume",
                section: "experience",
                text: "Managed operations."
            ),
        ]
        var first = ProposedEdit(
            id: "first",
            section: "experience",
            originalText: "Managed operations.",
            proposedText: "Led operations.",
            rationale: "Wording",
            evidenceIDs: ["resume:001"],
            confidence: 0.8,
            status: .approved,
            source: "optional-service"
        )
        var response = TailorResponse(
            analysisID: "test",
            engine: "test",
            evidence: evidence,
            job: baseline.job,
            proposals: [first],
            gapQuestions: [],
            safetyFindings: [],
            integrityWarnings: [],
            scores: baseline.scores
        )
        var request = ExportRequest(
            resumeText: repeatedResume,
            response: response,
            candidateName: "Candidate"
        )
        XCTAssertThrowsError(
            try LocalExportService.createCandidateReviewedResume(from: request)
        )

        first = response.proposals[0]
        var second = first
        second.status = .approved
        response.proposals = [first, second]
        request = ExportRequest(
            resumeText: "EXPERIENCE\nManaged operations.",
            response: response,
            candidateName: "Candidate"
        )
        XCTAssertThrowsError(
            try LocalExportService.createCandidateReviewedResume(from: request)
        )
    }

    @MainActor
    func testChangingInputsImmediatelyMakesAnalysisUnavailable() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory)
        )
        model.draft = DemoData.draft

        await model.analyze()
        XCTAssertNotNil(model.currentResponse)
        XCTAssertEqual(model.step, .review)

        model.draft.jobText += "\nRequired: contract management"

        XCTAssertNil(model.currentResponse)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNil(model.response)
        XCTAssertEqual(model.step, .analyze)
    }

    @MainActor
    func testApprovingAfterAnEditDoesNotSilentlyDiscardVeteranWording() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(
            workspaceStore: ResilientWorkspaceStore(directory: directory),
            jobTrackerStore: ResilientJobTrackerStore(directory: directory)
        )
        model.draft = DemoData.draft
        await model.analyze()
        let proposal = try XCTUnwrap(model.currentResponse?.proposals.first)
        let veteranEdit = proposal.proposedText

        model.setProposal(
            id: proposal.id,
            status: .edited,
            editedText: veteranEdit
        )
        model.setProposal(id: proposal.id, status: .approved)

        let preserved = try XCTUnwrap(
            model.currentResponse?.proposals.first { $0.id == proposal.id }
        )
        XCTAssertEqual(preserved.status, .edited)
        XCTAssertEqual(preserved.editedText, veteranEdit)

        model.useSuggestedProposal(id: proposal.id)
        let reverted = try XCTUnwrap(
            model.currentResponse?.proposals.first { $0.id == proposal.id }
        )
        XCTAssertEqual(reverted.status, .approved)
        XCTAssertNil(reverted.editedText)
    }

    func testSharedJobInboxRoundTripsAndAcknowledgesSafePayload() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let payload = try SharedJobPayload(
            sourceURL: "https://jobs.example.gov/posting/42",
            text: "Operations Manager\nRequirements: logistics leadership"
        )

        try SharedJobInbox.enqueue(payload, directoryOverride: directory)
        let pending = try SharedJobInbox.pending(directoryOverride: directory)

        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, payload.id)
        XCTAssertEqual(pending.first?.sourceURL, payload.sourceURL)
        XCTAssertEqual(pending.first?.text, payload.text)
        try SharedJobInbox.acknowledge(payload.id, directoryOverride: directory)
        XCTAssertTrue(try SharedJobInbox.pending(directoryOverride: directory).isEmpty)
    }

    func testSharedJobInboxRejectsEmbeddedCredentials() {
        XCTAssertThrowsError(try SharedJobPayload(
            sourceURL: "https://username:password@example.com/job/42",
            text: nil
        ))
    }

    func testSharedJobInboxRejectsOversizedTextInsteadOfTruncatingIt() {
        XCTAssertThrowsError(try SharedJobPayload(
            sourceURL: nil,
            text: String(repeating: "x", count: SharedJobPayload.maximumTextCharacters + 1)
        ))
    }

    @MainActor
    func testSharedJobDoesNotMixNewLinkWithExistingPostingBeforeApproval() throws {
        let workspaceDirectory = temporaryDirectory()
        let inboxDirectory = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: workspaceDirectory)
            try? FileManager.default.removeItem(at: inboxDirectory)
        }
        let store = ResilientWorkspaceStore(directory: workspaceDirectory)
        var currentDraft = DemoData.draft
        currentDraft.jobText = "Current job posting"
        currentDraft.jobFilename = "CurrentJob.txt"
        currentDraft.jobURL = "https://current.example/job/1"
        try store.save(state(with: currentDraft))
        let shared = try SharedJobPayload(
            sourceURL: "https://new.example/job/2",
            text: "New job posting"
        )
        try SharedJobInbox.enqueue(shared, directoryOverride: inboxDirectory)

        var model: AppModel? = AppModel(
            workspaceStore: store,
            jobTrackerStore: ResilientJobTrackerStore(directory: workspaceDirectory),
            sharedInboxDirectoryOverride: inboxDirectory
        )
        model?.handleIncomingShare()

        XCTAssertEqual(model?.draft.jobText, "Current job posting")
        XCTAssertEqual(model?.draft.jobURL, "https://current.example/job/1")
        XCTAssertTrue(model?.isSharedJobDecisionPresented == true)

        model?.replaceCurrentJobWithSharedItem()

        XCTAssertEqual(model?.draft.jobText, "New job posting")
        XCTAssertEqual(model?.draft.jobURL, "https://new.example/job/2")
        XCTAssertTrue(try SharedJobInbox.pending(directoryOverride: inboxDirectory).isEmpty)
        model = nil
    }

    @MainActor
    func testKeepingCurrentJobDiscardsPendingURLOnlyShareWithoutChangingContext() throws {
        let workspaceDirectory = temporaryDirectory()
        let inboxDirectory = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: workspaceDirectory)
            try? FileManager.default.removeItem(at: inboxDirectory)
        }
        let store = ResilientWorkspaceStore(directory: workspaceDirectory)
        var currentDraft = DemoData.draft
        currentDraft.jobText = "Current job posting"
        currentDraft.jobURL = "https://current.example/job/1"
        try store.save(state(with: currentDraft))
        let shared = try SharedJobPayload(
            sourceURL: "https://new.example/job/2",
            text: nil
        )
        try SharedJobInbox.enqueue(shared, directoryOverride: inboxDirectory)

        var model: AppModel? = AppModel(
            workspaceStore: store,
            jobTrackerStore: ResilientJobTrackerStore(directory: workspaceDirectory),
            sharedInboxDirectoryOverride: inboxDirectory
        )
        model?.handleIncomingShare()

        XCTAssertTrue(model?.isSharedJobDecisionPresented == true)
        model?.keepCurrentJob()

        XCTAssertEqual(model?.draft.jobText, "Current job posting")
        XCTAssertEqual(model?.draft.jobURL, "https://current.example/job/1")
        XCTAssertTrue(try SharedJobInbox.pending(directoryOverride: inboxDirectory).isEmpty)
        model = nil
    }

    private func state(with draft: WorkspaceDraft) -> WorkspacePersistenceState {
        WorkspacePersistenceState(
            hasStarted: true,
            stepRawValue: AppModel.FlowStep.importDocuments.rawValue,
            draft: draft,
            response: nil,
            linkedInKit: nil
        )
    }

    private func localResponse() -> TailorResponse {
        LocalCareerEngine.analyze(TailorRequest(
            resumeText: "EXPERIENCE\nMOS 88M\nLed 12 personnel.",
            jobText: "Operations Manager\nRequirements: logistics leadership",
            profile: CandidateProfile(targetRole: "Operations Manager"),
            mode: .civilian,
            useAI: false,
            aiConsent: false
        ))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ApplyReadyVetsTests-\(UUID().uuidString)")
    }
}
