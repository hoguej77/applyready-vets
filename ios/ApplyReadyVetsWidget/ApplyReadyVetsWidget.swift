import SwiftUI
import WidgetKit

private struct NextApplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: ApplicationWidgetSnapshot
    let snapshotUnavailable: Bool
}

private struct NextApplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextApplicationEntry {
        NextApplicationEntry(
            date: Date(),
            snapshot: ApplicationWidgetSnapshot(
                updatedAt: Date(),
                activeCount: 3,
                details: ApplicationWidgetSnapshot.ApplicationDetails(
                    roleTitle: "Operations Manager",
                    employer: "Next opportunity",
                    status: "Preparing",
                    deadline: Calendar.current.date(
                        byAdding: .day,
                        value: 4,
                        to: Date()
                    )
                )
            ),
            snapshotUnavailable: false
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (NextApplicationEntry) -> Void
    ) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(entry(for: ApplicationWidgetSnapshotStore.read()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<NextApplicationEntry>) -> Void
    ) {
        let result = ApplicationWidgetSnapshotStore.read()
        let entry = entry(for: result)
        let refresh = Calendar.current.date(
            byAdding: result.needsShortRetry ? .minute : .hour,
            value: result.needsShortRetry ? 5 : 4,
            to: Date()
        ) ?? Date().addingTimeInterval(
            result.needsShortRetry ? 300 : 14_400
        )
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func entry(
        for result: ApplicationWidgetSnapshotStore.ReadResult
    ) -> NextApplicationEntry {
        NextApplicationEntry(
            date: Date(),
            snapshot: result.snapshot,
            snapshotUnavailable: result.needsShortRetry
        )
    }
}

private struct NextApplicationWidgetView: View {
    let entry: NextApplicationEntry
    @Environment(\.redactionReasons) private var redactionReasons

    var body: some View {
        if redactionReasons.contains(.privacy) ||
            entry.snapshotUnavailable {
            privatePlaceholder
                .unredacted()
        } else if entry.snapshot.activeCount == 0 {
            VStack(alignment: .leading, spacing: 8) {
                Label("ApplyReady Vets", systemImage: "briefcase")
                    .font(.headline)
                Text("Track your next opportunity")
                    .font(.subheadline)
                Spacer()
                Text("No active applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let details = entry.snapshot.details {
            detailedApplication(details)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("APPLICATIONS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.snapshot.activeCount) active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .privacySensitive()
                }
                Text("Details stay private")
                    .font(.headline)
                    .lineLimit(2)
                Text("You can opt in from ApplyReady Vets Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Label("Open application tracker", systemImage: "checklist")
                    .font(.caption)
            }
        }
    }

    private var privatePlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("ApplyReady Vets", systemImage: "lock.fill")
                .font(.headline)
            Text("Application details protected")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("Unlock to view")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailedApplication(
        _ details: ApplicationWidgetSnapshot.ApplicationDetails
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("NEXT APPLICATION")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.snapshot.activeCount) active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(details.roleTitle)
                .font(.headline)
                .lineLimit(2)
            Text(details.employer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            HStack {
                Label(details.status, systemImage: "checklist")
                Spacer()
                if let deadline = details.deadline {
                    Label {
                        Text(deadline, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .font(.caption)
        }
        .privacySensitive()
    }
}

struct ApplyReadyVetsNextApplicationWidget: Widget {
    let kind = ApplicationWidgetSnapshotStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: NextApplicationProvider()
        ) { entry in
            NextApplicationWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "applyreadyvets://applications"))
        }
        .configurationDisplayName("Next Application")
        .description("See a private application summary, with details only when you opt in.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ApplyReadyVetsWidgetBundle: WidgetBundle {
    var body: some Widget {
        ApplyReadyVetsNextApplicationWidget()
    }
}
