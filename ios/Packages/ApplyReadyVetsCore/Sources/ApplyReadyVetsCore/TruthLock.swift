import Foundation

public enum TruthLock {
    public struct Result: Equatable, Sendable {
        public let accepted: Bool
        public let reason: String
    }

    public static func validate(
        _ proposal: ProposedEdit,
        evidence: [EvidenceItem],
        targetTitle: String = ""
    ) -> Result {
        let groupedEvidence = Dictionary(grouping: evidence, by: \.id)
        let duplicateIDs = groupedEvidence.filter { $0.value.count > 1 }.map(\.key).sorted()
        guard duplicateIDs.isEmpty else {
            return Result(
                accepted: false,
                reason: "Evidence identifiers are not unique: \(duplicateIDs.joined(separator: ", "))."
            )
        }
        let lookup = groupedEvidence.compactMapValues { $0.first }
        guard !proposal.evidenceIDs.isEmpty else {
            return Result(accepted: false, reason: "No source evidence was cited.")
        }
        guard proposal.evidenceIDs.allSatisfy({ lookup[$0] != nil }) else {
            return Result(accepted: false, reason: "A source citation is missing.")
        }
        let citedEvidence = proposal.evidenceIDs.compactMap { lookup[$0] }
        let source = citedEvidence.map(\.text).joined(separator: " ")
        let isExactLocalRule = LocalCareerEngine.isExactLocalRuleProposal(
            proposal,
            citedEvidence: citedEvidence,
            allEvidence: evidence
        )
        if proposal.source == "private-local-rules", !isExactLocalRule {
            return Result(
                accepted: false,
                reason: "The local-rule proposal is not an allowlisted evidence-backed terminology transform."
            )
        }
        if !isExactLocalRule {
            guard proposal.evidenceIDs.count == 1,
                  normalizedPhrase(source) == normalizedPhrase(proposal.originalText) else {
                return Result(
                    accepted: false,
                    reason: "Generative wording must cite the one exact source line being changed."
                )
            }
        }
        guard preservesLimitingLanguage(
            from: proposal.originalText,
            in: proposal.effectiveText
        ) else {
            return Result(
                accepted: false,
                reason: "The edit removes a negation, uncertainty, or limiting qualifier."
            )
        }
        let unsupported = numbers(in: proposal.effectiveText).subtracting(numbers(in: source))
        guard unsupported.isEmpty else {
            return Result(accepted: false, reason: "The edit adds an unsupported number.")
        }
        if !isExactLocalRule,
           let claim = firstUnsupportedClaimToken(
                in: proposal.effectiveText,
                comparedWith: source
           ) {
            return Result(
                accepted: false,
                reason: "The edit adds candidate-specific wording not found in its cited evidence (\(claim))."
            )
        }
        let normalizedTitle = normalizedPhrase(targetTitle)
        let normalizedProposal = normalizedPhrase(proposal.effectiveText)
        let normalizedEvidence = normalizedPhrase(source)
        guard normalizedTitle.isEmpty ||
                !normalizedProposal.contains(normalizedTitle) ||
                normalizedEvidence.contains(normalizedTitle) else {
            return Result(
                accepted: false,
                reason: "The edit copies the target job title without supporting evidence."
            )
        }
        guard !SensitiveContentPolicy.containsSensitiveContent(proposal.effectiveText) else {
            return Result(accepted: false, reason: "The edit contains sensitive personal or operational information.")
        }
        guard proposal.effectiveText.trimmingCharacters(in: .whitespacesAndNewlines) !=
                proposal.originalText.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return Result(accepted: false, reason: "The edit does not change the source text.")
        }
        return Result(accepted: true, reason: "Supported by cited candidate evidence.")
    }

    public static func applyApprovedEdits(to resume: String, proposals: [ProposedEdit]) -> String {
        proposals.reduce(resume) { partial, proposal in
            guard [.approved, .edited].contains(proposal.status),
                  let range = partial.range(of: proposal.originalText) else { return partial }
            return partial.replacingCharacters(in: range, with: proposal.effectiveText)
        }
    }

    private static func numbers(in text: String) -> Set<String> {
        let pattern = #"(?<!\w)(?:\$)?\d+(?:[.,]\d+)*(?:%|[KkMm])?(?!\w)"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return Set(expression.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        })
    }

    private static func normalizedPhrase(_ text: String) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    private static func firstUnsupportedClaimToken(
        in proposedText: String,
        comparedWith source: String
    ) -> String? {
        let sourceWords = claimWords(in: source)
        var allowed = sourceWords
        let equivalenceGroups: [Set<String>] = [
            ["lead", "leads", "led", "leading"],
            ["manage", "manages", "managed", "managing"],
            ["supervise", "supervises", "supervised", "supervising"],
            ["direct", "directs", "directed", "directing"],
            ["coordinate", "coordinates", "coordinated", "coordinating"],
            ["improve", "improves", "improved", "improving"],
            ["increase", "increases", "increased", "increasing"],
            ["enhance", "enhances", "enhanced", "enhancing"],
            ["optimize", "optimizes", "optimized", "optimizing"],
            ["build", "builds", "built", "building"],
            ["develop", "develops", "developed", "developing"],
            ["create", "creates", "created", "creating"],
            ["maintain", "maintains", "maintained", "maintaining"],
            ["sustain", "sustains", "sustained", "sustaining"],
            ["train", "trains", "trained", "training"],
            ["teach", "teaches", "taught", "teaching"],
            ["instruct", "instructs", "instructed", "instructing"],
            ["plan", "plans", "planned", "planning"],
            ["schedule", "schedules", "scheduled", "scheduling"],
            ["analyze", "analyzes", "analyzed", "analyzing"],
            ["assess", "assesses", "assessed", "assessing"],
        ]
        for group in equivalenceGroups where !sourceWords.isDisjoint(with: group) {
            allowed.formUnion(group)
        }
        return claimWords(in: proposedText)
            .subtracting(allowed)
            .sorted()
            .first
    }

    private static func claimWords(in text: String) -> Set<String> {
        let functionWords: Set<String> = [
            "a", "an", "the", "and", "or", "but", "for", "with", "from", "into",
            "through", "across", "while", "that", "this", "these", "those", "using", "via",
            "within", "over", "under", "to", "of", "in", "on", "at", "by", "as", "per",
            "than", "be", "am", "is", "are", "was", "were", "been", "being", "do", "does",
            "did", "have", "has", "had", "will", "would", "can", "could", "may", "might",
            "must", "should", "not", "no", "never", "without", "only", "also", "i", "me",
            "my", "mine", "we", "us", "our", "ours", "you", "your", "yours", "he", "him",
            "his", "she", "her", "hers", "they", "them", "their", "theirs", "it", "its", "who",
            "which", "where", "when", "why", "how", "what", "up", "down", "out", "off",
        ]
        guard let expression = try? NSRegularExpression(
            pattern: #"[A-Za-z][+#]+|[A-Za-z](?:[A-Za-z0-9'/-]*[A-Za-z0-9])?"#
        ) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return Set(expression.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            let word = text[swiftRange]
                .trimmingCharacters(in: CharacterSet(charactersIn: "'/-"))
                .lowercased()
            return !word.isEmpty && !functionWords.contains(word) ? word : nil
        })
    }

    private static func preservesLimitingLanguage(
        from originalText: String,
        in proposedText: String
    ) -> Bool {
        let markerGroups: [Set<String>] = [
            ["no", "not", "never", "without", "neither", "nor", "lacks", "lacking"],
            ["may", "might", "could", "possibly", "potentially"],
            ["assist", "assisted", "support", "supported", "help", "helped", "contribute", "contributed", "participate", "participated", "collaborate", "collaborated"],
        ]
        let original = allWords(in: originalText)
        let proposed = allWords(in: proposedText)
        return markerGroups.allSatisfy { group in
            original.isDisjoint(with: group) || !proposed.isDisjoint(with: group)
        }
    }

    private static func allWords(in text: String) -> Set<String> {
        guard let expression = try? NSRegularExpression(pattern: #"[A-Za-z]+"#) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return Set(expression.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { text[$0].lowercased() }
        })
    }
}
