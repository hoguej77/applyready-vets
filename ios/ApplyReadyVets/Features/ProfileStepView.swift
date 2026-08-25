import SwiftUI

struct ProfileStepView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepIntroduction(
                    eyebrow: "Step 2 of 5",
                    title: "Add your service context",
                    detail: "This helps translate military language accurately. Leave anything blank that you do not want to share."
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text("Career target").font(.title3.bold())
                    LabeledTextField(
                        title: "Name",
                        prompt: "Your name",
                        maximumCharacters: CareerInputPolicy.Field.name.maximumCharacters,
                        text: $model.draft.profile.fullName
                    )
                    LabeledTextField(
                        title: "Target role",
                        prompt: "Fleet Operations Manager",
                        maximumCharacters: CareerInputPolicy.Field.targetRole.maximumCharacters,
                        text: $model.draft.profile.targetRole
                    )
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top) {
                            contactFields
                        }
                        VStack(alignment: .leading) {
                            contactFields
                        }
                    }
                    LabeledTextField(
                        title: "Location",
                        prompt: "City, State",
                        maximumCharacters: CareerInputPolicy.Field.location.maximumCharacters,
                        text: $model.draft.profile.location
                    )
                    LabeledTextField(
                        title: "LinkedIn URL",
                        prompt: "linkedin.com/in/…",
                        maximumCharacters: CareerInputPolicy.Field.linkedInURL.maximumCharacters,
                        text: $model.draft.profile.linkedin
                    )
                    Picker("Resume type", selection: $model.draft.mode) {
                        ForEach(ResumeMode.allCases) { mode in Text(mode.label).tag(mode) }
                    }
                    .pickerStyle(.menu)
                    Toggle("I am a military spouse", isOn: $model.draft.profile.militarySpouse)
                }
                .cardStyle()

                if model.draft.mode == .federal {
                    FederalApplicationCard()
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Military service").font(.title3.bold())
                            Text("MOS, AFSC, rating, or specialty codes are welcome.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Add", systemImage: "plus") {
                            model.draft.profile.militaryService.append(MilitaryService())
                        }
                        .disabled(
                            model.draft.profile.militaryService.count >=
                                CareerInputPolicy.maximumMilitaryServiceEntries
                        )
                    }

                    if model.draft.profile.militaryService.isEmpty {
                        Text("No service entry added yet. Your resume can still be analyzed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach($model.draft.profile.militaryService) { $service in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(service.occupationCode.isEmpty ? "Service entry" : service.occupationCode)
                                    .font(.headline)
                                Spacer()
                                Button(role: .destructive) {
                                    model.draft.profile.militaryService.removeAll { $0.id == service.id }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .labelStyle(.iconOnly)
                            }
                            LabeledTextField(
                                title: "Branch",
                                prompt: "Army",
                                maximumCharacters: CareerInputPolicy.Field.militaryBranch.maximumCharacters,
                                text: $service.branch
                            )
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .top) {
                                    rankAndOccupationFields(service: $service)
                                }
                                VStack(alignment: .leading) {
                                    rankAndOccupationFields(service: $service)
                                }
                            }
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .top) {
                                    componentAndPayGradeFields(service: $service)
                                }
                                VStack(alignment: .leading) {
                                    componentAndPayGradeFields(service: $service)
                                }
                            }
                            LabeledTextField(
                                title: "Military occupation title",
                                prompt: "Motor Transport Operator",
                                maximumCharacters: CareerInputPolicy.Field.militaryOccupationTitle.maximumCharacters,
                                text: $service.occupationTitle
                            )
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .top) {
                                    serviceDateFields(service: $service)
                                }
                                VStack(alignment: .leading) {
                                    serviceDateFields(service: $service)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        if service.id != model.draft.profile.militaryService.last?.id { Divider() }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Military Career Crosswalk", systemImage: "arrow.triangle.branch")
                        .font(.title3.bold())
                    Text("Search 12,921 included military occupation mappings from the O*NET Resource Center’s August 2024 release, available offline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        MilitaryCrosswalkView(
                            serviceEntries: model.draft.profile.militaryService
                        )
                    } label: {
                        Label("Explore civilian occupations", systemImage: "briefcase")
                    }
                    Text("Official crosswalk data is a starting point—not résumé evidence and not a guarantee of qualification.")
                        .font(.footnote)
                        .foregroundStyle(Brand.navy)
                }
                .cardStyle()

                AIConsentCard()

                HStack(spacing: 12) {
                    Button("Back") { model.back() }
                        .buttonStyle(.bordered)
                    PrimaryActionButton(
                        title: "Continue to analysis",
                        disabled: !model.canContinueFromImport
                    ) { model.next() }
                }
                if !model.canContinueFromImport {
                    Text("Use the occupation crosswalk now if it helps, then return to Import and add both your resume and one job posting before analysis.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var contactFields: some View {
        LabeledTextField(
            title: "Email",
            prompt: "you@example.com",
            maximumCharacters: CareerInputPolicy.Field.email.maximumCharacters,
            text: $model.draft.profile.email
        )
        LabeledTextField(
            title: "Phone",
            prompt: "Optional",
            maximumCharacters: CareerInputPolicy.Field.phone.maximumCharacters,
            text: $model.draft.profile.phone
        )
    }

    @ViewBuilder
    private func rankAndOccupationFields(
        service: Binding<MilitaryService>
    ) -> some View {
        LabeledTextField(
            title: "Rank",
            prompt: "SSG",
            maximumCharacters: CareerInputPolicy.Field.militaryRank.maximumCharacters,
            text: service.rank
        )
        LabeledTextField(
            title: "Occupation code",
            prompt: "88M",
            maximumCharacters: CareerInputPolicy.Field.militaryOccupationCode.maximumCharacters,
            text: service.occupationCode
        )
    }

    @ViewBuilder
    private func componentAndPayGradeFields(
        service: Binding<MilitaryService>
    ) -> some View {
        LabeledTextField(
            title: "Component",
            prompt: "Active, Reserve…",
            maximumCharacters: CareerInputPolicy.Field.militaryComponent.maximumCharacters,
            text: service.component
        )
        LabeledTextField(
            title: "Pay grade",
            prompt: "E-6",
            maximumCharacters: CareerInputPolicy.Field.militaryPayGrade.maximumCharacters,
            text: service.payGrade
        )
    }

    @ViewBuilder
    private func serviceDateFields(
        service: Binding<MilitaryService>
    ) -> some View {
        LabeledTextField(
            title: "Service start",
            prompt: "MM/YYYY",
            maximumCharacters: CareerInputPolicy.Field.militaryServiceDate.maximumCharacters,
            text: service.serviceStart
        )
        LabeledTextField(
            title: "Service end",
            prompt: "MM/YYYY",
            maximumCharacters: CareerInputPolicy.Field.militaryServiceDate.maximumCharacters,
            text: service.serviceEnd
        )
    }
}

private struct FederalApplicationCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Federal application identity", systemImage: "building.columns")
                .font(.title3.bold())
            Text("Tie this résumé version to the exact announcement. Do not add a series or grade to prior work unless it was actually a federal position.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LabeledTextField(
                title: "Announcement number",
                prompt: "Example: DE-12345678-26-ABC",
                maximumCharacters: CareerInputPolicy.Field.federalAnnouncement.maximumCharacters,
                text: announcementNumber
            )
            LabeledTextField(
                title: "Target series and grade",
                prompt: "Example: GS-0343-11",
                maximumCharacters: CareerInputPolicy.Field.federalSeriesAndGrade.maximumCharacters,
                text: targetSeriesAndGrade
            )
            Text("Current USAJOBS guidance limits federal résumés to two pages. The final PDF still requires a visual page-count check.")
                .font(.footnote)
                .foregroundStyle(Brand.navy)
        }
        .cardStyle()
    }

    private var announcementNumber: Binding<String> {
        Binding(
            get: { model.draft.federalDetails?.announcementNumber ?? "" },
            set: { value in
                var details = model.draft.federalDetails ?? FederalApplicationDetails()
                details.announcementNumber = value
                model.draft.federalDetails = details
            }
        )
    }

    private var targetSeriesAndGrade: Binding<String> {
        Binding(
            get: { model.draft.federalDetails?.targetSeriesAndGrade ?? "" },
            set: { value in
                var details = model.draft.federalDetails ?? FederalApplicationDetails()
                details.targetSeriesAndGrade = value
                model.draft.federalDetails = details
            }
        )
    }
}

private struct AIConsentCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Optional writing assistance", systemImage: "sparkles").font(.title3.bold())
                Spacer()
                Toggle("Use AI", isOn: $model.draft.useAI).labelsHidden()
            }
            Text("Private rules run first on every device. On eligible iPhone and iPad models, Apple Intelligence can add optional on-device wording suggestions. Citation and pattern checks run before you review them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if model.draft.useAI {
                Toggle(isOn: $model.draft.aiConsent) {
                    Text("I agree to optional on-device AI suggestions for this application workspace. I can turn this off at any time. Eligible devices process this step on-device. Nothing is approved automatically, and I remain responsible for final accuracy.")
                        .font(.subheadline.weight(.semibold))
                }
                Text("If consent is off, the private rules engine and Truth Lock still complete the analysis.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            #if DEBUG
            Toggle(
                isOn: Binding(
                    get: { model.draft.serviceConsent == true },
                    set: { model.draft.serviceConsent = $0 }
                )
            ) {
                Text("Allow the local development service to process unsupported file formats and provide a test fallback when on-device assistance is unavailable.")
                    .font(.subheadline.weight(.semibold))
            }
            Text("Developer builds can connect to the service shown in Settings. Public builds keep external processing disabled unless a named provider, data-use notice, retention terms, and deletion process are shipped.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            #else
            Label(
                "External AI processing is disabled in this release.",
                systemImage: "network.slash"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            #endif
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}
