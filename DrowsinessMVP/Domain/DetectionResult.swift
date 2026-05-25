import Foundation
import Vision

/// 1フレームの検出結果
struct DetectionResult {
    /// 顔が検出されたか
    var faceDetected: Bool

    /// 左目の開き度 (0.0=完全閉じ, 1.0=完全開き)
    var leftEyeOpenRatio: Float

    /// 右目の開き度
    var rightEyeOpenRatio: Float

    /// 平均目開き度
    var eyeOpenRatio: Float { (leftEyeOpenRatio + rightEyeOpenRatio) / 2.0 }

    /// Pitch 推定値（下向き: 負、上向き: 正）
    var pitchEstimate: Float

    /// Yaw 推定値（左向き: 負、右向き: 正）
    var yawEstimate: Float

    /// Roll 推定値
    var rollEstimate: Float

    /// フレームのタイムスタンプ
    var timestamp: TimeInterval

    static let empty = DetectionResult(
        faceDetected: false,
        leftEyeOpenRatio: 1.0,
        rightEyeOpenRatio: 1.0,
        pitchEstimate: 0,
        yawEstimate: 0,
        rollEstimate: 0,
        timestamp: 0
    )
}
