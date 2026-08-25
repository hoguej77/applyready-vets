import SwiftUI

struct AddHouseholdProfileView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var preferredName = ""
    @State private var relationship = HouseholdRelationship.veteran
    @State private var branch = ""
    @State private var careerGoal = ""
    @State private var assistanceLevel = AssistanceLevel.privateCore

    var body: some View {
        NavigationStack {
            Form {
                ProfileIdentityFields(
                    preferredName: $preferredName,
                    relationship: $relationship,
                    branch: $branch,
                    careerGoal: $careerGoal
                )
                Section("Assistance") {
                    Picker("Level", selection: $assistanceLevel) {
                        ForEach(AssistanceLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    Text(assistanceLevel.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Label(
                        "This profile and its career workspace are stored locally with complete file protection.",
                        systemImage: "lock.shield"
                    )
                    .font(.footnote)
                }
            }
            .navigationTitle("Add person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if model.createHouseholdProfile(
                            preferredName: preferredName,
                            relationship: relationship,
                            branch: branch,
                            careerGoal: careerGoal,
                            assistanceLevel: assistanceLevel
                        ) {
                            dismiss()
                        }
                    }
                    .disabled(
                        preferredName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }
}

struct EditHouseholdProfileView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var preferredName = ""
    @State private var relationship = HouseholdRelationship.veteran
    @State private var branch = ""
    @State private var careerGoal = ""

    var body: some View {
        Form {
            ProfileIdentityFields(
                preferredName: $preferredName,
                relationship: $relationship,
                branch: $branch,
                careerGoal: $careerGoal
            )
            Section("Protected profile") {
                Text("Use a preferred name. Full legal contact details belong only in the application profile when a job requires them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    model.updateActiveHouseholdProfile(
                        preferredName: preferredName,
                        relationship: relationship,
                        branch: branch,
                        careerGoal: careerGoal
                    )
                    dismiss()
                }
                .disabled(
                    preferredName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
        .onAppear {
            guard let profile = model.activeHouseholdProfile else { return }
            preferredName = profile.preferredName
            relationship = profile.relationship
            branch = profile.branch
            careerGoal = profile.careerGoal
        }
    }
}

private struct ProfileIdentityFields: View {
    @Binding var preferredName: String
    @Binding var relationship: HouseholdRelationship
    @Binding var branch: String
    @Binding var careerGoal: String

    var body: some View {
        Section("Person") {
            TextField("Preferred name", text: $preferredName)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
            Picker("Relationship to service", selection: $relationship) {
                ForEach(HouseholdRelationship.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            TextField("Branch or affiliation (optional)", text: $branch)
                .textInputAutocapitalization(.words)
            TextField("Career direction (optional)", text: $careerGoal)
                .textInputAutocapitalization(.sentences)
        }
        Section {
            Label(
                "Never enter an SSN, DoD ID, VA claim number, date of birth, or medical information here.",
                systemImage: "hand.raised"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

struct ExternalAssistantHandoffView: View {
    @EnvironmentObject private var model: AppModel
    @State private var text = ""
    @State private var reviewed = false

    var body: some View {
        Form {
            Section("How it works") {
                Text("Paste only the material you want to share, review it here, then choose an installed app from Apple’s share sheet. ApplyReady Vets does not sign in to ChatGPT or Copilot and does not send anything in the background.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Text to share") {
                TextEditor(text: $text)
                    .frame(minHeight: 190)
                    .accessibilityLabel("Text to share with an external assistant")
                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Toggle("I reviewed this text and chose to share it", isOn: $reviewed)
            }

            Section {
                if model.activeAssistanceLevel.allowsExternalHandoff {
                    ShareLink(
                        item: boundedShareText,
                        preview: SharePreview("Career-writing request")
                    ) {
                        Label("Choose an assistant or app", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!canShare)
                } else {
                    Button("Enable preview-first sharing") {
                        model.setAssistanceLevel(.externalByApproval)
                    }
                }
                Text("The receiving app’s privacy policy and account terms apply after you choose it. OpenAI API keys must never be stored in this iPhone app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("External handoff")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: text) { _, newValue in
            if newValue.count > 8_000 {
                text = String(newValue.prefix(8_000))
            }
            reviewed = false
        }
    }

    private var boundedShareText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canShare: Bool {
        reviewed && !boundedShareText.isEmpty
    }
}
