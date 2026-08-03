import SwiftUI
import Charts

/// `SolarDualComparisonChartView`는 서로 다른 두 독립 데이터 모델(Heterogenous Data Models e.g. SalesModel vs ExpenseModel)을
/// 대조하여 비교 렌더링하는 시각화 컴포넌트입니다.
public struct SolarDualComparisonChartView<
    ItemA: Identifiable & Sendable,
    ItemB: Identifiable & Sendable,
    XValue: Hashable & Sendable & CustomStringConvertible,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let bindingA: VizDataBinding<ItemA, XValue, YValue>
    public let bindingB: VizDataBinding<ItemB, XValue, YValue>
    public let labelA: String
    public let labelB: String

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedIndex: Int?

    public init(
        bindingA: VizDataBinding<ItemA, XValue, YValue>,
        bindingB: VizDataBinding<ItemB, XValue, YValue>,
        labelA: String = "Series A",
        labelB: String = "Series B"
    ) {
        self.bindingA = bindingA
        self.bindingB = bindingB
        self.labelA = labelA
        self.labelB = labelB
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            let containerWidth = max(geometry.size.width, 1.0)

            VStack(alignment: .leading, spacing: 12) {
                // Header Legend
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.seriesColors.first ?? theme.accentColor)
                            .frame(width: 8, height: 8)
                        Text(labelA)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.primaryTextColor)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.seriesColors.dropFirst().first ?? Color.blue)
                            .frame(width: 8, height: 8)
                        Text(labelB)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.primaryTextColor)
                    }
                }
                .padding(.horizontal, 4)

                ZStack(alignment: .topLeading) {
                    Chart {
                        ForEach(bindingA.data) { item in
                            let xVal = bindingA.extractX(from: item)
                            let yVal = bindingA.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                        }
                        .foregroundStyle(theme.seriesColors.first ?? theme.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        ForEach(bindingB.data) { item in
                            let xVal = bindingB.extractX(from: item)
                            let yVal = bindingB.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                            .foregroundStyle(theme.seriesColors.dropFirst().first ?? Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [4, 4]))
                        }

                        if let selectedIndex, selectedIndex < bindingA.data.count {
                            let itemA = bindingA.data[selectedIndex]
                            let xVal = bindingA.extractX(from: itemA)

                            RuleMark(x: .value("Selected", xVal.description))
                                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: theme.gridLineWidth, dash: [2, 2]))
                                .foregroundStyle(theme.borderColor)
                            AxisValueLabel()
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: theme.gridLineWidth))
                                .foregroundStyle(theme.borderColor)
                            AxisValueLabel()
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }
                    .padding(8)

                    if let selectedIndex, selectedIndex < bindingA.data.count {
                        let itemA = bindingA.data[selectedIndex]
                        let xKeyA = bindingA.extractX(from: itemA).description
                        let valA = Double(bindingA.extractY(from: itemA))

                        let matchingItemB = bindingB.data.first { bindingB.extractX(from: $0).description == xKeyA }
                        let valB = matchingItemB != nil ? Double(bindingB.extractY(from: matchingItemB!)) : valA

                        DeltaTooltipOverlay(
                            xLabel: xKeyA,
                            valueA: valA,
                            valueB: valB,
                            labelA: labelA,
                            labelB: labelB,
                            theme: theme
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .padding(12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(theme.borderColor, lineWidth: 1)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard value.location.x >= 0 && value.location.x <= containerWidth && value.location.y >= 0 && value.location.y <= geometry.size.height else {
                                if selectedIndex != nil { selectedIndex = nil }
                                return
                            }

                            let totalCount = max(bindingA.data.count, 1)
                            let ratio = min(max(value.location.x / containerWidth, 0.0), 1.0)
                            let index = min(max(Int(round(ratio * CGFloat(totalCount - 1))), 0), totalCount - 1)

                            if selectedIndex != index {
                                selectedIndex = index
                                Task { @MainActor in
                                    SolarVizHaptics.shared.playSelection()
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedIndex = nil
                            }
                        }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Heterogenous Dual Comparison Line Chart, \(labelA) versus \(labelB)")
    }
}
