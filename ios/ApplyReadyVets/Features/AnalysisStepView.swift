import SwiftUI

struct AnalysisStepView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepIntroduction(
                    eyebrow: "Step 3 of 5",
                    title: "Run an evidence-first analysis",
                    detail: "ApplyReady Vets compares the job with your actual experience, flags gaps, and drafts changes that can be traced back to your words."
                )

                VStack(alignment: .leading, spacing: 16) {
                    Text("Ready to analyze").font(.title3.bold())
                    summaryRow(icon: "doc.text", label: "Resume", value: model.draft.resumeFilename.isEmpty ? "Pasted text" : model.draft.resumeFilename)
                    summaryRow(icon: "briefcase", label: "Job", value: model.draft.jobFilename.isEmpty ? "Pasted text" : model.draft.jobFilename)
                    summaryRow(icon: "slider.horizontal.3", label: "Mode", value: model.effectiveResumeMode.label)
                    summaryRow(
                        icon: model.draft.useAI ? "sparkles" : "lock.shield",
                        label: "Engine",
                        value: model.draft.useAI && model.draft.aiConsent
                            ? "Private core + optional AI + Truth Lock"
                            : "Private rules + Truth Lock"
                    )
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 14) {
                    Text("What happens next").font(.headline)
                    BulletRow(icon: "iphone", title: "Private baseline", detail: "Evidence, job-match, safety, and veteran-language checks run locally before any optional AI step.")
                    BulletRow(icon: "eye.slash", title: "Sensitive-pattern scan", detail: "Potential SSNs, medical details, and OPSEC-sensitive language pause AI assistance for review.")
                    BulletRow(icon: "link", title: "Evidence linking", detail: "Suggestions must cite one or more source lines from your materials.")
                    BulletRow(icon: "hand.raised", title: "Human approval", detail: "Nothing is accepted automatically. You decide what reaches the export.")
                }
                .cardStyle()

                if let response = model.currentResponse {
                    AnalysisResultsSummary(response: response)
                    if model.effectiveResumeMode == .federal {
                        FederalReadinessCard(
                            resumeText: model.draft.resumeText,
                            profile: model.draft.profile,
                            details: model.draft.federalDetails
                        )
                    }
                    PrimaryActionButton(title: "Review proposed changes", icon: "checkmark.shield") {
                        model.step = .review
                    }
                } else {
                    PrimaryActionButton(
                        title: "Analyze my match",
                        icon: "sparkles",
                        disabled: !model.canContinueFromImport
                    ) {
                        Task { await model.analyze() }
                    }
                    if !model.canContinueFromImport {
                        Text("Add a resume and one job posting—and review any import warnings—before analysis.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Back") { model.back() }
                    .buttonStyle(.bordered)
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .task(id: prewarmKey) {
            guard model.draft.useAI,
                  model.draft.aiConsent,
                  model.currentResponse == nil else { return }
            await OnDeviceProposalService.prewarm(mode: model.effectiveResumeMode)
        }
    }

    private var prewarmKey: String {
        [
            model.effectiveResumeMode.rawValue,
            model.draft.useAI.description,
            model.draft.aiConsent.description,
            model.currentResponse == nil ? "new" : "complete",
        ].joined(separator: ":")
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label(label, systemImage: icon).font(.subheadline.weight(.semibold))
            Spacer()
            Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        }
    }
}

struct AnalysisResultsSummary: View {
    let response: TailorResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Document checks").font(.title3.bold())
                Spacer()
                StatusPill(text: response.engine, systemImage: engineIcon)
            }
            ReadinessGauge(title: "Job-keyword overlap", value: response.scores.qualificationCoverage)
            ReadinessGauge(title: "Evidence strength", value: response.scores.evidenceStrength)
            ReadinessGauge(title: "Acronym clarity", value: response.scores.acronymClarity)
            Text(response.scores.disclaimer).font(.footnote).foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var engineIcon: String {
        if response.engine.contains("apple") { return "cpu" }
        if response.engine.contains("openai") { return "sparkles" }
        return "gearshape.2"
    }
}
