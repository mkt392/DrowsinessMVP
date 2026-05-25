# 眠気検知MVP — DrowsinessMVP

iOS 向け眠気・よそ見検知アプリ（注意喚起用）

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| UI | SwiftUI |
| カメラ | AVFoundation |
| 顔検出 | Apple Vision (VNDetectFaceLandmarksRequest) |
| 目開閉判定 | Eye Aspect Ratio (EAR) |
| 頭部姿勢 | VNFaceObservation.pitch/yaw (iOS 16+) / ランドマーク推定 |
| データ保存 | JSON / UserDefaults |

## ディレクトリ構成

```
DrowsinessMVP/
  App/
    DrowsinessMVPApp.swift        ← @main エントリーポイント
  Views/
    HomeView.swift                ← ホーム画面
    DrivingView.swift             ← 運転中画面（メイン）
    HistoryView.swift             ← アラート履歴
    SettingsView.swift            ← 設定画面
    CameraPreviewView.swift       ← UIViewRepresentable ラッパー
  Camera/
    CameraManager.swift           ← フロントカメラ管理
  Vision/
    FaceLandmarkDetector.swift    ← Vision 顔検出（Protocol 化）
    EyeStateDetector.swift        ← EAR による目開閉判定
    HeadPoseEstimator.swift       ← Pitch/Yaw/Roll 推定
  Domain/
    DrowsinessState.swift         ← 状態 enum
    AlertType.swift               ← アラート種別 enum
    DetectionResult.swift         ← フレームごとの検出結果
    DetectionSettings.swift       ← 判定閾値設定
  Services/
    DrowsinessDetectionEngine.swift  ← 中核エンジン（状態管理）
    AlertService.swift               ← 音・バイブ制御
    HistoryStore.swift               ← 履歴 JSON 保存
  Models/
    AlertEvent.swift              ← アラートイベント記録
    DrivingSession.swift          ← 走行セッション
```

## Xcode プロジェクト作成手順

1. Xcode を開く → **File > New > Project**
2. **iOS > App** を選択
   - Product Name: `DrowsinessMVP`
   - Bundle Identifier: `com.yourname.drowsinessmvp`
   - Interface: **SwiftUI**
   - Language: **Swift**
3. 保存先に `DrowsinessMVP/` フォルダを指定
4. Xcode が生成したデフォルトの `ContentView.swift` と `Assets.xcassets` は削除
5. Xcode のプロジェクトナビゲーターで **DrowsinessMVP グループを右クリック > Add Files to "DrowsinessMVP"...** を選択し、以下のフォルダを追加（Copy items にチェックしない）:
   - `App/DrowsinessMVPApp.swift`
   - `Views/` フォルダごと
   - `Camera/` フォルダごと
   - `Vision/` フォルダごと
   - `Domain/` フォルダごと
   - `Services/` フォルダごと
   - `Models/` フォルダごと
6. **Info.plist** の `NSCameraUsageDescription` が設定されていることを確認
7. **Signing & Capabilities** に実機の Apple ID を設定

## 必要な設定

### Info.plist（カメラ権限）
```xml
<key>NSCameraUsageDescription</key>
<string>インカメラで顔を検出し、眠気・よそ見・下向きを検知するために使用します。映像は保存されません。</string>
```

### 最低動作環境
- iOS 15.0+（iOS 16+ 推奨：Pitch/Yaw が精度向上）
- 実機推奨（シミュレーターではカメラ不可）

## 判定ロジック概要

```
EAR (Eye Aspect Ratio) = Σ縦距離 / (横距離 × ペア数)
EAR / 0.35 → eyeOpenRatio (0.0〜1.0)

eyeOpenRatio < 0.35 → 目閉じ判定
目閉じ継続 ≥ 1.0秒 → EyesClosedWarning
目閉じ継続 ≥ 2.0秒 → EyesClosedDanger + アラート

pitch < -0.3 かつ継続 ≥ 2.0秒 → LookingDown + アラート
|yaw| > 0.35 かつ継続 ≥ 2.5秒 → LookingAway + アラート
顔未検出 継続 ≥ 3.0秒 → FaceMissing + アラート

同一アラート種別は 5秒間クールダウン
```

## 将来の拡張ポイント

- `FaceLandmarkDetecting` プロトコル経由で **MediaPipe Face Landmarker** へ差し替え可能
- `HistoryStoring` プロトコル経由で **SwiftData / CoreData** へ差し替え可能
- `HeadPoseEstimator` を Vision → Core ML モデルへ差し替え可能

## 免責事項

> このアプリは**運転補助・注意喚起用**です。  
> 検知結果の正確性を保証するものではありません。  
> 事故防止を保証するものではありません。
