import SwiftUI

/// ## Quick View
/// `TreeTile`은 TreeMap 시각화에서 할당된 2차원 사각형 영역 및 비율 정보입니다.
public struct TreeTile<Item: Identifiable & Sendable>: Identifiable, Sendable {
    public let id: String
    public let item: Item
    public let rect: CGRect
    public let percentage: Double

    public init(id: String = UUID().uuidString, item: Item, rect: CGRect, percentage: Double) {
        self.id = id
        self.item = item
        self.rect = rect
        self.percentage = percentage
    }
}

/// ## Quick View
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
    XValue: Hashable & Sendable & CustomStringConvertible,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var selectedTileID: String?

    public init(binding: VizDataBinding<Item, XValue, YValue>) {
        self.binding = binding
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            let tiles = computeTiles(bounds: CGRect(origin: .zero, size: geometry.size))

            ZStack(alignment: .topLeading) {
                ForEach(Array(tiles.enumerated()), id: \.element.id) { index, tile in
                    let isSelected = selectedTileID == tile.id
                    let color = theme.seriesColors[index % theme.seriesColors.count]

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(isSelected ? 0.95 : 0.75))
                            .shadow(color: isSelected ? color.opacity(0.6) : Color.black.opacity(0.2), radius: isSelected ? 8 : 2)

                        VStack(spacing: 4) {
                            Text(binding.extractX(from: tile.item).description)
                                .font(.system(size: max(10, min(tile.rect.width * 0.12, 14)), weight: .bold))
                                .foregroundColor(theme.primaryTextColor)
                                .lineLimit(1)

                            Text(String(format: "%.1f%%", tile.percentage))
                                .font(.system(size: max(9, min(tile.rect.width * 0.1, 12)), weight: .semibold, design: .rounded))
                                .foregroundColor(theme.primaryTextColor.opacity(0.85))
                                .lineLimit(1)
                        }
                        .padding(4)
                    }
                    .frame(width: max(tile.rect.width - 4, 1), height: max(tile.rect.height - 4, 1))
                    .position(x: tile.rect.midX, y: tile.rect.midY)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white : theme.borderColor, lineWidth: isSelected ? 2 : 1)
                            .frame(width: max(tile.rect.width - 4, 1), height: max(tile.rect.height - 4, 1))
                            .position(x: tile.rect.midX, y: tile.rect.midY)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTileID = isSelected ? nil : tile.id
                        }
                        Task { @MainActor in
                            SolarVizHaptics.shared.playSelection()
                        }
                    }
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
    }

    private func computeTiles(bounds: CGRect) -> [TreeTile<Item>] {
        guard !binding.data.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }
        let totalValue = binding.data.reduce(0.0) { $0 + Double(binding.extractY(from: $1)) }
        guard totalValue > 0 else { return [] }

        var result: [TreeTile<Item>] = []
        var currentRect = bounds

        let sortedItems = binding.data.sorted { Double(binding.extractY(from: $0)) > Double(binding.extractY(from: $1)) }

        for (index, item) in sortedItems.enumerated() {
            let val = Double(binding.extractY(from: item))
            let pct = (val / totalValue) * 100.0
            let ratio = val / totalValue

            let tileRect: CGRect
            if currentRect.width >= currentRect.height {
                let w = currentRect.width * CGFloat(ratio)
                tileRect = CGRect(x: currentRect.origin.x, y: currentRect.origin.y, width: w, height: currentRect.height)
                currentRect.origin.x += w
                currentRect.size.width -= w
            } else {
                let h = currentRect.height * CGFloat(ratio)
                tileRect = CGRect(x: currentRect.origin.x, y: currentRect.origin.y, width: currentRect.width, height: h)
                currentRect.origin.y += h
                currentRect.size.height -= h
            }

            result.append(TreeTile(id: "tile_\(index)", item: item, rect: tileRect, percentage: pct))
        }

        return result
    }
}
