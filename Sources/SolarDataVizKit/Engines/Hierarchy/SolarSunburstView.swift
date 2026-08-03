import SwiftUI

/// ## Quick View
/// `SunburstArc`는 Sunburst 동심원 링 상의 부채꼴 아치 세그먼트 데이터 구조체입니다.
public struct SunburstArc<Item: Identifiable & Sendable>: Identifiable, Sendable {
    public let id: String
    public let item: Item
    public let startAngle: Angle
    public let endAngle: Angle
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat
    public let label: String
    public let percentage: Double

    public init(
        id: String = UUID().uuidString,
        item: Item,
        startAngle: Angle,
        endAngle: Angle,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        label: String,
        percentage: Double
    ) {
        self.id = id
        self.item = item
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.label = label
        self.percentage = percentage
    }
}

/// ## Quick View
/// `SolarSunburstView`는 1차 대분류 및 2차 소분류 계층 구조를 동심원 부채꼴 링으로 확장하여 시각화하는 뷰 컴포넌트입니다.
///
/// - **특징**:
///   - **Concentric Ring Donut**: 계층형 세그먼트를 부채꼴 링 형태로 아크 드로잉.
///   - **Interactive Arc Selection**: 부채꼴 아치 선택 시 오버레이 강조 및 햅틱 피드백 트리거.
///
/// ## 사용 예시
/// ```swift
/// SolarSunburstView(binding: mySunburstBinding)
///     .solarVizTheme(.darkCarbon)
/// ```
public struct SolarSunburstView<
    Item: Identifiable & Sendable,
    XValue: Hashable & Sendable & CustomStringConvertible,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedArcID: String?

    public init(binding: VizDataBinding<Item, XValue, YValue>) {
        self.binding = binding
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = min(geometry.size.width, geometry.size.height) / 2 - 16
            let arcs = computeArcs(center: center, maxRadius: maxRadius)

            ZStack {
                ForEach(Array(arcs.enumerated()), id: \.element.id) { index, arc in
                    let isSelected = selectedArcID == arc.id
                    let color = theme.seriesColors[index % theme.seriesColors.count]

                    Path { path in
                        path.addArc(
                            center: center,
                            radius: arc.outerRadius,
                            startAngle: arc.startAngle,
                            endAngle: arc.endAngle,
                            clockwise: false
                        )
                        path.addArc(
                            center: center,
                            radius: arc.innerRadius,
                            startAngle: arc.endAngle,
                            endAngle: arc.startAngle,
                            clockwise: true
                        )
                        path.closeSubpath()
                    }
                    .fill(color.opacity(isSelected ? 0.95 : 0.75))
                    .overlay(
                        Path { path in
                            path.addArc(
                                center: center,
                                radius: arc.outerRadius,
                                startAngle: arc.startAngle,
                                endAngle: arc.endAngle,
                                clockwise: false
                            )
                            path.addArc(
                                center: center,
                                radius: arc.innerRadius,
                                startAngle: arc.endAngle,
                                endAngle: arc.startAngle,
                                clockwise: true
                            )
                            path.closeSubpath()
                        }
                        .stroke(isSelected ? Color.white : theme.borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(arc.label)")
                    .accessibilityValue("\(String(format: "%.1f", arc.percentage)) percent")
                    .accessibilityHint("Double tap to highlight segment")
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedArcID = isSelected ? nil : arc.id
                        }
                        Task { @MainActor in
                            SolarVizHaptics.shared.playSelection()
                        }
                    }
                }

                // Center Label
                VStack(spacing: 2) {
                    Text(selectedArcID == nil ? "Total" : "Selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                    if let selectedArc = arcs.first(where: { $0.id == selectedArcID }) {
                        Text(selectedArc.label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.primaryTextColor)
                        Text(String(format: "%.1f%%", selectedArc.percentage))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentColor)
                    } else {
                        Text("\(binding.data.count) Items")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.primaryTextColor)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .fill(environmentTheme.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .stroke(environmentTheme.borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hierarchical Sunburst Chart")
        .accessibilityValue("\(binding.sortedGroupKeys.count) parent categories, \(binding.data.count) total child items")
    }

    /// 2-Level Hierarchical Sunburst Ring Algorithm (Parent Group Ring + Child Sub-item Ring)
    private func computeArcs(center: CGPoint, maxRadius: CGFloat) -> [SunburstArc<Item>] {
        guard !binding.data.isEmpty, maxRadius > 0 else { return [] }
        let totalValue = binding.data.reduce(0.0) { $0 + max(0.0, Double(binding.extractY(from: $1))) }
        guard totalValue > 0 else { return [] }

        var arcs: [SunburstArc<Item>] = []
        var currentAngle: Double = -90.0 // Start at 12 o'clock

        let innerRingR0 = maxRadius * 0.30
        let innerRingR1 = maxRadius * 0.58

        let outerRingR0 = maxRadius * 0.62
        let outerRingR1 = maxRadius * 0.90

        let sortedGroupedData = binding.sortedGroupedData()

        for (groupIndex, groupTuple) in sortedGroupedData.enumerated() {
            let groupName = groupTuple.key
            let groupItems = groupTuple.items
            let groupSum = groupItems.reduce(0.0) { $0 + max(0.0, Double(binding.extractY(from: $1))) }
            guard groupSum > 0 else { continue }

            let groupSweep = (groupSum / totalValue) * 360.0
            let groupStartAngle = currentAngle
            let groupEndAngle = currentAngle + groupSweep
            let groupPct = (groupSum / totalValue) * 100.0

            // 1. Parent Level Arc (Inner Ring)
            if let firstItem = groupItems.first {
                arcs.append(SunburstArc(
                    id: "parent_\(groupIndex)_\(groupName)",
                    item: firstItem,
                    startAngle: Angle(degrees: groupStartAngle),
                    endAngle: Angle(degrees: groupEndAngle),
                    innerRadius: innerRingR0,
                    outerRadius: innerRingR1,
                    label: groupName,
                    percentage: groupPct
                ))
            }

            // 2. Child Level Arcs (Outer Ring inside Parent angular span)
            var childAngle = groupStartAngle
            for (itemIndex, item) in groupItems.enumerated() {
                let val = max(0.0, Double(binding.extractY(from: item)))
                let itemSweep = (val / groupSum) * groupSweep
                let itemStartA = Angle(degrees: childAngle)
                let itemEndA = Angle(degrees: childAngle + itemSweep)
                childAngle += itemSweep

                let itemPct = (val / totalValue) * 100.0
                let itemLabel = binding.extractX(from: item).description

                arcs.append(SunburstArc(
                    id: "child_\(groupIndex)_\(itemIndex)",
                    item: item,
                    startAngle: itemStartA,
                    endAngle: itemEndA,
                    innerRadius: outerRingR0,
                    outerRadius: outerRingR1,
                    label: itemLabel,
                    percentage: itemPct
                ))
            }

            currentAngle += groupSweep
        }

        return arcs
    }
}
