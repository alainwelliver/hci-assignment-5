// AI Attribution: Generated with Claude Opus 4.6

import Foundation
import Combine
import CoreMotion
import UIKit

@MainActor
final class NavigationViewModel: ObservableObject {

    // Home tab sub-step: landing page vs. manual from/to search + route options
    enum HomeStep { case landing, search }
    @Published var homeStep: HomeStep = .landing

    // Pre-fills for SearchView when opened from landing flows
    @Published var prefillStart: Station? = nil
    @Published var prefillDest: Station? = nil

    // Signal SearchView to focus the FROM field on appear (manual CTA flow)
    @Published var focusFromFieldOnAppear: Bool = false

    // Tab selection
    @Published var selectedTab: Int = 0

    // Navigation session state
    @Published var isNavigating: Bool = false
    @Published var isARMode: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var arrived: Bool = false

    // Route endpoints (set by search screen)
    @Published var startStation: Station?
    @Published var destStation: Station?

    // Active route definition resolved from start/dest pair
    @Published var activeRoute: RouteDefinition?

    // Pedometer (single source of truth for both 2D and AR)
    @Published var stepCount: Int = 0

    // Pedometer baseline at the start of the current leg, so "steps left"
    // counts down per-leg even when AR auto-advances ahead of the pedometer.
    @Published var stepCountAtLegStart: Int = 0

    private let pedometer = CMPedometer()

    // Throttle for pedometer-driven auto-advance. Guarantees each instruction
    // gets a render pass before the next one can fire, even if CMPedometer
    // delivers a batched update that crosses multiple step thresholds at once.
    private var lastAdvanceAt: Date?
    private let minStepDwell: TimeInterval = 1.5

    private func fireDirectionHaptic() {
        Haptics.shared.impact(.medium)
    }

    // MARK: - Active route accessors

    private var activeWaypoints: [Waypoint] { activeRoute?.waypoints ?? [] }
    private var activeNavSteps: [NavStep] { activeRoute?.navSteps ?? [] }

    var currentStep: NavStep {
        let steps = activeNavSteps
        guard !steps.isEmpty else {
            return NavStep(id: 0, direction: .straight, label: "", estimatedTimeRemaining: "", trainLine: "L", trainColor: "#2185D5", distanceMeters: 0)
        }
        let idx = min(max(0, currentStepIndex), steps.count - 1)
        return steps[idx]
    }

    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex >= max(0, activeNavSteps.count - 1) }

    var currentWaypoint: Waypoint? {
        let wps = activeWaypoints
        guard !wps.isEmpty else { return nil }
        let idx = min(max(0, currentStepIndex), wps.count - 1)
        return wps[idx]
    }

    var activeWaypointCount: Int { activeRoute?.activeWaypointCount ?? 0 }

    var stepsRemainingInLeg: Int {
        let wps = activeWaypoints
        let nextIndex = currentStepIndex + 1
        guard nextIndex < wps.count, currentStepIndex < wps.count else { return 0 }
        let legTotal = max(0, wps[nextIndex].stepThreshold - wps[currentStepIndex].stepThreshold)
        let stepsInLeg = max(0, stepCount - stepCountAtLegStart)
        return max(0, legTotal - stepsInLeg)
    }

    // MARK: - Session lifecycle

    private func resolveActiveRoute() {
        if let start = startStation, let dest = destStation {
            activeRoute = routeFor(origin: start.name, destination: dest.name)
        } else {
            activeRoute = nil
        }
    }

    func startNavigation() {
        Haptics.shared.prepareAll()
        resolveActiveRoute()
        isNavigating = true
        isARMode = false
        currentStepIndex = 0
        arrived = false
        stepCount = 0
        stepCountAtLegStart = 0
        lastAdvanceAt = nil
        selectedTab = 1
        startPedometer()
    }

    func openManualSearch() {
        prefillStart = nil
        prefillDest = nil
        focusFromFieldOnAppear = true
        homeStep = .search
        selectedTab = 0
    }

    func openSearchWithDestination(_ destination: Station) {
        if let originName = originForDestination[destination.name] {
            prefillStart = demoStations.first { $0.name == originName }
        } else {
            prefillStart = nil
        }
        prefillDest = destination
        focusFromFieldOnAppear = false
        homeStep = .search
        selectedTab = 0
    }

    func backToLanding() {
        prefillStart = nil
        prefillDest = nil
        focusFromFieldOnAppear = false
        homeStep = .landing
    }

    func reset() {
        stopPedometer()
        isNavigating = false
        isARMode = false
        currentStepIndex = 0
        arrived = false
        stepCount = 0
        stepCountAtLegStart = 0
        lastAdvanceAt = nil
        startStation = nil
        destStation = nil
        activeRoute = nil
        prefillStart = nil
        prefillDest = nil
        focusFromFieldOnAppear = false
        selectedTab = 0
        homeStep = .landing
    }

    // MARK: - 2D manual step controls

    func nextStep() {
        guard !arrived else { return }
        if isLastStep {
            arrived = true
            stopPedometer()
        } else {
            currentStepIndex += 1
            stepCountAtLegStart = stepCount
            fireDirectionHaptic()
        }
    }

    func previousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
            stepCountAtLegStart = stepCount
        }
    }

    // MARK: - AR mode toggle

    func toggleARMode() {
        isARMode.toggle()
    }

    // MARK: - Called by TunnelRouteNavigator when AR auto-advances

    func syncStepFromAR(legIndex: Int, didArrive: Bool) {
        let steps = activeNavSteps
        guard !steps.isEmpty else { return }
        let mapped = min(legIndex, steps.count - 1)
        let changed = mapped != currentStepIndex
        currentStepIndex = mapped
        if changed {
            stepCountAtLegStart = stepCount
            fireDirectionHaptic()
        }
        if didArrive {
            arrived = true
            stopPedometer()
        }
    }

    // MARK: - Auto-advance based on step thresholds

    private func checkStepThresholdAdvance() {
        guard isNavigating, !arrived else { return }
        let wps = activeWaypoints
        let steps = activeNavSteps
        guard !wps.isEmpty, !steps.isEmpty else { return }

        let nextIndex = currentStepIndex + 1
        guard nextIndex < wps.count else { return }

        // Don't collapse two transitions into one render frame when a batched
        // CMPedometer update crosses multiple thresholds at once.
        if let last = lastAdvanceAt, Date().timeIntervalSince(last) < minStepDwell {
            return
        }

        if stepCount >= wps[nextIndex].stepThreshold {
            if nextIndex >= wps.count - 1 {
                currentStepIndex = steps.count - 1
                stepCountAtLegStart = stepCount
                lastAdvanceAt = Date()
                fireDirectionHaptic()
                arrived = true
                stopPedometer()
            } else {
                currentStepIndex = nextIndex
                stepCountAtLegStart = stepCount
                lastAdvanceAt = Date()
                fireDirectionHaptic()
            }
        }
    }

    // MARK: - Pedometer

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard error == nil, let data else { return }
            Task { @MainActor in
                self?.stepCount = data.numberOfSteps.intValue
                self?.checkStepThresholdAdvance()
            }
        }
    }

    private func stopPedometer() {
        pedometer.stopUpdates()
    }
}
