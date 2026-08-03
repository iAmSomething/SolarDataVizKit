import Foundation
import CoreGraphics

/// 베이지안 수치해석 추이 및 오차 범위(불확실성 구간) 정보를 저장하는 구조체입니다.
public struct BayesianTrendPoint: Sendable, Identifiable, Hashable {
    /// 데이터 포인트 식별자
    public let id: String
    /// X축 좌표/수치
    public let x: Double
    /// 베이지안 사후 평균 추이 값 \(\mu(x)\)
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

/// 베이지안 선형 회귀 및 가우시안 프로세스 기반 추이/불확실성 계산 수학 엔진입니다.
public struct BayesianTrendCalculator: Sendable {
    /// 입력 데이터 포인트를 바탕으로 베이지안 사후 추이 및 95% 불확실성 오차 범위를 계산합니다.
    ///
    /// - Parameters:
    ///   - points: 입력 관측 2D 좌표 포인트 배열 (CGPoint)
    ///   - sampleCount: 보간 생성할 X축 분할 샘플 수 (기본값: 100)
    ///   - noiseVariance: 관측 노이즈 분산 \(\sigma_n^2\) (기본값: 0.05)
    /// - Returns: 베이지안 추이 포인트 배열
    public static func computeTrend(
        points: [CGPoint],
        sampleCount: Int = 100,
        noiseVariance: Double = 0.05
    ) -> [BayesianTrendPoint] {
        guard points.count >= 2 else { return [] }

        let sorted = points.sorted(by: { $0.x < $1.x })
        let minX = Double(sorted.first!.x)
        let maxX = Double(sorted.last!.x)
        let rangeX = max(maxX - minX, 1e-6)

        let xs = sorted.map { Double($0.x) }
        let ys = sorted.map { Double($0.y) }
        let n = Double(sorted.count)

        // Calculate sample means for linear prior
        let meanX = xs.reduce(0.0, +) / n
        let meanY = ys.reduce(0.0, +) / n

        var num = 0.0
        var den = 0.0
        for i in 0..<sorted.count {
            let dx = xs[i] - meanX
            num += dx * (ys[i] - meanY)
            den += dx * dx
        }

        let beta1 = abs(den) > 1e-9 ? num / den : 0.0
        let beta0 = meanY - beta1 * meanX

        // Estimate residual variance
        var residualSum = 0.0
        for i in 0..<sorted.count {
            let pred = beta0 + beta1 * xs[i]
            let diff = ys[i] - pred
            residualSum += diff * diff
        }
        let s2 = max(residualSum / max(n - 2.0, 1.0), noiseVariance)

        var result: [BayesianTrendPoint] = []
        result.reserveCapacity(sampleCount)

        let step = rangeX / Double(max(sampleCount - 1, 1))

        for idx in 0..<sampleCount {
            let curX = minX + Double(idx) * step
            let mu = beta0 + beta1 * curX

            // Bayesian leverage uncertainty function: \(\sigma^2(x) = s^2 (1/N + (x-\bar{x})^2 / \sum (x-\bar{x})^2)\)
            let dx = curX - meanX
            let leverage = (1.0 / n) + (den > 1e-9 ? (dx * dx) / den : 0.0)
            let sigma = sqrt(s2 * (1.0 + leverage))

            let z95 = 1.96
            let upper = mu + z95 * sigma
            let lower = mu - z95 * sigma

            result.append(
                BayesianTrendPoint(
                    id: "bayes_\(idx)",
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
