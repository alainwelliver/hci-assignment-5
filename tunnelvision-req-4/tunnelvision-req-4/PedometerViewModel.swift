//
//  PedometerViewModel.swift
//  tunnelvision-req-4
//  Started by Alain Welliver on 4/1/26. Completed using AI assistnace with Claude Code's Claude 4.5 Sonnet

import Foundation
import Combine
import CoreMotion

struct Waypoint {
    let id: Int
    let name: String
    let instruction: String
    let stepThreshold: Int
}

@MainActor
final class PedometerViewModel: ObservableObject {

    let route: [Waypoint] = [
        Waypoint(id: 1, name: "Start: HCI Classroom",  instruction: "Walk straight toward the door",          stepThreshold: 0),
        Waypoint(id: 2, name: "Classroom Door",         instruction: "Turn right and walk down the hallway",   stepThreshold: 10),
        Waypoint(id: 3, name: "Hallway Junction",       instruction: "Turn right toward the elevators",        stepThreshold: 40),
        Waypoint(id: 4, name: "Arrived: Elevators",     instruction: "You have arrived.",                      stepThreshold: 50),
    ]

    @Published var stepCount: Int = 0
    @Published var currentWaypointIndex: Int = 0
    @Published var isARMode: Bool = false

    private let pedometer = CMPedometer()
    private var startDate: Date = Date()

    /// Multiplier applied to steps counted while in AR mode to compensate
    /// for reduced pedometer accuracy when the phone is held upright.
    private let arMultiplier: Double = 1.5

    /// Raw pedometer value at the moment the user last switched modes.
    private var rawStepsAtModeSwitch: Int = 0
    /// Effective (reported) step count at the moment the user last switched modes.
    private var effectiveStepsAtModeSwitch: Int = 0

    var currentWaypoint: Waypoint { route[currentWaypointIndex] }
    var isArrived: Bool { currentWaypointIndex == route.count - 1 }
    var nextWaypoint: Waypoint? { isArrived ? nil : route[currentWaypointIndex + 1] }

    /// Call when the user switches between 2D and AR mode.
    func setARMode(_ enabled: Bool) {
        guard enabled != isARMode else { return }
        rawStepsAtModeSwitch = lastRawSteps
        effectiveStepsAtModeSwitch = stepCount
        isARMode = enabled
    }

    var stepsToNext: Int? {
        guard let next = nextWaypoint else { return nil }
        return max(0, next.stepThreshold - stepCount)
    }

    var progress: Double {
        let total = Double(route.last!.stepThreshold)
        return min(Double(stepCount) / total, 1.0)
    }

    /// Most recent raw pedometer value (before any multiplier).
    private var lastRawSteps: Int = 0

    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        startDate = Date()
        pedometer.startUpdates(from: startDate) { [weak self] data, _ in
            guard let self, let data else { return }
            let rawSteps = data.numberOfSteps.intValue
            Task { @MainActor in
                self.lastRawSteps = rawSteps
                let delta = rawSteps - self.rawStepsAtModeSwitch
                let scaledDelta = self.isARMode
                    ? Int(Double(delta) * self.arMultiplier)
                    : delta
                self.stepCount = self.effectiveStepsAtModeSwitch + scaledDelta
                self.updateWaypoint()
            }
        }
    }

    func reset() {
        pedometer.stopUpdates()
        stepCount = 0
        currentWaypointIndex = 0
        lastRawSteps = 0
        rawStepsAtModeSwitch = 0
        effectiveStepsAtModeSwitch = 0
        startTracking()
    }

    private let triggerOffset = 5

    private func updateWaypoint() {
        for i in stride(from: route.count - 1, through: 0, by: -1) {
            let trigger = max(0, route[i].stepThreshold - triggerOffset)
            if stepCount >= trigger {
                if i != currentWaypointIndex {
                    currentWaypointIndex = i
                }
                break
            }
        }
        if isArrived {
            pedometer.stopUpdates()
        }
    }
}
