import Foundation
import Combine

/// アラート履歴をローカル（JSON）に保存する
/// 将来的に SwiftData/CoreData への差し替えが可能なように protocol 化
protocol HistoryStoring {
    func save(event: AlertEvent)
    func loadAll() -> [AlertEvent]
    func clear()
}

final class HistoryStore: HistoryStoring, ObservableObject {

    @Published var events: [AlertEvent] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileURL = dir.appendingPathComponent("alert_history.json")
        events = loadAll()
    }

    // MARK: - Public

    func save(event: AlertEvent) {
        events.insert(event, at: 0)
        persist()
    }

    func loadAll() -> [AlertEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([AlertEvent].self, from: data)
        } catch {
            print("[HistoryStore] 読み込みエラー: \(error)")
            return []
        }
    }

    func clear() {
        events = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private func persist() {
        // 最大 1000件
        let toSave = Array(events.prefix(1000))
        do {
            let data = try JSONEncoder().encode(toSave)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[HistoryStore] 保存エラー: \(error)")
        }
    }
}
