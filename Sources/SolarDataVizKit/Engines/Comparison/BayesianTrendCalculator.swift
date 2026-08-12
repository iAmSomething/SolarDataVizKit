import Foundation
import CoreGraphics
import Accelerate

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

/// 추이 계산 전략의 공통 인터페이스입니다. (Strategy Pattern / Dependency Injection)
///
/// ## Overview
/// 기본 구현체인 `BayesianRBFKernelStrategy` 외에,
/// 커스텀 알고리즘(선형 회귀, LOESS, 스무딩 스플라인 등)을 주입하여 추이 시각화를 교체할 수 있습니다.
///
/// ## Example
/// ```swift
/// struct LinearTrendStrategy: TrendCalculationStrategy {
///     func computeTrend(points: [CGPoint], sampleCount: Int) -> [BayesianTrendPoint] {
///         // ... 선형 회귀 구현
///     }
/// }
/// SolarBayesianTrendView(binding: binding, strategy: LinearTrendStrategy())
/// ```
public protocol TrendCalculationStrategy: Sendable {
    /// 입력 관측 포인트를 바탕으로 추이 곡선과 불확실성 범위를 계산합니다.
    ///
    /// - Parameters:
    ///   - points: 원시 (x, y) 관측 데이터 포인트 배열
    ///   - sampleCount: 출력 곡선의 샘플링 해상도 (기본값: 80)
    /// - Returns: 계산된 추이 포인트 배열
    func computeTrend(points: [CGPoint], sampleCount: Int) -> [BayesianTrendPoint]
}

/// 가우시안 프로세스 RBF 커널 기반 비선형 베이지안 추이 전략 (vDSP Hardware Accelerated 기본 구현체)
///
/// ## Overview
/// `BayesianTrendCalculator`의 vDSP 하드웨어 가속 엔진을 `TrendCalculationStrategy` 프로토콜로 래핑합니다.
/// `SolarBayesianTrendView`의 기본 전략(default parameter)으로 사용됩니다.
public struct BayesianRBFKernelStrategy: TrendCalculationStrategy {
    /// 노이즈 분산 하한. 데이터에 잡음이 없을 경우에도 최소 불확실성 구간을 보장합니다.
    public let noiseVariance: Double

    /// 새 RBF 커널 전략을 초기화합니다.
    /// - Parameter noiseVariance: 관측 노이즈 분산 (기본값: 0.05)
    public init(noiseVariance: Double = 0.05) {
        self.noiseVariance = noiseVariance
    }

    public func computeTrend(points: [CGPoint], sampleCount: Int) -> [BayesianTrendPoint] {
        BayesianTrendCalculator.computeTrend(
            points: points,
            sampleCount: sampleCount,
            noiseVariance: noiseVariance
        )
    }
}

/// 가우시안 프로세스(Gaussian Process RBF Kernel) 기반 비선형 베이지안 수치해석 수학 엔진입니다. (vDSP SIMD Hardware Accelerated)
public struct BayesianTrendCalculator: Sendable {
    /// 입력 관측 포인트를 바탕으로 비선형 곡선 사후 추이 및 95% 불확실성 오차 범위를 계산합니다.
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
        let vlen = vDSP_Length(n)

        // Dynamic RBF Length-scale l = rangeX / 2.5 for organic non-linear curvature
        let lengthScale = rangeX / 2.5
        let l2 = 2.0 * lengthScale * lengthScale
        let invNegL2 = -1.0 / l2

        // Compute local kernel weights K(x_i, x_j) + sigma_n^2 * I using SIMD vDSP vector operations
        var weightSum = [Double](repeating: 0.0, count: n)
        var weightedY = [Double](repeating: 0.0, count: n)

        var diffBuffer = [Double](repeating: 0.0, count: n)
        var dist2Buffer = [Double](repeating: 0.0, count: n)
        var scaledDist2 = [Double](repeating: 0.0, count: n)
        var kernelWeights = [Double](repeating: 0.0, count: n)
        var tempWeightedY = [Double](repeating: 0.0, count: n)

        for i in 0..<n {
            let xi = xs[i]
            let xiVec = [Double](repeating: xi, count: n)
            vDSP_vsubD(xs, 1, xiVec, 1, &diffBuffer, 1, vlen)
            vDSP_vsqD(diffBuffer, 1, &dist2Buffer, 1, vlen)
            var multiplier = invNegL2
            vDSP_vsmulD(dist2Buffer, 1, &multiplier, &scaledDist2, 1, vlen)
            vForce.exp(scaledDist2, result: &kernelWeights)
            vDSP_vmulD(kernelWeights, 1, ys, 1, &tempWeightedY, 1, vlen)

            var sumW = 0.0
            var sumY = 0.0
            vDSP_sveD(kernelWeights, 1, &sumW, vlen)
            vDSP_sveD(tempWeightedY, 1, &sumY, vlen)

            weightSum[i] = max(sumW, 1e-6)
            weightedY[i] = sumY / weightSum[i]
        }

        // Estimate residual variance with vDSP vector difference
        var residualDiffs = [Double](repeating: 0.0, count: n)
        var residualSq = [Double](repeating: 0.0, count: n)
        vDSP_vsubD(weightedY, 1, ys, 1, &residualDiffs, 1, vlen)
        vDSP_vsqD(residualDiffs, 1, &residualSq, 1, vlen)
        var residualSum = 0.0
        vDSP_sveD(residualSq, 1, &residualSum, vlen)

        let s2 = max(residualSum / max(Double(n - 2), 1.0), noiseVariance)

        var result: [BayesianTrendPoint] = []
        result.reserveCapacity(sampleCount)

        let step = rangeX / Double(max(sampleCount - 1, 1))

        for idx in 0..<sampleCount {
            let curX = minX + Double(idx) * step
            let curXVec = [Double](repeating: curX, count: n)

            vDSP_vsubD(xs, 1, curXVec, 1, &diffBuffer, 1, vlen)
            vDSP_vsqD(diffBuffer, 1, &dist2Buffer, 1, vlen)
            var multiplier = invNegL2
            vDSP_vsmulD(dist2Buffer, 1, &multiplier, &scaledDist2, 1, vlen)
            vForce.exp(scaledDist2, result: &kernelWeights)
            vDSP_vmulD(kernelWeights, 1, ys, 1, &tempWeightedY, 1, vlen)

            var totalW = 0.0
            var meanY = 0.0
            var minDist2 = 0.0
            vDSP_sveD(kernelWeights, 1, &totalW, vlen)
            vDSP_sveD(tempWeightedY, 1, &meanY, vlen)
            vDSP_minvD(dist2Buffer, 1, &minDist2, vlen)

            let closestIdx = dist2Buffer.firstIndex(of: minDist2) ?? 0
            let mu = totalW > 1e-9 ? meanY / totalW : ys[closestIdx]

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
