import SwiftUI
import Charts

/// ## Quick View
/// `SolarComparisonChartView`는 Swift Charts(iOS 16+) 기반의 다중 데이터 시리즈 비교 시각화 컴포넌트입니다.
///
/// - **특징**:
///   - **Dual Series Comparison**: 두 데이터선(Line & Area)을 나란히 배치하고 시각적으로 비교.
///   - **Intersection Haptics**: 데이터 교차점에 도달하는 순간 `playImpact(.medium)` 햅틱 피드백 트리거.
///   - **Scrubbing Tooltip**: 터치 드래그에 맞춰 실시간 델타 차이 수치 오버레이 노출.
///   - **Zero Leak Guaranteed**: 제스처 클로저 내 값 타입 상태 조작으로 메모리 누수 방지.
///
/// ## 사용 예시
/// ```swift
/// SolarComparisonChartView(
///     binding: myBinding,
///     seriesA: "2025 Sales",
///     seriesB: "2026 Sales"
/// )
/// .solarVizTheme(.darkCarbon)
/// ```
public struct SolarComparisonChartView<
    Item: Identifiable & Sendable,
    XValue: Hashable & Sendable & CustomStringConvertible,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let seriesA: String
    public let seriesB: String

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedIndex: Int?
    @State private var previousCrossIndex: Int?

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        seriesA: String = "Series A",
        seriesB: String = "Series B"
    ) {
        self.binding = binding
        self.seriesA = seriesA
        self.seriesB = seriesB
    }

    private var sortedGroups: [(key: String, items: [Item])] {
        binding.sortedGroupedData()
    }

    private var itemsA: [Item] {
        if let match = sortedGroups.first(where: { $0.key == seriesA }) {
            return match.items
        }
        return sortedGroups.first?.items ?? []
    }

    private var itemsB: [Item] {
        if let match = sortedGroups.first(where: { $0.key == seriesB }) {
            return match.items
        }
        return sortedGroups.dropFirst().first?.items ?? []
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
                        Text(seriesA)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.primaryTextColor)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.seriesColors.dropFirst().first ?? Color.blue)
                            .frame(width: 8, height: 8)
                        Text(seriesB)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.primaryTextColor)
                    }
                }
                .padding(.horizontal, 4)

                // Main Chart Canvas
                ZStack(alignment: .topLeading) {
                    Chart {
                        // Draw Area Shading Path
                        ForEach(itemsA) { item in
                            let xVal = binding.extractX(from: item)
                            let yVal = binding.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                        }
                        .foregroundStyle(theme.seriesColors.first ?? theme.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        ForEach(itemsB) { item in
                            let xVal = binding.extractX(from: item)
                            let yVal = binding.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                            .foregroundStyle(theme.seriesColors.dropFirst().first ?? Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [4, 4]))
                        }

                        if let selectedIndex, selectedIndex < itemsA.count {
                            let itemA = itemsA[selectedIndex]
                            let xVal = binding.extractX(from: itemA)

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

                    // Key-Based Joined Tooltip Overlay on Touch Selection
                    if let selectedIndex, selectedIndex < itemsA.count {
                        let itemA = itemsA[selectedIndex]
                        let xKeyA = binding.extractX(from: itemA).description
                        let valA = Double(binding.extractY(from: itemA))

                        // Match item B by exact X-key equality instead of blind array index matching
                        let matchingItemB = itemsB.first { binding.extractX(from: $0).description == xKeyA }
                        let valB = matchingItemB != nil ? Double(binding.extractY(from: matchingItemB!)) : valA

                        DeltaTooltipOverlay(
                            xLabel: xKeyA,
                            valueA: valA,
                            valueB: valB,
                            labelA: seriesA,
                            labelB: seriesB,
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
                            let totalCount = max(itemsA.count, 1)
                            let ratio = min(max(value.location.x / containerWidth, 0.0), 1.0)
                            let index = min(max(Int(round(ratio * CGFloat(totalCount - 1))), 0), totalCount - 1)

                            if selectedIndex != index {
                                selectedIndex = index
                                Task { @MainActor in
                                    SolarVizHaptics.shared.playSelection()
                                }
                                checkIntersectionHaptic(at: index)
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
        .accessibilityLabel("Comparison Line Chart, \(seriesA) versus \(seriesB)")
        .accessibilityValue("\(itemsA.count) data points. Touch or drag to inspect delta values.")
    }

    private func checkIntersectionHaptic(at index: Int) {
        guard index > 0, index < itemsA.count, index < itemsB.count else { return }
        let prevDiff = Double(binding.extractY(from: itemsA[index - 1])) - Double(binding.extractY(from: itemsB[index - 1]))
        let currDiff = Double(binding.extractY(from: itemsA[index])) - Double(binding.extractY(from: itemsB[index]))

        // Check for sign flip (intersection crossing)
        if (prevDiff >= 0 && currDiff < 0) || (prevDiff < 0 && currDiff >= 0) {
            if previousCrossIndex != index {
                previousCrossIndex = index
                Task { @MainActor in
                    SolarVizHaptics.shared.playImpact(style: .medium)
                }
            }
        }
    }
}
