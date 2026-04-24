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

    /// Recompute arrow rotation from the current device heading against the
    /// shared per-leg axis heading owned by `NavigationViewModel`.
    ///
    /// When either value is `nil`, the previously-computed rotation is held
    /// rather than snapped to zero. This avoids a brief flash to the arrow's
    /// baseline orientation in the first frames after a mode switch, while
    /// the just-restarted motion overlay has not yet delivered its first
    /// heading sample.
    func update(axisHeading: Double?, deviceHeading: Double?) {
        guard let h = deviceHeading, let axis = axisHeading else { return }
        let raw = NavigationBearing.shortestAngleDegrees(h, axis)
        var clamped = raw
        if clamped > 90 { clamped = 90 }
        if clamped < -90 { clamped = -90 }
        arrowRotationDegrees = clamped
    }
}
