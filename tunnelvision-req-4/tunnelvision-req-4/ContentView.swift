//
//  ContentView.swift
//  tunnelvision-req-4
//
//  Created by Alain Welliver on 4/1/26. Completed using AI assistnace with Claude Code's Claude 4.5 Sonnet
//

import SwiftUI

private let tunnelGreen = Color(red: 0x17 / 255.0, green: 0xc9 / 255.0, blue: 0x64 / 255.0)

struct ContentView: View {
    @StateObject private var vm = PedometerViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // ── Top: live step count ──────────────────────────────────────
            Text("Steps: \(vm.stepCount)")
                .font(.title2.monospacedDigit())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Divider()

            // ── Middle: current waypoint ──────────────────────────────────
            Spacer()

            if vm.isArrived {
                arrivedView
            } else {
                waypointView
            }

            Spacer()

            Divider()

            // ── Bottom: progress bar + next waypoint + reset ──────────────
            bottomSection
                .padding(.horizontal)
                .padding(.vertical, 16)
        }
        .onAppear { vm.startTracking() }
    }

    // MARK: - Subviews

    private var waypointView: some View {
        VStack(spacing: 12) {
            Text(vm.currentWaypoint.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(vm.currentWaypoint.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Waypoint \(vm.currentWaypointIndex + 1) of \(vm.route.count)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    private var arrivedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(tunnelGreen)

            Text("Arrived!")
                .font(.largeTitle.bold())
                .foregroundStyle(tunnelGreen)

            Text(vm.currentWaypoint.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var bottomSection: some View {
        VStack(spacing: 10) {
            // Progress bar
            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .tint(tunnelGreen)

            // Next waypoint hint
            Group {
                if let next = vm.nextWaypoint, let stepsLeft = vm.stepsToNext {
                    Text("Next: \(next.name) in ~\(stepsLeft) steps")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Route complete")
                        .font(.footnote)
                        .foregroundStyle(tunnelGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Reset button
            Button(action: { vm.reset() }) {
                Text("Reset")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
    }
}

#Preview {
    ContentView()
}
