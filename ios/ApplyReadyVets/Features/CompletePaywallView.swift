import SwiftUI

struct CompletePaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "briefcase.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Brand.navyLight)
                            .accessibilityHidden(true)
                        Text("One workspace is free")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Brand.navy)
                        Text("Keep using your first tracked application from import through export. ApplyReady Vets Complete unlocks unlimited tracked application workspaces with one transparent lifetime purchase.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Unlimited tracked applications", systemImage: "infinity")
                        Label("Statuses, notes, deadlines, and required documents", systemImage: "checklist")
                        Label("Packet version history for every job", systemImage: "doc.on.doc")
                        Label("One price. No subscription, ads, credits, tips, or feature packs", systemImage: "checkmark.seal")
                    }
                    .font(.headline)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Built for the whole application")
                            .font(.headline)
                            .foregroundStyle(Brand.navy)
                        Label("Military occupation context and separate civilian or federal review", systemImage: "person.text.rectangle")
                        Label("Evidence-linked wording verified before export", systemImage: "checkmark.shield")
                        Label("Job links, deadlines, notes, versions, LinkedIn copy, and Files output stay together", systemImage: "folder.badge.gearshape")
                        Text("A general chatbot can draft text. ApplyReady Vets preserves the job, candidate evidence, safety decisions, and approved packet as one private workflow—even when writing assistance is unavailable.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()

                    if !entitlements.hasResolvedInitialEntitlement {
                        ProgressView("Checking your Apple Account…")
                    } else if entitlements.hasComplete {
                        Label("Complete access is active.", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Brand.success)
                    } else if entitlements.isLoading {
                        ProgressView("Checking Apple purchase options…")
                    } else if let product = entitlements.completeProduct {
                        Button {
                            Task { await entitlements.purchaseComplete() }
                        } label: {
                            HStack {
                                Label("Unlock Complete", systemImage: "lock.open")
                                Spacer()
                                Text(product.displayPrice)
                            }
                            .font(.headline)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.navySurface)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apple purchase options are unavailable right now. Your first workspace remains fully usable; no data is held hostage.")
                                .foregroundStyle(.secondary)
                            if entitlements.storefrontEnabled {
                                Button("Try purchase options again", systemImage: "arrow.clockwise") {
                                    Task { await entitlements.reloadProducts() }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .cardStyle()
                    }

                    Button("Restore a previous purchase", systemImage: "arrow.clockwise") {
                        Task { await entitlements.restorePurchases() }
                    }
                    .disabled(!entitlements.canRestorePurchases)

                    if !entitlements.message.isEmpty {
                        Text(entitlements.message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("This is the app's only consumer purchase. It unlocks the features already described above; future roadmap items are not sold as if they already exist. Refunds and purchase history are handled by Apple.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(22)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("ApplyReady Vets Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: entitlements.hasComplete) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }
}
