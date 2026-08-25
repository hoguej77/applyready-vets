import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                VStack(spacing: 0) {
                    ProgressHeader()
                    stepContent
                }
            }
            .navigationTitle(model.step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(AppModel.FlowStep.allCases) { step in
                            Button {
                                if canVisit(step) {
                                    if reduceMotion {
                                        model.step = step
                                    } else {
                                        withAnimation(.snappy) {
                                            model.step = step
                                        }
                                    }
                                }
                            } label: {
                                Label(step.title, systemImage: icon(for: step))
                                    .labelStyle(.titleAndIcon)
                            }
                            .disabled(!canVisit(step))
                        }
                    } label: {
                        Label("Application steps", systemImage: "list.number")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showsSettings = true
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let status = model.statusMessage {
                    Label(status, systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.success)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 680)
                        .cardStyle()
                        .padding(.horizontal, 16)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .environmentObject(model)
            }
        }
        .tint(Brand.navyLight)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .importDocuments: ImportStepView()
        case .serviceProfile: ProfileStepView()
        case .analyze: AnalysisStepView()
        case .review: ReviewStepView()
        case .export: ExportStepView()
        }
    }

    private func canVisit(_ step: AppModel.FlowStep) -> Bool {
        step.rawValue <= model.step.rawValue || (step == .export && model.currentResponse != nil)
    }

    private func icon(for step: AppModel.FlowStep) -> String {
        if step.rawValue < model.step.rawValue { return "checkmark.circle.fill" }
        if step == model.step { return "circle.inset.filled" }
        return "\(step.rawValue + 1).circle"
    }
}

private struct ProgressHeader: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(AppModel.FlowStep.allCases) { step in
                    Circle()
                        .fill(color(for: step))
                        .frame(width: step == model.step ? 10 : 7, height: step == model.step ? 10 : 7)
                        .accessibilityHidden(true)
                    if step != AppModel.FlowStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < model.step.rawValue
                                ? Brand.navyLight
                                : Color.secondary.opacity(0.20))
                            .frame(height: 2)
                            .accessibilityHidden(true)
                    }
                }
            }
            HStack {
                Text("Step \(model.step.rawValue + 1) of \(AppModel.FlowStep.allCases.count) · \(model.step.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.navy)
                Spacer()
                if let next = nextStep {
                    Text("Next: \(next.title)")
                        .font(.caption)
                        .foregroundStyle(Brand.navy)
                } else if model.exportURL != nil {
                    Label("Packet ready", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.success)
                } else {
                    Label("Ready to export", systemImage: "doc.badge.plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.navyLight)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(model.step.rawValue + 1) of \(AppModel.FlowStep.allCases.count), \(model.step.title)")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }

    private func color(for step: AppModel.FlowStep) -> Color {
        step.rawValue <= model.step.rawValue
            ? Brand.navyLight
            : Color.secondary.opacity(0.20)
    }

    private var progress: Double {
        Double(model.step.rawValue + 1) / Double(AppModel.FlowStep.allCases.count)
    }

    private var nextStep: AppModel.FlowStep? {
        AppModel.FlowStep(rawValue: model.step.rawValue + 1)
    }
}
