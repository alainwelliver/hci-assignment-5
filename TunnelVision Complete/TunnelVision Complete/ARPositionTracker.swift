// AI Attribution: Generated with Claude Opus 4.6

#if os(iOS)
import ARKit
import Combine
import Foundation

@MainActor
final class ARPositionTracker: NSObject, ObservableObject {
    let session = ARSession()

    @Published private(set) var isTracking = false
    @Published var errorMessage: String?

    var onDisplacement: ((SIMD2<Float>) -> Void)?

    private var previousPosition: SIMD3<Float>?

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        config.isLightEstimationEnabled = false
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isTracking = false
        previousPosition = nil
    }

    func stop() {
        session.pause()
        isTracking = false
    }
}

// MARK: - ARSessionDelegate

extension ARPositionTracker: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pos = frame.camera.transform.columns.3
        let current = SIMD3<Float>(pos.x, pos.y, pos.z)
        let tracking = frame.camera.trackingState == .normal

        DispatchQueue.main.async {
            self.isTracking = tracking

            if tracking {
                self.errorMessage = nil
                if let prev = self.previousPosition {
                    let dx = current.x - prev.x
                    let dz = current.z - prev.z
                    let d = SIMD2<Float>(dx, dz)
                    if simd_length(d) > 0.0005 {
                        self.onDisplacement?(d)
                    }
                }
            }
            self.previousPosition = current
        }
    }

    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async {
            switch camera.trackingState {
            case .notAvailable:
                self.errorMessage = "AR tracking not available"
                self.isTracking = false
            case .limited(let reason):
                self.isTracking = false
                switch reason {
                case .initializing:
                    self.errorMessage = "Initializing AR…"
                case .excessiveMotion:
                    self.errorMessage = "Move slower"
                case .insufficientFeatures:
                    self.errorMessage = "Need more visual detail"
                case .relocalizing:
                    self.errorMessage = "Relocalizing…"
                @unknown default:
                    self.errorMessage = "AR limited"
                }
            case .normal:
                self.errorMessage = nil
                self.isTracking = true
            }
        }
    }
}
#endif
