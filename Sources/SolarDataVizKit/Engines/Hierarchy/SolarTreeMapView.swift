import SwiftUI

/// `SolarTreeMapView`는 사각형 면적 비율로 구성비를 분할 표현하는 트리맵(TreeMap) 시각화 컴포넌트입니다.
///
/// - **특징**:
///   - **Squarified Aspect Ratio Tiling**: 전체 대비 수치 비중에 정비례하는 사각형 면적 분할.
///   - **Interactive Selection**: 타일 터치 시 강조 인디케이터 오버레이 및 햅틱 피드백 연동.
///
/// ## 사용 예시
/// ```swift
/// SolarTreeMapView(binding: myTreeMapBinding)
///     .solarVizTheme(.darkCarbon)
/// ```
public struct SolarTreeMapView<
    Item: Identifiable & Sendable,
    XValue: SolarPlottable,
    YValue: BinaryFloatingPoint & Sendable,
    Placeholder: View
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let strategy: any TreemapLayoutStrategy

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @Environment(\.solarVizHapticsEnabled) private var hapticsEnabled
    @State private var selectedTileID: String?
    @State private var tiles: [TreeTile<Item>] = []
    
    private let placeholder: () -> Placeholder
    public var onTileSelected: ((Item?) -> Void)?

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        strategy: any TreemapLayoutStrategy = SquarifiedTreemapStrategy(),
        initialSelectedTileID: String? = nil,
        onTileSelected: ((Item?) -> Void)? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.binding = binding
        self.strategy = strategy
        self._selectedTileID = State(initialValue: initialSelectedTileID)
        self.onTileSelected = onTileSelected
        self.placeholder = placeholder
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            Group {
                if geometry.size.width > 10 && geometry.size.height > 10 {
                    if tiles.isEmpty {
                        placeholder()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        ZStack(alignment: .topLeading) {
                            ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                                tileView(tile: tile, index: index, theme: theme)
                            }
                        }
                    }
                }
            }
            .task(id: "\(binding.versionToken)_\(geometry.size.width)x\(geometry.size.height)") {
                guard geometry.size.width > 10, geometry.size.height > 10 else { return }
                let rect = CGRect(origin: .zero, size: geometry.size)
                let localBinding = binding
                let localStrategy = strategy
                
                let newTiles = await Task.detached(priority: .userInitiated) {
                    localStrategy.computeTiles(
                        data: localBinding.data,
                        extractY: { Double(localBinding.extractY(from: $0)) },
                        extractID: { String(describing: $0.id) },
                        bounds: rect
                    )
                }.value
                
                withAnimation(SolarVizAnimation.layoutReflow) {
                    self.tiles = newTiles
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .fill(environmentTheme.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .stroke(environmentTheme.borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Treemap Category Allocation Chart")
        .accessibilityValue("\(binding.data.count) tiles total")
    }

    @ViewBuilder
    private func tileView(tile: TreeTile<Item>, index: Int, theme: SolarVizTheme) -> some View {
        let isSelected = selectedTileID == tile.id
        let color = theme.colorForSeries(at: index, totalCount: tiles.count)

        let titleText = String(describing: binding.extractX(from: tile.item))
        let pctText = String(format: "%.1f%%", tile.percentage)
        let tileW = max(tile.rect.width - 4, 1.0)
        let tileH = max(tile.rect.height - 4, 1.0)

        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.95))
                    .shadow(color: color.opacity(0.6), radius: 8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.75))
            }

            if tileW > 40 && tileH > 30 {
                VStack(spacing: 4) {
                    Text(titleText)
                        .font(.system(size: max(10, min(tile.rect.width * 0.12, 14)), weight: .bold))
                        .foregroundColor(theme.primaryTextColor)
                        .lineLimit(1)

                    Text(pctText)
                        .font(.system(size: max(9, min(tile.rect.width * 0.1, 12)), weight: .semibold, design: .rounded))
                        .foregroundColor(theme.primaryTextColor.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(4)
            }
        }
        .accessibilityLabel(titleText)
        .accessibilityValue(String(describing: binding.extractY(from: tile.item)))
        .frame(width: tileW, height: tileH)
        .position(x: tile.rect.midX, y: tile.rect.midY)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.white : theme.borderColor, lineWidth: isSelected ? 2 : 1)
                .frame(width: tileW, height: tileH)
                .position(x: tile.rect.midX, y: tile.rect.midY)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titleText)
        .accessibilityValue("\(String(format: "%.1f", tile.percentage)) percent")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityHint("Double tap to toggle selection highlight")
        .onTapGesture {
            withAnimation(SolarVizAnimation.selection) {
                let newID = isSelected ? nil : tile.id
                selectedTileID = newID
                onTileSelected?(isSelected ? nil : tile.item)
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
extension SolarTreeMapView where Placeholder == EmptyView {
    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        strategy: any TreemapLayoutStrategy = SquarifiedTreemapStrategy(),
        initialSelectedTileID: String? = nil,
        onTileSelected: ((Item?) -> Void)? = nil
    ) {
        self.init(binding: binding, strategy: strategy, initialSelectedTileID: initialSelectedTileID, onTileSelected: onTileSelected, placeholder: { EmptyView() })
    }
}
