#if os(iOS)
import Combine
import CoreMotion
import Foundation

/// Horizontal parallax from **yaw** only (rotation in the plane of the screen), not roll/pitch.
/// Arrow alignment comes from `TunnelRouteNavigator`. Uses a baseline at `start()` so the cluster
/// stays stable relative to how you were holding the phone when the screen appeared.
final class DeviceMotionOverlay: ObservableObject {
    private let motion = CMMotionManager()

    @Published var offset: CGSize = .zero
    /// 0…360° clockwise from magnetic north — fed to `TunnelRouteNavigator` for the arrow (same yaw as parallax).
    @Published var magneticHeadingDegrees: Double?

    private var yawBaselineRadians: Double?

    func start() {
        yawBaselineRadians = nil
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 45.0
        motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, _ in
            guard let self, let attitude = data?.attitude else { return }
            let yaw = attitude.yaw
            if self.yawBaselineRadians == nil {
                self.yawBaselineRadians = yaw
            }
            let baseline = self.yawBaselineRadians ?? yaw
            var deltaYaw = Self.shortestAngleDelta(from: baseline, to: yaw)
            // Cap so large spins don’t throw the HUD off-screen (~±35° from baseline).
            let cap = 35.0 * .pi / 180
            if deltaYaw > cap { deltaYaw = cap }
            if deltaYaw < -cap { deltaYaw = -cap }
            let x = CGFloat(deltaYaw) * 95
            self.offset = CGSize(width: x, height: 0)
            self.magneticHeadingDegrees = Self.headingDegrees(fromYawRadians: yaw)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        yawBaselineRadians = nil
        magneticHeadingDegrees = nil
    }

    private static func headingDegrees(fromYawRadians yaw: Double) -> Double {
        var deg = -yaw * 180.0 / .pi
        deg = deg.truncatingRemainder(dividingBy: 360)
        if deg < 0 { deg += 360 }
        return deg
    }

    /// Wraps angular difference to (−π, π] so heading wrap-around stays stable.
    private static func shortestAngleDelta(from: Double, to: Double) -> Double {
        var d = to - from
        while d > .pi { d -= 2 * .pi }
        while d <= -.pi { d += 2 * .pi }
        return d
    }
}
#endif
