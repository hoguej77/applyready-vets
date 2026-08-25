import StoreKit
import SwiftUI

struct LegalSourcesView: View {
    var body: some View {
        List {
            Section("Independent product") {
                Label(
                    "ApplyReady Vets is an independent career-writing tool. It is not affiliated with, endorsed by, or operated by the U.S. Department of Veterans Affairs or any other government agency.",
                    systemImage: "building.columns.circle"
                )
                Text("The app does not use the VA seal, VA logo, military branch insignia, or government trademarks. Its accessible civic design is original and intentionally distinct from official services.")
                    .foregroundStyle(.secondary)
            }

            Section("What this app is—and is not") {
                Text("ApplyReady Vets offers writing, organization, and application-readiness guidance. It is not legal advice, benefits advice, an accredited claims service, an employer, or a promise of eligibility, interviews, or employment.")
                Text("AI output can be incomplete or wrong. Truth Lock reduces unsupported claims, but you must review and approve every change.")
            }

            Section("Government identity and trademark sources") {
                SourceLink(
                    title: "38 C.F.R. § 1.9",
                    detail: "Controls use of the official VA seal and prohibits uses that imply VA endorsement.",
                    url: "https://www.ecfr.gov/current/title-38/chapter-I/part-1/section-1.9"
                )
                SourceLink(
                    title: "18 U.S.C. § 701",
                    detail: "Addresses unauthorized manufacture, sale, or possession of official insignia.",
                    url: "https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title18-section701"
                )
                SourceLink(
                    title: "15 U.S.C. § 1125(a)",
                    detail: "Prohibits misleading representations likely to confuse people about affiliation, sponsorship, or approval.",
                    url: "https://uscode.house.gov/view.xhtml?req=(title:15%20section:1125(a)%20edition:prelim)"
                )
            }

            Section("Platform and privacy rules") {
                SourceLink(
                    title: "Apple App Review Guidelines",
                    detail: "Payment, privacy, accurate-metadata, and anti-impersonation requirements.",
                    url: "https://developer.apple.com/app-store/review/guidelines/"
                )
                SourceLink(
                    title: "LinkedIn User Agreement",
                    detail: "ApplyReady Vets prepares copy-ready text but does not sign in, create accounts, scrape profiles, or automate LinkedIn activity.",
                    url: "https://www.linkedin.com/legal/user-agreement"
                )
            }

            Section("Authoritative career guidance") {
                SourceLink(
                    title: "USAJOBS resume guidance",
                    detail: "Federal resumes are limited to two pages and must address the announcement's qualifications.",
                    url: "https://help.usajobs.gov/faq/application/documents/resume/what-to-include"
                )
                SourceLink(
                    title: "USAJOBS veterans hiring path",
                    detail: "Official veteran preference, documentation, and hiring-path guidance.",
                    url: "https://help.usajobs.gov/working-in-government/unique-hiring-paths/veterans"
                )
                SourceLink(
                    title: "O*NET military crosswalk",
                    detail: "Official downloadable military occupation mappings. This build identifies its August 2024 source release and keeps the crosswalk available offline.",
                    url: "https://www.onetcenter.org/crosswalks.html"
                )
                SourceLink(
                    title: "O*NET data license",
                    detail: "Attribution and reuse terms for the occupational data included in the app.",
                    url: "https://www.onetcenter.org/license_agreements.html"
                )
                SourceLink(
                    title: "OPM Executive Core Qualifications",
                    detail: "Official Senior Executive Service leadership-qualification framework.",
                    url: "https://www.opm.gov/policy-data-oversight/senior-executive-service/executive-core-qualifications/"
                )
                SourceLink(
                    title: "VA Veteran Readiness and Employment",
                    detail: "Official information about eligible resume development and employment support.",
                    url: "https://www.benefits.va.gov/vocrehab/"
                )
                SourceLink(
                    title: "DOL Veterans’ Employment and Training Service",
                    detail: "Official employment resources for Veterans, service members, and military spouses.",
                    url: "https://www.dol.gov/agencies/vets/veterans"
                )
            }
        }
        .navigationTitle("Legal & sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section("Privacy at a glance") {
                Text("Effective August 1, 2026. ApplyReady Vets is designed as a local-first career-writing tool. It does not sell personal information, run advertising tracking, or use third-party analytics SDKs.")
                Text("This in-app policy is available before account creation because the app does not require an account for its private core.")
                    .foregroundStyle(.secondary)
            }

            Section("Local storage and Apple backups") {
#if DEBUG
                Text("Your resume, job posting, service profile, Truth Lock decisions, and locally generated files are processed locally for the private core. The workspace and recovery copy use iOS complete file protection; an optional service token is stored in Keychain.")
#else
                Text("Your resume, job posting, service profile, Truth Lock decisions, and locally generated files are processed locally. The workspace and recovery copy use iOS complete file protection. This release stores no external-service token.")
#endif
                Text("User-authored work remains eligible for device or iCloud Backup under your Apple backup settings so a lost or replaced device can be restored. ApplyReady Vets does not receive or control those encrypted system backups.")
#if DEBUG
                Text("Settings → Delete local workspace removes the app workspace, Job Tracker, recovery copies, shared job inbox, app-managed Files output/sample folders, and saved service token from the current device. It does not delete files you selected elsewhere, copies you shared, separately hosted service data, or older device backups managed through Apple settings.")
#else
                Text("Settings → Delete local workspace removes the app workspace, Job Tracker, recovery copies, shared job inbox, and app-managed Files output and sample folders from the current device. It does not delete files you selected elsewhere, copies you shared, or older device backups managed through Apple settings.")
#endif
            }

            Section("Optional AI and service use") {
                Text("The private core does not require a cloud AI account. If a future release offers a separately hosted import or AI fallback, the app will show a specific consent screen before it sends a document, job link, or text to that provider. That screen must identify the provider, the exact data sent, the purpose, retention/deletion terms, and how to decline.")
                Text("This release does not configure a public cloud service endpoint. Apple on-device intelligence, where supported and explicitly enabled, remains on the device.")
                    .foregroundStyle(.secondary)
            }

            Section("What the app may handle") {
                Text("The content you choose to enter can include contact details, work history, military service information, resume text, job text, and career preferences. The app uses that information only to provide the features you request.")
                Text("Do not enter Social Security numbers, bank details, classified or controlled information, or unnecessary medical details. The app provides pattern warnings, but no automated scan can find every sensitive detail.")
            }

            Section("Sharing and third parties") {
                Text("The app does not sign in to or publish to LinkedIn, Indeed, Workday, USAJOBS, or an employer. It prepares candidate-reviewed text and opens user-controlled handoffs only.")
                Text("Links to government resources, employers, and job platforms open under those organizations’ own privacy terms.")
            }

            Section("Children, security, and changes") {
                Text("ApplyReady Vets is not directed to children under 13. No security measure is perfect; protect your device with a passcode and review every export before sharing it.")
                Text("Material policy changes will be reflected in this screen and in the public App Store privacy-policy page before release.")
            }

#if DEBUG
            Section("Support before public release") {
                Text("Jonathan Hogue Develops will publish a public support contact and privacy-policy URL in the App Store listing before TestFlight distribution beyond internal testing or any public release. Do not submit the app for public review until those URLs are live.")
                    .foregroundStyle(.secondary)
            }
#endif
        }
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportDevelopmentView: View {
    @EnvironmentObject private var entitlements: EntitlementManager

    var body: some View {
        List {
            Section {
                Label("Transparent veteran-first pricing", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Brand.navy)
                Text("One tracked application workspace is free from import through export. Complete unlocks unlimited tracked application workspaces with one lifetime purchase. No subscriptions, ads, feature packs, credits, tips, or repeated upsells. The App Store shows the exact local price before you buy.")
            }

            Section("ApplyReady Vets Complete") {
                if !entitlements.hasResolvedInitialEntitlement {
                    ProgressView("Checking your Apple Account…")
                } else if entitlements.hasComplete {
                    Label("Lifetime access is active on this Apple Account.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Brand.success)
                } else if entitlements.isLoading {
                    ProgressView("Checking lifetime unlock…")
                } else if let completeProduct = entitlements.completeProduct {
                    Button {
                        Task { await entitlements.purchaseComplete() }
                    } label: {
                        LabeledContent(completeProduct.displayName, value: completeProduct.displayPrice)
                    }
                    Text("Unlocks unlimited tracked applications, including their statuses, notes, deadlines, required-document lists, and packet version histories. Roadmap features are not sold as if they already exist.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Apple purchase options are unavailable right now. Your first workspace remains fully usable.")
                        .foregroundStyle(.secondary)
                    if entitlements.storefrontEnabled {
                        Button("Try purchase options again", systemImage: "arrow.clockwise") {
                            Task { await entitlements.reloadProducts() }
                        }
                    }
                }

                if entitlements.storefrontEnabled {
                    Button("Restore purchases", systemImage: "arrow.clockwise") {
                        Task { await entitlements.restorePurchases() }
                    }
                    .disabled(!entitlements.canRestorePurchases)
                }
            }

            if !entitlements.message.isEmpty {
                Section("Status") {
                    Text(entitlements.message)
                }
            }

            Section("Payment transparency") {
                    Text("Complete is the app's only consumer purchase. Apple processes the payment, shows the exact local price before confirmation, and handles refund requests through the App Store. Restore purchases reconnects an eligible lifetime purchase to this Apple Account.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Complete & pricing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SourceLink: View {
    let title: String
    let detail: String
    let url: String

    var body: some View {
        Group {
            if let destination = URL(string: url) {
                Link(destination: destination) {
                    linkLabel
                }
                .accessibilityHint("Opens the authoritative source in your browser")
            } else {
                linkLabel
                    .accessibilityHint("The authoritative source link is unavailable")
            }
        }
    }

    private var linkLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: "arrow.up.right.square")
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
