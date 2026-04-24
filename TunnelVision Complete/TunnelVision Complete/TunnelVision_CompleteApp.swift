// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

@main
struct TunnelVision_CompleteApp: App {
    @StateObject private var navigationVM = NavigationViewModel()
    @StateObject private var transitVM = TransitViewModel()

    init() {
        UserDefaults.standard.register(defaults: ["hapticFeedbackEnabled": true])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationVM)
                .environmentObject(transitVM)
                .task {
                    await transitVM.loadData()
                }
        }
    }
}
