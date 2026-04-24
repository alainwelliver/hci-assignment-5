// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel

    var body: some View {
        if navigationVM.showLanding {
            LandingView()
        } else {
            CustomTabView()
        }
    }
}

// MARK: - Custom Tab View

private struct TabMeta {
    let tag: Int
    let icon: String
    let label: String
}

private let tabs: [TabMeta] = [
    TabMeta(tag: 0, icon: "house.fill",                   label: "Home"),
    TabMeta(tag: 1, icon: "location.fill.viewfinder",      label: "Navigate"),
    TabMeta(tag: 2, icon: "gearshape.fill",                label: "Settings"),
]

struct CustomTabView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel

    private let green = Color(hex: "#17c964")

    var body: some View {
        // Content pane — only the active tab is rendered, preserving onAppear semantics
        Group {
            switch navigationVM.selectedTab {
            case 0:  SearchView()
            case 1:  NavigationContainerView()
            case 2:  SettingsView()
            default: SearchView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                customTabBar
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                let isSelected = navigationVM.selectedTab == tab.tag
                Button {
                    navigationVM.selectedTab = tab.tag
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? green : Color(.systemGray2))
                            .scaleEffect(isSelected ? 1.05 : 1.0)

                        Text(tab.label)
                            .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? green : Color(.systemGray2))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(isSelected ? green : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                            Spacer()
                        }
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.18), value: isSelected)
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationViewModel())
        .environmentObject(TransitViewModel())
}
