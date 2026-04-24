import SwiftUI

#if os(iOS)
import UIKit

private let tunnelGreen = Color(red: 23 / 255, green: 201 / 255, blue: 100 / 255)

struct ARNavigationView: View {
    @StateObject private var arTracker = ARPositionTracker()
    @StateObject private var motion = DeviceMotionOverlay()
    @StateObject private var routeNav = TunnelRouteNavigator()

    var body: some View {
        ZStack {
            ARCameraPreview(session: arTracker.session)
                .ignoresSafeArea()

            if let err = arTracker.errorMessage {
                trackingBanner(err)
            }

            overlayContent
        }
        .onAppear {
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

    private var overlayContent: some View {
        VStack(spacing: 0) {
            trainBanner
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Spacer(minLength: 0)

            directionCluster

            Spacer(minLength: 0)

            infoCards
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
        }
    }

    private var trainBanner: some View {
        HStack(spacing: 8) {
            Text("v5")
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.5))
            Text("Next")
                .font(.subheadline.weight(.medium))
            ZStack {
                Circle()
                    .fill(Color(red: 1, green: 0.23, blue: 0.19))
                    .frame(width: 28, height: 28)
                Text("1")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text("train arriving in 4 min")
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var directionCluster: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(tunnelGreen)
                .shadow(color: tunnelGreen.opacity(0.45), radius: 12)

            Image(systemName: "chevron.up.2")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(tunnelGreen.opacity(0.9))

            Text(routeNav.primaryInstruction)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        }
        .offset(stabilizedOffset)
        .rotationEffect(.degrees(routeNav.arrowRotationDegrees))
        .animation(.easeOut(duration: 0.12), value: routeNav.arrowRotationDegrees)
        .animation(.easeOut(duration: 0.1), value: motion.offset)
    }

    private var stabilizedOffset: CGSize {
        CGSize(width: -motion.offset.width, height: -motion.offset.height)
    }

    private var infoCards: some View {
        HStack(spacing: 12) {
            floatingCard(
                title: "Waypoint \(min(routeNav.currentLegIndex + 1, routeNav.totalLegs))/\(routeNav.totalLegs)",
                value: "\(Int(routeNav.distanceToNextWaypoint)) m"
            )
            floatingCard(title: "Steps", value: "\(routeNav.sessionSteps)")
        }
    }

    private func floatingCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tunnelGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tunnelGreen.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}

#else

struct ARNavigationView: View {
    var body: some View {
        Text("TunnelVision — Requirement 3 runs on iPhone with camera and motion.")
            .multilineTextAlignment(.center)
            .padding()
    }
}

#endif
