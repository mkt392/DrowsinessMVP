import Foundation

/// アラートイベントの記録
struct AlertEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var sessionId: UUID
    var alertType: AlertType
    var startedAt: Date
    var durationSeconds: TimeInterval
    var createdAt: Date = Date()

    var formattedStartedAt: String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm:ss"
        return f.string(from: startedAt)
    }

    var formattedDuration: String {
        String(format: "%.1f秒", durationSeconds)
    }
}
