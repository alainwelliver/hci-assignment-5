// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricUnits") private var useMetric = true
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled = true
    @AppStorage("showStepCounter") private var showStepCounter = false
    @AppStorage("showNextTrainBanner") private var showNextTrainBanner = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TunnelVision")
                                .font(.headline)
                            Text("Subway Transfer Navigator")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }

                Section("Navigation") {
                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticEnabled) { _, newValue in
                        if newValue { Haptics.shared.impact(.medium) }
                    }
                    Toggle(isOn: $showStepCounter) {
                        Label("Step Counter Display", systemImage: "figure.walk")
                    }
                    Toggle(isOn: $useMetric) {
                        Label("Use Metric Units", systemImage: "ruler")
                    }
                    HStack {
                        Text("Distance Unit")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(useMetric ? "Meters" : "Feet")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .font(.footnote)
                }

                Section("Transit") {
                    Toggle(isOn: $showNextTrainBanner) {
                        Label("Next Train Banner", systemImage: "tram.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
