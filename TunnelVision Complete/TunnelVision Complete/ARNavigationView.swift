import SwiftUI

#if os(iOS)
import UIKit

private let tunnelGreen = Color(red: 23 / 255, green: 201 / 255, blue: 100 / 255)
private let warningOrange = Color(hex: "#f5a524")

struct ARNavigationView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel
    @EnvironmentObject var transitVM: TransitViewModel
    @AppStorage("useMetricUnits") private var useMetric = true
    @AppStorage("showStepCounter") private var showStepCounter = false
    @AppStorage("showNextTrainBanner") private var showNextTrainBanner = false

    @StateObject private var arTracker = ARPositionTracker()
    @StateObject private var motion = DeviceMotionOverlay()
    @StateObject private var routeNav = TunnelRouteNavigator()

    @State private var showExitConfirmation = false

    var body: some View {
        ZStack {
            ARCameraPreview(session: arTracker.session)
                .ignoresSafeArea()

            if let err = arTracker.errorMessage {
                trackingBanner(err)
            }

            overlayContent

            if routeNav.isWrongDirection {
                wrongDirectionOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: routeNav.isWrongDirection)
        .onAppear {
            routeNav.navigationViewModel = navigationVM
            if let route = navigationVM.activeRoute {
                routeNav.configure(with: route)
            }
            arTracker.start()
            motion.start()
            routeNav.start(tracker: arTracker)
        }
        .onDisappear {
            routeNav.stop()
            motion.stop()
            arTracker.stop()
        }
        .onChange(of: motion.magneticHeadingDegrees) { _, newValue in
            routeNav.updateDeviceHeadingDegrees(newValue)
        }
        .statusBarHidden(false)
        .alert("Exit Navigation?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) { navigationVM.reset() }
        } message: {
            Text("This will end your current route and return to the home screen.")
        }
    }

    private func trackingBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
    }

    private var wrongDirectionOverlay: some View {
        ZStack {
            warningOrange.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(warningOrange)

                Text("Wrong Direction")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Turn around to continue")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(warningOrange.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: warningOrange.opacity(0.3), radius: 16, y: 4)
        }
        .allowsHitTesting(false)
    }

    private var overlayContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { showExitConfirmation = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark")
                        Text("Exit")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                    )
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
                    .foregroundStyle(warningOrange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(warningOrange.opacity(0.18))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if showNextTrainBanner {
                trainBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)

            directionCluster

            Spacer(minLength: 0)

            arInfoSection
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

            Button(action: {
                navigationVM.toggleARMode()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                    Text("Back to 2D Mode")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color(hex: "#006FEE")))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            skipControls
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
    }

    private var trainBanner: some View {
        HStack(spacing: 8) {
            if let nextTrain = transitVM.nextTrains.first {
                if transitVM.dataSource == .schedule {
                    Text("The next")
                        .font(.subheadline.weight(.medium))

                    routeBadge(size: 28, font: .headline.weight(.bold))

                    Text("train is scheduled in \(scheduledMinutes(for: nextTrain)) min")
                        .font(.subheadline)
                } else {
                    Text("Next")
                        .font(.subheadline.weight(.medium))

                    routeBadge(size: 28, font: .headline.weight(.bold))

                    if nextTrain.isDelayed {
                        Text("delayed · \(nextTrain.timeRemainingString(from: transitVM.currentTime))")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "#f5a524"))
                    } else {
                        Text("train arriving in \(nextTrain.timeRemainingString(from: transitVM.currentTime))")
                            .font(.subheadline)
                            .foregroundStyle(tunnelGreen)
                    }
                }
            } else {
                inlineRouteText(transitVM.emptyStateMessage,
                                font: .subheadline,
                                color: .secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var directionCluster: some View {
        VStack(spacing: 48) {
            DirectionArrowView(
                direction: routeNav.currentDirection,
                tint: tunnelGreen,
                rotationDegrees: routeNav.arrowRotationDegrees,
                stabilizedOffset: stabilizedOffset,
                arrowShadow: true,
                useFadingStackOpacity: false
            )
            .offset(y: -24)

            Text(routeNav.primaryInstruction)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .animation(.easeOut(duration: 0.2), value: routeNav.primaryInstruction)
                .offset(y: 32)
        }
    }

    private var stabilizedOffset: CGSize {
        CGSize(width: -motion.offset.width, height: -motion.offset.height)
    }

    private var formattedDistance: String {
        let step = navigationVM.currentStep
        if useMetric {
            return String(format: "%.0f m", step.distanceMeters)
        } else {
            return String(format: "%.0f ft", step.distanceMeters * 3.28084)
        }
    }

    private var arInfoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Label(formattedDistance, systemImage: "ruler")
                if showStepCounter {
                    Label("\(navigationVM.stepsRemainingInLeg) steps left", systemImage: "shoeprints.fill")
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(tunnelGreen)

            Text("Estimated Time Remaining: \(navigationVM.currentStep.estimatedTimeRemaining)")
                .font(.system(size: 14))
                .foregroundStyle(tunnelGreen.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var skipControls: some View {
        VStack(spacing: 6) {
            Text("Look ahead or go back to a previous step")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 16) {
                Button(action: { navigationVM.previousStep() }) {
                    Text("← Previous")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(navigationVM.isFirstStep ? tunnelGreen.opacity(0.35) : tunnelGreen)
                        .background(Capsule().fill(Color.clear))
                        .overlay(Capsule().strokeBorder(navigationVM.isFirstStep ? tunnelGreen.opacity(0.25) : tunnelGreen, lineWidth: 2))
                }
                .disabled(navigationVM.isFirstStep)

                Button(action: { navigationVM.nextStep() }) {
                    Text(navigationVM.isLastStep ? "Arrived" : "Next →")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(tunnelGreen))
                        .overlay(Capsule().strokeBorder(tunnelGreen, lineWidth: 2))
                }
            }
        }
    }

    private func routeBadge(size: CGFloat, font: Font) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2185D5"))
                .frame(width: size, height: size)
            Text("L")
                .font(font)
                .foregroundStyle(.white)
        }
    }

    private func scheduledMinutes(for train: Train) -> Int {
        let interval = train.arrivalTime.timeIntervalSince(transitVM.currentTime)
        return max(1, Int((interval / 60).rounded()))
    }

    @ViewBuilder
    private func inlineRouteText(_ message: String, font: Font, color: Color) -> some View {
        let parts = message.components(separatedBy: " L ")
        if parts.count > 1 {
            Text(parts[0] + " ")
                .font(font)
                .foregroundStyle(color)
            routeBadge(size: 28, font: .headline.weight(.bold))
            Text(" " + parts.dropFirst().joined(separator: " L "))
                .font(font)
                .foregroundStyle(color)
        } else {
            Text(message)
                .font(font)
                .foregroundStyle(color)
        }
    }

}

#else

struct ARNavigationView: View {
    var body: some View {
        Text("AR Navigation requires an iPhone with camera and motion sensors.")
            .multilineTextAlignment(.center)
            .padding()
    }
}

#endif
