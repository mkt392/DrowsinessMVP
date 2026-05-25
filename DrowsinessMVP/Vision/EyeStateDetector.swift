import Foundation
import Vision

/// 目の開閉状態を判定する
final class EyeStateDetector {

    struct EyeOpenRatios {
        var left: Float
        var right: Float
    }

    /// Vision ランドマークから左右の EyeOpenRatio を計算する
    /// Eye Aspect Ratio (EAR) = (縦距離の合計) / (横距離 * 2)
    func computeEyeOpenRatios(
        landmarks: VNFaceLandmarks2D?,
        faceBoundingBox: CGRect
    ) -> EyeOpenRatios {
        guard let landmarks else {
            return EyeOpenRatios(left: 1.0, right: 1.0)
        }

        let leftRatio  = eyeAspectRatio(points: landmarks.leftEye?.normalizedPoints)
        let rightRatio = eyeAspectRatio(points: landmarks.rightEye?.normalizedPoints)

        return EyeOpenRatios(left: leftRatio, right: rightRatio)
    }

    // MARK: - Private

    /// EAR を計算する（6点モデル）
    /// Vision の leftEye/rightEye は正規化座標の配列（時計回り or 反時計回り）
    private func eyeAspectRatio(points: [CGPoint]?) -> Float {
        guard let pts = points, pts.count >= 6 else {
            return 1.0  // ランドマークなし → 開いているとみなす
        }

        // Vision の目ランドマークは 16点（seventySevenPoints の場合）
        // 6点モデルに近似: 0=左端, 3=右端, 上側中央, 下側中央
        // 点が 6点以上ある場合: 0,1,2,3,4,5 で EAR を近似
        let n = pts.count

        // 水平距離（目の幅）: pts[0] ↔ pts[n/2]
        let p0 = pts[0]
        let p3 = pts[n / 2]
        let horizontal = distance(p0, p3)

        guard horizontal > 0 else { return 1.0 }

        // 垂直距離（複数ペア）
        var verticalSum: CGFloat = 0.0
        let pairs: [(Int, Int)]

        if n >= 12 {
            // 16点モデル近似: 上まぶた 1,2, 下まぶた n-2, n-3
            pairs = [(1, n - 1), (2, n - 2), (3, n - 3)]
        } else {
            // 6点モデル
            pairs = [(1, 5), (2, 4)]
        }

        for (i, j) in pairs {
            if i < n && j < n {
                verticalSum += distance(pts[i], pts[j])
            }
        }

        let ear = Float(verticalSum / (CGFloat(pairs.count) * horizontal))
        // EAR を 0〜1 にクランプ（正規化）
        // 通常の開き = 0.2〜0.4 EAR なので 0.4 でスケール
        return min(1.0, ear / 0.35)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
