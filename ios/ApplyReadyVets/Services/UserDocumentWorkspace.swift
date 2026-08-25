import Foundation

enum UserDocumentWorkspace {
    static let samplesFolderName = "Samples"
    static let outputFolderName = "Output"

    static var filesLocationDescription: String {
        "Browse → On My iPhone (or On My iPad) → ApplyReady Vets"
    }

    static func prepareSimulatorDocuments(
        fileManager: FileManager = .default
    ) throws {
        #if DEBUG && targetEnvironment(simulator)
        let samples = try managedDirectory(
            named: samplesFolderName,
            fileManager: fileManager
        )
        _ = try managedDirectory(
            named: outputFolderName,
            fileManager: fileManager
        )

        try writeIfMissing(
            DemoData.resume.trimmingCharacters(in: .whitespacesAndNewlines) + "\n",
            to: samples.appendingPathComponent("Sample Veteran Resume.txt"),
            fileManager: fileManager
        )
        try writeIfMissing(
            DemoData.job.trimmingCharacters(in: .whitespacesAndNewlines) + "\n",
            to: samples.appendingPathComponent("Sample Job Posting.txt"),
            fileManager: fileManager
        )
        try writeIfMissing(
            """
            APPLYREADY VETS — SIMULATOR FILE TEST

            In ApplyReady Vets:
            1. Choose Start my application or Explore with safe demo data.
            2. Tap Choose file under Current resume or Target job.
            3. In Apple's file picker choose Browse.
            4. Open On My iPhone (or On My iPad) → ApplyReady Vets → Samples.
            5. Select the matching sample file.

            After export, open Files → Browse → On My iPhone (or On My iPad) → ApplyReady Vets → Output.
            The employer-facing resume and private review are separate files.

            The Recents view is populated by files you recently opened or saved.
            The Shared view is supplied by iCloud Drive and appears only when the
            Simulator is signed in to an Apple Account with shared iCloud items.
            """,
            to: samples.appendingPathComponent("How to Test Files.txt"),
            fileManager: fileManager
        )
        #endif
    }

    static func outputDirectory(
        override: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        if let override {
            try createProtectedDirectory(override, fileManager: fileManager)
            return override
        }
        return try managedDirectory(
            named: outputFolderName,
            fileManager: fileManager
        )
    }

    static func existingOutputFile(
        named filename: String,
        fileManager: FileManager = .default
    ) -> URL? {
        let trimmed = filename.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty,
              (trimmed as NSString).lastPathComponent == trimmed,
              !trimmed.contains("\0"),
              let directory = try? outputDirectory(fileManager: fileManager)
                .standardizedFileURL else {
            return nil
        }
        let candidate = directory
            .appendingPathComponent(trimmed, isDirectory: false)
            .standardizedFileURL
        guard candidate.deletingLastPathComponent() == directory,
              fileManager.fileExists(atPath: candidate.path) else {
            return nil
        }
        return candidate
    }

    static func deleteManagedDocuments(
        fileManager: FileManager = .default
    ) throws {
        let documents = try documentsDirectory(fileManager: fileManager)
        for folder in [samplesFolderName, outputFolderName] {
            let directory = documents.appendingPathComponent(
                folder,
                isDirectory: true
            )
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        }
    }

    private static func managedDirectory(
        named name: String,
        fileManager: FileManager
    ) throws -> URL {
        let directory = try documentsDirectory(fileManager: fileManager)
            .appendingPathComponent(name, isDirectory: true)
        try createProtectedDirectory(directory, fileManager: fileManager)
        return directory
    }

    private static func documentsDirectory(
        fileManager: FileManager
    ) throws -> URL {
        try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private static func createProtectedDirectory(
        _ directory: URL,
        fileManager: FileManager
    ) throws {
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
        )
    }

    private static func writeIfMissing(
        _ text: String,
        to destination: URL,
        fileManager: FileManager
    ) throws {
        guard !fileManager.fileExists(atPath: destination.path) else { return }
        try Data(text.utf8).write(
            to: destination,
            options: [.atomic, .completeFileProtection]
        )
    }
}
