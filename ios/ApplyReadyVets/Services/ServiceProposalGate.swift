import Foundation

enum ServiceProposalGate {
    static let maximumProposals = 12
    static let maximumEditCharacters = 4_000
    static let maximumRationaleCharacters = 1_000
    static let maximumSectionCharacters = 100
    static let maximumEvidenceIDs = 16

    static func merge(
        _ serviceResponse: TailorResponse,
        into baseline: TailorResponse,
        resumeText: String,
        enforceTruthLock: Bool = true
    ) -> TailorResponse {
        var merged = baseline
        var seen = Set(merged.proposals.map {
            "\($0.originalText)\u{001F}\($0.proposedText)"
        })

        for remote in serviceResponse.proposals.prefix(maximumProposals) {
            guard !remote.originalText.isEmpty,
                  !remote.proposedText.isEmpty,
                  remote.originalText.count <= maximumEditCharacters,
                  remote.proposedText.count <= maximumEditCharacters,
                  remote.evidenceIDs.count <= maximumEvidenceIDs,
                  remote.confidence.isFinite,
                  resumeText.contains(remote.originalText),
                  OnDeviceProposalService.hasExactResumeEvidence(
                    originalText: remote.originalText,
                    evidenceIDs: remote.evidenceIDs,
                    evidence: baseline.evidence
                  ) else {
                continue
            }

            let proposal = ProposedEdit(
                id: UUID().uuidString,
                section: String(remote.section.prefix(maximumSectionCharacters)),
                originalText: remote.originalText,
                proposedText: remote.proposedText,
                rationale: String(remote.rationale.prefix(maximumRationaleCharacters)),
                evidenceIDs: Array(remote.evidenceIDs.prefix(maximumEvidenceIDs)),
                confidence: min(max(remote.confidence, 0), 1),
                status: .pending,
                editedText: nil,
                source: enforceTruthLock
                    ? "optional-service"
                    : "optional-service-unverified"
            )
            let key = "\(proposal.originalText)\u{001F}\(proposal.proposedText)"
            guard !seen.contains(key) else {
                continue
            }
            let validation = TruthLock.validate(
                    proposal,
                    evidence: baseline.evidence,
                    targetTitle: baseline.job.title
                  )
            guard !SensitiveContentPolicy.containsSensitiveContent(
                    proposal.effectiveText
                  ),
                  (!enforceTruthLock || validation.accepted) else {
                continue
            }
            seen.insert(key)
            merged.proposals.append(proposal)
        }
        return merged
    }
}
