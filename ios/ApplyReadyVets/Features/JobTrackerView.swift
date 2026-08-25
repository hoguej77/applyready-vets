import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct JobTrackerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var searchText = ""
    @State private var statusFilter: JobApplicationStatus?
    @State private var showsNewApplication = false

    var body: some View {
        NavigationStack {
            Group {
                if model.jobApplications.isEmpty {
                    JobTrackerEmptyState {
                        if model.requestNewApplicationWorkspace() {
                            showsNewApplication = true
                        }
                    }
                } else {
                    List {
                        Section {
                            TrackerSummaryCard(records: model.jobApplications)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }

                        Section(statusFilter.map { "\($0.label) applications" } ?? "All applications") {
                            ForEach(filteredApplications) { record in
                                NavigationLink {
                                    JobApplicationDetailView(applicationID: record.id)
                                } label: {
                                    JobApplicationRow(record: record)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        model.deleteJobApplication(id: record.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Employer, role, job ID, or notes"
                    )
                }
            }
            .navigationTitle("Applications")
            .toolbar {
                if !model.jobApplications.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                statusFilter = nil
                            } label: {
                                if statusFilter == nil {
                                    Label("All statuses", systemImage: "checkmark")
                                } else {
                                    Text("All statuses")
                                }
                            }
                            ForEach(JobApplicationStatus.allCases) { status in
                                Button {
                                    statusFilter = status
                                } label: {
                                    if statusFilter == status {
                                        Label(status.label, systemImage: "checkmark")
                                    } else {
                                        Label(status.label, systemImage: status.systemImage)
                                    }
                                }
                            }
                        } label: {
                            Label(
                                statusFilter?.label ?? "Filter",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add application", systemImage: "plus") {
                        if model.requestNewApplicationWorkspace() {
                            showsNewApplication = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showsNewApplication) {
                JobApplicationEditor { record in
                    if model.upsertJobApplication(record) {
                        showsNewApplication = false
                    }
                }
            }
            .navigationDestination(item: $model.selectedTrackedApplicationID) { id in
                JobApplicationDetailView(applicationID: id)
            }
        }
    }

    private var filteredApplications: [JobApplicationRecord] {
        model.jobApplications.filter { record in
            let matchesStatus = statusFilter == nil || record.status == statusFilter
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return matchesStatus }
            let searchable = [
                record.employer,
                record.roleTitle,
                record.jobID,
                record.notes,
                record.platform.label,
            ].joined(separator: " ")
            return matchesStatus && searchable.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct JobTrackerEmptyState: View {
    let addApplication: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "briefcase")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Brand.primary)
                    .accessibilityHidden(true)
                Text("No applications yet")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("Save a job from LinkedIn, Indeed, Workday, USAJOBS, or an employer site. Keep its deadline, notes, status, and packet history together.")
                    .font(.body)
                    .foregroundStyle(Brand.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: addApplication) {
                    Label("Add an application", systemImage: "plus")
                        .font(.headline)
                        .labelStyle(.titleAndIcon)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Brand.navySurface)
            }
            .frame(maxWidth: 440)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}

private struct TrackerSummaryCard: View {
    let records: [JobApplicationRecord]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 16
                ) {
                    summaryMetrics
                }
            } else {
                HStack(spacing: 12) {
                    metric("Active", activeCount, "hourglass")
                    Divider()
                    metric("Applied", appliedCount, "paperplane")
                    Divider()
                    metric("Interviews", interviewCount, "person.2")
                    Divider()
                    metric("Offers", offerCount, "checkmark.seal")
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var summaryMetrics: some View {
        metric("Active", activeCount, "hourglass")
        metric("Applied", appliedCount, "paperplane")
        metric("Interviews", interviewCount, "person.2")
        metric("Offers", offerCount, "checkmark.seal")
    }

    private var activeCount: Int {
        records.filter(\.status.isActive).count
    }

    private var appliedCount: Int {
        records.filter { $0.status == .applied }.count
    }

    private var interviewCount: Int {
        records.filter { $0.status == .interviewing }.count
    }

    private var offerCount: Int {
        records.filter { [.offer, .accepted].contains($0.status) }.count
    }

    private func metric(_ title: String, _ value: Int, _ icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(Brand.navyLight)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.title3.monospacedDigit().bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

private struct JobApplicationRow: View {
    let record: JobApplicationRecord
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.displayTitle)
                        .font(.headline)
                    Text(record.displayEmployer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label(record.status.label, systemImage: record.status.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.navyLight)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.displayTitle)
                            .font(.headline)
                        Text(record.displayEmployer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label(record.status.label, systemImage: record.status.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.navyLight)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    applicationMetadata
                }
                VStack(alignment: .leading, spacing: 5) {
                    applicationMetadata
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var applicationMetadata: some View {
        Label(record.platform.label, systemImage: record.platform.systemImage)
        if let deadline = record.deadline {
            Label {
                Text(deadline, style: .date)
            } icon: {
                Image(systemName: "calendar")
            }
        }
        if !record.packetVersions.isEmpty {
            Label("\(record.packetVersions.count)", systemImage: "doc.on.doc")
        }
        if !record.statusEvidence.isEmpty {
            Label("\(record.statusEvidence.count)", systemImage: "photo")
        }
    }
}

private struct PacketFileShareRow: View {
    let label: String
    let filename: String
    var isPrivate = false

    var body: some View {
        if let url = UserDocumentWorkspace.existingOutputFile(
            named: filename
        ) {
            ShareLink(item: url) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                        Text(filename)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(
                        systemName: isPrivate
                            ? "lock.doc"
                            : "square.and.arrow.up"
                    )
                }
            }
        } else {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                    Text("\(filename) is no longer in Files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "doc.badge.exclamationmark")
            }
        }
    }
}

struct JobApplicationDetailView: View {
    @EnvironmentObject private var model: AppModel
    let applicationID: UUID

    @State private var showsEditor = false
    @State private var confirmsDeletion = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let record {
                List {
                    Section("Application") {
                        LabeledContent("Employer", value: record.displayEmployer)
                        LabeledContent("Role", value: record.displayTitle)
                        LabeledContent("Source", value: record.platform.label)
                        if !record.jobID.isEmpty {
                            LabeledContent("Job ID", value: record.jobID)
                        }
                        if let destination = JobURLPolicy.normalize(record.sourceURL).flatMap(URL.init(string:)) {
                            Link(destination: destination) {
                                Label("Open original posting", systemImage: "arrow.up.right.square")
                            }
                        }
                    }

                    Section("Progress") {
                        Picker(
                            "Status",
                            selection: Binding(
                                get: { record.status },
                                set: { model.updateJobApplicationStatus(id: record.id, status: $0) }
                            )
                        ) {
                            ForEach(JobApplicationStatus.allCases) { status in
                                Label(status.label, systemImage: status.systemImage).tag(status)
                            }
                        }
                        if let deadline = record.deadline {
                            LabeledContent("Deadline") {
                                Text(deadline.formatted(date: .abbreviated, time: .omitted))
                            }
                        } else {
                            LabeledContent("Deadline", value: "Not set")
                        }
                    }

                    StatusEvidenceSection(record: record)

                    if !record.requiredDocuments.isEmpty {
                        Section("Required documents") {
                            ForEach(record.requiredDocuments, id: \.self) { document in
                                Label(document, systemImage: "doc")
                            }
                        }
                    }

                    Section("Notes") {
                        Text(record.notes.isEmpty ? "No notes yet." : record.notes)
                            .foregroundStyle(record.notes.isEmpty ? .secondary : .primary)
                    }

                    Section("Packet versions") {
                        if record.packetVersions.isEmpty {
                            Text("Create an export from the Builder to attach version 1.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(record.packetVersions.sorted { $0.number > $1.number }) { version in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Version \(version.number)")
                                        .font(.headline)
                                    PacketFileShareRow(
                                        label: "Employer PDF or résumé",
                                        filename: version.resumeFilename
                                    )
                                    if let richText = version.richTextFilename {
                                        PacketFileShareRow(
                                            label: "Editable RTF",
                                            filename: richText
                                        )
                                    }
                                    if let plainText = version.plainTextFilename {
                                        PacketFileShareRow(
                                            label: "Parser-safe TXT",
                                            filename: plainText
                                        )
                                    }
                                    if let privateReview = version.privateReviewFilename {
                                        PacketFileShareRow(
                                            label: "Private candidate review",
                                            filename: privateReview,
                                            isPrivate: true
                                        )
                                    }
                                    Text(version.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .contain)
                            }
                        }
                    }

                    Section {
                        Button("Prepare this job in Builder", systemImage: "doc.badge.plus") {
                            model.startWorkspace(for: record.id)
                        }
                        Button("Delete application", systemImage: "trash", role: .destructive) {
                            confirmsDeletion = true
                        }
                    } footer: {
                        Text("ApplyReady Vets never submits an application or stores a job-site password.")
                    }
                }
                .navigationTitle(record.displayTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { showsEditor = true }
                    }
                }
                .sheet(isPresented: $showsEditor) {
                    JobApplicationEditor(record: record) { updated in
                        if model.upsertJobApplication(updated) {
                            showsEditor = false
                        }
                    }
                }
                .confirmationDialog(
                    "Delete this application?",
                    isPresented: $confirmsDeletion,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        model.deleteJobApplication(id: record.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes its status, notes, deadlines, and packet history from this device. Exported files in Files are not removed.")
                }
            } else {
                ContentUnavailableView("Application unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var record: JobApplicationRecord? {
        model.jobApplications.first { $0.id == applicationID }
    }
}

private struct StatusEvidenceSection: View {
    @EnvironmentObject private var model: AppModel
    let record: JobApplicationRecord

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsFileImporter = false
    @State private var isSaving = false

    var body: some View {
        Section {
            if record.statusEvidence.isEmpty {
                ContentUnavailableView {
                    Label("No status images", systemImage: "photo.badge.plus")
                } description: {
                    Text("Save a portal confirmation, interview invite, or other visual reference privately with this application.")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(record.statusEvidence.sorted { $0.createdAt > $1.createdAt }) { evidence in
                    NavigationLink {
                        JobStatusEvidencePreview(
                            evidence: evidence,
                            applicationID: record.id
                        )
                    } label: {
                        StatusEvidenceRow(
                            evidence: evidence,
                            applicationID: record.id
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            _ = model.removeJobStatusEvidence(
                                evidence,
                                from: record.id
                            )
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                preferredItemEncoding: .compatible
            ) {
                Label("Add photo or screenshot", systemImage: "photo.badge.plus")
            }
            .disabled(additionIsUnavailable)

            Button("Choose image from Files", systemImage: "folder") {
                showsFileImporter = true
            }
            .disabled(additionIsUnavailable)
        } header: {
            Text("Status evidence")
        } footer: {
            if record.statusEvidence.count >= PrivateImageStore.maximumStatusEvidencePerApplication {
                Text("You can keep up to \(PrivateImageStore.maximumStatusEvidencePerApplication) status images for one application.")
            } else {
                Text("Images stay on this device unless you explicitly share them. Review every image before sharing it with anyone.")
            }
        }
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    importImageFile(url)
                }
            case let .failure(error):
                model.errorMessage = "The image could not be selected: \(error.localizedDescription)"
            }
        }
        .onChange(of: selectedPhoto) { _, selection in
            guard let selection else { return }
            Task {
                await importSelectedPhoto(selection)
            }
        }
    }

    private var additionIsUnavailable: Bool {
        isSaving ||
            record.statusEvidence.count >= PrivateImageStore.maximumStatusEvidencePerApplication
    }

    @MainActor
    private func importSelectedPhoto(_ selection: PhotosPickerItem) async {
        isSaving = true
        defer {
            isSaving = false
            selectedPhoto = nil
        }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw PrivateImageStore.StoreError.imageUnreadable
            }
            saveStatusEvidence(data)
        } catch {
            model.errorMessage = "The selected photo could not be saved: \(error.localizedDescription)"
        }
    }

    private func importImageFile(_ url: URL) {
        isSaving = true
        defer { isSaving = false }
        let wasAccessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if wasAccessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            saveStatusEvidence(try Data(contentsOf: url, options: [.mappedIfSafe]))
        } catch {
            model.errorMessage = "The chosen image could not be saved: \(error.localizedDescription)"
        }
    }

    private func saveStatusEvidence(_ data: Data) {
        do {
            let evidence = try PrivateImageStore.saveStatusEvidence(
                data,
                applicationID: record.id
            )
            guard model.addJobStatusEvidence(evidence, to: record.id) else {
                try? PrivateImageStore.removeStatusEvidence(
                    evidence,
                    applicationID: record.id
                )
                return
            }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}

private struct StatusEvidenceRow: View {
    let evidence: JobStatusEvidence
    let applicationID: UUID

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = PrivateImageStore.statusEvidenceImage(
                    for: evidence,
                    applicationID: applicationID
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 42)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Status image")
                    .font(.headline)
                Text(evidence.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct JobStatusEvidencePreview: View {
    let evidence: JobStatusEvidence
    let applicationID: UUID

    var body: some View {
        Group {
            if let image = PrivateImageStore.statusEvidenceImage(
                for: evidence,
                applicationID: applicationID
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Saved job status image")
                        Text("Saved \(evidence.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let url = PrivateImageStore.statusEvidenceURL(
                            for: evidence,
                            applicationID: applicationID
                        ) {
                            ShareLink(item: url) {
                                Label("Share image", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView(
                    "Status image unavailable",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("The protected image file could not be found on this device.")
                )
            }
        }
        .navigationTitle("Status image")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct JobApplicationEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: JobApplicationRecord
    @State private var hasDeadline: Bool
    @State private var requiredDocumentsText: String

    let onSave: (JobApplicationRecord) -> Void

    init(
        record: JobApplicationRecord? = nil,
        onSave: @escaping (JobApplicationRecord) -> Void
    ) {
        let initial = record ?? JobApplicationRecord()
        _draft = State(initialValue: initial)
        _hasDeadline = State(initialValue: initial.deadline != nil)
        _requiredDocumentsText = State(initialValue: initial.requiredDocuments.joined(separator: "\n"))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Opportunity") {
                    TextField(
                        "Employer",
                        text: limited($draft.employer, field: .employer)
                    )
                        .textContentType(.organizationName)
                    TextField(
                        "Role title",
                        text: limited($draft.roleTitle, field: .roleTitle)
                    )
                    TextField(
                        "Job ID",
                        text: limited($draft.jobID, field: .jobID)
                    )
                    TextField(
                        "Job posting URL",
                        text: limited($draft.sourceURL, field: .jobURL)
                    )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .onChange(of: draft.sourceURL) { _, value in
                            if JobURLPolicy.normalize(value) != nil {
                                draft.platform = JobPlatform.detect(from: value)
                            }
                        }
                    if sourceURLIsInvalid {
                        Label(
                            JobURLPolicy.validationMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.danger)
                        .accessibilityIdentifier("trackerJobURLValidationError")
                    }
                    Picker("Source", selection: $draft.platform) {
                        ForEach(JobPlatform.allCases) { platform in
                            Label(platform.label, systemImage: platform.systemImage).tag(platform)
                        }
                    }
                    Picker("Status", selection: $draft.status) {
                        ForEach(JobApplicationStatus.allCases) { status in
                            Label(status.label, systemImage: status.systemImage).tag(status)
                        }
                    }
                }

                Section("Deadline") {
                    Toggle("This posting has a deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker(
                            "Application deadline",
                            selection: Binding(
                                get: { draft.deadline ?? Calendar.current.date(byAdding: .day, value: 14, to: Date())! },
                                set: { draft.deadline = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }

                Section("Required documents") {
                    TextEditor(
                        text: limited(
                            $requiredDocumentsText,
                            maximumCharacters:
                                CareerInputPolicy.maximumRequiredDocuments *
                                (CareerInputPolicy.Field.requiredDocument.maximumCharacters + 1)
                        )
                    )
                        .frame(minHeight: 90)
                        .accessibilityLabel("Required documents")
                        .accessibilityHint("Enter one requested document per line")
                    Text("Enter one item per line, such as résumé, transcript, DD-214, SF-50, or Schedule A letter. Only include documents the announcement actually requests.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Private notes") {
                    TextEditor(
                        text: limited($draft.notes, field: .trackerNotes)
                    )
                        .frame(minHeight: 130)
                        .accessibilityLabel("Private notes")
                        .accessibilityHint("Enter notes about this application")
                }
            }
            .navigationTitle(draft.createdAt == draft.updatedAt ? "New application" : "Edit application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.deadline = hasDeadline ? (draft.deadline ?? Date()) : nil
                        draft.requiredDocuments = requiredDocumentsText
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        onSave(draft)
                    }
                    .disabled(
                        sourceURLIsInvalid ||
                        (draft.employer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                         draft.roleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    )
                }
            }
        }
    }

    private var sourceURLIsInvalid: Bool {
        let enteredURL = draft.sourceURL.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return !enteredURL.isEmpty && JobURLPolicy.normalize(enteredURL) == nil
    }

    private func limited(
        _ text: Binding<String>,
        field: CareerInputPolicy.Field
    ) -> Binding<String> {
        limited(text, maximumCharacters: field.maximumCharacters)
    }

    private func limited(
        _ text: Binding<String>,
        maximumCharacters: Int
    ) -> Binding<String> {
        Binding(
            get: { text.wrappedValue },
            set: { newValue in
                guard newValue.count <= maximumCharacters else { return }
                text.wrappedValue = newValue
            }
        )
    }
}
