import Foundation
import Vision

/// 頭部姿勢（Pitch/Yaw/Roll）を推定する
final class HeadPoseEstimator {

    struct HeadPose {
        /// 上下 (-1.0 下向き〜+1.0 上向き)
        var pitch: Float
        /// 左右 (-1.0 左向き〜+1.0 右向き)
        var yaw: Float
        /// ロール (-1.0〜+1.0)
        var roll: Float
    }

    /// Vision の VNFaceObservation から姿勢を推定する
    func estimate(face: VNFaceObservation) -> HeadPose {
        // iOS 16+ の場合は pitch/yaw/roll が直接取得できる
        if #available(iOS 16.0, *) {
            if let pitch = face.pitch, let yaw = face.yaw, let roll = face.roll {
                return HeadPose(
                    pitch: pitch.floatValue,
                    yaw: yaw.floatValue,
                    roll: roll.floatValue
                )
            }
        }

        // フォールバック: ランドマーク位置から簡易推定
        return estimateFromLandmarks(face: face)
    }

    // MARK: - Fallback ランドマーク推定

    private func estimateFromLandmarks(face: VNFaceObservation) -> HeadPose {
        guard let landmarks = face.landmarks else {
            return HeadPose(pitch: 0, yaw: 0, roll: 0)
        }

        let pitch = estimatePitch(landmarks: landmarks, boundingBox: face.boundingBox)
        let yaw   = estimateYaw(landmarks: landmarks, boundingBox: face.boundingBox)
        let roll  = estimateRoll(landmarks: landmarks)

        return HeadPose(pitch: pitch, yaw: yaw, roll: roll)
    }

    /// 鼻・目・口の縦位置関係から Pitch を推定
    private func estimatePitch(
        landmarks: VNFaceLandmarks2D,
        boundingBox: CGRect
    ) -> Float {
        guard let nose = landmarks.nose?.normalizedPoints.first,
              let leftEye = landmarks.leftEye?.normalizedPoints.first,
              let rightEye = landmarks.rightEye?.normalizedPoints.first
        else { return 0 }

        let eyeMidY = (leftEye.y + rightEye.y) / 2.0
        // 鼻が目より大幅に下（顔座標系では上）にあれば下向き
        let relativeNoseY = nose.y - eyeMidY
        // 正規化: 約 -0.3〜+0.3 を -1〜+1 にマッピング
        let pitch = Float(relativeNoseY / 0.3)
        return max(-1.0, min(1.0, pitch))
    }

    /// 左右目の x 座標差・顔矩形幅から Yaw を推定
    private func estimateYaw(
        landmarks: VNFaceLandmarks2D,
        boundingBox: CGRect
    ) -> Float {
        guard let leftEyePts = landmarks.leftEye?.normalizedPoints,
              let rightEyePts = landmarks.rightEye?.normalizedPoints,
              let leftX = leftEyePts.first?.x,
              let rightX = rightEyePts.first?.x
        else { return 0 }

        // 正面向きなら左目(0.3付近) 右目(0.7付近)
        let eyeMidX = (leftX + rightX) / 2.0
        // 0.5 から外れた量を Yaw とみなす
        let yaw = Float((eyeMidX - 0.5) * 2.0)
        return max(-1.0, min(1.0, yaw))
    }

    /// 左右目の y 座標差から Roll を推定
    private func estimateRoll(landmarks: VNFaceLandmarks2D) -> Float {
        guard let leftEyePts = landmarks.leftEye?.normalizedPoints,
              let rightEyePts = landmarks.rightEye?.normalizedPoints,
              let leftPt = leftEyePts.first,
              let rightPt = rightEyePts.first
        else { return 0 }

        let dx = rightPt.x - leftPt.x
        let dy = rightPt.y - leftPt.y
        guard dx != 0 else { return 0 }
        let angle = atan2(dy, dx)
        // ラジアン → -1〜+1 正規化（π/4 = 45度を上限）
        return Float(angle / (Double.pi / 4))
    }
}
