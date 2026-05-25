import AVFoundation
import Combine
import UIKit

/// フロントカメラを管理し、フレームを提供する
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Published

    @Published var isRunning: Bool = false
    @Published var cameraPermissionGranted: Bool = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Internal

    /// フレームを受け取るハンドラ（FaceLandmarkDetector が登録する）
    var sampleBufferHandler: ((CMSampleBuffer) -> Void)?

    // MARK: - Private

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.drowsiness.camera.session")
    private let videoDataOutputQueue = DispatchQueue(
        label: "com.drowsiness.camera.videoOutput",
        qos: .userInteractive
    )

    // MARK: - Init

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permission

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }

    // MARK: - Setup

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .medium

            // フロントカメラを選択
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                print("[CameraManager] フロントカメラが見つかりません")
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            } catch {
                print("[CameraManager] Input エラー: \(error)")
                self.session.commitConfiguration()
                return
            }

            // ビデオ出力
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.videoDataOutputQueue)

            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            }

            // プレビューレイヤー作成
            let preview = AVCaptureVideoPreviewLayer(session: self.session)
            preview.videoGravity = .resizeAspectFill

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.previewLayer = preview
            }
        }
    }

    // MARK: - Control

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        sampleBufferHandler?(sampleBuffer)
    }
}
