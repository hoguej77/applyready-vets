import SwiftUI

struct FederalReadinessCard: View {
    let resumeText: String
    let profile: CandidateProfile
    let details: FederalApplicationDetails?

    private var checks: [FederalResumeCheck] {
        FederalResumeReview.checks(
            resumeText: resumeText,
            profile: profile,
            details: details
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Federal résumé review", systemImage: "building.columns")
                    .font(.title3.bold())
                Spacer()
                StatusPill(text: "USAJOBS", systemImage: "checklist")
            }
            Text("This is a requirement-by-requirement review, not a federal eligibility score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(checks) { check in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: check.state))
                        .foregroundStyle(color(for: check.state))
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(check.title)
                            .font(.headline)
                        Text(check.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            if let sourceURL = URL(string: FederalResumeReview.sourceURL) {
                Link("Current USAJOBS résumé requirements", destination: sourceURL)
                    .font(.footnote.weight(.semibold))
            } else {
                Text("USAJOBS requirements link unavailable")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Source reviewed \(FederalResumeReview.sourceReviewedDate).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private func icon(for state: FederalCheckState) -> String {
        switch state {
        case .ready: "checkmark.circle.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .verify: "eye.circle.fill"
        }
    }

    private func color(for state: FederalCheckState) -> Color {
        switch state {
        case .ready: Brand.success
        case .attention: Brand.danger
        case .verify: Brand.gold
        }
    }
}
