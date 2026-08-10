import Foundation
import CoreGraphics

/// 베이지안 수치해석 추이 및 오차 범위(불확실성 구간) 정보를 저장하는 구조체입니다. (Swift 6 Strict Concurrency Sendable 준수)
public struct BayesianTrendPoint: Sendable, Identifiable, Hashable {
    /// 데이터 포인트 식별자
    public let id: String
    /// X축 좌표/수치
    public let x: Double
    /// 베이지안 비선형 사후 평균 추이 값 \(\mu(x)\)
    public let mean: Double
    /// 95% 신뢰 구간 상한선 \(\mu(x) + 1.96\sigma(x)\)
    public let upperLimit: Double
    /// 95% 신뢰 구간 하한선 \(\mu(x) - 1.96\sigma(x)\)
    public let lowerLimit: Double
    /// 표준 편차 \(\sigma(x)\)
    public let stdDev: Double

    public init(
        id: String = UUID().uuidString,
        x: Double,
        mean: Double,
        upperLimit: Double,
        lowerLimit: Double,
        stdDev: Double
    ) {
        self.id = id
        self.x = x
        self.mean = mean
        self.upperLimit = upperLimit
        self.lowerLimit = lowerLimit
        self.stdDev = stdDev
    }
}

/// 가우시안 프로세스(Gaussian Process RBF Kernel) 기반 비선형 베이지안 수치해석 수학 엔진입니다.
public struct BayesianTrendCalculator: Sendable {
    /// 입력 관측 포인트를 바탕으로 비선형 곡선 사후 추이 및 95% 불확실성 오차 범위를 계산합니다.
    ///
    /// - Parameters:
    ///   - points: 입력 관측 2D 좌표 포인트 배열 (CGPoint)
    ///   - sampleCount: 보간 생성할 X축 분할 샘플 수 (기본값: 80)
    ///   - noiseVariance: 관측 노이즈 분산 \(\sigma_n^2\) (기본값: 0.05)
    /// - Returns: 비선형 베이지안 추이 포인트 배열
    @Sendable
    public static func computeTrend(
        points: [CGPoint],
        sampleCount: Int = 80,
        noiseVariance: Double = 0.05
    ) -> [BayesianTrendPoint] {
        // 1. NaN / Infinity input sanitization
        let sanitized = points.compactMap { pt -> CGPoint? in
            let x = Double(pt.x)
            let y = Double(pt.y)
            guard x.isFinite, y.isFinite, !x.isNaN, !y.isNaN else { return nil }
            return pt
        }

        // 2. Defense against empty or single point datasets
        guard sanitized.count >= 2 else {
            if let single = sanitized.first {
                let x = Double(single.x)
                let y = Double(single.y)
                return [BayesianTrendPoint(id: "single", x: x, mean: y, upperLimit: y + 1.0, lowerLimit: y - 1.0, stdDev: 0.5)]
            }
            return []
        }

        let sorted = sanitized.sorted(by: { $0.x < $1.x })

        let sampledPoints: [CGPoint]
        if sorted.count > 500 {
            let strideStep = max(Int(ceil(Double(sorted.count) / 500.0)), 1)
            sampledPoints = sorted.enumerated().compactMap { $0.offset % strideStep == 0 ? $0.element : nil }
        } else {
            sampledPoints = sorted
        }

        let minX = Double(sorted.first!.x)
        let maxX = Double(sorted.last!.x)
        let rangeX = max(maxX - minX, 1e-6)

        let xs = sampledPoints.map { Double($0.x) }
        let ys = sampledPoints.map { Double($0.y) }
        let n = sampledPoints.count

        // Dynamic RBF Length-scale l = rangeX / 2.5 for organic non-linear curvature
        let lengthScale = rangeX / 2.5
        let l2 = 2.0 * lengthScale * lengthScale

        // Compute local kernel weights K(x_i, x_j) + sigma_n^2 * I
        var weightSum = [Double](repeating: 0.0, count: n)
        var weightedY = [Double](repeating: 0.0, count: n)

        for i in 0..<n {
            var sumW = 0.0
            var sumY = 0.0
            for j in 0..<n {
                let dx = xs[i] - xs[j]
                let dist2 = dx * dx
                let w = exp(-dist2 / l2)
                sumW += w
                sumY += w * ys[j]
            }
            weightSum[i] = max(sumW, 1e-6)
            weightedY[i] = sumY / weightSum[i]
        }

        // Estimate residual variance
        var residualSum = 0.0
        for i in 0..<n {
            let diff = ys[i] - weightedY[i]
            residualSum += diff * diff
        }
        let s2 = max(residualSum / max(Double(n - 2), 1.0), noiseVariance)

        var result: [BayesianTrendPoint] = []
        result.reserveCapacity(sampleCount)

        let step = rangeX / Double(max(sampleCount - 1, 1))

        for idx in 0..<sampleCount {
            let curX = minX + Double(idx) * step

            // Non-linear Gaussian Kernel Nadaraya-Watson Bayesian Posterior Mean \(\mu(x_*)\)
            var totalW = 0.0
            var meanY = 0.0
            var minDist2 = Double.greatestFiniteMagnitude
            var closestIdx = 0

            for i in 0..<n {
                let dx = curX - xs[i]
                let dist2 = dx * dx
                if dist2 < minDist2 {
                    minDist2 = dist2
                    closestIdx = i
                }
                let w = exp(-dist2 / l2)
                totalW += w
                meanY += w * ys[i]
            }

            let mu = totalW > 1e-9 ? meanY / totalW : ys[closestIdx]

            // Distance-based Bayesian Uncertainty expansion: \(\sigma(x_*) = \sqrt{s^2 (1 + d_{min}^2 / l^2)}\)
            let distLeverage = sqrt(minDist2) / max(lengthScale, 1e-6)
            let sigma = sqrt(max(s2 * (1.0 + distLeverage * distLeverage * 0.5), 1e-6))

            let z95 = 1.96
            let upper = mu + z95 * sigma
            let lower = mu - z95 * sigma

            result.append(
                BayesianTrendPoint(
                    id: "bayes_curve_\(idx)",
                    x: curX,
                    mean: mu,
                    upperLimit: upper,
                    lowerLimit: lower,
                    stdDev: sigma
                )
            )
        }

        return result
    }
}
