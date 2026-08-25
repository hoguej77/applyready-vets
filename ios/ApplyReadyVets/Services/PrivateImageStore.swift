import Foundation
import UIKit

/// Keeps sensitive screenshots, photos, and generated headshots out of the
/// tracker JSON and in files protected whenever the device is locked.
enum PrivateImageStore {
    enum StoreError: LocalizedError {
        case imageUnreadable
        case imageTooLarge
        case invalidFilename

        var errorDescription: String? {
            switch self {
            case .imageUnreadable:
                "That image could not be read. Try a PNG, JPEG, or a different screenshot."
            case .imageTooLarge:
                "That image is too large to store safely. Choose an image smaller than 12 MB."
            case .invalidFilename:
                "The saved image reference is invalid."
            }
        }
    }

    static let maximumStatusEvidencePerApplication = 6
    private static let maximumInputBytes = 12 * 1_024 * 1_024
    private static let maximumPixelDimension: CGFloat = 4_096

    static func saveStatusEvidence(
        _ data: Data,
        applicationID: UUID
    ) throws -> JobStatusEvidence {
        let evidence = JobStatusEvidence(filename: "\(UUID().uuidString).jpg")
        let normalized = try normalizedJPEGData(from: data)
        try write(
            normalized,
            filename: evidence.filename,
            in: try statusEvidenceDirectory(for: applicationID)
        )
        return evidence
    }

    static func statusEvidenceURL(
        for evidence: JobStatusEvidence,
        applicationID: UUID
    ) -> URL? {
        guard isSafeImageFilename(evidence.filename),
              let directory = try? statusEvidenceDirectory(for: applicationID) else {
            return nil
        }
        let url = directory.appendingPathComponent(evidence.filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func statusEvidenceImage(
        for evidence: JobStatusEvidence,
        applicationID: UUID
    ) -> UIImage? {
        guard let url = statusEvidenceURL(for: evidence, applicationID: applicationID) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    static func removeStatusEvidence(
        _ evidence: JobStatusEvidence,
        applicationID: UUID
    ) throws {
        guard isSafeImageFilename(evidence.filename) else {
            throw StoreError.invalidFilename
        }
        let url = try statusEvidenceDirectory(for: applicationID)
            .appendingPathComponent(evidence.filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    static func removeAllStatusEvidence(for applicationID: UUID) throws {
        let directory = try statusEvidenceDirectory(for: applicationID)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    static func saveHeadshotSource(_ data: Data) throws -> UIImage {
        let normalized = try normalizedJPEGData(from: data)
        let directory = try headshotDirectory()
        try write(normalized, filename: "source.jpg", in: directory)
        try? removeGeneratedHeadshot()
        guard let image = UIImage(data: normalized) else {
            throw StoreError.imageUnreadable
        }
        return image
    }

    static func saveGeneratedHeadshot(from url: URL) throws -> UIImage {
        let normalized = try normalizedJPEGData(from: Data(contentsOf: url))
        let directory = try headshotDirectory()
        try write(normalized, filename: "generated.jpg", in: directory)
        guard let image = UIImage(data: normalized) else {
            throw StoreError.imageUnreadable
        }
        return image
    }

    static func savedHeadshotSource() -> UIImage? {
        savedHeadshotImage(named: "source.jpg")
    }

    static func savedGeneratedHeadshot() -> UIImage? {
        savedHeadshotImage(named: "generated.jpg")
    }

    static func savedGeneratedHeadshotURL() -> URL? {
        savedHeadshotURL(named: "generated.jpg")
    }

    static func removeHeadshotSource() throws {
        try removeHeadshotImage(named: "source.jpg")
        try? removeGeneratedHeadshot()
    }

    static func removeGeneratedHeadshot() throws {
        try removeHeadshotImage(named: "generated.jpg")
    }

    static func removeAll() throws {
        let directory = try rootDirectory()
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private static func normalizedJPEGData(from data: Data) throws -> Data {
        guard data.count <= maximumInputBytes else { throw StoreError.imageTooLarge }
        guard let source = UIImage(data: data) else { throw StoreError.imageUnreadable }
        let sourceSize = source.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            throw StoreError.imageUnreadable
        }

        let scale = min(
            1,
            maximumPixelDimension / max(sourceSize.width, sourceSize.height)
        )
        let targetSize = CGSize(
            width: max(1, (sourceSize.width * scale).rounded(.down)),
            height: max(1, (sourceSize.height * scale).rounded(.down))
        )
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        let normalized = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            UIColor.systemBackground.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let result = normalized.jpegData(compressionQuality: 0.9),
              result.count <= maximumInputBytes else {
            throw StoreError.imageTooLarge
        }
        return result
    }

    private static func savedHeadshotImage(named filename: String) -> UIImage? {
        guard let url = savedHeadshotURL(named: filename) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private static func savedHeadshotURL(named filename: String) -> URL? {
        guard let directory = try? headshotDirectory() else { return nil }
        let url = directory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func removeHeadshotImage(named filename: String) throws {
        let url = try headshotDirectory().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func statusEvidenceDirectory(for applicationID: UUID) throws -> URL {
        let directory = try rootDirectory()
            .appendingPathComponent("JobStatus", isDirectory: true)
            .appendingPathComponent(applicationID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private static func headshotDirectory() throws -> URL {
        let directory = try rootDirectory().appendingPathComponent(
            "HeadshotStudio",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private static func rootDirectory() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("ApplyReadyVetsPrivateImages", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private static func write(
        _ data: Data,
        filename: String,
        in directory: URL
    ) throws {
        let destination = directory.appendingPathComponent(filename)
        try data.write(
            to: destination,
            options: [.atomic, .completeFileProtection]
        )
    }

    private static func isSafeImageFilename(_ filename: String) -> Bool {
        JobStatusEvidence(filename: filename).hasSafeLocalFilename
    }
}
