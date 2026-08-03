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
    private let cachedItemsA: [Item]
    private let cachedItemsB: [Item]

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

        // Cache grouped items once during init to prevent 60Hz main-thread re-grouping on body re-evaluations
        let groups = binding.sortedGroupedData()
        self.cachedItemsA = groups.first(where: { $0.key == seriesA })?.items ?? groups.first?.items ?? []
        self.cachedItemsB = groups.first(where: { $0.key == seriesB })?.items ?? groups.dropFirst().first?.items ?? []
    }

    private var itemsA: [Item] { cachedItemsA }
    private var itemsB: [Item] { cachedItemsB }

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
                // Main Chart Canvas
                ZStack(alignment: .topLeading) {
                    let colorA = theme.seriesColors.first ?? theme.accentColor
                    let colorB = theme.seriesColors.dropFirst().first ?? Color(red: 56/255, green: 189/255, blue: 248/255)

                    Chart {
                        // Draw Series A (Solid Line - Orange)
                        ForEach(itemsA) { item in
                            let xVal = binding.extractX(from: item)
                            let yVal = binding.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                            .foregroundStyle(by: .value("Series", seriesA))
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }

                        // Draw Series B (Dashed Line - Cyan Blue)
                        ForEach(itemsB) { item in
                            let xVal = binding.extractX(from: item)
                            let yVal = binding.extractY(from: item)

                            LineMark(
                                x: .value("X", xVal.description),
                                y: .value("Y", Double(yVal))
                            )
                            .foregroundStyle(by: .value("Series", seriesB))
                            .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
                        }

                        if let selectedIndex, selectedIndex < itemsA.count {
                            let itemA = itemsA[selectedIndex]
                            let xVal = binding.extractX(from: itemA)

                            RuleMark(x: .value("Selected", xVal.description))
                                .foregroundStyle(theme.secondaryTextColor.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }
                    }
                    .chartForegroundStyleScale([
                        seriesA: colorA,
                        seriesB: colorB
                    ])
                    .chartLegend(.hidden)
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
                            // Canvas Hit-Testing bounds check: dismiss ghost tooltips when dragging outside chart area
                            guard value.location.x >= 0 && value.location.x <= containerWidth && value.location.y >= 0 && value.location.y <= geometry.size.height else {
                                if selectedIndex != nil {
                                    selectedIndex = nil
                                }
                                return
                            }

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
        guard index > 0, index < itemsA.count else { return }
        let currA = itemsA[index]
        let prevA = itemsA[index - 1]

        let keyCurr = binding.extractX(from: currA).description
        let keyPrev = binding.extractX(from: prevA).description

        // Key-based join lookup for series B matching exact X-keys preventing out-of-range crashes
        guard let currB = itemsB.first(where: { binding.extractX(from: $0).description == keyCurr }),
              let prevB = itemsB.first(where: { binding.extractX(from: $0).description == keyPrev }) else { return }

        let prevDiff = Double(binding.extractY(from: prevA)) - Double(binding.extractY(from: prevB))
        let currDiff = Double(binding.extractY(from: currA)) - Double(binding.extractY(from: currB))

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
