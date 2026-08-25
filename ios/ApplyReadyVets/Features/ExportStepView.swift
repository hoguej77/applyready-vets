import SwiftUI

struct ExportStepView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showsLinkedInKit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepIntroduction(
                    eyebrow: "Step 5 of 5",
                    title: "Create your candidate-reviewed resume",
                    detail: "Only suggestions you approved or edited are applied. The employer-facing resume stays separate from your private scores, gap questions, and review record."
                )

                if let response = model.currentResponse {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Application file contents").font(.title3.bold())
                        packetRow(icon: "doc.richtext", title: "Three employer-facing formats", detail: "PDF for presentation, editable RTF, and parser-safe TXT with identical candidate-reviewed wording")
                        packetRow(icon: "lock.shield", title: "Separate private review", detail: "Candidate-only scores, questions, warnings, and record for \(model.approvedCount) accepted changes")
                    }
                    .cardStyle()

                    AnalysisResultsSummary(response: response)

                    if model.effectiveResumeMode == .federal {
                        FederalReadinessCard(
                            resumeText: model.draft.resumeText,
                            profile: model.draft.profile,
                            details: model.draft.federalDetails
                        )
                    }

                    LinkedInFeatureCard(showsKit: $showsLinkedInKit)

                    if let jobURL = model.draft.jobURL,
                       !jobURL.isEmpty,
                       let reviewedResumeText = model.candidateReviewedResumeText {
                        ApplicationHandoffCard(
                            jobURL: jobURL,
                            finalResumeText: reviewedResumeText,
                            resumeFileURL: model.exportPDFURL ?? model.exportRichTextURL ?? model.exportURL
                        )
                    }

                    if !response.safetyFindings.isEmpty || !response.job.riskFlags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Review before applying", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline).foregroundStyle(Brand.danger)
                            ForEach(response.safetyFindings) { finding in Text("• \(finding.title): \(finding.detail)") }
                            ForEach(response.job.riskFlags, id: \.self) { flag in Text("• \(flag)") }
                        }
                        .font(.subheadline)
                        .cardStyle()
                    }

                    if let plainTextURL = model.exportURL {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Choose the format the employer requests")
                                .font(.title3.bold())
                            Text("All three contain the same reviewed resume. When a posting names a required format, follow that instruction.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let pdfURL = model.exportPDFURL {
                                EmployerFileShareRow(
                                    title: "PDF resume",
                                    detail: "Best for visual review and PDF uploads",
                                    icon: "doc.fill",
                                    url: pdfURL,
                                    isRecommended: true
                                )
                            }
                            if let richTextURL = model.exportRichTextURL {
                                EmployerFileShareRow(
                                    title: "Editable RTF resume",
                                    detail: "Opens in Pages and Microsoft Word",
                                    icon: "doc.richtext",
                                    url: richTextURL
                                )
                            }
                            EmployerFileShareRow(
                                title: "Parser-safe TXT resume",
                                detail: "Best for copying into application fields",
                                icon: "text.document",
                                url: plainTextURL
                            )
                        }
                        .cardStyle()

                        if let privateReviewURL = model.privateReviewURL {
                            ShareLink(item: privateReviewURL) {
                                Label("Save or share my private review report", systemImage: "lock.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            Text("Keep the private report for yourself. Do not upload it as a resume or send it to an employer.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.danger)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Saved in Files", systemImage: "folder.fill")
                                .font(.headline)
                                .foregroundStyle(Brand.success)
                            Text("\(UserDocumentWorkspace.filesLocationDescription) → Output")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.navy)
                            Text("The three employer files and private review are separate. The buttons above open Apple’s Share Sheet, including Save to Files, AirDrop, Mail, and other installed destinations.")
                                .font(.footnote)
                                .foregroundStyle(Brand.navy)
                        }
                        .cardStyle()
                    } else {
                        PrimaryActionButton(title: "Create application files", icon: "checkmark.shield.fill") {
                            Task { await model.exportPacket() }
                        }
                    }

                    Text("Before submitting, compare the export with the job announcement and verify every date, number, credential, veteran status, accommodation statement, clearance statement, school request, and eligibility claim.")
                        .font(.footnote)
                        .foregroundStyle(Brand.navy)
                } else {
                    ContentUnavailableView("Nothing to export", systemImage: "shippingbox", description: Text("Complete an analysis first."))
                        .cardStyle()
                }

                Button("Back") { model.back() }.buttonStyle(.bordered)
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showsLinkedInKit) {
            if let kit = model.linkedInKit {
                LinkedInKitView(kit: kit)
            }
        }
    }

    private func packetRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(Brand.gold).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

private struct EmployerFileShareRow: View {
    let title: String
    let detail: String
    let icon: String
    let url: URL
    var isRecommended = false

    var body: some View {
        ShareLink(item: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Brand.navyLight)
                    .frame(width: 40, height: 40)
                    .background(
                        Brand.navyLight.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Brand.success)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Brand.success.opacity(0.10),
                                    in: Capsule()
                                )
                        }
                    }
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Brand.navyLight)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Apple’s Share Sheet for \(url.lastPathComponent)")
    }
}

private struct LinkedInFeatureCard: View {
    @EnvironmentObject private var model: AppModel
    @Binding var showsKit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Special feature", systemImage: "person.text.rectangle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Brand.navyLight)
                    Text("LinkedIn Profile Builder").font(.title3.bold())
                }
                Spacer()
                StatusPill(text: "Candidate review", systemImage: "checkmark.shield")
            }
            Text("Create copy-ready headline options, About text, skills to verify, experience highlights, networking messages, and a privacy checklist.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("The app never signs in to LinkedIn and never publishes for you.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.navyLight)

            if model.linkedInKit == nil {
                Button("Create my LinkedIn kit", systemImage: "text.badge.checkmark") {
                    Task { await model.buildLinkedInKit() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.navySurface)
            } else {
                Button("Open LinkedIn kit", systemImage: "doc.text.magnifyingglass") {
                    showsKit = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.navySurface)
            }
        }
        .cardStyle()
    }
}
