import Foundation
import CoreGraphics
import CoreText

enum LocalExportService {
    struct CandidateExportBundle: Equatable {
        let pdfURL: URL
        let richTextURL: URL
        let plainTextURL: URL

        var allURLs: [URL] {
            [pdfURL, richTextURL, plainTextURL]
        }
    }

    enum ExportError: LocalizedError {
        case sourceMissing(String)
        case emptyResume
        case ambiguousSource(String)
        case conflictingEdits(String)
        case truthLockRejected(String, String)
        case criticalSensitiveContent
        case federalPageLimitExceeded(Int)
        case invalidPDF

        var errorDescription: String? {
            switch self {
            case .emptyResume:
                "Export stopped because this workspace has no resume text. Import or paste a resume and run Analysis first."
            case let .sourceMissing(section):
                "Truth Lock stopped export because the source text for \(section) is no longer in the resume. Run analysis again."
            case let .ambiguousSource(section):
                "Export stopped because the same \(section) source text appears more than once. Make the lines distinct, then run Analysis again so the correct job entry cannot be changed by mistake."
            case let .conflictingEdits(section):
                "Export stopped because more than one accepted edit targets the same or overlapping \(section) text. Keep one version, then try again."
            case let .truthLockRejected(section, reason):
                "Truth Lock stopped the \(section) edit: \(reason)"
            case .criticalSensitiveContent:
                "Export stopped because the resume contains a critical sensitive-data warning. Remove the flagged SSN, birth date, banking, classified, or operational detail and run Analysis again."
            case let .federalPageLimitExceeded(pageCount):
                "The federal PDF is \(pageCount) pages. Current USAJOBS guidance generally limits federal résumés to two pages, so shorten and verify it before export."
            case .invalidPDF:
                "Export stopped because the PDF could not be verified. Your existing files were not replaced."
            }
        }
    }

    static func validatedResumeText(from request: ExportRequest) throws -> String {
        guard !request.resumeText
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExportError.emptyResume
        }
        guard !SensitiveContentPolicy.hasCriticalFinding(in: request.resumeText) else {
            throw ExportError.criticalSensitiveContent
        }
        let canonicalEvidence = LocalCareerEngine.canonicalEvidence(
            resumeText: request.resumeText,
            profile: request.profile
        )
        let approved = request.response.proposals.filter {
            [.approved, .edited].contains($0.status)
        }
        let duplicateTargets = Dictionary(grouping: approved, by: \.originalText)
            .first { $0.value.count > 1 }
        if let duplicateTargets {
            throw ExportError.conflictingEdits(duplicateTargets.value[0].section)
        }

        var replacements: [(proposal: ProposedEdit, range: NSRange)] = []
        for proposal in approved {
            let ranges = ranges(
                of: proposal.originalText,
                in: request.resumeText
            )
            guard !ranges.isEmpty else {
                throw ExportError.sourceMissing(proposal.section)
            }
            guard ranges.count == 1, let range = ranges.first else {
                throw ExportError.ambiguousSource(proposal.section)
            }
            let validation = TruthLock.validate(
                proposal,
                evidence: canonicalEvidence,
                targetTitle: request.response.job.title
            )
            guard validation.accepted else {
                throw ExportError.truthLockRejected(proposal.section, validation.reason)
            }
            replacements.append((proposal, range))
        }

        for leftIndex in replacements.indices {
            for rightIndex in replacements.indices where rightIndex > leftIndex {
                if NSIntersectionRange(
                    replacements[leftIndex].range,
                    replacements[rightIndex].range
                ).length > 0 {
                    throw ExportError.conflictingEdits(
                        replacements[rightIndex].proposal.section
                    )
                }
            }
        }

        let finalResume = NSMutableString(string: request.resumeText)
        for replacement in replacements.sorted(by: { $0.range.location > $1.range.location }) {
            finalResume.replaceCharacters(
                in: replacement.range,
                with: replacement.proposal.effectiveText
            )
        }
        let finalResumeText = finalResume as String
        guard !SensitiveContentPolicy.hasCriticalFinding(in: finalResumeText) else {
            throw ExportError.criticalSensitiveContent
        }
        return finalResumeText
    }

    /// Creates the employer-facing file. It intentionally contains only the
    /// candidate-reviewed resume so ATS parsing and employer review are not
    /// polluted by private scores, gap questions, or safety warnings.
    static func createCandidateReviewedResume(
        from request: ExportRequest,
        applicationID: UUID? = nil,
        packetVersion: Int? = nil,
        directoryOverride: URL? = nil
    ) throws -> URL {
        let finalResume = try validatedResumeText(from: request)
        let destinationDirectory = try UserDocumentWorkspace.outputDirectory(
            override: directoryOverride
        )
        let destination = destinationDirectory.appendingPathComponent(
            "\(candidateFilenameStem(for: request, applicationID: applicationID, packetVersion: packetVersion)).txt"
        )
        try Data(
            employerFacingDocument(finalResume: finalResume, request: request).utf8
        ).write(
            to: destination,
            options: [.atomic, .completeFileProtection]
        )
        return destination
    }

    /// Creates three employer-facing representations of the same
    /// candidate-reviewed content. The PDF is presentation-ready, RTF remains
    /// editable in Pages or Word, and TXT is the safest option for copy/paste
    /// into rigid application fields. Private scores and review notes are never
    /// included in any file in this bundle.
    static func createCandidateReviewedBundle(
        from request: ExportRequest,
        applicationID: UUID? = nil,
        packetVersion: Int? = nil,
        directoryOverride: URL? = nil
    ) throws -> CandidateExportBundle {
        let finalResume = try validatedResumeText(from: request)
        let document = employerFacingDocument(
            finalResume: finalResume,
            request: request
        )
        let destination = try UserDocumentWorkspace.outputDirectory(
            override: directoryOverride
        )
        let stem = candidateFilenameStem(
            for: request,
            applicationID: applicationID,
            packetVersion: packetVersion
        )
        let plainTextURL = destination.appendingPathComponent("\(stem).txt")
        let richTextURL = destination.appendingPathComponent("\(stem).rtf")
        let pdfURL = destination.appendingPathComponent("\(stem).pdf")
        let outputURLs = [plainTextURL, richTextURL, pdfURL]
        let existingOutputPaths = Set(
            outputURLs
                .filter { FileManager.default.fileExists(atPath: $0.path) }
                .map(\.path)
        )

        do {
            _ = try writePDF(
                document,
                to: pdfURL,
                maximumPageCount: isFederalRequest(request) ? 2 : nil
            )
            try Data(document.utf8).write(
                to: plainTextURL,
                options: [.atomic, .completeFileProtection]
            )
            try Data(rtfDocument(for: document).utf8).write(
                to: richTextURL,
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            for url in outputURLs where !existingOutputPaths.contains(url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            throw error
        }

        return CandidateExportBundle(
            pdfURL: pdfURL,
            richTextURL: richTextURL,
            plainTextURL: plainTextURL
        )
    }

    /// Creates a separate candidate-only review record. The UI labels this as
    /// private and never uses it as the default employer handoff.
    static func createPrivateReviewReport(
        from request: ExportRequest,
        applicationID: UUID? = nil,
        packetVersion: Int? = nil,
        directoryOverride: URL? = nil
    ) throws -> URL {
        _ = try validatedResumeText(from: request)
        let safeName = sanitizedFilename(
            request.candidateName.isEmpty ? "Veteran" : request.candidateName
        )
        let versionSuffix = packetVersion.map { "_v\(max($0, 1))" } ?? ""
        let applicationSuffix = applicationID.map {
            "_A\(String($0.uuidString.prefix(8)))"
        } ?? ""
        let destination = try UserDocumentWorkspace.outputDirectory(
            override: directoryOverride
        )
            .appendingPathComponent(
                "ApplyReadyVets_\(safeName)_Private_Review\(applicationSuffix)\(versionSuffix).txt"
            )
        let approved = request.response.proposals.filter {
            [.approved, .edited].contains($0.status)
        }

        let trace = approved.isEmpty
            ? "No proposed edits were approved."
            : approved.map { proposal in
                """
                • Section: \(proposal.section)
                  Source: \(proposal.originalText)
                  Final: \(proposal.effectiveText)
                  Evidence: \(proposal.evidenceIDs.joined(separator: ", "))
                """
            }.joined(separator: "\n")
        let gaps = request.response.gapQuestions.isEmpty
            ? "No unanswered high-priority keyword questions were generated."
            : request.response.gapQuestions.map {
                "• [\($0.priority.uppercased())] \($0.question)"
            }.joined(separator: "\n")
        let safety = request.response.safetyFindings.isEmpty
            ? "No configured sensitive-pattern warnings were found."
            : request.response.safetyFindings.map {
                "• \($0.title): \($0.detail)"
            }.joined(separator: "\n")
        let federalReview = isFederalRequest(request)
            ? FederalResumeReview.checks(
                resumeText: request.resumeText,
                profile: request.profile,
                details: request.federalDetails
            ).map {
                "• [\($0.state.rawValue.uppercased())] \($0.title): \($0.detail)"
            }.joined(separator: "\n")
            : "Not applicable; this workspace was not exported in Federal mode."

        let document = """
        APPLYREADY VETS — PRIVATE CANDIDATE REVIEW
        Keep this file private. Do not upload it as a resume or send it to an employer.

        DOCUMENT CHECKS
        Job-keyword overlap: \(request.response.scores.qualificationCoverage)/100
        Evidence strength: \(request.response.scores.evidenceStrength)/100
        Acronym clarity: \(request.response.scores.acronymClarity)/100
        \(request.response.scores.disclaimer)

        QUESTIONS TO VERIFY
        \(gaps)

        TRUTH LOCK REVIEW RECORD
        \(trace)

        SAFETY REVIEW
        \(safety)

        FEDERAL RESUME REVIEW
        \(federalReview)
        Source reviewed \(FederalResumeReview.sourceReviewedDate):
        \(FederalResumeReview.sourceURL)

        IMPORTANT
        This private report is writing and application-readiness guidance, not a hiring,
        eligibility, legal, benefits, or employment guarantee. ApplyReady Vets is
        an independent product and is not affiliated with or endorsed by the U.S.
        Department of Veterans Affairs, Department of Defense, OPM, USAJOBS, or
        any employer or job platform.
        """
        try Data(document.utf8).write(
            to: destination,
            options: [.atomic, .completeFileProtection]
        )
        return destination
    }

    private static func federalResumeDocument(
        finalResume: String,
        request: ExportRequest
    ) -> String {
        let profile = request.profile
        let details = request.federalDetails ?? FederalApplicationDetails()
        let trimmedResume = finalResume.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let contact = [
            profile.fullName,
            profile.email,
            profile.phone,
            profile.location,
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter {
                !$0.isEmpty &&
                    !resume(trimmedResume, alreadyContainsContactValue: $0)
            }
            .joined(separator: " | ")
        let announcement = details.announcementNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let seriesAndGrade = details.targetSeriesAndGrade
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let target = [
            announcement.isEmpty ||
                resume(trimmedResume, alreadyContainsContactValue: announcement)
                ? nil
                : "Announcement: \(announcement)",
            seriesAndGrade.isEmpty ||
                resume(trimmedResume, alreadyContainsContactValue: seriesAndGrade)
                ? nil
                : "Target series/grade: \(seriesAndGrade)",
        ]
            .compactMap(\.self)
            .joined(separator: "\n")

        return ([contact, target, trimmedResume]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")) + "\n"
    }

    private static func employerFacingDocument(
        finalResume: String,
        request: ExportRequest
    ) -> String {
        isFederalRequest(request)
            ? federalResumeDocument(finalResume: finalResume, request: request)
            : finalResume.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    private static func candidateFilenameStem(
        for request: ExportRequest,
        applicationID: UUID?,
        packetVersion: Int?
    ) -> String {
        let safeName = sanitizedFilename(
            request.candidateName.isEmpty ? "Veteran" : request.candidateName
        )
        let base = isFederalRequest(request)
            ? "ApplyReadyVets_\(safeName)_Federal_Resume"
            : "ApplyReadyVets_\(safeName)_Resume"
        let applicationSuffix = applicationID.map {
            "_A\(String($0.uuidString.prefix(8)))"
        } ?? ""
        let versionSuffix = packetVersion.map { "_v\(max($0, 1))" } ?? ""
        return "\(base)\(applicationSuffix)\(versionSuffix)"
    }

    private static func isFederalRequest(_ request: ExportRequest) -> Bool {
        request.mode == .federal ||
            (request.mode == .auto && request.response.job.federal)
    }

    private static func resume(
        _ resumeText: String,
        alreadyContainsContactValue value: String
    ) -> Bool {
        let foldedResume = resumeText.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        let foldedValue = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        if foldedResume.localizedCaseInsensitiveContains(foldedValue) {
            return true
        }

        let valueDigits = value.filter(\.isNumber)
        guard valueDigits.count >= 7 else { return false }
        return resumeText.filter(\.isNumber).contains(valueDigits)
    }

    private static func rtfDocument(for text: String) -> String {
        var body = ""
        body.reserveCapacity(text.count + 128)
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 10:
                body += "\\par\n"
            case 9:
                body += "\\tab "
            case 92:
                body += "\\\\"
            case 123:
                body += "\\{"
            case 125:
                body += "\\}"
            case 32...126:
                body.append(Character(scalar))
            default:
                for codeUnit in String(scalar).utf16 {
                    body += "\\u\(Int(Int16(bitPattern: codeUnit)))?"
                }
            }
        }
        return """
        {\\rtf1\\ansi\\deff0
        {\\fonttbl{\\f0 Arial;}}
        \\viewkind4\\uc1\\pard\\f0\\fs22\\sl276\\slmult1
        \(body)
        }
        """
    }

    private static func writePDF(
        _ text: String,
        to destination: URL,
        maximumPageCount: Int?
    ) throws -> Int {
        let fileManager = FileManager.default
        let temporaryURL = destination
            .deletingLastPathComponent()
            .appendingPathComponent(
                ".\(destination.lastPathComponent).\(UUID().uuidString).tmp",
                isDirectory: false
            )
        guard fileManager.createFile(
            atPath: temporaryURL.path,
            contents: nil,
            attributes: [.protectionKey: FileProtectionType.complete]
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer {
            if fileManager.fileExists(atPath: temporaryURL.path) {
                try? fileManager.removeItem(at: temporaryURL)
            }
        }

        let pageCount = try renderPDF(text, to: temporaryURL)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: temporaryURL.path
        )
        try validatePDF(at: temporaryURL, expectedPageCount: pageCount)
        if let maximumPageCount, pageCount > maximumPageCount {
            throw ExportError.federalPageLimitExceeded(pageCount)
        }

        if fileManager.fileExists(atPath: destination.path) {
            _ = try fileManager.replaceItemAt(
                destination,
                withItemAt: temporaryURL,
                backupItemName: nil,
                options: [.usingNewMetadataOnly]
            )
        } else {
            try fileManager.moveItem(at: temporaryURL, to: destination)
        }
        return pageCount
    }

    private static func renderPDF(
        _ text: String,
        to destination: URL
    ) throws -> Int {
        guard let consumer = CGDataConsumer(url: destination as CFURL) else {
            throw CocoaError(.fileWriteUnknown)
        }
        var pageBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(
            consumer: consumer,
            mediaBox: &pageBox,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }

        var lineSpacing = CGFloat(2)
        let paragraphStyle = withUnsafePointer(to: &lineSpacing) { pointer in
            let settings = [
                CTParagraphStyleSetting(
                    spec: .lineSpacingAdjustment,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: UnsafeRawPointer(pointer)
                ),
            ]
            return CTParagraphStyleCreate(settings, settings.count)
        }
        let font = CTFontCreateWithName("Arial" as CFString, 10.5, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraphStyle,
        ]
        let attributedText = NSAttributedString(
            string: text,
            attributes: attributes
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let contentRect = pageBox.insetBy(dx: 54, dy: 54)
        var location = 0
        var pageCount = 0

        while location < attributedText.length {
            context.beginPDFPage(nil)
            pageCount += 1
            let path = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: location, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else {
                context.endPDFPage()
                context.closePDF()
                throw CocoaError(.fileWriteUnknown)
            }
            location += visible.length
            context.endPDFPage()
        }

        if attributedText.length == 0 {
            context.beginPDFPage(nil)
            pageCount += 1
            context.endPDFPage()
        }
        context.closePDF()
        return pageCount
    }

    private static func validatePDF(
        at url: URL,
        expectedPageCount: Int
    ) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let signature = try handle.read(upToCount: 5) ?? Data()
        guard signature == Data("%PDF-".utf8),
              let document = CGPDFDocument(url as CFURL),
              document.numberOfPages == expectedPageCount,
              expectedPageCount > 0,
              (1...expectedPageCount).allSatisfy({
                  document.page(at: $0) != nil
              }) else {
            throw ExportError.invalidPDF
        }
    }

    private static func sanitizedFilename(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let replaced = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(String(scalar)) : "_"
        }
        let collapsed = String(replaced)
            .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return collapsed.isEmpty ? "Veteran" : String(collapsed.prefix(60))
    }

    private static func ranges(of needle: String, in haystack: String) -> [NSRange] {
        guard !needle.isEmpty else { return [] }
        let source = haystack as NSString
        var results: [NSRange] = []
        var searchRange = NSRange(location: 0, length: source.length)
        while searchRange.length > 0 {
            let found = source.range(of: needle, options: [], range: searchRange)
            guard found.location != NSNotFound else { break }
            results.append(found)
            let nextLocation = NSMaxRange(found)
            searchRange = NSRange(
                location: nextLocation,
                length: source.length - nextLocation
            )
        }
        return results
    }
}
