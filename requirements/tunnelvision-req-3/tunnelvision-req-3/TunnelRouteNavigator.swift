#if os(iOS)
import Combine
import CoreLocation
import CoreMotion
import Foundation
import simd

// MARK: - Route builder

struct RouteLeg {
    let bearingDegrees: Double
    let distanceMeters: Double
    let instruction: String
}

struct TunnelRoute {
    let waypoints: [CLLocationCoordinate2D]
    let legInstructions: [String]

    init(start: CLLocationCoordinate2D, legs: [RouteLeg]) {
        var pts = [start]
        var instructions: [String] = []
        var current = start
        for leg in legs {
            current = Self.destination(from: current, bearingDeg: leg.bearingDegrees, distanceM: leg.distanceMeters)
            pts.append(current)
            instructions.append(leg.instruction)
        }
        self.waypoints = pts
        self.legInstructions = instructions
    }

    private static func destination(from: CLLocationCoordinate2D, bearingDeg: Double, distanceM: Double) -> CLLocationCoordinate2D {
        let R = 6_371_000.0
        let φ1 = from.latitude * .pi / 180
        let λ1 = from.longitude * .pi / 180
        let θ = bearingDeg * .pi / 180
        let δ = distanceM / R
        let φ2 = asin(sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ))
        let λ2 = λ1 + atan2(sin(θ) * sin(δ) * cos(φ1), cos(δ) - sin(φ1) * sin(φ2))
        return CLLocationCoordinate2D(latitude: φ2 * 180 / .pi, longitude: λ2 * 180 / .pi)
    }
}

// MARK: - Demo routes

enum DemoRoutes {
    static let lShapedTunnel = TunnelRoute(
        start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
        legs: [
            RouteLeg(bearingDegrees: 180, distanceMeters: 50, instruction: "Walk straight"),
            RouteLeg(bearingDegrees: 90,  distanceMeters: 30, instruction: "Turn right"),
            RouteLeg(bearingDegrees: 180, distanceMeters: 40, instruction: "Walk straight"),
        ]
    )

    static let straightCorridor = TunnelRoute(
        start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
        legs: [
            RouteLeg(bearingDegrees: 180, distanceMeters: 100, instruction: "Walk straight"),
        ]
    )
}

// MARK: - Geo / vector helpers

private func bearingDegrees(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let φ1 = from.latitude * .pi / 180
    let φ2 = to.latitude * .pi / 180
    let Δλ = (to.longitude - from.longitude) * .pi / 180
    let y = sin(Δλ) * cos(φ2)
    let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
    let θ = atan2(y, x) * 180 / .pi
    var b = θ.truncatingRemainder(dividingBy: 360)
    if b < 0 { b += 360 }
    return b
}

private func distanceMeters(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    CLLocation(latitude: from.latitude, longitude: from.longitude)
        .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
}

private func shortestAngleDegrees(_ a: Double, _ b: Double) -> Double {
    var d = b - a
    while d > 180 { d -= 360 }
    while d < -180 { d += 360 }
    return d
}

/// Convert a compass bearing to a unit vector in ARKit's `.gravityAndHeading` world space.
/// +X = east, −Z = north.  So bearing 0° (north) → (0, −1), bearing 90° (east) → (1, 0).
private func bearingToWorldUnit(_ bearingDeg: Double) -> SIMD2<Float> {
    let rad = Float(bearingDeg * .pi / 180)
    return SIMD2<Float>(sin(rad), -cos(rad))
}

// MARK: - Navigator (ARKit visual odometry)

/// Uses **ARKit world tracking** for distance instead of pedometer.
/// Displacement each frame is projected onto the bearing to the next waypoint:
///   - Walking toward it → distance shrinks.
///   - Walking away → distance grows.
///   - Walking sideways → no change.
/// Pedometer is kept only for the step-count display.
@MainActor
final class TunnelRouteNavigator: NSObject, ObservableObject {

    // UI state
    @Published var arrowRotationDegrees: Double = 0
    @Published var primaryInstruction: String = "Follow the route"
    @Published var distanceToNextWaypoint: Double = 0
    @Published var sessionSteps: Int = 0
    @Published var currentLegIndex: Int = 0
    @Published var totalLegs: Int = 0
    @Published var arrived: Bool = false

    // Pedometer (step count only)
    private let pedometer = CMPedometer()

    // AR tracker (injected)
    private var tracker: ARPositionTracker?

    // Route
    private let waypoints: [CLLocationCoordinate2D]
    private let legInstructions: [String]
    private var legDistances: [Double] = []

    /// How far you've walked toward the current waypoint [meters].
    private var distanceWalkedThisLeg: Double = 0

    /// Magnetic heading from DeviceMotionOverlay (for the arrow).
    private var deviceHeadingDegrees: Double?

    private let arrivalThresholdMeters: Double = 3.0

    init(route: TunnelRoute = DemoRoutes.lShapedTunnel) {
        self.waypoints = route.waypoints
        self.legInstructions = route.legInstructions
        super.init()
        precondition(waypoints.count >= 2)
        totalLegs = waypoints.count - 1
        buildLegDistances()
    }

    func start(tracker: ARPositionTracker) {
        self.tracker = tracker
        currentLegIndex = 0
        distanceWalkedThisLeg = 0
        sessionSteps = 0
        arrived = false
        updateDistanceToWaypoint()

        tracker.onDisplacement = { [weak self] displacement in
            self?.handleDisplacement(displacement)
        }

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                guard error == nil, let data else { return }
                Task { @MainActor in
                    self?.sessionSteps = data.numberOfSteps.intValue
                }
            }
        }
        recomputeUI()
    }

    func stop() {
        tracker?.onDisplacement = nil
        pedometer.stopUpdates()
        tracker = nil
    }

    func updateDeviceHeadingDegrees(_ degrees: Double?) {
        deviceHeadingDegrees = degrees
        recomputeUI()
    }

    // MARK: - ARKit displacement (called directly from AR frame callback)

    private func handleDisplacement(_ displacement: SIMD2<Float>) {
        guard !arrived else { return }

        let waypointDir = bearingToWorldUnit(bearingToNextWaypoint())
        let projected = simd_dot(displacement, waypointDir)

        distanceWalkedThisLeg += Double(projected)
        distanceWalkedThisLeg = max(0, distanceWalkedThisLeg)

        if currentLegIndex < legDistances.count,
           distanceWalkedThisLeg >= legDistances[currentLegIndex] - arrivalThresholdMeters {
            advanceToNextWaypoint()
        }

        updateDistanceToWaypoint()
        recomputeUI()
    }

    // MARK: - Route geometry

    private func buildLegDistances() {
        legDistances = []
        for i in 0 ..< (waypoints.count - 1) {
            legDistances.append(distanceMeters(from: waypoints[i], to: waypoints[i + 1]))
        }
    }

    private func bearingToNextWaypoint() -> Double {
        guard currentLegIndex < waypoints.count - 1 else { return 0 }
        return bearingDegrees(from: waypoints[currentLegIndex], to: waypoints[currentLegIndex + 1])
    }

    private func updateDistanceToWaypoint() {
        guard currentLegIndex < legDistances.count else {
            distanceToNextWaypoint = 0
            return
        }
        distanceToNextWaypoint = max(0, legDistances[currentLegIndex] - distanceWalkedThisLeg)
    }

    private func advanceToNextWaypoint() {
        if currentLegIndex < legDistances.count {
            let overshoot = distanceWalkedThisLeg - legDistances[currentLegIndex]
            currentLegIndex += 1
            distanceWalkedThisLeg = max(0, overshoot)
        }
        if currentLegIndex >= waypoints.count - 1 {
            arrived = true
            distanceWalkedThisLeg = 0
        }
    }

    // MARK: - UI

    private func recomputeUI() {
        if arrived {
            arrowRotationDegrees = 0
            primaryInstruction = "You have arrived"
            distanceToNextWaypoint = 0
            return
        }

        let target = bearingToNextWaypoint()

        if let h = deviceHeadingDegrees {
            var raw = shortestAngleDegrees(h, target)
            if raw > 90 { raw = 90 }
            if raw < -90 { raw = -90 }
            arrowRotationDegrees = raw
        } else {
            arrowRotationDegrees = 0
        }

        if currentLegIndex < legInstructions.count {
            primaryInstruction = legInstructions[currentLegIndex]
        } else {
            primaryInstruction = "Walk straight"
        }
    }
}
#endif
