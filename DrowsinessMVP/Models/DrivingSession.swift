import Foundation

/// 走行セッション
struct DrivingSession: Identifiable, Codable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date?

    var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        guard let d = duration else { return "-" }
        let minutes = Int(d) / 60
        let seconds = Int(d) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
