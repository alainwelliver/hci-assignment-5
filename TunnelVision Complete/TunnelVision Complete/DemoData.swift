// AI Attribution: Generated with Claude Opus 4.6

#if os(iOS)
import CoreLocation
#endif
import Foundation
import SwiftUI

// MARK: - Demo Stations

let demoStations = [
    Station(name: "HCI Classroom"),
    Station(name: "2nd Floor Computer Systems Lab"),
    Station(name: "AGH Ground Floor Elevators"),
    Station(name: "2nd Floor Bathrooms"),
]

let originStationNames: Set<String> = [
    "HCI Classroom",
    "2nd Floor Computer Systems Lab",
]

let destinationStationNames: Set<String> = [
    "AGH Ground Floor Elevators",
    "2nd Floor Bathrooms",
]

// Each destination is reached from a single fixed origin in this demo.
let originForDestination: [String: String] = [
    "AGH Ground Floor Elevators": "HCI Classroom",
    "2nd Floor Bathrooms": "2nd Floor Computer Systems Lab",
]

// MARK: - Route Definition

struct RouteDefinition: Identifiable {
    let id = UUID()
    let originName: String
    let destinationName: String
    let waypoints: [Waypoint]

    var navSteps: [NavStep] { makeNavSteps(for: waypoints) }
    var activeWaypointCount: Int { max(0, waypoints.count - 1) }

    #if os(iOS)
    var tunnelRoute: TunnelRoute { makeTunnelRoute(from: waypoints) }
    #endif
}

// MARK: - Route Catalog

let hciToElevatorsRoute = RouteDefinition(
    originName: "HCI Classroom",
    destinationName: "AGH Ground Floor Elevators",
    waypoints: [
        Waypoint(id: 1, name: "Start: HCI Classroom",  instruction: "Walk straight toward the door",        direction: .straight,   stepThreshold: 0),
        Waypoint(id: 2, name: "Classroom Door",         instruction: "Turn right and walk down the hallway", direction: .turnRight,  stepThreshold: 10),
        Waypoint(id: 3, name: "Hallway Junction",       instruction: "Turn right toward the elevators",      direction: .turnRight,  stepThreshold: 40),
        Waypoint(id: 4, name: "Arrived: Elevators",     instruction: "You have arrived.",                    direction: .straight,   stepThreshold: 50),
    ]
)

let labToBathroomsRoute = RouteDefinition(
    originName: "2nd Floor Computer Systems Lab",
    destinationName: "2nd Floor Bathrooms",
    waypoints: [
        Waypoint(id: 1, name: "Start: 2nd Floor Computer Systems Lab", instruction: "Walk straight toward the door",  direction: .straight,  stepThreshold: 0),
        Waypoint(id: 2, name: "Lab Door",                              instruction: "Turn right toward the hallway",  direction: .turnRight, stepThreshold: 10),
        Waypoint(id: 3, name: "Hallway End",                           instruction: "Turn left",                      direction: .turnLeft,  stepThreshold: 70),
        Waypoint(id: 4, name: "Arrived: 2nd Floor Bathrooms",          instruction: "You have arrived.",              direction: .straight,  stepThreshold: 75),
    ]
)

let allRoutes: [RouteDefinition] = [
    hciToElevatorsRoute,
    labToBathroomsRoute,
]

func routeFor(origin: String, destination: String) -> RouteDefinition? {
    allRoutes.first { $0.originName == origin && $0.destinationName == destination }
}

// MARK: - NavStep derivation

private let avgStepLengthMeters = 0.75
private let secondsPerStep = 1.5

func makeNavSteps(for waypoints: [Waypoint]) -> [NavStep] {
    guard waypoints.count >= 2 else { return [] }
    var steps: [NavStep] = []
    let activeWaypoints = waypoints.dropLast()
    let lastThreshold = waypoints.last!.stepThreshold

    for (i, wp) in activeWaypoints.enumerated() {
        let nextThreshold = waypoints[i + 1].stepThreshold
        let segmentSteps = nextThreshold - wp.stepThreshold
        let dist = Double(segmentSteps) * avgStepLengthMeters
        let totalRemainingSteps = lastThreshold - wp.stepThreshold
        let totalRemainingSec = Int(Double(totalRemainingSteps) * secondsPerStep)
        let mins = totalRemainingSec / 60
        let secs = totalRemainingSec % 60
        let timeStr = String(format: "~%d:%02d", mins, secs)
        steps.append(NavStep(
            id: wp.id,
            direction: wp.direction,
            label: wp.instruction,
            estimatedTimeRemaining: timeStr,
            trainLine: "L",
            trainColor: "#2185D5",
            distanceMeters: dist
        ))
    }
    return steps
}

// MARK: - Route Timeline Generator (for search screen)

func generateDemoRoute(for route: RouteDefinition) -> [RouteStep] {
    let totalSteps = (route.waypoints.last?.stepThreshold ?? 50) - (route.waypoints.first?.stepThreshold ?? 0)
    let walkingSeconds = Double(totalSteps) * secondsPerStep
    let walkingMinutes = max(1, Int(ceil(walkingSeconds / 60.0)))

    return [
        RouteStep(instruction: route.originName, subtitle: "Starting point"),
        RouteStep(instruction: "Walking transfer", subtitle: "~\(walkingMinutes) min walking"),
        RouteStep(instruction: route.destinationName, subtitle: "Destination"),
    ]
}

func generateDemoRoute(from start: String, to destination: String) -> [RouteStep] {
    if let route = routeFor(origin: start, destination: destination) {
        return generateDemoRoute(for: route)
    }
    return [
        RouteStep(instruction: start, subtitle: "Starting point"),
        RouteStep(instruction: "Walking transfer", subtitle: nil),
        RouteStep(instruction: destination, subtitle: "Destination"),
    ]
}

// MARK: - Multiple Route Options

func generateDemoRouteOptions(for route: RouteDefinition) -> [RouteOption] {
    let totalSteps = (route.waypoints.last?.stepThreshold ?? 50) - (route.waypoints.first?.stepThreshold ?? 0)
    let walkingSeconds = Double(totalSteps) * secondsPerStep
    let walkingMinutes = max(1, Int(ceil(walkingSeconds / 60.0)))
    let directionCount = route.waypoints.count - 1
    let start = route.originName
    let destination = route.destinationName

    let walkingSubtitle = "~\(walkingMinutes) min walking"

    let stepsTemplate = [
        RouteStep(instruction: start, subtitle: "Starting point"),
        RouteStep(instruction: "Walking transfer", subtitle: walkingSubtitle),
        RouteStep(instruction: destination, subtitle: "Destination"),
    ]

    return [
        RouteOption(label: "Fastest", badgeColor: Color(hex: "#17c964"), steps: stepsTemplate, durationMinutes: walkingMinutes, transfers: directionCount),
        RouteOption(label: "Fewer Turns", badgeColor: Color(hex: "#006FEE"), steps: stepsTemplate, durationMinutes: walkingMinutes, transfers: 1),
        RouteOption(label: "Accessible", badgeColor: Color(hex: "#f5a524"), steps: stepsTemplate, durationMinutes: walkingMinutes + 3, transfers: 2),
    ]
}

func generateDemoRouteOptions(from start: String, to destination: String) -> [RouteOption] {
    if let route = routeFor(origin: start, destination: destination) {
        return generateDemoRouteOptions(for: route)
    }
    // Fallback: return an empty list so UI can render a "no route" state.
    return []
}

// MARK: - TunnelRoute (for AR navigation)

#if os(iOS)
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

@MainActor
func makeTunnelRoute(from waypoints: [Waypoint]) -> TunnelRoute {
    var legs: [RouteLeg] = []
    var runningBearing: Double = 180

    for i in 0 ..< max(0, waypoints.count - 1) {
        let wp = waypoints[i]
        let next = waypoints[i + 1]
        let segmentSteps = next.stepThreshold - wp.stepThreshold
        let dist = Double(segmentSteps) * avgStepLengthMeters

        switch wp.direction {
        case .turnRight, .bearRight:  runningBearing += 90
        case .turnLeft, .bearLeft:    runningBearing -= 90
        default: break
        }
        runningBearing = runningBearing.truncatingRemainder(dividingBy: 360)
        if runningBearing < 0 { runningBearing += 360 }

        legs.append(RouteLeg(
            bearingDegrees: runningBearing,
            distanceMeters: dist,
            instruction: wp.instruction
        ))
    }

    return TunnelRoute(
        start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
        legs: legs
    )
}

@MainActor
enum DemoRoutes {
    static var hciToElevators: TunnelRoute { hciToElevatorsRoute.tunnelRoute }

    static let straightCorridor = TunnelRoute(
        start: CLLocationCoordinate2D(latitude: 40.75890, longitude: -73.98550),
        legs: [
            RouteLeg(bearingDegrees: 180, distanceMeters: 100, instruction: "Walk straight"),
        ]
    )
}
#endif
