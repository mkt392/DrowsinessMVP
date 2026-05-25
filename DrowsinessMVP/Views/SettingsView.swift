import SwiftUI

struct SettingsView: View {

    @AppStorage("settings_json") private var settingsJSON: String = ""

    @State private var settings = DetectionSettings()
    @State private var saved = false

    // MARK: - Body

    var body: some View {
        Form {
            // 目閉じ閾値
            Section("目閉じ判定") {
                LabeledContent("注意（秒）") {
                    Stepper(
                        String(format: "%.1f", settings.eyesClosedWarningSeconds),
                        value: $settings.eyesClosedWarningSeconds,
                        in: 0.3...5.0,
                        step: 0.1
                    )
                }
                LabeledContent("危険（秒）") {
                    Stepper(
                        String(format: "%.1f", settings.eyesClosedDangerSeconds),
                        value: $settings.eyesClosedDangerSeconds,
                        in: 0.5...10.0,
                        step: 0.1
                    )
                }
                LabeledContent("閉じ判定閾値") {
                    Stepper(
                        String(format: "%.2f", settings.eyeClosedThreshold),
                        value: $settings.eyeClosedThreshold,
                        in: 0.1...0.6,
                        step: 0.01
                    )
                }
            }

            // 下向き
            Section("下向き判定") {
                LabeledContent("継続秒数") {
                    Stepper(
                        String(format: "%.1f", settings.lookingDownSeconds),
                        value: $settings.lookingDownSeconds,
                        in: 0.5...10.0,
                        step: 0.1
                    )
                }
                LabeledContent("Pitch 閾値") {
                    Stepper(
                        String(format: "%.2f", settings.lookingDownPitchThreshold),
                        value: $settings.lookingDownPitchThreshold,
                        in: -1.0 ... -0.05,
                        step: 0.05
                    )
                }
            }

            // よそ見
            Section("よそ見判定") {
                LabeledContent("継続秒数") {
                    Stepper(
                        String(format: "%.1f", settings.lookingAwaySeconds),
                        value: $settings.lookingAwaySeconds,
                        in: 0.5...10.0,
                        step: 0.1
                    )
                }
                LabeledContent("Yaw 閾値") {
                    Stepper(
                        String(format: "%.2f", settings.lookingAwayYawThreshold),
                        value: $settings.lookingAwayYawThreshold,
                        in: 0.1...0.8,
                        step: 0.05
                    )
                }
            }

            // 顔未検出
            Section("顔未検出") {
                LabeledContent("判定秒数") {
                    Stepper(
                        String(format: "%.1f", settings.faceMissingSeconds),
                        value: $settings.faceMissingSeconds,
                        in: 1.0...10.0,
                        step: 0.5
                    )
                }
            }

            // アラート
            Section("アラート") {
                Toggle("アラート音", isOn: $settings.alertSoundEnabled)
                Toggle("バイブ", isOn: $settings.vibrationEnabled)

                Picker("感度", selection: $settings.sensitivity) {
                    ForEach(DetectionSettings.Sensitivity.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 保存
            Section {
                Button {
                    saveSettings()
                } label: {
                    HStack {
                        Spacer()
                        Label(saved ? "保存しました" : "設定を保存", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        Spacer()
                    }
                }
                .foregroundStyle(saved ? .green : .blue)
            }

            // リセット
            Section {
                Button(role: .destructive) {
                    settings = DetectionSettings()
                } label: {
                    HStack {
                        Spacer()
                        Label("デフォルトに戻す", systemImage: "arrow.counterclockwise")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: loadSettings)
    }

    // MARK: - Persistence

    private func loadSettings() {
        guard !settingsJSON.isEmpty,
              let data = settingsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(DetectionSettings.self, from: data)
        else { return }
        settings = decoded
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings),
              let json = String(data: data, encoding: .utf8)
        else { return }
        settingsJSON = json
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
