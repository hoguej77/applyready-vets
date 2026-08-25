import SwiftUI

struct StepIntroduction: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption)
                .bold()
                .foregroundStyle(Brand.navyLight)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Brand.navy)
            Text(detail)
                .font(.body)
                .foregroundStyle(Brand.navy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryActionButton: View {
    let title: String
    var icon = "arrow.right"
    var disabled = false
    let action: () -> Void

    var body: some View {
        if disabled {
            // Disabled prominent controls intentionally reduce contrast, but
            // that can make the next step illegible. State the prerequisite
            // directly and restore the action as soon as it becomes valid.
            Label("Complete the required information to continue", systemImage: "info.circle")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Brand.secondaryText)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("(title) is unavailable until required information is complete")
        } else {
            Button(action: action) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // A filled action needs one fixed, high-contrast tint because SwiftUI
            // uses white foreground content for the prominent control in both
            // appearances. Keep the adaptive blue for links and text elsewhere.
            .tint(Brand.navySurface)
        }
    }
}

struct LabeledTextField: View {
    let title: String
    var prompt = ""
    var maximumCharacters: Int?
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.semibold))
            TextField(prompt, text: boundedText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(title)
        }
    }

    private var boundedText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                guard maximumCharacters.map({
                    newValue.count <= $0
                }) ?? true else { return }
                text = newValue
            }
        )
    }
}

struct ReadinessGauge: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value)%").monospacedDigit().font(.headline)
            }
            ProgressView(value: Double(value), total: 100)
                .tint(value >= 70 ? Brand.success : Brand.gold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value) percent")
    }
}

struct StatusPill: View {
    let text: String
    let systemImage: String
    var color: Color = Brand.navyLight

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.11), in: Capsule())
    }
}

struct BulletRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Brand.navyLight)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PathwayTile: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.navyLight)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Brand.navy)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Brand.navy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .cardStyle()
    }
}
