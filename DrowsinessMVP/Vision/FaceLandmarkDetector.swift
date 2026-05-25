import Foundation
import Vision
import AVFoundation

// MARK: - Protocol（将来的に MediaPipe へ差し替え可能）

protocol FaceLandmarkDetecting {
    /// CMSampleBuffer から DetectionResult を非同期取得
    func detect(sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) async -> DetectionResult
}

// MARK: - Apple Vision 実装

final class VisionFaceLandmarkDetector: FaceLandmarkDetecting {

    private let eyeStateDetector = EyeStateDetector()
    private let headPoseEstimator = HeadPoseEstimator()

    /// Vision リクエスト（顔 + ランドマーク）
    private lazy var faceRequest: VNDetectFaceLandmarksRequest = {
        let req = VNDetectFaceLandmarksRequest()
        req.constellation = .seventySevenPoints
        return req
    }()

    func detect(sampleBuffer: CMSampleBuffer, timestamp: TimeInterval) async -> DetectionResult {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return .empty
        }

        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .leftMirrored,
                options: [:]
            )
            do {
                try handler.perform([faceRequest])
            } catch {
                continuation.resume(returning: .empty)
                return
            }

            guard let results = faceRequest.results, let face = results.first else {
                var result = DetectionResult.empty
                result.timestamp = timestamp
                continuation.resume(returning: result)
                return
            }

            let landmarks = face.landmarks
            let eyeRatios = eyeStateDetector.computeEyeOpenRatios(landmarks: landmarks, faceBoundingBox: face.boundingBox)
            let pose = headPoseEstimator.estimate(face: face)

            let result = DetectionResult(
                faceDetected: true,
                leftEyeOpenRatio: eyeRatios.left,
                rightEyeOpenRatio: eyeRatios.right,
                pitchEstimate: pose.pitch,
                yawEstimate: pose.yaw,
                rollEstimate: pose.roll,
                timestamp: timestamp
            )
            continuation.resume(returning: result)
        }
    }
}
