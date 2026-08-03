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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(binding.extractX(from: tile.item).description)")
                    .accessibilityValue("\(String(format: "%.1f", tile.percentage)) percent")
                    .accessibilityHint("Double tap to toggle selection highlight")
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Treemap Category Allocation Chart")
        .accessibilityValue("\(binding.data.count) tiles total")
    }

    /// Bruls et al. Squarified Treemap Layout Algorithm
    private func computeTiles(bounds: CGRect) -> [TreeTile<Item>] {
        guard !binding.data.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }
        let totalValue = binding.data.reduce(0.0) { $0 + max(0.0, Double(binding.extractY(from: $1))) }
        guard totalValue > 0 else { return [] }

        let sorted = binding.data.map { (item: $0, val: max(0.0, Double(binding.extractY(from: $0)))) }
            .sorted { $0.val > $1.val }

        var tiles: [TreeTile<Item>] = []
        var remainingRect = bounds
        var currentRow: [(item: Item, val: Double)] = []

        func worstAspectRatio(row: [(item: Item, val: Double)], sideLength: CGFloat) -> CGFloat {
            guard !row.isEmpty, sideLength > 0 else { return .greatestFiniteMagnitude }
            let sumVal = row.reduce(0.0) { $0 + $1.val }
            let rowArea = (sumVal / totalValue) * Double(bounds.width * bounds.height)
            guard rowArea > 0 else { return .greatestFiniteMagnitude }

            let rowThickness = CGFloat(rowArea) / sideLength
            var maxAR: CGFloat = 0

            for elem in row {
                let elemArea = (elem.val / totalValue) * Double(bounds.width * bounds.height)
                let length = CGFloat(elemArea) / rowThickness
                let ar = max(rowThickness / length, length / rowThickness)
                if ar > maxAR { maxAR = ar }
            }
            return maxAR
        }

        func layoutRow(row: [(item: Item, val: Double)], in rect: inout CGRect) {
            guard !row.isEmpty else { return }
            let sumVal = row.reduce(0.0) { $0 + $1.val }
            let rowFraction = sumVal / totalValue
            let totalBoundsArea = bounds.width * bounds.height
            let rowArea = CGFloat(rowFraction) * totalBoundsArea

            let isHorizontal = rect.width >= rect.height
            let sideLength = isHorizontal ? rect.height : rect.width
            guard sideLength > 0 else { return }
            let rowThickness = rowArea / sideLength

            var offset: CGFloat = 0
            for elem in row {
                let elemFraction = elem.val / sumVal
                let elemLength = sideLength * CGFloat(elemFraction)
                let pct = (elem.val / totalValue) * 100.0

                let tileRect: CGRect
                if isHorizontal {
                    tileRect = CGRect(x: rect.origin.x, y: rect.origin.y + offset, width: rowThickness, height: elemLength)
                } else {
                    tileRect = CGRect(x: rect.origin.x + offset, y: rect.origin.y, width: elemLength, height: rowThickness)
                }
                offset += elemLength
                tiles.append(TreeTile(id: "tile_\(tiles.count)", item: elem.item, rect: tileRect, percentage: pct))
            }

            if isHorizontal {
                rect.origin.x += rowThickness
                rect.size.width -= rowThickness
            } else {
                rect.origin.y += rowThickness
                rect.size.height -= rowThickness
            }
        }

        for itemTuple in sorted {
            let sideLength = min(remainingRect.width, remainingRect.height)

            if currentRow.isEmpty {
                currentRow.append(itemTuple)
            } else {
                let currentWorst = worstAspectRatio(row: currentRow, sideLength: sideLength)
                var nextRow = currentRow
                nextRow.append(itemTuple)
                let nextWorst = worstAspectRatio(row: nextRow, sideLength: sideLength)

                if nextWorst <= currentWorst {
                    currentRow.append(itemTuple)
                } else {
                    layoutRow(row: currentRow, in: &remainingRect)
                    currentRow = [itemTuple]
                }
            }
        }

        if !currentRow.isEmpty {
            layoutRow(row: currentRow, in: &remainingRect)
        }

        return tiles
    }
}
