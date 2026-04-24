// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct NavigationContainerView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

    var body: some View {
        Group {
            if navigationVM.showTripOverview {
                tripOverviewView
            } else if !navigationVM.isNavigating {
                placeholderView
            } else if navigationVM.arrived {
                ArrivalView()
            } else if navigationVM.isARMode {
                ARNavigationView()
            } else {
                Navigation2DView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationVM.showTripOverview)
        .animation(.easeInOut(duration: 0.3), value: navigationVM.isARMode)
        .animation(.easeInOut(duration: 0.3), value: navigationVM.arrived)
        .animation(.easeInOut(duration: 0.3), value: navigationVM.isNavigating)
    }

    private var tripOverviewView: some View {
        let startName = navigationVM.startStation?.name ?? "Unknown"
        let destName = navigationVM.destStation?.name ?? "Unknown"
        let currentRoute = generateDemoRoute(from: startName, to: destName)

        return VStack(spacing: 0) {
            Text("Trip Overview")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(hex: "#1a1a2e"))
                .padding(.top, 28)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(currentRoute.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            Circle()
                                .stroke(Color(hex: "#f31260"), lineWidth: 2)
                                .background(Circle().fill(Color.white))
                                .frame(width: 16, height: 16)

                            if index < currentRoute.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#f31260"))
                                    .frame(width: 2)
                                    .frame(minHeight: 60)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.instruction)
                                .font(.system(size: 14, weight: index == 1 ? .semibold : .bold))
                                .foregroundColor(index == 1 ? Color(hex: "#444455") : Color(hex: "#1a1a2e"))

                            if let subtitle = step.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#666677"))
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, -2)
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer()

            Button {
                navigationVM.startNavigation()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                    Text("Start Navigation")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color(hex: "#17c964"))
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#fcfcfc").ignoresSafeArea())
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
