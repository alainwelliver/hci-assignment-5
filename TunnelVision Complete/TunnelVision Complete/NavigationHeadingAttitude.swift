import Foundation
import SwiftUI
import Combine

// MARK: - Shared bearing math (keeps 2D live rotation aligned with AR / TunnelRouteNavigator)

enum NavigationBearing {
    static func legBearingOffsets(waypoints: [Waypoint]) -> [Double] {
        var out: [Double] = []
        var running: Double = 0
        let activeCount = max(0, waypoints.count - 1)
        for i in 0 ..< activeCount {
            switch waypoints[i].direction {
            case .turnRight, .bearRight: running += 90
            case .turnLeft, .bearLeft: running -= 90
            default: break
            }
            out.append(running)
        }
        return out
    }

    static func currentTargetBearing(legIndex: Int, base: Double, offsets: [Double]) -> Double? {
        guard legIndex < offsets.count else { return nil }
        var b = (base + offsets[legIndex]).truncatingRemainder(dividingBy: 360)
        if b < 0 { b += 360 }
        return b
    }

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

    private var legBearingOffsets: [Double] = []
    private var initialHeadingDegrees: Double?

    func configure(route: RouteDefinition?) {
        legBearingOffsets = NavigationBearing.legBearingOffsets(waypoints: route?.waypoints ?? [])
    }

    /// Clear captured heading (e.g. new AR-style session or new route start).
    func resetSession() {
        initialHeadingDegrees = nil
        arrowRotationDegrees = 0
    }

    func update(legIndex: Int, deviceHeading: Double?) {
        if initialHeadingDegrees == nil, let h = deviceHeading {
            initialHeadingDegrees = h
        }
        if let h = deviceHeading,
           let base = initialHeadingDegrees,
           let target = NavigationBearing.currentTargetBearing(legIndex: legIndex, base: base, offsets: legBearingOffsets) {
            let raw = NavigationBearing.shortestAngleDegrees(h, target)
            var clamped = raw
            if clamped > 90 { clamped = 90 }
            if clamped < -90 { clamped = -90 }
            arrowRotationDegrees = clamped
        } else {
            arrowRotationDegrees = 0
        }
    }
}
