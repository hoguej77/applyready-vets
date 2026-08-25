import Testing
@testable import ApplyReadyVetsCore

@Test func truthLockRejectsUnsupportedNumber() {
    let evidence = [EvidenceItem(id: "resume:001", source: "resume", section: "experience", text: "Led 12 people.")]
    let proposal = ProposedEdit(
        id: "p1",
        section: "experience",
        originalText: "Led 12 people.",
        proposedText: "Led 25 people with 99% readiness.",
        rationale: "Stronger",
        evidenceIDs: ["resume:001"],
        confidence: 0.9
    )
    #expect(TruthLock.validate(proposal, evidence: evidence).accepted == false)
}

@Test func approvedEditIsApplied() {
    var proposal = ProposedEdit(
        id: "p1",
        section: "experience",
        originalText: "MOS 88M",
        proposedText: "Motor Transport Operator (88M)",
        rationale: "Translate",
        evidenceIDs: ["resume:001"],
        confidence: 0.9
    )
    proposal.status = .approved
    let output = TruthLock.applyApprovedEdits(to: "MOS 88M", proposals: [proposal])
    #expect(output == "Motor Transport Operator (88M)")
}

@Test func truthLockRejectsUnsupportedQualitativeClaimsBeyondAKeywordDenylist() {
    let evidence = [
        EvidenceItem(
            id: "resume:001",
            source: "resume",
            section: "experience",
            text: "Managed logistics operations."
        ),
    ]
    let unsupported = [
        "Managed logistics operations and negotiated enterprise vendor contracts.",
        "Managed logistics operations and designed zero-trust identity systems.",
        "Managed logistics operations and delivered regulatory compliance audits.",
    ]

    for text in unsupported {
        let proposal = ProposedEdit(
            id: text,
            section: "experience",
            originalText: "Managed logistics operations.",
            proposedText: text,
            rationale: "Test",
            evidenceIDs: ["resume:001"],
            confidence: 0.9,
            source: "optional-service"
        )
        #expect(TruthLock.validate(proposal, evidence: evidence).accepted == false)
    }
}

@Test func safetyPolicyDoesNotMisclassifyOrdinarySapOrOperationalReadiness() {
    #expect(!SensitiveContentPolicy.hasCriticalFinding(in: "Managed SAP ERP migration."))
    #expect(!SensitiveContentPolicy.hasCriticalFinding(in: "Improved operational readiness."))
    #expect(SensitiveContentPolicy.hasCriticalFinding(in: "Included classified operation details."))
}

@Test func truthLockRejectsNegationRemovalAndCrossLineClaimRecombination() {
    let negated = EvidenceItem(
        id: "resume:001",
        source: "resume",
        section: "experience",
        text: "Did not manage AWS operations."
    )
    let reversed = ProposedEdit(
        id: "negation",
        section: "experience",
        originalText: negated.text,
        proposedText: "Managed AWS operations.",
        rationale: "Unsafe reversal",
        evidenceIDs: [negated.id],
        confidence: 0.9,
        source: "optional-service"
    )
    #expect(TruthLock.validate(reversed, evidence: [negated]).accepted == false)

    let logistics = EvidenceItem(
        id: "resume:002",
        source: "resume",
        section: "experience",
        text: "Managed logistics operations."
    )
    let training = EvidenceItem(
        id: "resume:003",
        source: "resume",
        section: "training",
        text: "Completed AWS fundamentals training."
    )
    let recombined = ProposedEdit(
        id: "recombined",
        section: "experience",
        originalText: logistics.text,
        proposedText: "Managed AWS operations.",
        rationale: "Unsafe relationship",
        evidenceIDs: [logistics.id, training.id],
        confidence: 0.9,
        source: "optional-service"
    )
    #expect(TruthLock.validate(recombined, evidence: [logistics, training]).accepted == false)
}

@Test func truthLockRejectsDuplicateEvidenceIDs() {
    let duplicated = [
        EvidenceItem(
            id: "resume:001",
            source: "resume",
            section: "experience",
            text: "Led 12 people."
        ),
        EvidenceItem(
            id: "resume:001",
            source: "resume",
            section: "experience",
            text: "Led 12 people."
        ),
    ]
    let proposal = ProposedEdit(
        id: "dup1",
        section: "experience",
        originalText: "Led 12 people.",
        proposedText: "Led twelve people.",
        rationale: "Duplicate evidence",
        evidenceIDs: ["resume:001"],
        confidence: 0.9,
        source: "optional-service"
    )

    #expect(TruthLock.validate(proposal, evidence: duplicated).accepted == false)
}

@Test func demoDraftHasBothRequiredInputs() {
    #expect(!DemoData.draft.resumeText.isEmpty)
    #expect(!DemoData.draft.jobText.isEmpty)
}
