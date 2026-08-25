import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var stage = Stage.welcome
    @State private var preferredName = ""
    @State private var relationship = HouseholdRelationship.veteran
    @State private var branch = ""
    @State private var careerGoal = ""
    @State private var assistanceLevel = AssistanceLevel.privateCore
    @FocusState private var focusedField: Field?

    private enum Stage: Int, CaseIterable {
        case welcome
        case identity
        case assistance
        case ready
    }

    private enum Field {
        case name
        case branch
        case goal
    }

    var body: some View {
        ZStack {
            BrandBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topLine
                    stageContent
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 142)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .animation(.snappy(duration: 0.35), value: stage)
        .tint(Brand.primary)
    }

    private var topLine: some View {
        HStack(spacing: 12) {
            if stage == .welcome {
                BrandMark(compact: true)
                Text("ApplyReady Vets")
                    .font(.headline)
                    .foregroundStyle(Brand.ink)
            } else {
                Button("Back", systemImage: "chevron.left") {
                    focusedField = nil
                    moveBack()
                }
                .labelStyle(.iconOnly)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(
                    Color(.secondarySystemBackground),
                    in: Circle()
                )
                .accessibilityLabel("Back")
            }

            Spacer()

            if stage != .welcome {
                Text("\(stage.rawValue) of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.primaryDark)
                    .monospacedDigit()
            }
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .welcome:
            welcomeContent
                .transition(.opacity.combined(with: .move(edge: .leading)))
        case .identity:
            identityContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        case .assistance:
            assistanceContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        case .ready:
            readyContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Brand.accentRed)
                    .frame(width: 46, height: 4)
                    .accessibilityHidden(true)

                Text("Your experience. Ready for what’s next.")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("Turn service and life experience into focused applications—with private tools and veteran-specific guidance.")
                    .font(.body)
                    .foregroundStyle(Brand.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                WelcomePromiseRow(
                    icon: "checkmark.shield",
                    title: "Nothing leaves without you",
                    detail: "You review every export and submission."
                )
                Divider().padding(.leading, 50)
                WelcomePromiseRow(
                    icon: "lock",
                    title: "Private by default",
                    detail: "Core work stays protected on this device."
                )
                Divider().padding(.leading, 50)
                WelcomePromiseRow(
                    icon: "person.2",
                    title: "Separate household profiles",
                    detail: "Help someone without mixing their career work with yours."
                )
            }
            .padding(.horizontal, 16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 22)
            )

            Text("Independent product—not affiliated with VA, DoD, OPM, USAJOBS, job platforms, or employers. Results are not guaranteed.")
                .font(.caption)
                .foregroundStyle(Brand.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var identityContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            WelcomeHeading(
                eyebrow: "YOUR PRIVATE PROFILE",
                title: "Who are we helping?",
                detail: "This keeps each person’s career work separate on this device. Use a preferred name—not a government ID."
            )

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Preferred name")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "",
                        text: $preferredName,
                        prompt: Text("Name").foregroundStyle(Brand.secondaryText)
                    )
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .branch }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 50)
                        .background(
                            Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityLabel("Preferred name")
                        .accessibilityHint("Used only to personalize this protected local profile")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationship to service")
                        .font(.subheadline.weight(.semibold))
                    Picker("Relationship to service", selection: $relationship) {
                        ForEach(HouseholdRelationship.allCases) { option in
                            Label(option.label, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .background(
                        Color(.tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Branch or affiliation · Optional")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "",
                        text: $branch,
                        prompt: Text("Branch").foregroundStyle(Brand.secondaryText)
                    )
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .branch)
                        .onSubmit { focusedField = .goal }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 50)
                        .background(
                            Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityLabel("Branch or affiliation, optional")
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Career direction · Optional")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "",
                        text: $careerGoal,
                        prompt: Text("Career goal").foregroundStyle(Brand.secondaryText)
                    )
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .goal)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 50)
                        .background(
                            Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityLabel("Career direction, optional")
                }
            }

            Label(
                "We do not ask for an SSN, DoD ID, VA claim number, date of birth, or medical information.",
                systemImage: "hand.raised.fill"
            )
            .font(.footnote)
            .foregroundStyle(Brand.primaryDark)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var assistanceContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            WelcomeHeading(
                eyebrow: "YOUR CHOICE",
                title: "Choose your assistance level.",
                detail: "Start private and change this anytime. No external service is connected automatically."
            )

            VStack(spacing: 12) {
                ForEach(AssistanceLevel.allCases) { level in
                    AssistanceChoiceCard(
                        level: level,
                        isSelected: assistanceLevel == level
                    ) {
                        assistanceLevel = level
                    }
                }
            }

            Label(
                "Truth Lock and your final review remain part of every assisted workflow.",
                systemImage: "checkmark.seal"
            )
            .font(.footnote)
            .foregroundStyle(Brand.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 26) {
            WelcomeHeading(
                eyebrow: "READY",
                title: "Welcome, \(safeDisplayName).",
                detail: "Your workspace will open with one clear next step. You can add other household profiles later in Settings."
            )

            VStack(alignment: .leading, spacing: 16) {
                ReviewLine(
                    label: "Profile",
                    value: relationship.label,
                    icon: relationship.systemImage
                )
                if !branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ReviewLine(label: "Affiliation", value: branch, icon: "shield")
                }
                ReviewLine(
                    label: "Assistance",
                    value: assistanceLevel.shortTitle,
                    icon: assistanceLevel.systemImage
                )
                ReviewLine(
                    label: "Storage",
                    value: "Protected on this device",
                    icon: "lock.fill"
                )
            }
            .padding(18)
            .background(
                Brand.primaryLighter,
                in: RoundedRectangle(cornerRadius: 20)
            )

            Text("A local household profile is not an online account and does not sync resumes to relatives’ devices. App Store purchase sharing is a separate StoreKit decision.")
                .font(.footnote)
                .foregroundStyle(Brand.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 8) {
            PrimaryActionButton(
                title: primaryButtonTitle,
                icon: stage == .ready ? "checkmark" : "arrow.right",
                disabled: stage == .identity && safeDisplayName.isEmpty
            ) {
                focusedField = nil
                advance()
            }
            .accessibilityIdentifier(primaryButtonIdentifier)

            if stage == .welcome {
                Button {
                    model.loadDemo()
                } label: {
                    Label("Explore with safe demo data", systemImage: "play.circle")
                        .font(.subheadline.weight(.semibold))
                }
                // A quieter native text action keeps the onboarding decision
                // hierarchy clear and avoids a second wide, low-contrast pill.
                .buttonStyle(.plain)
                .foregroundStyle(Brand.primary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityHint("Opens the app with fictional sample information")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(.bar)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
    }

    private var primaryButtonTitle: String {
        switch stage {
        case .welcome: "Get started"
        case .identity, .assistance: "Continue"
        case .ready: "Enter my workspace"
        }
    }

    private var primaryButtonIdentifier: String {
        switch stage {
        case .welcome: "Onboarding.GetStarted"
        case .identity: "Onboarding.Profile.Continue"
        case .assistance: "Onboarding.Assistance.Continue"
        case .ready: "Onboarding.EnterWorkspace"
        }
    }

    private var safeDisplayName: String {
        preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func advance() {
        switch stage {
        case .welcome:
            stage = .identity
        case .identity:
            guard !safeDisplayName.isEmpty else { return }
            stage = .assistance
        case .assistance:
            stage = .ready
        case .ready:
            _ = model.createHouseholdProfile(
                preferredName: preferredName,
                relationship: relationship,
                branch: branch,
                careerGoal: careerGoal,
                assistanceLevel: assistanceLevel
            )
        }
    }

    private func moveBack() {
        guard let previous = Stage(rawValue: stage.rawValue - 1) else { return }
        stage = previous
    }
}

private struct WelcomeHeading: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(Brand.primary)
            Text(title)
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(.body)
                .foregroundStyle(Brand.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct WelcomePromiseRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.primary)
                .frame(width: 34, height: 34)
                .background(Brand.primaryLighter, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Brand.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Brand.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct AssistanceChoiceCard: View {
    let level: AssistanceLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: level.systemImage)
                    .font(.headline)
                    .foregroundStyle(isSelected ? Color.white : Brand.primary)
                    .frame(width: 42, height: 42)
                    .background(
                        isSelected ? Brand.primary : Brand.primaryLighter,
                        in: Circle()
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(level.title)
                        .font(.headline)
                        .foregroundStyle(Brand.ink)
                    Text(level.detail)
                        .font(.subheadline)
                        .foregroundStyle(Brand.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Brand.primary : Color.secondary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Brand.primaryLighter : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Brand.primary : Color.primary.opacity(0.07),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(level.title). \(level.detail)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct ReviewLine: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Brand.primaryDark)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Brand.secondaryText)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
