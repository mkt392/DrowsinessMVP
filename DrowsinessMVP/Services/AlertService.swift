import Foundation
import AudioToolbox
import AVFoundation
import UIKit

/// アラート音・バイブを管理するサービス
final class AlertService {

    // MARK: - Private

    private var audioPlayer: AVAudioPlayer?
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Init

    init() {
        feedbackGenerator.prepare()
        impactGenerator.prepare()
        setupAudioSession()
    }

    // MARK: - Public

    func trigger(type: AlertType, settings: DetectionSettings) {
        if settings.alertSoundEnabled {
            playSound(for: type)
        }
        if settings.vibrationEnabled {
            vibrate(for: type)
        }
    }

    // MARK: - Private Sound

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AlertService] AudioSession エラー: \(error)")
        }
    }

    private func playSound(for type: AlertType) {
        let soundID: SystemSoundID
        switch type {
        case .eyesClosedWarning:
            soundID = 1322  // 軽い通知音
        case .eyesClosedDanger:
            soundID = 1005  // 強い警告音
        case .lookingDown:
            soundID = 1054
        case .lookingAway:
            soundID = 1057
        case .faceMissing:
            soundID = 1000
        }
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Private Vibration

    private func vibrate(for type: AlertType) {
        switch type {
        case .eyesClosedDanger:
            // 強いバイブ × 3
            for delay in [0.0, 0.3, 0.6] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.impactGenerator.impactOccurred()
                }
            }
        case .eyesClosedWarning:
            feedbackGenerator.notificationOccurred(.warning)
        case .lookingDown, .lookingAway:
            feedbackGenerator.notificationOccurred(.warning)
        case .faceMissing:
            feedbackGenerator.notificationOccurred(.error)
        }
    }
}
