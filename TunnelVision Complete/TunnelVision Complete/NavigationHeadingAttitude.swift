// AI Attribution: Generated with Claude Opus 4.6

import Foundation
import SwiftUI
import Combine

// MARK: - Shared bearing math (keeps 2D live rotation aligned with AR / TunnelRouteNavigator)

enum NavigationBearing {
    static func shortestAngleDegrees(_ a: Double, _ b: Double) -> Double {
        var d = b - a
        while d > 180 { d -= 360 }
        while d < -180 { d += 360 }
        return d
    }
}

@MainActor
final class NavigationHeadingAttitude: ObservableObject {
    @Published var arrowRotationDegrees: Double = 0

    // Heading axis used as the rotation reference for the *current* leg. We
    // snap this to the user's physical heading each time the leg changes so
    // each new leg treats "forward" as wherever the user is now pointing.
    private var currentAxisHeadingDegrees: Double?
    private var lastLegIndex: Int = -1

    func configure(route: RouteDefinition?) {
        // No per-route configuration is needed with the relative-axis approach.
        _ = route
    }

    /// Clear captured heading (e.g. new AR-style session or new route start).
    func resetSession() {
        currentAxisHeadingDegrees = nil
        arrowRotationDegrees = 0
        lastLegIndex = -1
    }

    func update(legIndex: Int, deviceHeading: Double?) {
        if legIndex != lastLegIndex {
            if let h = deviceHeading {
                currentAxisHeadingDegrees = h
            }
            lastLegIndex = legIndex
        }
        if currentAxisHeadingDegrees == nil, let h = deviceHeading {
            currentAxisHeadingDegrees = h
        }

        if let h = deviceHeading, let axis = currentAxisHeadingDegrees {
            let raw = NavigationBearing.shortestAngleDegrees(h, axis)
            var clamped = raw
            if clamped > 90 { clamped = 90 }
            if clamped < -90 { clamped = -90 }
            arrowRotationDegrees = clamped
        } else {
            arrowRotationDegrees = 0
        }
    }
}
