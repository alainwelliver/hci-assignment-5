#if os(iOS)
import ARKit
import SwiftUI
import UIKit

/// Shows the live camera feed from an ARKit session (replaces the old AVCaptureSession preview).
struct ARCameraPreview: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session = session
        arView.automaticallyUpdatesLighting = false
        arView.rendersContinuously = true
        arView.contentMode = .scaleAspectFill
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if uiView.session !== session {
            uiView.session = session
        }
    }
}
#endif
