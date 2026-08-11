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

    private var activeItemsA: [Item] {
        let groups = binding.sortedGroupedData()
        return groups.first(where: { $0.key == seriesA })?.items ?? groups.first?.items ?? []
    }

    private var activeItemsB: [Item] {
        let groups = binding.sortedGroupedData()
        return groups.first(where: { $0.key == seriesB })?.items ?? groups.dropFirst().first?.items ?? []
    }

    private var activeDictB: [String: Item] {
        var dict: [String: Item] = [:]
        for item in activeItemsB {
            let key = binding.extractX(from: item).description
            dict[key] = item
        }
        return dict
    }

    public let initialSelectedIndex: Int?
    public let showIntersectionRegions: Bool

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        seriesA: String = "Series A",
        seriesB: String = "Series B",
        initialSelectedIndex: Int? = nil,
        showIntersectionRegions: Bool = false
    ) {
        self.binding = binding
        self.seriesA = seriesA
        self.seriesB = seriesB
        self.initialSelectedIndex = initialSelectedIndex
        self.showIntersectionRegions = showIntersectionRegions
        self._selectedIndex = State(initialValue: initialSelectedIndex)
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
                    let colorA = theme.seriesColors.first ?? theme.accentColor
                    let colorB = theme.seriesColors.dropFirst().first ?? Color(red: 56/255, green: 189/255, blue: 248/255)
                    let itemsA = activeItemsA
                    let itemsB = activeItemsB

                    Chart {
                        seriesMarks(items: itemsA, seriesName: seriesA, isDashed: false)
                        seriesMarks(items: itemsB, seriesName: seriesB, isDashed: true)

                        if let selectedIndex, selectedIndex < itemsA.count {
                            let itemA = itemsA[selectedIndex]
                            RuleMark(x: .value("Selected", binding.extractX(from: itemA).description))
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
                    if let selectedIndex, selectedIndex < activeItemsA.count {
                        let itemA = activeItemsA[selectedIndex]
                        let xKeyA = binding.extractX(from: itemA).description
                        let valA = Double(binding.extractY(from: itemA))

                        // Fast O(1) Dictionary Lookup
                        let matchingItemB = activeDictB[xKeyA]
                        let valB = matchingItemB != nil ? Double(binding.extractY(from: matchingItemB!)) : valA

                        let totalCount = max(activeItemsA.count, 1)
                        let progress = CGFloat(selectedIndex) / CGFloat(max(totalCount - 1, 1))
                        let targetX = containerWidth * progress
                        let tooltipWidth: CGFloat = 160.0
                        let clampedX = min(max(targetX - tooltipWidth / 2, 0), containerWidth - tooltipWidth)

                        DeltaTooltipOverlay(
                            xLabel: xKeyA,
                            valueA: valA,
                            valueB: valB,
                            labelA: seriesA,
                            labelB: seriesB,
                            theme: theme
                        )
                        .offset(x: clampedX, y: 0)
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

                            let totalCount = max(activeItemsA.count, 1)
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
        .accessibilityValue("\(activeItemsA.count) data points. Touch or drag to inspect delta values.")
        .onChange(of: initialSelectedIndex) { newValue in
            selectedIndex = newValue
        }
    }

    private func checkIntersectionHaptic(at index: Int) {
        guard index > 0, index < activeItemsA.count else { return }
        let currA = activeItemsA[index]
        let prevA = activeItemsA[index - 1]

        let keyCurr = binding.extractX(from: currA).description
        let keyPrev = binding.extractX(from: prevA).description

        // Key-based join lookup for series B matching exact X-keys preventing out-of-range crashes
        guard let currB = activeItemsB.first(where: { binding.extractX(from: $0).description == keyCurr }),
              let prevB = activeItemsB.first(where: { binding.extractX(from: $0).description == keyPrev }) else { return }

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

    @ChartContentBuilder
    private func seriesMarks(items: [Item], seriesName: String, isDashed: Bool) -> some ChartContent {
        ForEach(items) { item in
            let xStr = binding.extractX(from: item).description
            let yVal = Double(binding.extractY(from: item))
            LineMark(
                x: .value("X", xStr),
                y: .value("Y", yVal)
            )
            .foregroundStyle(by: .value("Series", seriesName))
            .lineStyle(StrokeStyle(lineWidth: isDashed ? 2 : 3, dash: isDashed ? [4, 4] : []))
        }
    }
}
