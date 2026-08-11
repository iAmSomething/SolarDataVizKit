import SwiftUI

/// ## Quick View
/// `SunburstArc`는 Sunburst 동심원 링 상의 부채꼴 아치 세그먼트 데이터 구조체입니다.
public struct SunburstArc<Item: Identifiable & Sendable>: Identifiable, Sendable {
    public let id: String
    public let item: Item
    public let startAngle: Angle
    public let endAngle: Angle
    public let innerRadiusRatio: CGFloat
    public let outerRadiusRatio: CGFloat
    public let label: String
    public let percentage: Double
    public let groupIndex: Int
    public let isChild: Bool
    public let childIndex: Int

    public var innerRadius: CGFloat { innerRadiusRatio * 150.0 }
    public var outerRadius: CGFloat { outerRadiusRatio * 150.0 }

    public func innerRadius(maxRadius: CGFloat) -> CGFloat { innerRadiusRatio * maxRadius }
    public func outerRadius(maxRadius: CGFloat) -> CGFloat { outerRadiusRatio * maxRadius }

    public init(
        id: String = UUID().uuidString,
        item: Item,
        startAngle: Angle,
        endAngle: Angle,
        innerRadiusRatio: CGFloat,
        outerRadiusRatio: CGFloat,
        label: String,
        percentage: Double,
        groupIndex: Int = 0,
        isChild: Bool = false,
        childIndex: Int = 0
    ) {
        self.id = id
        self.item = item
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadiusRatio = innerRadiusRatio
        self.outerRadiusRatio = outerRadiusRatio
        self.label = label
        self.percentage = percentage
        self.groupIndex = groupIndex
        self.isChild = isChild
        self.childIndex = childIndex
    }

    public init(
        id: String = UUID().uuidString,
        item: Item,
        startAngle: Angle,
        endAngle: Angle,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        label: String,
        percentage: Double,
        groupIndex: Int = 0,
        isChild: Bool = false,
        childIndex: Int = 0
    ) {
        let baseMax: CGFloat = max(outerRadius, 1.0)
        self.init(
            id: id,
            item: item,
            startAngle: startAngle,
            endAngle: endAngle,
            innerRadiusRatio: innerRadius / baseMax,
            outerRadiusRatio: outerRadius / baseMax,
            label: label,
            percentage: percentage,
            groupIndex: groupIndex,
            isChild: isChild,
            childIndex: childIndex
        )
    }
}

/// ## Quick View
/// `SolarSunburstView`는 1차 대분류 및 2차 소분류 계층 구조를 동심원 부채꼴 링으로 확장하여 시각화하는 뷰 컴포넌트입니다.
public struct SolarSunburstView<
    Item: Identifiable & Sendable,
    XValue: Hashable & Sendable & CustomStringConvertible,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedArcID: String?
    @State private var cachedArcs: [SunburstArc<Item>]

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        initialSelectedArcID: String? = nil
    ) {
        self.binding = binding
        self._selectedArcID = State(initialValue: initialSelectedArcID)
        self._cachedArcs = State(initialValue: [])
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = min(geometry.size.width, geometry.size.height) / 2
            let arcs = cachedArcs

            ZStack {
                ForEach(arcs) { arc in
                    arcView(arc: arc, center: center, maxRadius: maxRadius, theme: theme)
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
                        Text("100%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
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
        .accessibilityLabel("Concentric Sunburst Donut Chart")
        .accessibilityValue("\(binding.data.count) data elements")
        .task(id: binding.dataHash) {
            let targetBinding = binding
            let newArcs = await Task.detached(priority: .userInitiated) {
                targetBinding.sunburstArcs()
            }.value
            withAnimation(.easeOut(duration: 0.3)) {
                self.cachedArcs = newArcs
            }
        }
    }

    @ViewBuilder
    private func arcView(arc: SunburstArc<Item>, center: CGPoint, maxRadius: CGFloat, theme: SolarVizTheme) -> some View {
        let isSelected = selectedArcID == arc.id
        let baseColor = !theme.seriesColors.isEmpty ? theme.seriesColors[arc.groupIndex % theme.seriesColors.count] : theme.accentColor
        let color = arc.isChild ? baseColor.opacity(0.60 + 0.12 * Double(arc.childIndex % 3)) : baseColor

        let innerR = arc.innerRadius(maxRadius: maxRadius)
        let outerR = arc.outerRadius(maxRadius: maxRadius)

        ZStack {
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerR,
                    startAngle: arc.startAngle,
                    endAngle: arc.endAngle,
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: innerR,
                    startAngle: arc.endAngle,
                    endAngle: arc.startAngle,
                    clockwise: true
                )
                path.closeSubpath()
            }
            .fill(color.opacity(isSelected ? 0.95 : (arc.isChild ? 0.80 : 0.95)))
            .overlay(
                Path { path in
                    let sweepDeg = abs(arc.endAngle.degrees - arc.startAngle.degrees)
                    if sweepDeg >= 359.9 {
                        path.addArc(center: center, radius: outerR, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                        path.addArc(center: center, radius: innerR, startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
                    } else {
                        path.addArc(center: center, radius: outerR, startAngle: arc.startAngle, endAngle: arc.endAngle, clockwise: false)
                        path.addArc(center: center, radius: innerR, startAngle: arc.endAngle, endAngle: arc.startAngle, clockwise: true)
                        path.closeSubpath()
                    }
                }
                .stroke(isSelected ? Color.white : theme.borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(arc.label)")
        .accessibilityValue("\(String(format: "%.1f", arc.percentage)) percent")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
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
}
