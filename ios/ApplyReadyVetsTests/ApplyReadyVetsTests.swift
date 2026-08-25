import XCTest
import SwiftUI
import UIKit
import UniformTypeIdentifiers
@testable import ApplyReadyVets

final class ApplyReadyVetsTests: XCTestCase {
    func testPrimaryActionSurfaceMeetsTextContrast() {
        let background = UIColor(Brand.navySurface)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(
            background.getRed(
                &red,
                green: &green,
                blue: &blue,
                alpha: &alpha
            )
        )

        let backgroundLuminance = relativeLuminance(
            red: red,
            green: green,
            blue: blue
        )
        let whiteLuminance: CGFloat = 1
        let ratio = (whiteLuminance + 0.05) /
            (backgroundLuminance + 0.05)

        XCTAssertGreaterThanOrEqual(
            ratio,
            4.5,
            "White primary-action text must retain WCAG AA contrast."
        )
    }

    func testDemoStartsWithEvidenceBearingNumbers() {
        XCTAssertTrue(DemoData.resume.contains("12 personnel"))
        XCTAssertTrue(DemoData.resume.contains("98%"))
    }

    private func relativeLuminance(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat
    ) -> CGFloat {
        func linearized(_ component: CGFloat) -> CGFloat {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearized(red) +
            0.7152 * linearized(green) +
            0.0722 * linearized(blue)
    }

    func testWorkspaceDraftRoundTrips() throws {
        var draft = DemoData.draft
        draft.useAI = false
        let encoded = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(WorkspaceDraft.self, from: encoded)
        XCTAssertEqual(decoded.profile.targetRole, "Fleet Operations Manager")
        XCTAssertFalse(decoded.useAI)
        XCTAssertEqual(decoded.jobURL, "https://www.usajobs.gov/job/000000000")
    }

    func testJobPlatformDetectionUsesExactDomainBoundaries() {
        XCTAssertEqual(JobPlatform.detect(from: "https://jobs.myworkdayjobs.com/acme/job/1"), .workday)
        XCTAssertEqual(JobPlatform.detect(from: "www.indeed.com/viewjob?jk=123"), .indeed)
        XCTAssertEqual(JobPlatform.detect(from: "https://www.linkedin.com/jobs/view/123"), .linkedin)
        XCTAssertEqual(JobPlatform.detect(from: "https://www.usajobs.gov/job/123"), .usajobs)
        XCTAssertEqual(JobPlatform.detect(from: "https://evilindeed.com/job/123"), .employerSite)
    }

    func testTailorResponseDecodesSnakeCaseAcronymFields() throws {
        let json = """
        {
          "analysis_id": "analysis-1",
          "engine": "apple-foundation-models:system",
          "evidence": [{
            "id": "resume:001",
            "source": "resume",
            "section": "experience",
            "text": "Led 12 personnel.",
            "redacted_for_ai": false
          }],
          "job": {
            "company": "Acme",
            "title": "Operations Manager",
            "keywords": [],
            "required_qualifications": [],
            "missing_keywords": [],
            "federal": false,
            "open_to_veterans": true,
            "risk_flags": []
          },
          "proposals": [{
            "id": "proposal-1",
            "section": "experience",
            "original_text": "Led 12 personnel.",
            "proposed_text": "Led a 12-person operations team.",
            "rationale": "Clear civilian wording.",
            "evidence_ids": ["resume:001"],
            "confidence": 0.9,
            "status": "pending",
            "edited_text": null,
            "source": "apple"
          }],
          "gap_questions": [],
          "safety_findings": [{
            "code": "review",
            "severity": "info",
            "title": "Review",
            "detail": "Verify the wording.",
            "evidence_id": "resume:001"
          }],
          "integrity_warnings": [],
          "scores": {
            "qualification_coverage": 80,
            "evidence_strength": 90,
            "acronym_clarity": 70,
            "application_readiness": 82,
            "disclaimer": "Guidance only."
          }
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TailorResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.analysisID, "analysis-1")
        XCTAssertEqual(response.proposals.first?.evidenceIDs, ["resume:001"])
        XCTAssertEqual(response.safetyFindings.first?.evidenceID, "resume:001")
        XCTAssertFalse(response.evidence[0].redactedForAI)
    }

    func testDocumentPickerOnlyOffersLocallySupportedTypes() throws {
        let offeredTypes = DocumentImportService.supportedContentTypes
        let offeredIdentifiers = Set(offeredTypes.map(\.identifier))
        let expectedIdentifiers = Set([
            UTType.pdf.identifier,
            UTType.image.identifier,
            UTType.plainText.identifier,
            UTType.rtf.identifier,
            UTType.html.identifier,
        ])

        XCTAssertEqual(offeredIdentifiers, expectedIdentifiers)
        XCTAssertTrue(offeredTypes.allSatisfy {
            DocumentImportService.supportsLocalImport(contentType: $0)
        })

        let docx = try XCTUnwrap(
            UTType(filenameExtension: "docx"),
            "The system should declare the standard DOCX type."
        )
        XCTAssertFalse(DocumentImportService.supportsLocalImport(contentType: docx))
        XCTAssertFalse(offeredTypes.contains { docx.conforms(to: $0) })
    }

    func testDOCXImportFailsWithClearLocalConversionGuidance() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("docx")
        try Data("not-a-real-word-document".utf8).write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await DocumentImportService.extractLocally(from: url)
            XCTFail("Expected DOCX import to be rejected.")
        } catch DocumentImportService.ImportError.unsupportedWordDocument {
            let message = DocumentImportService.ImportError.unsupportedWordDocument
                .localizedDescription
            XCTAssertTrue(message.contains("DOCX"))
            XCTAssertTrue(message.contains("PDF, RTF, or TXT"))
            XCTAssertTrue(message.localizedCaseInsensitiveContains("export"))
        } catch {
            XCTFail("Expected unsupportedWordDocument, got \(error)")
        }
    }

    func testRichDocumentSourceIsLimitedToFourMiB() async throws {
        let url = temporaryImportURL(extension: "rtf")
        try Data(count: DocumentImportService.maximumRichTextFileSize + 1)
            .write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await DocumentImportService.extractLocally(from: url)
            XCTFail("Expected the oversized rich document to be rejected.")
        } catch DocumentImportService.ImportError.fileTooLarge(let maximumMegabytes) {
            XCTAssertEqual(maximumMegabytes, 4)
        } catch {
            XCTFail("Expected fileTooLarge, got \(error)")
        }
    }

    func testExpandedImportTextUsesResumeSafetyCeiling() throws {
        let oversizedCharacters = String(
            repeating: "x",
            count: DocumentImportService.maximumExtractedCharacters + 1
        )

        XCTAssertThrowsError(
            try DocumentImportService.validatedExtractedText(oversizedCharacters)
        ) { error in
            guard case DocumentImportService.ImportError.extractedTextTooLarge =
                    error else {
                return XCTFail("Expected extractedTextTooLarge, got \(error)")
            }
            XCTAssertTrue(error.localizedDescription.contains("split"))
            XCTAssertTrue(error.localizedDescription.contains("250,000"))
        }

        let oversizedEncoding = String(repeating: "👨‍👩‍👧‍👦", count: 100_000)
        XCTAssertLessThanOrEqual(
            oversizedEncoding.count,
            DocumentImportService.maximumExtractedCharacters
        )
        XCTAssertGreaterThan(
            oversizedEncoding.utf8.count,
            DocumentImportService.maximumExtractedUTF8Bytes
        )
        XCTAssertThrowsError(
            try DocumentImportService.validatedExtractedText(oversizedEncoding)
        )
    }

    func testHTMLExpansionIsRejectedBeforeImportReturns() async throws {
        let url = temporaryImportURL(extension: "html")
        let html = "<html><body><p>" +
            String(
                repeating: "x",
                count: DocumentImportService.maximumExtractedCharacters + 1
            ) +
            "</p></body></html>"
        try Data(html.utf8).write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await DocumentImportService.extractLocally(from: url)
            XCTFail("Expected expanded HTML text to be rejected.")
        } catch DocumentImportService.ImportError.extractedTextTooLarge {
            // Expected: parsed rich text must pass the shared output ceiling.
        } catch {
            XCTFail("Expected extractedTextTooLarge, got \(error)")
        }
    }

    func testHTMLImportIsTextOnlyAndDropsResourceBearingMarkup() async throws {
        let url = temporaryImportURL(extension: "html")
        let html = """
        <html>
          <head>
            <link rel="stylesheet" href="https://invalid.example/private.css">
            <style>.private { background: url(https://invalid.example/pixel); }</style>
            <script>remoteSecret()</script>
          </head>
          <body>
            <img src="https://invalid.example/tracker.png" alt="hidden tracker">
            <p>Visible &amp; verified</p>
            <iframe src="https://invalid.example/frame">hidden frame</iframe>
          </body>
        </html>
        """
        try Data(html.utf8).write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        let optionalExtraction = try await DocumentImportService.extractLocally(from: url)
        let extraction = try XCTUnwrap(optionalExtraction)

        XCTAssertTrue(extraction.text.contains("Visible & verified"))
        XCTAssertFalse(extraction.text.contains("remoteSecret"))
        XCTAssertFalse(extraction.text.contains("hidden tracker"))
        XCTAssertFalse(extraction.text.contains("hidden frame"))
        XCTAssertFalse(extraction.text.contains("invalid.example"))
    }

    func testRTFExpansionIsRejectedBeforeImportReturns() async throws {
        let url = temporaryImportURL(extension: "rtf")
        let rtf = "{\\rtf1\\ansi " +
            String(
                repeating: "x",
                count: DocumentImportService.maximumExtractedCharacters + 1
            ) +
            "}"
        try Data(rtf.utf8).write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await DocumentImportService.extractLocally(from: url)
            XCTFail("Expected expanded RTF text to be rejected.")
        } catch DocumentImportService.ImportError.extractedTextTooLarge {
            // Expected: parsed rich text must pass the shared output ceiling.
        } catch {
            XCTFail("Expected extractedTextTooLarge, got \(error)")
        }
    }

    private func temporaryImportURL(extension pathExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ApplyReadyVetsImport-\(UUID().uuidString)")
            .appendingPathExtension(pathExtension)
    }
}
