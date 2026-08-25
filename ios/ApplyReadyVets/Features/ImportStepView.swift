import SwiftUI
import UniformTypeIdentifiers

struct ImportStepView: View {
    @EnvironmentObject private var model: AppModel
    @State private var importsResume = false
    @State private var importsJob = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepIntroduction(
                    eyebrow: "Step 1 of 5",
                    title: "Bring your documents",
                    detail: "Import a resume and job posting, or paste their text. TXT, RTF, HTML, images, and PDFs—including scanned pages—are read privately on-device. For a Word DOCX file, export a PDF, RTF, or TXT copy first; originals are never overwritten."
                )

                #if DEBUG && targetEnvironment(simulator)
                VStack(alignment: .leading, spacing: 10) {
                    Label("Simulator Files workspace ready", systemImage: "folder.badge.gearshape")
                        .font(.headline)
                        .foregroundStyle(Brand.success)
                    Text("Choose a file below, then open \(UserDocumentWorkspace.filesLocationDescription) → Samples. Generated files appear in the neighboring Output folder.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.navy)
                    Text("Recents updates after files are opened or saved. Shared is an iCloud Drive view and requires an Apple Account with shared iCloud items.")
                        .font(.footnote)
                        .foregroundStyle(Brand.navy)
                }
                .cardStyle()
                #endif

                documentCard(
                    title: "Current resume",
                    icon: "doc.text",
                    filename: model.draft.resumeFilename,
                    text: limitedText(
                        $model.draft.resumeText,
                        kind: .resume
                    ),
                    importAction: { importsResume = true }
                )

                documentCard(
                    title: "Target job",
                    icon: "briefcase",
                    filename: model.draft.jobFilename,
                    text: limitedText(
                        $model.draft.jobText,
                        kind: .job
                    ),
                    importAction: { importsJob = true }
                )

                VStack(alignment: .leading, spacing: 10) {
                    LabeledTextField(
                        title: "Or save a job link",
                        prompt: "https://…",
                        maximumCharacters: CareerInputPolicy.Field.jobURL.maximumCharacters,
                        text: $model.jobURL
                    )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let normalizedJobLink {
                        let platform = JobPlatform.detect(from: normalizedJobLink)
                        Label("\(platform.label) link detected", systemImage: platform.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.navyLight)
                    } else if jobLinkIsInvalid {
                        Label(
                            JobURLPolicy.validationMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.danger)
                        .accessibilityIdentifier("currentJobURLValidationError")
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            jobLinkActions
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            jobLinkActions
                        }
                    }
                    .disabled(normalizedJobLink == nil)
                    Button(
                        model.draft.trackerRecordID == nil ? "Add to Job Tracker" : "Update tracked application",
                        systemImage: model.draft.trackerRecordID == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath"
                    ) {
                        model.saveCurrentJobToTracker()
                    }
                    .disabled(
                        jobLinkIsInvalid ||
                        (!hasJobLinkText &&
                         model.draft.jobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    )
                    Text(jobLinkHelpText)
                        .font(.footnote)
                        .foregroundStyle(Brand.navy)
                    Divider()
                    Label(
                        "From Safari or a job app, choose Share → Save to ApplyReady Vets. Shared text never replaces an existing posting without your approval.",
                        systemImage: "square.and.arrow.down"
                    )
                    .font(.footnote)
                    .foregroundStyle(Brand.navy)
                }
                .cardStyle()

                if !model.importReviewWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Imported text needs your review", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(Brand.danger)
                        ForEach(model.importReviewWarnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.subheadline)
                        }
                        Text("Compare the imported text above with the original file, especially names, dates, numbers, codes, and any pages beyond the import limit.")
                            .font(.footnote)
                            .foregroundStyle(Brand.navy)
                        if model.hasAcknowledgedImportWarnings {
                            Label("You acknowledged these warnings.", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Brand.success)
                        } else {
                            Button("I reviewed the imported text and warnings", systemImage: "checkmark.shield") {
                                model.acknowledgeImportWarnings()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Brand.navySurface)
                        }
                    }
                    .cardStyle()
                }

                PrimaryActionButton(title: "Continue to profile", disabled: !model.canContinueFromImport) {
                    model.next()
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .fileImporter(
            isPresented: $importsResume,
            allowedContentTypes: DocumentImportService.supportedContentTypes
        ) { result in
            if case let .success(url) = result { Task { await model.importDocument(url: url, kind: .resume) } }
            if case let .failure(error) = result { model.errorMessage = error.localizedDescription }
        }
        .fileImporter(
            isPresented: $importsJob,
            allowedContentTypes: DocumentImportService.supportedContentTypes
        ) { result in
            if case let .success(url) = result { Task { await model.importDocument(url: url, kind: .job) } }
            if case let .failure(error) = result { model.errorMessage = error.localizedDescription }
        }
    }

    @ViewBuilder
    private var jobLinkActions: some View {
        Button("Save job link", systemImage: "bookmark") {
            model.saveJobLink()
        }
        #if DEBUG
        Button("Import readable page", systemImage: "arrow.down.doc") {
            Task { await model.importJobURL() }
        }
        #endif
    }

    private var jobLinkHelpText: String {
        #if DEBUG
        "Some job sites require sign-in or load content dynamically. Save the original link, then paste the posting text if the development page import cannot read it."
        #else
        "Job sites often require sign-in or load content dynamically. ApplyReady Vets saves the original link; paste the posting text above so it can be analyzed."
        #endif
    }

    private var hasJobLinkText: Bool {
        !model.jobURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var normalizedJobLink: String? {
        JobURLPolicy.normalize(model.jobURL)
    }

    private var jobLinkIsInvalid: Bool {
        hasJobLinkText && normalizedJobLink == nil
    }

    private func documentCard(
        title: String,
        icon: String,
        filename: String,
        text: Binding<String>,
        importAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon).font(.headline)
                Spacer()
                if !filename.isEmpty {
                    StatusPill(text: filename, systemImage: "checkmark")
                        .accessibilityLabel("Selected file: \(accessibleFilename(filename))")
                }
            }
            Button("Choose file", systemImage: "folder") { importAction() }
            Text("or paste text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.navy)
            TextEditor(text: text)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay { RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.25)) }
                .accessibilityLabel("\(title) text")
        }
        .cardStyle()
    }

    private func limitedText(
        _ text: Binding<String>,
        kind: CareerInputPolicy.Kind
    ) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                guard newValue.count <= kind.maximumCharacters else {
                    model.errorMessage = CareerInputPolicy.InputTooLarge(
                        kind: kind
                    ).localizedDescription
                    return
                }
                text.wrappedValue = newValue
            }
        )
    }

    private func accessibleFilename(_ filename: String) -> String {
        filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}
