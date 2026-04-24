// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct NavigationContainerView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

    var body: some View {
        Group {
            if !navigationVM.isNavigating {
                placeholderView
            } else if navigationVM.arrived {
                ArrivalView()
            } else if navigationVM.isARMode {
                ARNavigationView()
            } else {
                Navigation2DView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationVM.isARMode)
        .animation(.easeInOut(duration: 0.3), value: navigationVM.arrived)
        .animation(.easeInOut(duration: 0.3), value: navigationVM.isNavigating)
    }

    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#17c964").opacity(0.4))

            Text("No Active Route")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)

            Text("Start a route from the Home tab\nto begin navigation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
