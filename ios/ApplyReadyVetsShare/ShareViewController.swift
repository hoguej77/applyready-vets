import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    private enum LoadedAttachment: Sendable {
        case url(String)
        case text(String)
    }

    override func isContentValid() -> Bool {
        let hasTypedText = !(contentText ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        return hasTypedText || attachmentProviders().contains { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) ||
                provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
        }
    }

    override func didSelectPost() {
        let typedText = contentText
        let providers = attachmentProviders()

        Task { [weak self] in
            guard let self else { return }
            do {
                let loaded = await Self.loadFirstSupportedAttachment(from: providers)
                let sourceURL: String?
                let attachmentText: String?
                switch loaded {
                case let .url(value):
                    sourceURL = value
                    attachmentText = nil
                case let .text(value):
                    sourceURL = Self.httpURL(in: value)
                    attachmentText = value
                case nil:
                    sourceURL = nil
                    attachmentText = nil
                }

                let sharedNote = (typedText ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let finalText: String?
                switch (attachmentText, sharedNote.isEmpty ? nil : sharedNote) {
                case let (attachment?, note?):
                    finalText = "\(attachment)\n\nShared note:\n\(note)"
                case let (attachment?, nil):
                    finalText = attachment
                case let (nil, note?):
                    finalText = note
                case (nil, nil):
                    finalText = nil
                }
                let payload = try SharedJobPayload(
                    sourceURL: sourceURL,
                    text: finalText
                )
                try SharedJobInbox.enqueue(payload)
                await MainActor.run {
                    self.extensionContext?.completeRequest(
                        returningItems: nil,
                        completionHandler: nil
                    )
                }
            } catch {
                await MainActor.run {
                    self.extensionContext?.cancelRequest(withError: error)
                }
            }
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func attachmentProviders() -> [NSItemProvider] {
        extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []
    }

    private static func loadFirstSupportedAttachment(
        from providers: [NSItemProvider]
    ) async -> LoadedAttachment? {
        for provider in providers
        where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await loadURL(provider) {
                return .url(url.absoluteString)
            }
        }
        for provider in providers
        where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = await loadText(provider) {
                return .text(text)
            }
        }
        return nil
    }

    private static func loadURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSURL.self) { object, _ in
                continuation.resume(
                    returning: (object as? NSURL).map { $0 as URL }
                )
            }
        }
    }

    private static func loadText(_ provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSString.self) { object, _ in
                continuation.resume(
                    returning: (object as? NSString).map { $0 as String }
                )
            }
        }
    }

    private static func httpURL(in text: String) -> String? {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector
            .matches(in: text, range: range)
            .compactMap(\.url)
            .first { ["http", "https"].contains($0.scheme?.lowercased() ?? "") }?
            .absoluteString
    }
}
