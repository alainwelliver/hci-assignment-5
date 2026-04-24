import Foundation
import SwiftUI

// MARK: - Station (from SearchNavigationView)

struct Station: Identifiable, Equatable {
    let id = UUID()
    let name: String
}

// MARK: - Direction (from TunnelVision ContentView)

enum Direction {
    case straight, bearLeft, bearRight, turnLeft, turnRight, upStairs, downStairs, splitAhead
}

// MARK: - NavStep (from TunnelVision ContentView)

struct NavStep {
    let id: Int
    let direction: Direction
    let label: String
    let estimatedTimeRemaining: String
    let trainLine: String
    let trainColor: String
    let distanceMeters: Double

    var estimatedStepsForSegment: Int {
        Int((distanceMeters / 0.75).rounded())
    }
}

// MARK: - Waypoint (shared between 2D and AR navigation)

struct Waypoint: Identifiable {
    let id: Int
    let name: String
    let instruction: String
    let direction: Direction
    let stepThreshold: Int
}

// MARK: - Route Step (for search timeline)

struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let subtitle: String?
}

// MARK: - Route Option (for multiple route alternatives)

struct RouteOption: Identifiable {
    let id = UUID()
    let label: String
    let badgeColor: Color
    let steps: [RouteStep]
    let durationMinutes: Int
    let transfers: Int

    var summaryLine: String {
        "\(durationMinutes) min · \(transfers) transfer\(transfers == 1 ? "" : "s")"
    }
}

// MARK: - RouteLeg (from req-3 TunnelRouteNavigator)

struct RouteLeg {
    let bearingDegrees: Double
    let distanceMeters: Double
    let instruction: String
}

// MARK: - Train (from req-5 TransitModels)

struct Train: Identifiable {
    let id = UUID()
    let routeName: String
    let destination: String
    var arrivalTime: Date
    var isDelayed: Bool

    func timeRemainingString(from currentTime: Date) -> String {
        let timeDifference = arrivalTime.timeIntervalSince(currentTime)

        if timeDifference <= 0 {
            return "0:00 min"
        }

        let minutes = Int(timeDifference) / 60
        let seconds = Int(timeDifference) % 60

        return String(format: "%d:%02d min", minutes, seconds)
    }
}
