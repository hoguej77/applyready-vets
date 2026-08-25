import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var baseURL = ""
    @State private var token = ""
    @State private var confirmsDeletion = false
    @State private var confirmsProfileRemoval = false
    @State private var showsAddProfile = false

    var body: some View {
        NavigationStack {
            Form {
                Section("People on this device") {
                    if let profile = model.activeHouseholdProfile {
                        LabeledContent("Active profile", value: profile.displayName)
                        if model.householdProfiles.count > 1 {
                            Menu("Switch profile", systemImage: "person.2") {
                                ForEach(model.householdProfiles) { option in
                                    Button {
                                        model.switchHouseholdProfile(to: option.id)
                                    } label: {
                                        if option.id == profile.id {
                                            Label(option.displayName, systemImage: "checkmark")
                                        } else {
                                            Text(option.displayName)
                                        }
                                    }
                                }
                            }
                        }
                        NavigationLink("Edit \(profile.displayName)’s profile") {
                            EditHouseholdProfileView()
                                .environmentObject(model)
                        }
                        if model.householdProfiles.count > 1 {
                            Button(
                                "Remove \(profile.displayName) from this device",
                                systemImage: "person.crop.circle.badge.minus",
                                role: .destructive
                            ) {
                                confirmsProfileRemoval = true
                            }
                        }
                    }
                    Button("Add another person", systemImage: "person.badge.plus") {
                        showsAddProfile = true
                    }
                    Text("Each person gets a separate protected workspace on this device. This is not an online account or automatic iCloud family sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                #if DEBUG
                Section("Developer connection") {
                    TextField("Service URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    SecureField("Optional service token", text: $token)
                        .textInputAutocapitalization(.never)
                    Button("Save and test connection") {
                        model.configure(apiBaseURL: baseURL, token: token)
                        Task { await model.checkService() }
                    }
                    if let health = model.health {
                        Label(
                            healthLabel(health),
                            systemImage: health.aiConfigured ? "checkmark.shield.fill" : "lock.shield"
                        )
                        .foregroundStyle(health.aiConfigured ? Brand.success : Brand.navyLight)
                        if let provider = health.aiProvider {
                            LabeledContent("Active AI", value: providerLabel(provider))
                        }
                    }
                }
                #endif

                Section("Core capabilities") {
                    Label("Private analysis and Truth Lock ready", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(Brand.success)
                    Label("Protected autosave and recovery copy ready", systemImage: "arrow.clockwise.circle.fill")
                        .foregroundStyle(Brand.success)
                    Label("Local text, image, and bounded PDF/OCR import", systemImage: "doc.text.magnifyingglass")
                    Label("Local LinkedIn drafting and verified export", systemImage: "square.and.arrow.up.on.square")
                    let endpoint = CapabilitySnapshot.current(serviceURL: model.apiBaseURL).serviceEndpoint
                    Label(endpoint.label, systemImage: endpoint.systemImage)
                        .foregroundStyle(endpoint == .insecureRemote ? Brand.danger : .secondary)
                }

                Section("Writing assistance") {
                    let intelligence = CapabilitySnapshot.current(
                        serviceURL: model.apiBaseURL
                    ).deviceIntelligence
                    Label(intelligence.title, systemImage: intelligence.systemImage)
                        .foregroundStyle(intelligence.isOnDevice ? Brand.success : .primary)
                    Text(intelligence.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Assistance is optional. The private career engine, Truth Lock, manual editing, LinkedIn kit, and export remain available when no AI model or service is connected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Picker(
                        "Assistance level",
                        selection: Binding(
                            get: { model.activeAssistanceLevel },
                            set: { model.setAssistanceLevel($0) }
                        )
                    ) {
                        ForEach(AssistanceLevel.allCases) { level in
                            Text(level.shortTitle).tag(level)
                        }
                    }
                    Text(model.activeAssistanceLevel.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    NavigationLink("Share selected text with another app") {
                        ExternalAssistantHandoffView()
                            .environmentObject(model)
                    }
                    Toggle(
                        "Verify AI suggestions with Truth Lock",
                        isOn: Binding(
                            get: { model.truthLockEnabled },
                            set: { model.setTruthLockEnabled($0) }
                        )
                    )
                    Text(model.truthLockEnabled
                         ? "Recommended. Unsupported AI wording is removed before suggestions appear."
                         : "AI wording can appear only as an unverified draft. Sensitive-content blocking stays on, and employer-facing export still requires Truth Lock verification.")
                        .font(.footnote)
                        .foregroundStyle(model.truthLockEnabled ? .secondary : Brand.danger)
                }

                Section("Apple surfaces") {
                    Toggle(
                        "Show application titles in Spotlight",
                        isOn: Binding(
                            get: { model.spotlightApplicationsEnabled },
                            set: { model.setSpotlightApplicationsEnabled($0) }
                        )
                    )
                    Text("When enabled, Spotlight can find an application by role, employer, platform, or status and open it here. Resume text, notes, job-ad text, evidence, and exported files are never indexed. This is off by default.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle(
                        "Show application details in widgets",
                        isOn: Binding(
                            get: {
                                model.widgetApplicationDetailsEnabled
                            },
                            set: {
                                model.setWidgetApplicationDetailsEnabled($0)
                            }
                        )
                    )
                    Text("This separate setting is off by default. Without it, the widget stores no employer, role, status, or deadline. When enabled, its minimal snapshot uses complete file protection and WidgetKit hides private content while the device is locked.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
#if DEBUG
                    Label("API token is stored in iOS Keychain", systemImage: "key.fill")
#else
                    Label("No external-service token is stored", systemImage: "key.slash.fill")
#endif
                    Label("Workspace and recovery copy use complete file protection", systemImage: "lock.doc.fill")
                    Label("Eligible iPhone and iPad models can add private on-device suggestions", systemImage: "cpu")
#if DEBUG
                    Text("The core analysis runs locally. A configured service is used only for unsupported formats or as an expressly permitted fallback; on-device and service proposals must pass Truth Lock before approval and export.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Label("OpenAI key stays on your server—not this app", systemImage: "server.rack")
#else
                    Text("Core analysis and export run locally. On eligible devices, private on-device suggestions are optional and must pass Truth Lock before approval and export.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
#endif
                    Button("Delete local workspace", systemImage: "trash", role: .destructive) {
                        confirmsDeletion = true
                    }
                }

                Section("Support & policies") {
                    NavigationLink("Privacy policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Legal, sources, and non-affiliation") {
                        LegalSourcesView()
                    }
                    if let privacyPolicyURL = AppReviewLinks.privacyPolicyURL {
                        Link("Privacy policy on the web", destination: privacyPolicyURL)
                    }
                    if let supportURL = AppReviewLinks.supportURL {
                        Link("Support website", destination: supportURL)
                    }
#if DEBUG
                    if AppReviewLinks.privacyPolicyURL == nil || AppReviewLinks.supportURL == nil {
                        Label(
                            "Public Support and Privacy URLs are required before App Store submission.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(Brand.gold)
                    }
#endif
                }

                Section("About") {
                    LabeledContent("Product", value: "ApplyReady Vets")
                    LabeledContent("Developer", value: "Jonathan Hogue Develops")
                    LabeledContent("Version", value: versionLabel)
                    NavigationLink("Complete access & pricing") {
                        SupportDevelopmentView()
                    }
                    Text("Writing and readiness guidance only. ApplyReady Vets is independent and is not affiliated with, endorsed by, or operated by VA, DoD, OPM, USAJOBS, any job platform, or any employer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
            .onAppear {
                baseURL = model.apiBaseURL
                token = model.apiToken
            }
            .confirmationDialog(
                "Delete this device's saved workspace?",
                isPresented: $confirmsDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete local workspace", role: .destructive) { model.eraseLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes the protected workspace, Job Tracker, recovery copies, shared-job inbox, and app-managed Samples and Output folders. It does not delete original files you selected elsewhere in Files or data retained by a separately hosted service.")
            }
            .confirmationDialog(
                "Remove this person from ApplyReady Vets?",
                isPresented: $confirmsProfileRemoval,
                titleVisibility: .visible
            ) {
                if let profile = model.activeHouseholdProfile {
                    Button("Remove \(profile.displayName)", role: .destructive) {
                        model.removeActiveHouseholdProfile()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the active local profile, its tracker records, and its protected app workspaces. Files you already exported to the Files app remain so they are not destroyed unexpectedly.")
            }
            .sheet(isPresented: $showsAddProfile) {
                AddHouseholdProfileView()
                    .environmentObject(model)
            }
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "Unknown"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "Unknown"
        return "\(version) (build \(build))"
    }

    private func healthLabel(_ health: HealthResponse) -> String {
        if health.onDeviceAIAvailable == true {
            return "Local Apple service and Truth Lock ready"
        }
        if health.aiConfigured {
            return "Cloud AI and Truth Lock ready"
        }
        return "Truth Lock ready; AI provider unavailable"
    }

    private func providerLabel(_ provider: String) -> String {
        switch provider {
        case "apple-foundation-models":
            return "Apple on-device"
        case "openai":
            return "OpenAI cloud"
        default:
            return provider
        }
    }
}
