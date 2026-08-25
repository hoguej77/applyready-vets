import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ApplicationHandoffCard: View {
    let jobURL: String
    let finalResumeText: String

    @State private var copiedItem: String?

    private var platform: JobPlatform {
        JobPlatform.detect(from: jobURL)
    }

    private var destination: URL? {
        JobURLPolicy.normalize(jobURL).flatMap(URL.init(string:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: platform.systemImage)
                    .font(.title2)
                    .foregroundStyle(Brand.navyLight)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Finish on \(platform.label)")
                        .font(.title3.bold())
                    Text("ApplyReady Vets prepares the evidence-backed material. You review and submit it on the official site.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.navy)
                }
            }

            if let destination {
                Link(destination: destination) {
                    Label("Open original application", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.navySurface)
                .accessibilityHint("Leaves ApplyReady Vets and opens the saved job link")
            }

            ViewThatFits(in: .horizontal) {
                HStack {
                    copyActions
                }
                VStack(alignment: .leading, spacing: 10) {
                    copyActions
                }
            }
            .buttonStyle(.bordered)

            ShareLink(item: finalResumeText) {
                Label("Share final resume text", systemImage: "square.and.arrow.up")
            }

            Text("No passwords are stored, no private page is scraped, and no application is submitted automatically.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.navyLight)
            Text("Clipboard copies stay on this device and expire after 10 minutes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
        .contextMenu {
            if let destination {
                Link(destination: destination) {
                    Label("Open original application", systemImage: "arrow.up.right.square")
                }
            }
            Button("Copy final resume", systemImage: "doc.on.doc") {
                copyResume()
            }
            Button("Copy job link", systemImage: "link") {
                copyJobLink()
            }
            ShareLink(item: finalResumeText) {
                Label("Share final resume text", systemImage: "square.and.arrow.up")
            }
        }
        .sensoryFeedback(.success, trigger: copiedItem)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var copyActions: some View {
        Button("Copy final resume", systemImage: copiedItem == "resume" ? "checkmark" : "doc.on.doc") {
            copyResume()
        }
        Button("Copy job link", systemImage: copiedItem == "link" ? "checkmark" : "link") {
            copyJobLink()
        }
    }

    private func copyResume() {
        copyPrivately(finalResumeText)
        copiedItem = "resume"
    }

    private func copyJobLink() {
        copyPrivately(jobURL)
        copiedItem = "link"
    }

    private func copyPrivately(_ text: String) {
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: text]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(10 * 60),
            ]
        )
    }
}
