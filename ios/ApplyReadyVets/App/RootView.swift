import CoreSpotlight
import SwiftUI

enum ProtectedLaunchWorkGate {
    static func allowsHandling(
        entitlementResolved: Bool,
        localErasePending: Bool
    ) -> Bool {
        entitlementResolved && !localErasePending
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var entitlements: EntitlementManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if model.isLocalErasePending {
                protectedCleanupView
            } else if !entitlements.hasResolvedInitialEntitlement {
                initialAccessCheckView
            } else if model.requiresHouseholdProfileSelection {
                HouseholdProfileRecoveryView()
            } else if model.hasStarted && model.hasActiveHouseholdProfile {
                MainAppView()
            } else {
                WelcomeView()
            }
        }
        .disabled(model.isWorking)
        .accessibilityHidden(model.isWorking)
        .overlay {
            if model.isWorking {
                ZStack {
                    Color.black.opacity(0.22).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large).tint(Brand.navyLight)
                        Text("Working securely…").font(.headline)
                    }
                    .padding(28)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Working securely")
            }
        }
        .alert(
            "Needs attention",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Please try again.")
        }
        .confirmationDialog(
            "Use the shared job posting?",
            isPresented: Binding(
                get: { model.isSharedJobDecisionPresented },
                set: { model.isSharedJobDecisionPresented = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button("Replace current job") {
                model.replaceCurrentJobWithSharedItem()
            }
            Button("Keep current job") {
                model.keepCurrentJob()
            }
            Button("Decide later", role: .cancel) {
                model.isSharedJobDecisionPresented = false
            }
        } message: {
            Text("A shared \(model.pendingSharedJobDescription) is ready. Your current job text and link will not change without your choice.")
        }
        .task {
            await entitlements.start()
            handlePendingLaunchWorkIfReady()
        }
        .onReceive(NotificationCenter.default.publisher(for: .applyReadyShortcutRequested)) { _ in
            handlePendingLaunchWorkIfReady()
        }
        .onChange(of: entitlements.hasResolvedInitialEntitlement) { _, resolved in
            if resolved {
                handlePendingLaunchWorkIfReady()
            }
        }
        .onChange(of: model.isLocalErasePending) { wasPending, isPending in
            if wasPending, !isPending {
                handlePendingLaunchWorkIfReady()
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard !model.isLocalErasePending else { return }
            guard let identifier = activity.userInfo?[
                CSSearchableItemActivityIdentifier
            ] as? String else {
                return
            }
            model.openSpotlightApplication(searchableIdentifier: identifier)
        }
        .onOpenURL { url in
            guard !model.isLocalErasePending else { return }
            model.openDeepLink(url)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.resumePlatformPrivacyWork()
                handlePendingLaunchWorkIfReady()
            } else {
                model.saveForSceneTransition()
            }
        }
    }

    private var protectedCleanupView: some View {
        ContentUnavailableView {
            Label("Finishing private-data removal", systemImage: "lock.shield")
        } description: {
            Text("ApplyReady Vets will keep workspaces closed until the remaining protected files are removed.")
        } actions: {
            Button("Retry cleanup", systemImage: "arrow.clockwise") {
                model.retryLocalEraseCleanup()
            }
            .buttonStyle(.borderedProminent)
            .tint(Brand.navySurface)
        }
        .padding()
    }

    private var initialAccessCheckView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Brand.navyLight)
            Text("Checking access…")
                .font(.headline)
                .foregroundStyle(Brand.navy)
            Text("Your workspace will open after Apple verifies any existing lifetime purchase.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checking access")
    }

    private func handlePendingLaunchWorkIfReady() {
        guard ProtectedLaunchWorkGate.allowsHandling(
            entitlementResolved: entitlements.hasResolvedInitialEntitlement,
            localErasePending: model.isLocalErasePending
        ) else {
            return
        }
        model.handlePendingShortcut()
        model.handleIncomingShare()
    }
}

private struct HouseholdProfileRecoveryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(Brand.navyLight)
            Text("Choose a private workspace")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.ink)
            Text("Your saved workspace needs you to choose the person whose local career work you want to open.")
                .font(.body)
                .foregroundStyle(Brand.secondaryText)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                ForEach(model.householdProfiles) { profile in
                    Button {
                        model.switchHouseholdProfile(to: profile.id)
                    } label: {
                        HStack {
                            Label(profile.displayName, systemImage: "person.crop.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandBackground())
        .accessibilityElement(children: .contain)
    }
}
