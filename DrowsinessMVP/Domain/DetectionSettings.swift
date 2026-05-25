import Foundation

/// 判定ロジックの閾値設定
struct DetectionSettings: Codable {
    /// 目閉じ判定の EyeOpenRatio 閾値（これ以下を「閉じ」とみなす）
    var eyeClosedThreshold: Float = 0.35

    /// 目閉じ注意とみなす継続秒数
    var eyesClosedWarningSeconds: TimeInterval = 1.0

    /// 目閉じ危険とみなす継続秒数
    var eyesClosedDangerSeconds: TimeInterval = 2.0

    /// 下向き判定の Pitch 閾値（この値より小さければ下向き）
    var lookingDownPitchThreshold: Float = -0.3

    /// 下向き継続秒数
    var lookingDownSeconds: TimeInterval = 2.0

    /// よそ見判定の Yaw 閾値（絶対値がこれ以上）
    var lookingAwayYawThreshold: Float = 0.35

    /// よそ見継続秒数
    var lookingAwaySeconds: TimeInterval = 2.5

    /// 顔未検出継続秒数
    var faceMissingSeconds: TimeInterval = 3.0

    /// アラート音 ON/OFF
    var alertSoundEnabled: Bool = true

    /// バイブ ON/OFF
    var vibrationEnabled: Bool = true

    /// 感度（Low/Medium/High で各閾値をオフセット）
    var sensitivity: Sensitivity = .medium

    enum Sensitivity: String, Codable, CaseIterable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"

        var eyeClosedOffset: Float {
            switch self {
            case .low:    return -0.05
            case .medium: return 0.0
            case .high:   return 0.05
            }
        }

        var timeOffset: TimeInterval {
            switch self {
            case .low:    return 0.5
            case .medium: return 0.0
            case .high:   return -0.3
            }
        }
    }

    /// 感度補正後の目閉じ閾値
    var effectiveEyeClosedThreshold: Float {
        eyeClosedThreshold + sensitivity.eyeClosedOffset
    }

    /// 感度補正後の目閉じ注意秒数
    var effectiveEyesClosedWarningSeconds: TimeInterval {
        max(0.3, eyesClosedWarningSeconds + sensitivity.timeOffset)
    }

    /// 感度補正後の目閉じ危険秒数
    var effectiveEyesClosedDangerSeconds: TimeInterval {
        max(0.5, eyesClosedDangerSeconds + sensitivity.timeOffset)
    }

    /// 感度補正後の下向き秒数
    var effectiveLookingDownSeconds: TimeInterval {
        max(0.5, lookingDownSeconds + sensitivity.timeOffset)
    }

    /// 感度補正後のよそ見秒数
    var effectiveLookingAwaySeconds: TimeInterval {
        max(0.5, lookingAwaySeconds + sensitivity.timeOffset)
    }

    /// 感度補正後の顔未検出秒数
    var effectiveFaceMissingSeconds: TimeInterval {
        max(1.0, faceMissingSeconds + sensitivity.timeOffset)
    }
}
