import SwiftUI
import Charts

/// 베이지안 수치해석 추이 및 오차 범위(95% 신뢰 불확실성 구간) 시각화 컴포넌트입니다. (Swift 6 Concurrency & Zero Main-Thread Blocking)
///
/// ## Strategy Pattern (Dependency Injection)
/// 기본 전략 `BayesianRBFKernelStrategy`를 사용하거나, `TrendCalculationStrategy` 프로토콜을 구현한
/// 커스텀 전략(선형 회귀, LOESS 등)을 주입하여 추이 알고리즘을 교체할 수 있습니다.
///
/// ```swift
/// SolarBayesianTrendView(
///     binding: binding,
///     strategy: MyCustomTrendStrategy()
/// )
/// ```
public struct SolarBayesianTrendView<Item: Identifiable & Sendable, XValue: SolarPlottable & BinaryFloatingPoint, YValue: BinaryFloatingPoint & Sendable>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let title: String
    public let bandOpacity: Double
    /// 추이 계산 전략 (기본값: 가우시안 프로세스 RBF 커널 vDSP 가속 엔진)
    public let strategy: any TrendCalculationStrategy

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedPointIndex: Int?
    @State private var trendPoints: [BayesianTrendPoint] = []

    /// 추이 시각화 뷰를 초기화합니다.
    ///
    /// - Parameters:
    ///   - binding: 데이터 바인딩 래퍼
    ///   - title: 차트 제목 (기본값: "Bayesian Trend & Uncertainty")
    ///   - bandOpacity: 95% 불확실성 영역의 투명도 (기본값: 0.20)
    ///   - strategy: 추이 계산 전략 (기본값: `BayesianRBFKernelStrategy()`)
    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        title: String = "Bayesian Trend & Uncertainty",
        bandOpacity: Double = 0.20,
        strategy: any TrendCalculationStrategy = BayesianRBFKernelStrategy()
    ) {
        self.binding = binding
        self.title = title
        self.bandOpacity = bandOpacity
        self.strategy = strategy
    }

    public var body: some View {
        let theme = environmentTheme
        let points = trendPoints

        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                // Header Legend
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 8, height: 8)
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.primaryTextColor)
                    }

                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.accentColor.opacity(bandOpacity))
                            .frame(width: 14, height: 8)
                        Text("95% Uncertainty Band")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                .padding(.horizontal, 4)

                ZStack(alignment: .topLeading) {
                    Chart {
                        chartContent(points: points, theme: theme)
                    }
                    .chartOverlay { proxy in
                        GeometryReader { chartGeo in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if #available(macOS 14.0, iOS 17.0, *) {
                                                if let frame = proxy.plotFrame {
                                                    let origin = chartGeo[frame].origin
                                                    let locationX = value.location.x - origin.x
                                                    if let xVal: Double = proxy.value(atX: locationX) {
                                                        let closest = points.enumerated().min(by: { abs($0.element.x - xVal) < abs($1.element.x - xVal) })
                                                        selectedPointIndex = closest?.offset
                                                    }
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedPointIndex = nil
                                        }
                                )
                        }
                    }

                    // Interactive Glassmorphism Tooltip
                    if let idx = selectedPointIndex, idx >= 0, idx < points.count {
                        let pt = points[idx]
                        let margin = (pt.upperLimit - pt.mean)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "X: %.2f", pt.x))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.primaryTextColor)

                            HStack(spacing: 8) {
                                Text(String(format: "Mean: %.2f", pt.mean))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(theme.accentColor)

                                Text(String(format: "±%.2f (95%%)", margin))
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.backgroundColor.opacity(0.92))
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                        .padding(12)
                        .transition(.opacity)
                    }
                }
            }
            .padding(12)
            .background(theme.backgroundColor)
            .cornerRadius(environmentTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                    .stroke(environmentTheme.borderColor, lineWidth: 1)
            )
        }
        .task(id: binding.versionToken) {
            let calculated = await calculateTrendOffMainThread(
                binding: binding,
                strategy: strategy
            )
            if !Task.isCancelled {
                self.trendPoints = calculated
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bayesian Trend and Uncertainty Plot")
        .accessibilityValue("\(binding.data.count) observation points")
    }



    nonisolated private func calculateTrendOffMainThread(
        binding: VizDataBinding<Item, XValue, YValue>,
        strategy: any TrendCalculationStrategy
    ) async -> [BayesianTrendPoint] {
        if Task.isCancelled { return [] }
        let rawPoints = binding.data.map { item -> CGPoint in
            let x = Double(binding.extractX(from: item))
            let y = Double(binding.extractY(from: item))
            return CGPoint(x: x, y: y)
        }
        return strategy.computeTrend(points: rawPoints, sampleCount: 80)
    }

    @ChartContentBuilder
    private func chartContent(points: [BayesianTrendPoint], theme: SolarVizTheme) -> some ChartContent {
        let bandColor = theme.accentColor.opacity(bandOpacity)

        // 1. Raw Scatter Points
        ForEach(binding.data) { item in
            PointMark(
                x: .value("X", Double(binding.extractX(from: item))),
                y: .value("Y", Double(binding.extractY(from: item)))
            )
            .foregroundStyle(theme.secondaryTextColor.opacity(0.7))
            .symbolSize(24)
        }

        // 2. 95% Bayesian Uncertainty Band (AreaMark)
        ForEach(points) { pt in
            AreaMark(
                x: .value("X", pt.x),
                yStart: .value("Lower", pt.lowerLimit),
                yEnd: .value("Upper", pt.upperLimit)
            )
            .foregroundStyle(bandColor)
            .interpolationMethod(.catmullRom)
        }

        // 3. Posterior Mean Line
        ForEach(points) { pt in
            LineMark(
                x: .value("X", pt.x),
                y: .value("Mean", pt.mean)
            )
            .foregroundStyle(theme.accentColor)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .interpolationMethod(.catmullRom)
        }

        // 4. Touch Highlight
        if let idx = selectedPointIndex, idx >= 0, idx < points.count {
            let selectedPt = points[idx]

            RuleMark(x: .value("Selected X", selectedPt.x))
                .foregroundStyle(theme.primaryTextColor.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            PointMark(
                x: .value("Selected X", selectedPt.x),
                y: .value("Selected Mean", selectedPt.mean)
            )
            .foregroundStyle(theme.accentColor)
            .symbolSize(70)
        }
    }
}
