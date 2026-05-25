import Foundation

/// 眠気状態の種別
enum DrowsinessState: String, CaseIterable {
    case normal            = "Normal"
    case eyesClosedWarning = "EyesClosedWarning"
    case eyesClosedDanger  = "EyesClosedDanger"
    case lookingDown       = "LookingDown"
    case lookingAway       = "LookingAway"
    case faceMissing       = "FaceMissing"

    var displayName: String {
        switch self {
        case .normal:            return "正常"
        case .eyesClosedWarning: return "目閉じ注意"
        case .eyesClosedDanger:  return "目閉じ危険"
        case .lookingDown:       return "下向き"
        case .lookingAway:       return "よそ見"
        case .faceMissing:       return "顔未検出"
        }
    }

    var colorName: String {
        switch self {
        case .normal:            return "green"
        case .eyesClosedWarning: return "yellow"
        case .eyesClosedDanger:  return "red"
        case .lookingDown:       return "orange"
        case .lookingAway:       return "orange"
        case .faceMissing:       return "gray"
        }
    }

    var priority: Int {
        switch self {
        case .eyesClosedDanger:  return 5
        case .eyesClosedWarning: return 4
        case .lookingDown:       return 3
        case .lookingAway:       return 3
        case .faceMissing:       return 2
        case .normal:            return 0
        }
    }
}
