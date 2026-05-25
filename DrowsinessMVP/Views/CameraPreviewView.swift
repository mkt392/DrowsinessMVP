import SwiftUI
import AVFoundation

/// AVCaptureVideoPreviewLayer を SwiftUI にラップ
struct CameraPreviewView: UIViewRepresentable {

    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.setPreviewLayer(previewLayer)
    }

    // MARK: - Coordinator

    class PreviewUIView: UIView {
        private var currentPreviewLayer: AVCaptureVideoPreviewLayer?

        func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
            currentPreviewLayer?.removeFromSuperlayer()
            layer.frame = bounds
            layer.videoGravity = .resizeAspectFill
            self.layer.insertSublayer(layer, at: 0)
            currentPreviewLayer = layer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            currentPreviewLayer?.frame = bounds
        }
    }
}
