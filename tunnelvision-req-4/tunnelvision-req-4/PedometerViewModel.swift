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

    private let pedometer = CMPedometer()
    private var startDate: Date = Date()

    var currentWaypoint: Waypoint { route[currentWaypointIndex] }
    var isArrived: Bool { currentWaypointIndex == route.count - 1 }
    var nextWaypoint: Waypoint? { isArrived ? nil : route[currentWaypointIndex + 1] }

    var stepsToNext: Int? {
        guard let next = nextWaypoint else { return nil }
        return max(0, next.stepThreshold - stepCount)
    }

    var progress: Double {
        let total = Double(route.last!.stepThreshold)
        return min(Double(stepCount) / total, 1.0)
    }

    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        startDate = Date()
        pedometer.startUpdates(from: startDate) { [weak self] data, _ in
            guard let self, let data else { return }
            let steps = data.numberOfSteps.intValue
            Task { @MainActor in
                self.stepCount = steps
                self.updateWaypoint()
            }
        }
    }

    func reset() {
        pedometer.stopUpdates()
        stepCount = 0
        currentWaypointIndex = 0
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
