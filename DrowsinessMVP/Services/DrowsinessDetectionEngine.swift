import Foundation
import Combine
import AVFoundation

/// フレームごとの DetectionResult を受け取り、DrowsinessState を更新する中核エンジン
@MainActor
final class DrowsinessDetectionEngine: ObservableObject {

    // MARK: - Published

    @Published var currentState: DrowsinessState = .normal
    @Published var faceDetected: Bool = false
    @Published var eyeOpenRatio: Float = 1.0
    @Published var drowsinessScore: Int = 0  // 0〜100

    // MARK: - Dependencies

    private let alertService: AlertService
    private let historyStore: HistoryStore
    var settings: DetectionSettings

    // MARK: - Private Timing State

    private var eyesClosedStartTime: Date?
    private var lookingDownStartTime: Date?
    private var lookingAwayStartTime: Date?
    private var faceMissingStartTime: Date?

    private var currentSessionId: UUID?
    private var lastAlertStartedAt: [AlertType: Date] = [:]

    // MARK: - Init

    init(
        alertService: AlertService,
        historyStore: HistoryStore,
        settings: DetectionSettings = DetectionSettings()
    ) {
        self.alertService = alertService
        self.historyStore = historyStore
        self.settings = settings
    }

    // MARK: - Session

    func startSession() {
        currentSessionId = UUID()
        resetTimers()
    }

    func stopSession() {
        resetTimers()
        currentState = .normal
        drowsinessScore = 0
    }

    // MARK: - Process Frame

    func process(result: DetectionResult) {
        eyeOpenRatio = result.eyeOpenRatio
        faceDetected = result.faceDetected

        let now = Date()

        // 顔未検出
        if !result.faceDetected {
            handleFaceMissing(now: now)
            eyesClosedStartTime = nil
            lookingDownStartTime = nil
            lookingAwayStartTime = nil
            updateScore()
            return
        }

        faceMissingStartTime = nil

        // 目閉じ
        let eyesClosed = result.eyeOpenRatio < settings.effectiveEyeClosedThreshold
        handleEyesClosed(eyesClosed: eyesClosed, now: now)

        // 下向き
        let lookingDown = result.pitchEstimate < settings.lookingDownPitchThreshold
        handleLookingDown(lookingDown: lookingDown, now: now)

        // よそ見
        let lookingAway = abs(result.yawEstimate) > settings.lookingAwayYawThreshold
        handleLookingAway(lookingAway: lookingAway, now: now)

        // 状態優先度で最終 state を決定
        updateState(now: now, result: result)
        updateScore()
    }

    // MARK: - Individual Condition Handlers

    private func handleEyesClosed(eyesClosed: Bool, now: Date) {
        if eyesClosed {
            if eyesClosedStartTime == nil {
                eyesClosedStartTime = now
            }
        } else {
            eyesClosedStartTime = nil
        }
    }

    private func handleLookingDown(lookingDown: Bool, now: Date) {
        if lookingDown {
            if lookingDownStartTime == nil {
                lookingDownStartTime = now
            }
        } else {
            lookingDownStartTime = nil
        }
    }

    private func handleLookingAway(lookingAway: Bool, now: Date) {
        if lookingAway {
            if lookingAwayStartTime == nil {
                lookingAwayStartTime = now
            }
        } else {
            lookingAwayStartTime = nil
        }
    }

    private func handleFaceMissing(now: Date) {
        if faceMissingStartTime == nil {
            faceMissingStartTime = now
        }
        let elapsed = now.timeIntervalSince(faceMissingStartTime!)
        if elapsed >= settings.effectiveFaceMissingSeconds {
            triggerAlertIfNeeded(type: .faceMissing, duration: elapsed, now: now)
            currentState = .faceMissing
        } else {
            currentState = .normal
        }
    }

    private func updateState(now: Date, result: DetectionResult) {
        var candidates: [(state: DrowsinessState, priority: Int)] = []

        // 目閉じ
        if let start = eyesClosedStartTime {
            let elapsed = now.timeIntervalSince(start)
            if elapsed >= settings.effectiveEyesClosedDangerSeconds {
                triggerAlertIfNeeded(type: .eyesClosedDanger, duration: elapsed, now: now)
                candidates.append((.eyesClosedDanger, 5))
            } else if elapsed >= settings.effectiveEyesClosedWarningSeconds {
                triggerAlertIfNeeded(type: .eyesClosedWarning, duration: elapsed, now: now)
                candidates.append((.eyesClosedWarning, 4))
            }
        }

        // 下向き
        if let start = lookingDownStartTime {
            let elapsed = now.timeIntervalSince(start)
            if elapsed >= settings.effectiveLookingDownSeconds {
                triggerAlertIfNeeded(type: .lookingDown, duration: elapsed, now: now)
                candidates.append((.lookingDown, 3))
            }
        }

        // よそ見
        if let start = lookingAwayStartTime {
            let elapsed = now.timeIntervalSince(start)
            if elapsed >= settings.effectiveLookingAwaySeconds {
                triggerAlertIfNeeded(type: .lookingAway, duration: elapsed, now: now)
                candidates.append((.lookingAway, 3))
            }
        }

        if let best = candidates.max(by: { $0.priority < $1.priority }) {
            currentState = best.state
        } else {
            currentState = .normal
        }
    }

    // MARK: - Alert

    private func triggerAlertIfNeeded(type: AlertType, duration: TimeInterval, now: Date) {
        let coolDown = type.coolDownSeconds
        if let last = lastAlertStartedAt[type],
           now.timeIntervalSince(last) < coolDown {
            return
        }
        lastAlertStartedAt[type] = now

        alertService.trigger(type: type, settings: settings)

        // 履歴保存
        if let sessionId = currentSessionId {
            let event = AlertEvent(
                sessionId: sessionId,
                alertType: type,
                startedAt: now.addingTimeInterval(-duration),
                durationSeconds: duration
            )
            historyStore.save(event: event)
        }
    }

    // MARK: - Score

    private func updateScore() {
        switch currentState {
        case .normal:            drowsinessScore = max(0, drowsinessScore - 2)
        case .eyesClosedWarning: drowsinessScore = min(100, drowsinessScore + 5)
        case .eyesClosedDanger:  drowsinessScore = min(100, drowsinessScore + 20)
        case .lookingDown:       drowsinessScore = min(100, drowsinessScore + 8)
        case .lookingAway:       drowsinessScore = min(100, drowsinessScore + 8)
        case .faceMissing:       drowsinessScore = min(100, drowsinessScore + 3)
        }
    }

    // MARK: - Helpers

    private func resetTimers() {
        eyesClosedStartTime = nil
        lookingDownStartTime = nil
        lookingAwayStartTime = nil
        faceMissingStartTime = nil
        lastAlertStartedAt = [:]
    }
}
