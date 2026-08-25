import SwiftUI

@main
struct ApplyReadyVetsApp: App {
    @StateObject private var model: AppModel
    @StateObject private var entitlements: EntitlementManager

    init() {
        let entitlementManager = EntitlementManager()
        _entitlements = StateObject(wrappedValue: entitlementManager)
        _model = StateObject(wrappedValue: AppModel(entitlement: entitlementManager))
        ApplyReadyVetsShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(entitlements)
                .tint(Brand.navyLight)
        }
    }
}
