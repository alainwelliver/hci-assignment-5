// AI Attribution: Generated with Claude Opus 4.6

#if os(iOS)
import ARKit
import SwiftUI
import UIKit

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
