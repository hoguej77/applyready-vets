import SwiftUI

struct ReviewStepView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepIntroduction(
                    eyebrow: "Step 4 of 5",
                    title: "Truth Lock review",
                    detail: "Every card shows what would change and which source evidence supports it. Pending suggestions are excluded from export."
                )

                if let response = model.currentResponse {
                    ReviewSummary(response: response)

                    if response.proposals.isEmpty {
                        ContentUnavailableView(
                            "No safe rewrites proposed",
                            systemImage: "checkmark.shield",
                            description: Text("The app found no evidence-backed wording changes to recommend. Review the gap questions instead.")
                        )
                        .cardStyle()
                    } else {
                        ForEach(response.proposals) { proposal in
                            ProposalCard(
                                proposal: proposal,
                                evidence: evidence(for: proposal, in: response),
                                targetTitle: response.job.title
                            )
                        }
                    }

                    if !response.gapQuestions.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Questions only you can answer").font(.title3.bold())
                            Text("Do not add an answer unless it is true and you can support it.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            ForEach(response.gapQuestions) { gap in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(gap.requirement).font(.subheadline.weight(.semibold))
                                    Text(gap.question).font(.body)
                                }
                                if gap.id != response.gapQuestions.last?.id { Divider() }
                            }
                        }
                        .cardStyle()
                    }

                    Text("By approving or editing a suggestion, you attest that the final wording is accurate and supported by your records. Citation and pattern checks cannot prove every qualitative statement.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .cardStyle()

                    PrimaryActionButton(title: "Continue with \(model.approvedCount) candidate-approved", icon: "shippingbox") {
                        model.next()
                    }
                } else {
                    ContentUnavailableView(
                        "Analysis required",
                        systemImage: "magnifyingglass",
                        description: Text("Return to Analysis to generate evidence-backed proposals.")
                    )
                    .cardStyle()
                }

                Button("Back") { model.back() }.buttonStyle(.bordered)
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }

    private func evidence(for proposal: ProposedEdit, in response: TailorResponse) -> [EvidenceItem] {
        response.evidence.filter { proposal.evidenceIDs.contains($0.id) }
    }
}

private struct ReviewSummary: View {
    let response: TailorResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusPill(text: "\(response.proposals.count) proposals", systemImage: "doc.text.magnifyingglass")
                if !response.safetyFindings.isEmpty {
                    StatusPill(text: "\(response.safetyFindings.count) safety flags", systemImage: "exclamationmark.triangle", color: Brand.danger)
                }
            }
            if !response.integrityWarnings.isEmpty {
                ForEach(response.integrityWarnings, id: \.self) { warning in
                    Label(warning, systemImage: "checkmark.shield")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }
}

private struct ProposalCard: View {
    @EnvironmentObject private var model: AppModel
    let proposal: ProposedEdit
    let evidence: [EvidenceItem]
    let targetTitle: String

    @State private var isEditing = false
    @State private var editDraft: String
    @State private var editValidationMessage: String?
    @State private var editIsValid = false

    init(
        proposal: ProposedEdit,
        evidence: [EvidenceItem],
        targetTitle: String
    ) {
        self.proposal = proposal
        self.evidence = evidence
        self.targetTitle = targetTitle
        _editDraft = State(
            initialValue: proposal.editedText ?? proposal.proposedText
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(proposal.section).font(.headline)
                Spacer()
                StatusPill(
                    text: sourceLabel,
                    systemImage: sourceIcon
                )
            }

            comparison(title: "Before", text: proposal.originalText, color: .secondary)
            comparison(title: "Proposed", text: proposal.proposedText, color: Brand.navy)

            if isEditing {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your edit").font(.caption.weight(.bold)).foregroundStyle(Brand.navyLight)
                    TextEditor(text: boundedEditDraft)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .overlay { RoundedRectangle(cornerRadius: 10).stroke(Brand.gold) }
                        .accessibilityLabel("Edited resume wording")
                    if let editValidationMessage {
                        Label(
                            editValidationMessage,
                            systemImage: editIsValid
                                ? "checkmark.shield.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(editIsValid ? Brand.success : Brand.danger)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            editActionButtons
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            editActionButtons
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Why").font(.caption.weight(.bold)).foregroundStyle(Brand.navyLight)
                Text(proposal.rationale).font(.subheadline)
                ForEach(evidence) { item in
                    Label(item.text, systemImage: "link")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if isUnverifiedAI {
                Label(
                    "Unverified AI draft — edit it or verify it before approval and export.",
                    systemImage: "exclamationmark.shield"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.danger)
            }

            if !isEditing {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        decisionButtons
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        decisionButtons
                    }
                }
            }
        }
        .cardStyle()
        .overlay(alignment: .topTrailing) {
            if proposal.status != .pending {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .padding(10)
                    .accessibilityLabel("Status: \(proposal.status.rawValue)")
            }
        }
    }

    private var sourceLabel: String {
        switch proposal.source {
        case "apple-device": "On-device Apple model"
        case "apple-device-unverified": "Unverified on-device draft"
        case "private-local-repair": "Verified local repair"
        case "optional-service": "Optional service AI"
        case "optional-service-unverified": "Unverified service draft"
        default: "Built-in"
        }
    }

    private var sourceIcon: String {
        switch proposal.source {
        case "apple-device", "apple-device-unverified": "cpu"
        case "optional-service", "optional-service-unverified": "sparkles"
        default: "gearshape.2"
        }
    }

    private var isUnverifiedAI: Bool {
        proposal.source.hasSuffix("-unverified")
    }

    private func comparison(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(text).font(.body).foregroundStyle(color).textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var decisionButtons: some View {
        if isUnverifiedAI && proposal.status != .edited {
            Button("Verify & approve", systemImage: "checkmark.shield") {
                verifyAndApprove()
            }
            .buttonStyle(.bordered)
            .tint(Brand.success)
            .frame(maxWidth: .infinity)
        } else {
            decisionButton(
                proposal.status == .edited ? "Keep saved edit" : "Approve as accurate",
                icon: "checkmark",
                status: proposal.status == .edited ? .edited : .approved,
                color: Brand.success
            )
        }
        Button("Edit", systemImage: "pencil") {
            editDraft = proposal.editedText ?? proposal.proposedText
            editValidationMessage = nil
            editIsValid = false
            isEditing = true
        }
        .buttonStyle(.bordered)
        .tint(Brand.navyLight)
        .frame(maxWidth: .infinity)
        decisionButton(
            "Reject",
            icon: "xmark",
            status: .rejected,
            color: Brand.danger
        )
    }

    private func verifyAndApprove() {
        let validation = TruthLock.validate(
            proposal,
            evidence: evidence,
            targetTitle: targetTitle
        )
        guard validation.accepted else {
            editDraft = proposal.proposedText
            editValidationMessage = validation.reason
            editIsValid = false
            isEditing = true
            return
        }
        model.setProposal(id: proposal.id, status: .approved)
    }

    @ViewBuilder
    private var editActionButtons: some View {
        Button("Save verified edit", systemImage: "checkmark.shield") {
            saveEdit()
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.navySurface)
        .frame(maxWidth: .infinity)

        Button("Cancel", role: .cancel) {
            editDraft = proposal.editedText ?? proposal.proposedText
            editValidationMessage = nil
            editIsValid = false
            isEditing = false
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)

        Button("Use suggestion", systemImage: "arrow.uturn.backward") {
            model.useSuggestedProposal(id: proposal.id)
            editDraft = proposal.proposedText
            editValidationMessage = "The original suggestion is selected."
            editIsValid = true
            isEditing = false
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private func decisionButton(_ title: String, icon: String, status: ProposalStatus, color: Color) -> some View {
        Button {
            let edited = status == .edited
                ? (proposal.editedText ?? proposal.proposedText)
                : nil
            model.setProposal(id: proposal.id, status: status, editedText: edited)
        } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }

    private func saveEdit() {
        let trimmed = editDraft.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            editValidationMessage = "An accepted edit cannot be empty."
            editIsValid = false
            return
        }

        var candidate = proposal
        candidate.status = .edited
        candidate.editedText = trimmed
        let validation = TruthLock.validate(
            candidate,
            evidence: evidence,
            targetTitle: targetTitle
        )
        guard validation.accepted else {
            editValidationMessage = validation.reason
            editIsValid = false
            return
        }

        model.setProposal(
            id: proposal.id,
            status: .edited,
            editedText: trimmed
        )
        editDraft = trimmed
        editValidationMessage = "Saved and checked against the cited evidence."
        editIsValid = true
        isEditing = false
    }

    private var boundedEditDraft: Binding<String> {
        Binding(
            get: { editDraft },
            set: { newValue in
                guard newValue.count <=
                        CareerInputPolicy.Field.proposalEdit.maximumCharacters
                else {
                    editValidationMessage = CareerInputPolicy.FieldTooLarge(
                        field: .proposalEdit
                    ).localizedDescription
                    editIsValid = false
                    return
                }
                editDraft = newValue
            }
        )
    }

    private var statusIcon: String {
        switch proposal.status {
        case .approved: "checkmark.circle.fill"
        case .edited: "pencil.circle.fill"
        case .rejected: "xmark.circle.fill"
        case .pending: "circle"
        }
    }

    private var statusColor: Color {
        switch proposal.status {
        case .approved: Brand.success
        case .edited: Brand.navyLight
        case .rejected: Brand.danger
        case .pending: .secondary
        }
    }
}
