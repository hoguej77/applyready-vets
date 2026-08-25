import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsSettings = false
    @State private var showsNewApplication = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    pageHeading
                    nextActionPanel
                    prioritySection
                    applicationsSection
                    if !model.jobApplications.isEmpty {
                        pipelineSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(BrandBackground())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "person.crop.circle") {
                        showsSettings = true
                    }
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .environmentObject(model)
            }
            .sheet(isPresented: $showsNewApplication) {
                JobApplicationEditor { record in
                    if model.upsertJobApplication(record) {
                        showsNewApplication = false
                    }
                }
            }
        }
        .tint(Brand.navyLight)
    }

    private var pageHeading: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(greeting)
                .font(.title.bold())
                .foregroundStyle(Brand.navy)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .accessibilityHidden(true)
                Text(profileContext)
            }
            .font(.subheadline)
            .foregroundStyle(Brand.navy)
        }
    }

    private var nextActionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    nextUpLabel
                    stepLabel
                }
            } else {
                HStack {
                    nextUpLabel
                    Spacer()
                    stepLabel
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                if let activeWorkspaceRecord {
                    Text("\(activeWorkspaceRecord.displayTitle) · \(activeWorkspaceRecord.displayEmployer)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.secondaryText)
                        .lineLimit(2)
                }
                Text(nextActionTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text(nextActionDetail)
                    .font(.subheadline)
                    .foregroundStyle(Brand.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ProgressView(value: workflowProgress)
                .tint(Brand.primary)
                .accessibilityHidden(true)
                .allowsHitTesting(false)

            Button {
                model.selectedMainSection = .builder
            } label: {
                Label(
                    model.step == .importDocuments ? "Open workspace" : "Continue workspace",
                    systemImage: "arrow.right"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Brand.navySurface)
        }
        .padding(18)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Pipeline", actionTitle: "See all") {
                model.selectedMainSection = .tracker
            }

            pipelineMetrics
            .padding(.vertical, 14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
    }

    @ViewBuilder
    private var prioritySection: some View {
        if !priorityApplications.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("Due soon", actionTitle: "See all") {
                    model.selectedMainSection = .tracker
                }
                ForEach(priorityApplications.prefix(3)) { record in
                    NavigationLink {
                        JobApplicationDetailView(applicationID: record.id)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: urgencySymbol(for: record))
                                .font(.headline)
                                .foregroundStyle(urgencyColor(for: record))
                                .frame(width: 36, height: 36)
                                .background(
                                    urgencyColor(for: record).opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 9)
                                )
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(record.displayEmployer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let deadline = record.deadline {
                                    Text(deadlineText(deadline))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(urgencyColor(for: record))
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(14)
                        .background(
                            Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var pipelineMetrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(pipelineItems, id: \.label) { item in
                    pipelineMetric(value: item.value, label: item.label)
                }
            }
            .padding(.horizontal, 8)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(pipelineItems.enumerated()), id: \.element.label) { index, item in
                    pipelineMetric(value: item.value, label: item.label)
                    if index < pipelineItems.count - 1 {
                        Divider().frame(height: 34)
                    }
                }
            }
        }
    }

    private var pipelineItems: [(label: String, value: Int)] {
        [
            (
                "Active",
                model.jobApplications.filter(\.status.isActive).count
            ),
            (
                "Applied",
                model.jobApplications.filter { $0.status == .applied }.count
            ),
            (
                "Interviews",
                model.jobApplications.filter { $0.status == .interviewing }.count
            ),
            (
                "Offers",
                model.jobApplications.filter {
                    [.offer, .accepted].contains($0.status)
                }.count
            )
        ]
    }

    @ViewBuilder
    private var applicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Applications")

            if model.jobApplications.isEmpty {
                Button {
                    if model.requestNewApplicationWorkspace() {
                        showsNewApplication = true
                    }
                } label: {
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 8) {
                                applicationButtonCopy
                                Text("Add application")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.navyLight)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(Brand.navyLight)
                                    .frame(width: 38, height: 38)
                                    .background(
                                        Brand.navyLight.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .accessibilityHidden(true)
                                applicationButtonCopy
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(minHeight: 66)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dashboardApplications.prefix(3).enumerated()), id: \.element.id) { index, record in
                        NavigationLink {
                            JobApplicationDetailView(applicationID: record.id)
                        } label: {
                            DashboardApplicationRow(record: record)
                        }
                        .buttonStyle(.plain)

                        if index < min(dashboardApplications.count, 3) - 1 {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        }
    }

    private func sectionHeading(
        _ title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    sectionTitle(title)
                    if let actionTitle, let action {
                        sectionAction(actionTitle, action: action)
                    }
                }
            } else {
                HStack {
                    sectionTitle(title)
                    Spacer()
                    if let actionTitle, let action {
                        sectionAction(actionTitle, action: action)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Brand.navy)
    }

    private func sectionAction(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }

    private var nextUpLabel: some View {
        Text("NEXT UP")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.82))
    }

    private var stepLabel: some View {
        Text("Step \(model.step.rawValue + 1) of \(AppModel.FlowStep.allCases.count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
    }

    private var applicationButtonCopy: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Add your first application")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Save the job, deadline, notes, and packet versions")
                .font(.caption)
                .foregroundStyle(Brand.navy)
        }
    }

    private func pipelineMetric(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(Brand.navy)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.navy)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        model.activePreferredName.map { "Welcome, \($0)" }
            ?? "Your next move starts here"
    }

    private var profileContext: String {
        guard let profile = model.activeHouseholdProfile else {
            return "Private on this device"
        }
        return "\(profile.relationship.label) · \(profile.assistanceLevel.shortTitle) · Private profile"
    }

    private var activeWorkspaceRecord: JobApplicationRecord? {
        guard let id = model.draft.trackerRecordID else { return nil }
        return model.jobApplications.first { $0.id == id }
    }

    private var dashboardApplications: [JobApplicationRecord] {
        model.jobApplications.sorted { left, right in
            switch (left.deadline, right.deadline) {
            case let (leftDate?, rightDate?):
                if left.status.isActive != right.status.isActive {
                    return left.status.isActive
                }
                return leftDate == rightDate
                    ? left.updatedAt > right.updatedAt
                    : leftDate < rightDate
            case (_?, nil):
                return left.status.isActive
            case (nil, _?):
                return !right.status.isActive
            case (nil, nil):
                return left.updatedAt > right.updatedAt
            }
        }
    }

    private var priorityApplications: [JobApplicationRecord] {
        let start = Calendar.current.startOfDay(for: Date())
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: 14,
            to: start
        ) ?? start
        return model.jobApplications
            .filter {
                $0.status.isActive &&
                ($0.deadline.map { $0 < cutoff } ?? false)
            }
            .sorted {
                ($0.deadline ?? .distantFuture) <
                    ($1.deadline ?? .distantFuture)
            }
    }

    private func deadlineText(_ deadline: Date) -> String {
        let start = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: deadline)
        let days = Calendar.current.dateComponents(
            [.day],
            from: start,
            to: target
        ).day ?? 0
        switch days {
        case ..<0:
            return "Deadline passed \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago"
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        default:
            return "Due in \(days) days · \(deadline.formatted(date: .abbreviated, time: .omitted))"
        }
    }

    private func urgencyColor(for record: JobApplicationRecord) -> Color {
        guard let deadline = record.deadline else { return Brand.navyLight }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: deadline)
        ).day ?? 14
        return days <= 3 ? Brand.danger : Brand.gold
    }

    private func urgencySymbol(for record: JobApplicationRecord) -> String {
        guard let deadline = record.deadline else { return "calendar" }
        return deadline < Calendar.current.startOfDay(for: Date())
            ? "exclamationmark.triangle.fill"
            : "calendar.badge.clock"
    }

    private var workflowProgress: Double {
        Double(model.step.rawValue + 1) / Double(AppModel.FlowStep.allCases.count)
    }

    private var nextActionTitle: String {
        switch model.step {
        case .importDocuments: "Add the job and your resume"
        case .serviceProfile: "Confirm your career profile"
        case .analyze: "Check this application"
        case .review: "Review every suggested change"
        case .export: "Finish your application packet"
        }
    }

    private var nextActionDetail: String {
        switch model.step {
        case .importDocuments:
            "Start with the exact posting so every recommendation has a real target."
        case .serviceProfile:
            "Add only the service and career context that belongs in this application."
        case .analyze:
            "See separate evidence, content, federal, and formatting readiness checks."
        case .review:
            "Keep, edit, or reject each proposal before it can reach your resume."
        case .export:
            "Save your reviewed files and attach this version to the tracked job."
        }
    }
}

private struct DashboardApplicationRow: View {
    let record: JobApplicationRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.platform.systemImage)
                .font(.headline)
                .foregroundStyle(Brand.navyLight)
                .frame(width: 36, height: 36)
                .background(
                    Brand.navyLight.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(record.displayEmployer)
                    .font(.caption)
                    .foregroundStyle(Brand.navy)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(record.status.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.navyLight)
                if let deadline = record.deadline {
                    Text(deadline, style: .date)
                        .font(.caption2)
                        .foregroundStyle(Brand.navy)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 62)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct CareerToolkitView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var searchText = ""
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            List {
                if dynamicTypeSize.isAccessibilitySize {
                    Section {
                        TextField("Search tools and official help", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if matches("military occupation MOS AFSC rating O*NET translate experience") {
                    Section {
                        toolkitGroupHeader("Translate your experience")
                        NavigationLink {
                            MilitaryCrosswalkView(
                                serviceEntries: model.draft.profile.militaryService
                            )
                        } label: {
                            toolRow(
                                title: "Military career crosswalk",
                                detail: "12,921 offline mappings from O*NET’s August 2024 release",
                                icon: "arrow.triangle.branch"
                            )
                        }
                    }
                }

                if matches("civilian federal USAJOBS resume LinkedIn profile writing") {
                    Section {
                        toolkitGroupHeader("Build for the destination")
                        if matches("civilian resume writing") {
                            Button {
                                _ = model.beginNewApplication(mode: .civilian)
                            } label: {
                                toolRow(
                                    title: "Civilian application",
                                    detail: "Tailor evidence to one real posting",
                                    icon: "building.2"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if matches("federal USAJOBS resume") {
                            Button {
                                _ = model.beginNewApplication(mode: .federal)
                            } label: {
                                toolRow(
                                    title: "Federal application",
                                    detail: "Use dated USAJOBS requirement checks",
                                    icon: "building.columns"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if matches("LinkedIn profile about headline skills") {
                            Button {
                                model.step = model.currentResponse == nil ? .importDocuments : .export
                                model.selectedMainSection = .builder
                            } label: {
                                toolRow(
                                    title: "LinkedIn profile kit",
                                    detail: "Create candidate-reviewed copy to paste yourself",
                                    icon: "person.text.rectangle"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if matches("headshot portrait photo AI Apple Intelligence LinkedIn profile") {
                            NavigationLink {
                                HeadshotStudioView()
                            } label: {
                                toolRow(
                                    title: "Headshot studio",
                                    detail: "Create a career-ready image with a private source photo",
                                    icon: "person.crop.rectangle"
                                )
                            }
                        }
                    }
                }

                if matches("applications tracker LinkedIn Indeed Workday USAJOBS deadlines notes versions") {
                    Section {
                        toolkitGroupHeader("Organize the search")
                        Button {
                            model.selectedMainSection = .tracker
                        } label: {
                            toolRow(
                                title: "Application tracker",
                                detail: "Links, status, deadlines, notes, and packet versions",
                                icon: "briefcase"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if matches("official government sources VA DoD OPM USAJOBS DOL privacy legal help") {
                    Section {
                        toolkitGroupHeader("Trust and official help")
                        if matches("official government sources VA DoD OPM USAJOBS DOL help") {
                            NavigationLink {
                                LegalSourcesView()
                            } label: {
                                toolRow(
                                    title: "Official sources",
                                    detail: "Verify federal, veteran, legal, and career guidance",
                                    icon: "checkmark.shield"
                                )
                            }
                        }
                        if matches("privacy local device data") {
                            NavigationLink {
                                PrivacyPolicyView()
                            } label: {
                                toolRow(
                                    title: "Privacy at a glance",
                                    detail: "See what stays local and what never happens automatically",
                                    icon: "lock.shield"
                                )
                            }
                        }
                    }
                }

                if matches("independent product sign-in scraping publishing submission") {
                    Section {
                        toolkitGroupHeader("Product boundaries")
                        Text("Independent product. No job-site sign-in, scraping, automatic publishing, or automatic submission.")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                }

                if !searchText.isEmpty, !hasSearchResults {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .listStyle(.insetGrouped)
            // iOS 27 floats the Liquid Glass tab bar above scroll content.
            // Reserve a clear endpoint so the final toolkit rows never sit
            // beneath it at accessibility text sizes.
            .safeAreaPadding(.bottom, 88)
            .navigationTitle("Toolkit")
            .modifier(ToolkitSearchPresentation(text: $searchText))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "person.crop.circle") {
                        showsSettings = true
                    }
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .environmentObject(model)
            }
        }
    }

    private var hasSearchResults: Bool {
        [
            "military occupation MOS AFSC rating O*NET translate experience",
            "civilian federal USAJOBS resume LinkedIn profile writing",
            "headshot portrait photo AI Apple Intelligence LinkedIn profile",
            "applications tracker LinkedIn Indeed Workday USAJOBS deadlines notes versions",
            "official government sources VA DoD OPM USAJOBS DOL privacy legal help",
        ].contains(where: matches)
    }

    private func matches(_ keywords: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || keywords.localizedCaseInsensitiveContains(query)
    }

    private func toolkitGroupHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }

    private func toolRow(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Brand.navyLight)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct ToolkitSearchPresentation: ViewModifier {
    @Binding var text: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content
        } else {
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search tools and official help"
            )
        }
    }
}
