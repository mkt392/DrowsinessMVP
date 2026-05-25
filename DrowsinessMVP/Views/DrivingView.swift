import SwiftUI
import AVFoundation

struct DrivingView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var cameraManager = CameraManager()
    @StateObject private var engine: DrowsinessDetectionEngine = {
        let alertService = AlertService()
        let historyStore = HistoryStore()
        return DrowsinessDetectionEngine(alertService: alertService, historyStore: historyStore)
    }()

    @State private var detector: VisionFaceLandmarkDetector?
    @State private var showStopConfirm = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // カメラプレビュー
                cameraPreviewSection

                // 情報パネル
                infoPanel
            }

            // 停止ボタン
            VStack {
                HStack {
                    Spacer()
                    stopButton
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                }
                Spacer()
            }

            // アラートオーバーレイ
            if engine.currentState != .normal {
                alertOverlay
            }
        }
        .statusBar(hidden: true)
        .onAppear(perform: startDriving)
        .onDisappear(perform: stopDriving)
        .confirmationDialog("運転を終了しますか？", isPresented: $showStopConfirm) {
            Button("終了", role: .destructive) { dismiss() }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Camera Preview

    private var cameraPreviewSection: some View {
        Group {
            if let layer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: layer)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("カメラ起動中...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
            }
        }
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: 16) {
            // 顔検出状態
            faceDetectionStatus

            // 眠気スコア
            drowsinessScoreView

            // 現在の状態
            stateView

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .padding(.top, 4)
    }

    private var faceDetectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(engine.faceDetected ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            Text(engine.faceDetected ? "Face Detected" : "No Face Detected")
                .font(.subheadline)
                .foregroundStyle(engine.faceDetected ? .green : .secondary)
        }
        .padding(.top, 12)
    }

    private var drowsinessScoreView: some View {
        VStack(spacing: 6) {
            Text("眠気スコア")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(scoreColor)
                    .frame(width: max(0, CGFloat(engine.drowsinessScore) / 100.0 * (UIScreen.main.bounds.width - 48)), height: 12)
                    .animation(.linear(duration: 0.2), value: engine.drowsinessScore)
            }
            .padding(.horizontal, 24)

            Text("\(engine.drowsinessScore) / 100")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var scoreColor: Color {
        switch engine.drowsinessScore {
        case 0..<40:  return .green
        case 40..<70: return .yellow
        default:      return .red
        }
    }

    private var stateView: some View {
        VStack(spacing: 4) {
            Text("現在の状態")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(engine.currentState.displayName)
                .font(.title2.bold())
                .foregroundStyle(stateColor(engine.currentState))
                .animation(.easeInOut, value: engine.currentState)
        }
    }

    private func stateColor(_ state: DrowsinessState) -> Color {
        switch state {
        case .normal:            return .green
        case .eyesClosedWarning: return .yellow
        case .eyesClosedDanger:  return .red
        case .lookingDown:       return .orange
        case .lookingAway:       return .orange
        case .faceMissing:       return .gray
        }
    }

    // MARK: - Alert Overlay

    private var alertOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: alertIcon(engine.currentState))
                    .font(.title2)
                Text(engine.currentState.displayName)
                    .font(.headline.bold())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(stateColor(engine.currentState).opacity(0.9))
            )
            .foregroundStyle(.white)
            .padding(.bottom, UIScreen.main.bounds.height * 0.35 + 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: engine.currentState)
        }
    }

    private func alertIcon(_ state: DrowsinessState) -> String {
        switch state {
        case .normal:            return "checkmark.circle"
        case .eyesClosedWarning: return "eye.slash"
        case .eyesClosedDanger:  return "exclamationmark.triangle.fill"
        case .lookingDown:       return "arrow.down.circle.fill"
        case .lookingAway:       return "arrow.left.arrow.right.circle.fill"
        case .faceMissing:       return "person.crop.circle.badge.questionmark"
        }
    }

    // MARK: - Stop Button

    private var stopButton: some View {
        Button {
            showStopConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(radius: 4)
        }
    }

    // MARK: - Lifecycle

    private func startDriving() {
        let visionDetector = VisionFaceLandmarkDetector()
        detector = visionDetector

        engine.startSession()
        cameraManager.start()

        cameraManager.sampleBufferHandler = { [weak engine] sampleBuffer in
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            Task {
                let result = await visionDetector.detect(
                    sampleBuffer: sampleBuffer,
                    timestamp: timestamp
                )
                await MainActor.run {
                    engine?.process(result: result)
                }
            }
        }
    }

    private func stopDriving() {
        cameraManager.stop()
        cameraManager.sampleBufferHandler = nil
        engine.stopSession()
    }
}

#Preview {
    DrivingView()
}
