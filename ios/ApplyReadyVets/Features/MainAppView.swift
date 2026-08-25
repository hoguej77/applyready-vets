import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: $model.selectedMainSection) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "checklist")
                }
                .tag(AppModel.MainSection.home)

            WorkspaceView()
                .tabItem {
                    Label("Workspace", systemImage: "doc.text")
                }
                .tag(AppModel.MainSection.builder)

            JobTrackerView()
                .tabItem {
                    Label("Applications", systemImage: "briefcase")
                }
                // A zero badge adds visual noise and does not convey a state
                // someone can act on. Omit it until an active application
                // exists, which also keeps the tab label fully Dynamic-Type
                // friendly on iOS 27.
                .badge(activeApplicationBadge)
                .tag(AppModel.MainSection.tracker)

            CareerToolkitView()
                .tabItem {
                    Label("Toolkit", systemImage: "square.grid.2x2")
                }
                .tag(AppModel.MainSection.toolkit)
        }
        .tabViewStyle(.automatic)
        .sheet(isPresented: $model.showsCompletePaywall) {
            CompletePaywallView()
        }
    }

    private var activeApplicationCount: Int {
        model.jobApplications.filter(\.status.isActive).count
    }

    private var activeApplicationBadge: String? {
        guard activeApplicationCount > 0 else { return nil }
        return String(activeApplicationCount)
    }
}
