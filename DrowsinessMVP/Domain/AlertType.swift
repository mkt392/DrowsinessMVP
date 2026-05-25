import Foundation

/// アラート種別
enum AlertType: String, Codable, CaseIterable {
    case eyesClosedWarning = "EyesClosedWarning"
    case eyesClosedDanger  = "EyesClosedDanger"
    case lookingDown       = "LookingDown"
    case lookingAway       = "LookingAway"
    case faceMissing       = "FaceMissing"

    var displayName: String {
        switch self {
        case .eyesClosedWarning: return "目閉じ（注意）"
        case .eyesClosedDanger:  return "目閉じ（危険）"
        case .lookingDown:       return "下向き"
        case .lookingAway:       return "よそ見"
        case .faceMissing:       return "顔未検出"
        }
    }

    /// クールダウン秒数（同一アラートの連続発報防止）
    var coolDownSeconds: TimeInterval { 5.0 }

    /// 対応する DrowsinessState
    var state: DrowsinessState {
        switch self {
        case .eyesClosedWarning: return .eyesClosedWarning
        case .eyesClosedDanger:  return .eyesClosedDanger
        case .lookingDown:       return .lookingDown
        case .lookingAway:       return .lookingAway
        case .faceMissing:       return .faceMissing
        }
    }
}
