import SwiftUI

struct HistoryView: View {

    @StateObject private var historyStore = HistoryStore()
    @State private var showClearConfirm = false

    // MARK: - Body

    var body: some View {
        Group {
            if historyStore.events.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .navigationTitle("アラート履歴")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !historyStore.events.isEmpty {
                    Button("クリア", role: .destructive) {
                        showClearConfirm = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "履歴をすべて削除しますか？",
            isPresented: $showClearConfirm
        ) {
            Button("削除", role: .destructive) {
                historyStore.clear()
            }
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.6))
            Text("アラート履歴なし")
                .font(.title3.bold())
            Text("安全運転を続けています")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - List

    private var listView: some View {
        List {
            // セッション別にグループ化
            let grouped = Dictionary(grouping: historyStore.events) { $0.sessionId }

            ForEach(grouped.keys.sorted(by: { a, b in
                let aFirst = grouped[a]!.first!.startedAt
                let bFirst = grouped[b]!.first!.startedAt
                return aFirst > bFirst
            }), id: \.self) { sessionId in
                Section {
                    ForEach(grouped[sessionId]!.sorted(by: { $0.startedAt > $1.startedAt })) { event in
                        AlertEventRow(event: event)
                    }
                } header: {
                    Text("セッション: \(sessionId.uuidString.prefix(8).uppercased())")
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row

struct AlertEventRow: View {
    let event: AlertEvent

    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: iconName(event.alertType))
                .font(.title3)
                .foregroundStyle(iconColor(event.alertType))
                .frame(width: 32)

            // 詳細
            VStack(alignment: .leading, spacing: 2) {
                Text(event.alertType.displayName)
                    .font(.subheadline.bold())
                Text(event.formattedStartedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 継続秒数
            Text(event.formattedDuration)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(iconColor(event.alertType).opacity(0.1))
                .foregroundStyle(iconColor(event.alertType))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }

    private func iconName(_ type: AlertType) -> String {
        switch type {
        case .eyesClosedWarning: return "eye.slash"
        case .eyesClosedDanger:  return "exclamationmark.triangle.fill"
        case .lookingDown:       return "arrow.down.circle.fill"
        case .lookingAway:       return "arrow.left.arrow.right.circle.fill"
        case .faceMissing:       return "person.crop.circle.badge.questionmark"
        }
    }

    private func iconColor(_ type: AlertType) -> Color {
        switch type {
        case .eyesClosedWarning: return .yellow
        case .eyesClosedDanger:  return .red
        case .lookingDown:       return .orange
        case .lookingAway:       return .orange
        case .faceMissing:       return .gray
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
