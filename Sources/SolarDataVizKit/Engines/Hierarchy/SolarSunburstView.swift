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
    XValue: SolarPlottable,
    YValue: BinaryFloatingPoint & Sendable,
    Placeholder: View
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @Environment(\.solarVizHapticsEnabled) private var hapticsEnabled
    @State private var selectedArcID: String?
    @State private var cachedArcs: [SunburstArc<Item>]

    private let placeholder: () -> Placeholder
    public var onArcSelected: ((Item?) -> Void)?

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        initialSelectedArcID: String? = nil,
        onArcSelected: ((Item?) -> Void)? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.binding = binding
        self._selectedArcID = State(initialValue: initialSelectedArcID)
        self._cachedArcs = State(initialValue: [])
        self.onArcSelected = onArcSelected
        self.placeholder = placeholder
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            if geometry.size.width > 10 && geometry.size.height > 10 {
                if cachedArcs.isEmpty {
                    placeholder()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
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
        .task(id: binding.versionToken) {
            let targetBinding = binding
            let newArcs = await Task.detached(priority: .userInitiated) {
                targetBinding.sunburstArcs()
            }.value
            withAnimation(SolarVizAnimation.layoutReflow) {
                self.cachedArcs = newArcs
            }
        }
    }

    @ViewBuilder
    private func arcView(arc: SunburstArc<Item>, center: CGPoint, maxRadius: CGFloat, theme: SolarVizTheme) -> some View {
        let isSelected = selectedArcID == arc.id
        let totalGroups = Set(cachedArcs.map { $0.groupIndex }).count
        let baseColor = theme.colorForSeries(at: arc.groupIndex, totalCount: totalGroups)
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
            withAnimation(SolarVizAnimation.selection) {
                let newID = isSelected ? nil : arc.id
                selectedArcID = newID
                onArcSelected?(isSelected ? nil : arc.item)
            }
            Task { @MainActor in
                if hapticsEnabled {
                    SolarVizHaptics.shared.playSelection()
                }
            }
        }
    }
}

// MARK: - Backward Compatibility Init
extension SolarSunburstView where Placeholder == EmptyView {
    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        initialSelectedArcID: String? = nil,
        onArcSelected: ((Item?) -> Void)? = nil
    ) {
        self.init(binding: binding, initialSelectedArcID: initialSelectedArcID, onArcSelected: onArcSelected, placeholder: { EmptyView() })
    }
}

#if canImport(SwiftUI)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SolarSunburstNativeLayout: Layout {
    public init() {}

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 300, height: proposal.height ?? 300)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for subview in subviews {
            subview.place(
                at: center,
                anchor: .center,
                proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
            )
        }
    }
}
#endif
