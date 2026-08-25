import SwiftUI

struct MilitaryCrosswalkView: View {
    @State private var selectedBranch: MilitaryBranch
    @State private var query: String
    @State private var matches: [MilitaryOccupationMapping] = []
    @State private var metadata: MilitaryCrosswalkMetadata?
    @State private var errorMessage: String?
    @State private var isSearching = false

    init(serviceEntries: [MilitaryService]) {
        let first = serviceEntries.first
        _selectedBranch = State(initialValue: MilitaryBranch.parse(first?.branch ?? "") ?? .army)
        _query = State(initialValue: first?.occupationCode ?? "")
    }

    var body: some View {
        List {
            Section {
                Picker("Branch", selection: $selectedBranch) {
                    ForEach(MilitaryBranch.allCases) { branch in
                        Text(branch.label).tag(branch)
                    }
                }
                TextField("MOS, AFSC, rating, SFSC, or title", text: $query)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onSubmit { runSearch() }
                Button("Find civilian occupations", systemImage: "magnifyingglass") {
                    runSearch()
                }
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            } header: {
                Text("Military occupation")
            } footer: {
                Text("These are official crosswalk links, not a claim that you performed every task in a civilian occupation. Use your own verified experience when writing a résumé.")
            }

            if isSearching {
                Section {
                    ProgressView("Searching the on-device crosswalk…")
                }
            } else if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Brand.danger)
                }
            } else if matches.isEmpty, !query.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No exact crosswalk match",
                        systemImage: "questionmark.folder",
                        description: Text("Try a shorter code or occupation title. Confirm the selected branch.")
                    )
                }
            } else {
                ForEach(matches) { mapping in
                    Section {
                        ForEach(mapping.occupations) { occupation in
                            if let destination = occupationURL(occupation.code) {
                                Link(destination: destination) {
                                    occupationLabel(occupation)
                                }
                            } else {
                                occupationLabel(occupation)
                                    .accessibilityHint("O*NET detail link unavailable")
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(mapping.militaryCode) · \(mapping.militaryTitle)")
                            Text(mapping.personnelLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .textCase(nil)
                    }
                }
            }

            if let metadata {
                Section("Source and limits") {
                    Text("Source release: \(metadata.sourceRelease)")
                    Text(metadata.attribution)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let sourceURL = URL(string: metadata.sourceURL) {
                        Link("O*NET Resource Center source", destination: sourceURL)
                    }
                    if let licenseURL = URL(
                        string: "https://www.onetcenter.org/license_agreements.html"
                    ) {
                        Link("O*NET data licensing", destination: licenseURL)
                    }
                }
            }
        }
        .navigationTitle("Military Career Crosswalk")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await search()
            }
        }
    }

    private func runSearch() {
        Task { await search() }
    }

    @MainActor
    private func search() async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            let result = try await MilitaryCrosswalkStore.shared.search(
                branch: selectedBranch,
                query: query
            )
            metadata = result.metadata
            matches = result.matches
        } catch {
            matches = []
            errorMessage = error.localizedDescription
        }
    }

    private func occupationURL(_ code: String) -> URL? {
        URL(string: "https://www.onetonline.org/link/summary")?
            .appending(path: code)
    }

    private func occupationLabel(_ occupation: ONETOccupationMatch) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(occupation.title)
                .font(.headline)
            Text("O*NET-SOC \(occupation.code)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
