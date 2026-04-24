// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct Navigation2DView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel
    @AppStorage("useMetricUnits") private var useMetric = true
    @AppStorage("showStepCounter") private var showStepCounter = false
    @AppStorage("showNextTrainBanner") private var showNextTrainBanner = false

#if os(iOS)
    @StateObject private var motion = DeviceMotionOverlay()
    @StateObject private var headingAttitude = NavigationHeadingAttitude()
#endif

    @State private var showExitConfirmation = false
    @State private var showOverstepBanner = false

    private let green = Color(hex: "#17c964")
    private let orange = Color(hex: "#f5a524")

    private var step: NavStep { navigationVM.currentStep }

    private var formattedDistance: String {
        if useMetric {
            return String(format: "%.0f m", step.distanceMeters)
        } else {
            return String(format: "%.0f ft", step.distanceMeters * 3.28084)
        }
    }

    private var isOverstepped: Bool {
        guard let waypoints = navigationVM.activeRoute?.waypoints else { return false }
        let nextIndex = navigationVM.currentStepIndex + 1
        guard nextIndex < waypoints.count else { return false }
        let threshold = waypoints[nextIndex].stepThreshold
        return navigationVM.stepCount > threshold + 20
    }

#if os(iOS)
    private var stabilizedParallax2D: CGSize {
        CGSize(width: -motion.offset.width, height: -motion.offset.height)
    }
#endif

    @ViewBuilder
    private var directionArrows: some View {
#if os(iOS)
        DirectionArrowView(
            direction: step.direction,
            tint: green,
            rotationDegrees: headingAttitude.arrowRotationDegrees,
            stabilizedOffset: stabilizedParallax2D
        )
#else
        DirectionArrowView(direction: step.direction, tint: green)
#endif
    }

    var body: some View {
        VStack(spacing: 0) {

                // Top bar: exit + lost
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { showExitConfirmation = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "xmark")
                                Text("Exit")
                                    .fontWeight(.medium)
                            }
                            .font(.system(size: 15))
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.red.opacity(0.12)))
                        }

                        Spacer()

                        Menu {
                            Section("Need help getting back on track?") {
                                Button {
                                    navigationVM.previousStep()
                                } label: {
                                    Label("Go back one step", systemImage: "arrow.uturn.backward")
                                }
                                Button(role: .destructive) {
                                    navigationVM.startNavigation()
                                } label: {
                                    Label("Restart from the beginning", systemImage: "arrow.counterclockwise")
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Lost?")
                                    .fontWeight(.medium)
                            }
                            .font(.system(size: 15))
                            .foregroundColor(orange)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(orange.opacity(0.12)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Overstep warning banner (inline, below top bar)
                    if showOverstepBanner {
                        overstepBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                if showNextTrainBanner {
                    TrainArrivalPill()
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }

                Spacer()

                // Direction arrows (same triple-stack + motion/heading animation as AR)
                directionArrows
                    .frame(height: 200)

                Spacer().frame(height: 24)

                // Direction label
                Text(step.label)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Spacer().frame(height: 8)

                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Label(formattedDistance, systemImage: "ruler")
                        if showStepCounter {
                            Label("\(navigationVM.stepsRemainingInLeg) steps left", systemImage: "shoeprints.fill")
                        }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(green)

                    Text("Estimated Time Remaining: \(step.estimatedTimeRemaining)")
                        .font(.system(size: 14))
                        .foregroundColor(green.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 32)

                Spacer()

                // Activate AR button
                Button(action: { navigationVM.toggleARMode() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arkit")
                        Text("Activate AR Mode")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Capsule().fill(Color(hex: "#006FEE")))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

                // Step navigation controls
                VStack(spacing: 6) {
                    Text("Look ahead or go back to a previous step")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        NavButton(
                            title: "← Previous",
                            action: { navigationVM.previousStep() },
                            filled: false,
                            disabled: navigationVM.isFirstStep
                        )

                        NavButton(
                            title: navigationVM.isLastStep ? "Arrived" : "Next →",
                            action: { navigationVM.nextStep() },
                            filled: true,
                            disabled: false
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: navigationVM.currentStepIndex)
        .animation(.easeInOut(duration: 0.3), value: showOverstepBanner)
#if os(iOS)
        .onAppear {
            motion.start()
            headingAttitude.configure(route: navigationVM.activeRoute)
            headingAttitude.resetSession()
            headingAttitude.update(legIndex: navigationVM.currentStepIndex, deviceHeading: motion.magneticHeadingDegrees)
        }
        .onDisappear {
            motion.stop()
        }
        .onChange(of: navigationVM.activeRoute?.id) { _, _ in
            headingAttitude.configure(route: navigationVM.activeRoute)
            headingAttitude.resetSession()
            headingAttitude.update(legIndex: navigationVM.currentStepIndex, deviceHeading: motion.magneticHeadingDegrees)
        }
        .onChange(of: navigationVM.currentStepIndex) { _, newIndex in
            // Fresh trip / "Restart" sets step 0 and step count 0; capture a new forward heading.
            if newIndex == 0, navigationVM.stepCount == 0 {
                headingAttitude.resetSession()
            }
            headingAttitude.update(legIndex: newIndex, deviceHeading: motion.magneticHeadingDegrees)
        }
        .onChange(of: motion.magneticHeadingDegrees) { _, newHeading in
            headingAttitude.update(legIndex: navigationVM.currentStepIndex, deviceHeading: newHeading)
        }
#endif
        .onChange(of: isOverstepped) { overstepped in
            withAnimation {
                showOverstepBanner = overstepped
            }
        }
        .alert("Exit Navigation?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) { navigationVM.reset() }
        } message: {
            Text("This will end your current route and return to the home screen.")
        }
    }

    private var overstepBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.system(size: 15))

            VStack(alignment: .leading, spacing: 1) {
                Text("You may have missed a turn")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Tap \"Lost?\" above to recalibrate.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Button(action: { withAnimation { showOverstepBanner = false } }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(orange.cornerRadius(10))
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .shadow(color: orange.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Nav Button

struct NavButton: View {
    let title: String
    let action: () -> Void
    let filled: Bool
    var disabled: Bool = false

    private let green = Color(hex: "#17c964")

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(disabled ? Color.gray : (filled ? .white : green))
                .background(
                    Capsule()
                        .fill(disabled ? Color.gray.opacity(0.12) : (filled ? green : Color.clear))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(disabled ? Color.gray.opacity(0.3) : green, lineWidth: 2)
                )
        }
        .disabled(disabled)
    }
}
