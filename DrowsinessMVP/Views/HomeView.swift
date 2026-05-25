import SwiftUI

struct HomeView: View {

    @State private var showDriving = false
    @State private var showHistory = false
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // ロゴ・タイトル
                    VStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)

                        Text("眠気検知")
                            .font(.largeTitle.bold())

                        Text("Drowsiness Monitor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // メインボタン
                    Button {
                        showDriving = true
                    } label: {
                        Label("運転開始", systemImage: "car.fill")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)

                    // サブボタン
                    HStack(spacing: 16) {
                        Button {
                            showHistory = true
                        } label: {
                            Label("履歴", systemImage: "clock.fill")
                                .font(.callout.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        }

                        Button {
                            showSettings = true
                        } label: {
                            Label("設定", systemImage: "gearshape.fill")
                                .font(.callout.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // 注意文言
                    disclaimerView
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showDriving) {
                DrivingView()
            }
            .navigationDestination(isPresented: $showHistory) {
                HistoryView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerView: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("注意事項")
                    .fontWeight(.semibold)
            }
            .font(.footnote)

            Text("このアプリは運転補助・注意喚起用です。\n検知結果の正確性を保証するものではありません。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

#Preview {
    HomeView()
}
