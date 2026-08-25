import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct LinkedInKitView: View {
    @Environment(\.dismiss) private var dismiss
    let kit: LinkedInProfileKit
    @State private var copiedLabel: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StepIntroduction(
                        eyebrow: "Copy-ready career presence",
                        title: "LinkedIn Profile Kit",
                        detail: "Choose the language that sounds like you, verify it, then paste it into the matching LinkedIn section."
                    )

                    kitSection("Headline options", icon: "textformat") {
                        ForEach(Array(kit.headlineOptions.enumerated()), id: \.offset) { index, headline in
                            copyRow(label: "Headline \(index + 1)", text: headline)
                        }
                    }

                    kitSection("About", icon: "person.text.rectangle") {
                        Text(kit.aboutText).textSelection(.enabled)
                        CopyButton(label: "About", text: kit.aboutText, copiedLabel: $copiedLabel)
                    }

                    kitSection("Skills to verify", icon: "checkmark.seal") {
                        Text(kit.skills.joined(separator: " • "))
                            .textSelection(.enabled)
                        CopyButton(label: "Skills", text: kit.skills.joined(separator: "\n"), copiedLabel: $copiedLabel)
                    }

                    kitSection("Experience highlights", icon: "briefcase") {
                        ForEach(kit.experienceHighlights, id: \.self) { Text("• \($0)").textSelection(.enabled) }
                    }

                    kitSection("Networking messages", icon: "person.2") {
                        copyRow(label: "Connection message", text: kit.connectionMessage)
                        Divider()
                        copyRow(label: "Recruiter message", text: kit.recruiterMessage)
                    }

                    kitSection("Profile checklist", icon: "checklist") {
                        ForEach(kit.checklist, id: \.self) { Text("• \($0)") }
                    }

                    ShareLink(item: fullText) {
                        Label("Share LinkedIn copy", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        Brand.navySurface,
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                    Text(kit.disclaimer).font(.footnote).foregroundStyle(Brand.navy)
                }
                .padding(20)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(BrandBackground())
            .navigationTitle("LinkedIn Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .safeAreaInset(edge: .bottom) {
                if let copiedLabel {
                    Label("\(copiedLabel) copied", systemImage: "doc.on.doc.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.success)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                }
            }
        }
        .sensoryFeedback(.success, trigger: copiedLabel)
    }

    @ViewBuilder
    private func kitSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.title3.bold())
            content()
        }
        .cardStyle()
    }

    private func copyRow(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption.weight(.bold)).foregroundStyle(Brand.navyLight)
            Text(text).textSelection(.enabled)
            CopyButton(label: label, text: text, copiedLabel: $copiedLabel)
        }
    }

    private var fullText: String {
        (["HEADLINES"] + kit.headlineOptions + [
            "", "ABOUT", kit.aboutText,
            "", "SKILLS", kit.skills.joined(separator: "\n"),
            "", "EXPERIENCE HIGHLIGHTS", kit.experienceHighlights.joined(separator: "\n"),
            "", "CONNECTION MESSAGE", kit.connectionMessage,
            "", "RECRUITER MESSAGE", kit.recruiterMessage,
        ]).joined(separator: "\n")
    }
}

private struct CopyButton: View {
    let label: String
    let text: String
    @Binding var copiedLabel: String?

    var body: some View {
        Button("Copy", systemImage: "doc.on.doc") {
            UIPasteboard.general.setItems(
                [[UTType.utf8PlainText.identifier: text]],
                options: [
                    .localOnly: true,
                    .expirationDate: Date().addingTimeInterval(10 * 60),
                ]
            )
            copiedLabel = label
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Copies \(label) to the clipboard")
    }
}
