import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ApplicationHandoffCard: View {
    let jobURL: String
    let finalResumeText: String
    let resumeFileURL: URL?

    @State private var copiedItem: String?

    private var platform: JobPlatform {
        JobPlatform.detect(from: jobURL)
    }

    private var destination: URL? {
        JobURLPolicy.normalize(jobURL).flatMap(URL.init(string:))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if platform == .indeed {
                indeedReadySummary
            }

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
                    Label(
                        platform == .indeed
                            ? "Open Indeed to review and submit"
                            : "Open original application",
                        systemImage: "arrow.up.right.square"
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.navySurface)
                .accessibilityHint(
                    platform == .indeed
                        ? "Leaves ApplyReady Vets and opens Indeed. Review every employer question before submitting."
                        : "Leaves ApplyReady Vets and opens the saved job link"
                )
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

            if let resumeFileURL {
                ShareLink(item: resumeFileURL) {
                    Label("Share reviewed resume file", systemImage: "square.and.arrow.up")
                }
            } else {
                ShareLink(item: finalResumeText) {
                    Label("Share final resume text", systemImage: "square.and.arrow.up")
                }
            }

            Text(
                platform == .indeed
                    ? "ApplyReady Vets prepares the packet locally. Indeed submission, screening answers, and any profile data stay under your control on Indeed."
                    : "No passwords are stored, no private page is scraped, and no application is submitted automatically."
            )
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
            if let resumeFileURL {
                ShareLink(item: resumeFileURL) {
                    Label("Share reviewed resume file", systemImage: "square.and.arrow.up")
                }
            } else {
                ShareLink(item: finalResumeText) {
                    Label("Share final resume text", systemImage: "square.and.arrow.up")
                }
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

    private var indeedReadySummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Indeed Ready", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Brand.success)
            Text("Your reviewed, evidence-backed resume is prepared for this posting.")
                .font(.subheadline)
                .foregroundStyle(Brand.navy)
            VStack(alignment: .leading, spacing: 6) {
                Label("Copy or share the reviewed resume", systemImage: "checkmark.circle.fill")
                Label("Open the saved Indeed posting", systemImage: "checkmark.circle.fill")
                Label("Review screening questions and submit yourself", systemImage: "person.crop.circle.badge.checkmark")
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(Brand.navy)
            Text("This is a preparation and handoff tool, not an Indeed bot or official Indeed integration.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Brand.success.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Indeed Ready. Your reviewed resume is prepared. Review screening questions and submit yourself on Indeed.")
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
