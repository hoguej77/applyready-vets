import Foundation
import Security

struct KeychainStore {
    let service: String

    func save(_ value: String, account: String) throws {
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data(value.utf8),
        ]
        let updateStatus = SecItemUpdate(
            identity as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecItemNotFound {
            let status = SecItemAdd(
                identity.merging(attributes) { _, new in new } as CFDictionary,
                nil
            )
            guard status == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        } else if updateStatus != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
        }
    }

    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(account: String) {
        try? deleteVerified(account: account)
    }

    func deleteVerified(account: String) throws {
        let status = SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}

struct DraftStore {
    private func appSupportURL() -> URL? {
        try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private var fileURL: URL? {
        appSupportURL()?.appendingPathComponent("ApplyReadyVetsDraft.json")
    }

    private var legacyMusterForwardFileURL: URL? {
        appSupportURL()?.appendingPathComponent("MusterForwardDraft.json")
    }

    private var legacyFileURL: URL? {
        appSupportURL()?.appendingPathComponent("HogueResMasterDraft.json")
    }

    func save(_ draft: WorkspaceDraft) throws {
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        let data = try encoder.encode(draft)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    func load() -> WorkspaceDraft? {
        if let fileURL,
           let data = try? Data(contentsOf: fileURL),
           let draft = try? JSONDecoder().decode(WorkspaceDraft.self, from: data) {
            return draft
        }
        if let legacyMusterForwardFileURL,
           let data = try? Data(contentsOf: legacyMusterForwardFileURL),
           let draft = try? JSONDecoder().decode(WorkspaceDraft.self, from: data) {
            try? save(draft)
            return draft
        }
        guard let legacyFileURL,
              let data = try? Data(contentsOf: legacyFileURL),
              let draft = try? JSONDecoder().decode(WorkspaceDraft.self, from: data) else { return nil }
        try? save(draft)
        return draft
    }

    func delete() {
        try? deleteVerified()
    }

    func deleteVerified() throws {
        for url in [
            fileURL,
            legacyMusterForwardFileURL,
            legacyFileURL,
        ].compactMap(\.self) where
            FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
