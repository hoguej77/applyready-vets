import Foundation
import PDFKit
import UIKit
import UniformTypeIdentifiers
import Vision

enum DocumentImportService {
    enum ImportError: LocalizedError {
        case fileTooLarge(Int)
        case extractedTextTooLarge(maximumCharacters: Int, maximumMegabytes: Int)
        case unreadable
        case serviceConsentRequired
        case unsupportedWordDocument

        var errorDescription: String? {
            switch self {
            case let .fileTooLarge(limit):
                "This file is too large. Choose a file smaller than \(limit) MB."
            case let .extractedTextTooLarge(maximumCharacters, maximumMegabytes):
                "This document expands to too much text to import safely. Shorten it or split it into smaller files, keeping each under \(maximumCharacters.formatted()) characters and \(maximumMegabytes) MB of extracted text."
            case .unreadable:
                "No readable text was found. Try a clearer image, a selectable-text PDF, or a plain text file."
            case .serviceConsentRequired:
                "Private import supports text files, RTF, HTML, images, and selectable or scanned PDFs. Converting this file type requires the optional service and consent."
            case .unsupportedWordDocument:
                "Word DOCX files cannot be imported on this device. In Word, Pages, or Google Docs, export a PDF, RTF, or TXT copy, then import that copy."
            }
        }
    }

    static let maximumFileSize = 20 * 1_024 * 1_024
    static let maximumRichTextFileSize = 4 * 1_024 * 1_024
    static let maximumExtractedCharacters = CareerInputPolicy.Kind.resume.maximumCharacters
    static let maximumExtractedUTF8Bytes = CareerInputPolicy.Kind.resume.maximumUTF8Bytes
    static let supportedContentTypes: [UTType] = [
        .pdf,
        .image,
        .plainText,
        .rtf,
        .html,
    ]

    static func supportsLocalImport(contentType: UTType) -> Bool {
        supportedContentTypes.contains { contentType.conforms(to: $0) }
    }

    static func readSecurityScopedData(from url: URL) throws -> Data {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        return try checkedData(from: url)
    }

    static func extractLocally(from url: URL) async throws -> DocumentExtraction? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let pathExtension = url.pathExtension.lowercased()
        if pathExtension == "docx" {
            throw ImportError.unsupportedWordDocument
        }
        let type = UTType(filenameExtension: pathExtension)
        guard type.map(supportsLocalImport(contentType:)) == true ||
                ["txt", "md", "markdown", "csv", "tsv"].contains(pathExtension) else {
            return nil
        }
        let maximumSourceSize = isRichText(type)
            ? maximumRichTextFileSize
            : maximumFileSize
        let data = try checkedData(from: url, maximumSize: maximumSourceSize)
        let text: String?
        var warnings = ["Imported privately on this device."]

        if type?.conforms(to: .pdf) == true {
            let result = try await Task.detached(priority: .userInitiated) {
                try extractPDFText(data)
            }.value
            text = result.text
            warnings.append(contentsOf: result.warnings)
        } else if type?.conforms(to: .image) == true {
            let result = try await Task.detached(priority: .userInitiated) {
                try extractImageText(data)
            }.value
            text = result.text
            warnings.append(contentsOf: result.warnings)
        } else if type?.conforms(to: .rtf) == true {
            text = attributedText(data: data, documentType: .rtf)
        } else if type?.conforms(to: .html) == true {
            text = try plainTextFromHTML(data)
        } else if type?.conforms(to: .plainText) == true ||
                    type?.conforms(to: .commaSeparatedText) == true ||
                    ["txt", "md", "markdown", "csv", "tsv"].contains(pathExtension) {
            text = decodedString(data)
        } else {
            return nil
        }

        let cleaned = try validatedExtractedText(text)
        return DocumentExtraction(
            filename: url.lastPathComponent,
            text: cleaned,
            warnings: warnings
        )
    }

    static func validatedExtractedText(_ text: String?) throws -> String {
        guard let text else { throw ImportError.unreadable }
        guard text.count <= maximumExtractedCharacters,
              text.utf8.count <= maximumExtractedUTF8Bytes else {
            throw ImportError.extractedTextTooLarge(
                maximumCharacters: maximumExtractedCharacters,
                maximumMegabytes: maximumExtractedUTF8Bytes / 1_024 / 1_024
            )
        }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ImportError.unreadable }
        return cleaned
    }

    private static func checkedData(
        from url: URL,
        maximumSize: Int = maximumFileSize
    ) throws -> Data {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values?.fileSize, size > maximumSize {
            throw ImportError.fileTooLarge(maximumSize / 1_024 / 1_024)
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard data.count <= maximumSize else {
            throw ImportError.fileTooLarge(maximumSize / 1_024 / 1_024)
        }
        return data
    }

    private static func isRichText(_ type: UTType?) -> Bool {
        type?.conforms(to: .rtf) == true || type?.conforms(to: .html) == true
    }

    private static func decodedString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16)
            ?? String(data: data, encoding: .isoLatin1)
    }

    private static func attributedText(
        data: Data,
        documentType: NSAttributedString.DocumentType
    ) -> String? {
        try? NSAttributedString(
            data: data,
            options: [.documentType: documentType],
            documentAttributes: nil
        ).string
    }

    /// Extracts visible HTML text without instantiating a web-capable document
    /// reader. Resource-bearing markup is never resolved or fetched.
    private static func plainTextFromHTML(_ data: Data) throws -> String? {
        guard let source = decodedString(data) else { return nil }
        var output = ExtractedTextAccumulator(separator: "")
        var suppressedElements: [String] = []
        var cursor = source.startIndex

        while cursor < source.endIndex {
            guard let opening = source[cursor...].firstIndex(of: "<") else {
                if suppressedElements.isEmpty {
                    try output.append(String(source[cursor...]))
                }
                break
            }
            if suppressedElements.isEmpty, cursor < opening {
                try output.append(String(source[cursor..<opening]))
            }

            if source[opening...].hasPrefix("<!--") {
                guard let commentEnd = source[opening...].range(of: "-->") else {
                    break
                }
                cursor = commentEnd.upperBound
                continue
            }

            guard let closing = closingBracket(in: source, after: opening) else {
                if suppressedElements.isEmpty {
                    try output.append(String(source[opening...]))
                }
                break
            }
            let markupStart = source.index(after: opening)
            let markup = source[markupStart..<closing]
            let descriptor = htmlTagDescriptor(markup)

            if let descriptor {
                if descriptor.isClosing {
                    if suppressedElements.last == descriptor.name {
                        suppressedElements.removeLast()
                    }
                    if suppressedElements.isEmpty,
                       htmlLineBreakElements.contains(descriptor.name) {
                        try output.append("\n")
                    }
                } else if htmlSuppressedElements.contains(descriptor.name) {
                    if !descriptor.isSelfClosing {
                        suppressedElements.append(descriptor.name)
                    }
                } else if suppressedElements.isEmpty,
                          htmlLineBreakElements.contains(descriptor.name) {
                    try output.append("\n")
                }
            }
            cursor = source.index(after: closing)
        }

        return decodeHTMLEntities(output.text)
    }

    private static func closingBracket(
        in source: String,
        after opening: String.Index
    ) -> String.Index? {
        var cursor = source.index(after: opening)
        var quote: Character?
        while cursor < source.endIndex {
            let character = source[cursor]
            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == ">" {
                return cursor
            }
            cursor = source.index(after: cursor)
        }
        return nil
    }

    private static func htmlTagDescriptor(
        _ markup: Substring
    ) -> (name: String, isClosing: Bool, isSelfClosing: Bool)? {
        var content = markup.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty,
              !content.hasPrefix("!"),
              !content.hasPrefix("?") else {
            return nil
        }
        let isClosing = content.hasPrefix("/")
        if isClosing {
            content.removeFirst()
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let name = content.prefix {
            $0.isLetter || $0.isNumber || $0 == ":" || $0 == "-"
        }.lowercased()
        guard !name.isEmpty else { return nil }
        return (
            name,
            isClosing,
            !isClosing && content.hasSuffix("/")
        )
    }

    private static func decodeHTMLEntities(_ source: String) -> String {
        var decoded = ""
        decoded.reserveCapacity(source.count)
        var cursor = source.startIndex

        while cursor < source.endIndex {
            guard source[cursor] == "&",
                  let semicolon = source[cursor...].prefix(16).firstIndex(of: ";") else {
                decoded.append(source[cursor])
                cursor = source.index(after: cursor)
                continue
            }
            let entityStart = source.index(after: cursor)
            let entity = String(source[entityStart..<semicolon])
            if let replacement = decodedHTMLEntity(entity) {
                decoded.append(replacement)
                cursor = source.index(after: semicolon)
            } else {
                decoded.append(source[cursor])
                cursor = source.index(after: cursor)
            }
        }
        return decoded
    }

    private static func decodedHTMLEntity(_ entity: String) -> Character? {
        let named: [String: Character] = [
            "amp": "&",
            "apos": "'",
            "bull": "•",
            "gt": ">",
            "hellip": "…",
            "lt": "<",
            "mdash": "—",
            "nbsp": " ",
            "ndash": "–",
            "quot": "\"",
        ]
        if let character = named[entity.lowercased()] {
            return character
        }

        let scalarValue: UInt32?
        if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
            scalarValue = UInt32(entity.dropFirst(2), radix: 16)
        } else if entity.hasPrefix("#") {
            scalarValue = UInt32(entity.dropFirst())
        } else {
            scalarValue = nil
        }
        guard let scalarValue,
              let scalar = UnicodeScalar(scalarValue) else {
            return nil
        }
        return Character(String(scalar))
    }

    private static let htmlSuppressedElements: Set<String> = [
        "embed",
        "head",
        "iframe",
        "math",
        "noscript",
        "object",
        "script",
        "style",
        "svg",
        "template",
    ]

    private static let htmlLineBreakElements: Set<String> = [
        "article",
        "blockquote",
        "br",
        "dd",
        "div",
        "dl",
        "dt",
        "footer",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "hr",
        "li",
        "main",
        "ol",
        "p",
        "pre",
        "section",
        "table",
        "td",
        "th",
        "tr",
        "ul",
    ]

    private static func extractPDFText(_ data: Data) throws -> (text: String, warnings: [String]) {
        guard let document = PDFDocument(data: data) else { throw ImportError.unreadable }
        let pageLimit = min(document.pageCount, 12)
        var pages = ExtractedTextAccumulator(separator: "\n\n")
        var ocrPages = 0
        var confidenceTotal: Float = 0

        for index in 0..<pageLimit {
            guard let page = document.page(at: index) else { continue }
            let selectable = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !selectable.isEmpty {
                try pages.append(selectable)
                continue
            }
            let image = page.thumbnail(
                of: CGSize(width: 1_800, height: 2_400),
                for: .mediaBox
            )
            guard let cgImage = image.cgImage else { continue }
            let recognized = try recognizedText(in: cgImage)
            if !recognized.text.isEmpty {
                try pages.append(recognized.text)
                ocrPages += 1
                confidenceTotal += recognized.confidence
            }
        }

        var warnings: [String] = []
        if ocrPages > 0 {
            warnings.append("Used private on-device text recognition on \(ocrPages) scanned page(s). Verify names, dates, codes, and numbers.")
            let average = confidenceTotal / Float(ocrPages)
            if average < 0.75 {
                warnings.append("Some recognized text had lower confidence and needs careful review.")
            }
        }
        if document.pageCount > pageLimit {
            warnings.append("Only the first \(pageLimit) pages were imported to protect performance and battery life.")
        }
        return (pages.text, warnings)
    }

    private static func extractImageText(_ data: Data) throws -> (text: String, warnings: [String]) {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            throw ImportError.unreadable
        }
        let recognized = try recognizedText(in: cgImage)
        guard !recognized.text.isEmpty else { throw ImportError.unreadable }
        var warnings = ["Used private on-device text recognition. Verify names, dates, codes, and numbers."]
        if recognized.confidence < 0.75 {
            warnings.append("Some recognized text had lower confidence and needs careful review.")
        }
        return (recognized.text, warnings)
    }

    private static func recognizedText(in image: CGImage) throws -> (text: String, confidence: Float) {
        var lines = ExtractedTextAccumulator(separator: "\n")
        var confidences: [Float] = []
        var extractionError: Error?
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            for observation in observations {
                guard extractionError == nil else { break }
                guard let candidate = observation.topCandidates(1).first else { continue }
                do {
                    try lines.append(candidate.string)
                    confidences.append(candidate.confidence)
                } catch {
                    extractionError = error
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        if let extractionError {
            throw extractionError
        }
        let confidence = confidences.isEmpty
            ? 0
            : confidences.reduce(0, +) / Float(confidences.count)
        return (lines.text, confidence)
    }

    private struct ExtractedTextAccumulator {
        let separator: String
        private(set) var segments: [String] = []
        private var characterCount = 0
        private var utf8ByteCount = 0

        var text: String {
            segments.joined(separator: separator)
        }

        mutating func append(_ segment: String) throws {
            let addedSeparator = segments.isEmpty ? "" : separator
            let addedCharacters = addedSeparator.count + segment.count
            let addedUTF8Bytes = addedSeparator.utf8.count + segment.utf8.count
            guard addedCharacters <= maximumExtractedCharacters - characterCount,
                  addedUTF8Bytes <= maximumExtractedUTF8Bytes - utf8ByteCount else {
                throw ImportError.extractedTextTooLarge(
                    maximumCharacters: maximumExtractedCharacters,
                    maximumMegabytes: maximumExtractedUTF8Bytes / 1_024 / 1_024
                )
            }
            segments.append(segment)
            characterCount += addedCharacters
            utf8ByteCount += addedUTF8Bytes
        }
    }
}
