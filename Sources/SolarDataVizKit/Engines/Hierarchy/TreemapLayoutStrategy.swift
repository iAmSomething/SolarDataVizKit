import Foundation
import CoreGraphics

/// 트리맵의 개별 타일 사각형 영역 및 비율 정보 구조체입니다.
public struct TreeTile<Item: Sendable>: Identifiable, Sendable {
    public let id: String
    public let item: Item
    public let rect: CGRect
    public let percentage: Double

    public init(id: String, item: Item, rect: CGRect, percentage: Double) {
        self.id = id
        self.item = item
        self.rect = rect
        self.percentage = percentage
    }
}

/// 트리맵 타일 분할 알고리즘을 정의하는 오픈 전략 프로토콜(Strategy Pattern)입니다.
public protocol TreemapLayoutStrategy: Sendable {
    /// 주어진 데이터 요소 배열과 사각형 영역(Bounds)을 받아 TreeTile 사각형 배치 배열을 계산합니다.
    func computeTiles<Item>(
        data: [Item],
        extractY: @Sendable (Item) -> Double,
        bounds: CGRect
    ) -> [TreeTile<Item>]
}

/// Bruls et al. 황금 비율 1:1 Squarified 트리맵 타일 분할 전략 구현체입니다.
public struct SquarifiedTreemapStrategy: TreemapLayoutStrategy {
    public init() {}

    public func computeTiles<Item>(
        data: [Item],
        extractY: @Sendable (Item) -> Double,
        bounds: CGRect
    ) -> [TreeTile<Item>] {
        guard !data.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }
        let totalValue = data.reduce(0.0) { $0 + max(0.0, extractY($1)) }
        guard totalValue > 0 else { return [] }

        let sorted = data.map { (item: $0, val: max(0.0, extractY($0))) }
            .filter { $0.val > 0.0 }
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
                guard length > 0 else { continue }
                let ar = max(rowThickness / length, length / rowThickness)
                if ar > maxAR { maxAR = ar }
            }
            return maxAR
        }

        func layoutRow(row: [(item: Item, val: Double)], in rect: inout CGRect) {
            guard !row.isEmpty else { return }
            let sumVal = row.reduce(0.0) { $0 + $1.val }
            guard sumVal > 0 else { return }
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
            let sideLength = remainingRect.width >= remainingRect.height ? remainingRect.height : remainingRect.width
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

/// 직선 교차 분할 Slice-and-Dice 트리맵 타일 분할 전략 구현체입니다.
public struct SliceAndDiceTreemapStrategy: TreemapLayoutStrategy {
    public init() {}

    public func computeTiles<Item>(
        data: [Item],
        extractY: @Sendable (Item) -> Double,
        bounds: CGRect
    ) -> [TreeTile<Item>] {
        guard !data.isEmpty, bounds.width > 0, bounds.height > 0 else { return [] }
        let totalValue = data.reduce(0.0) { $0 + max(0.0, extractY($1)) }
        guard totalValue > 0 else { return [] }

        var tiles: [TreeTile<Item>] = []
        var offset: CGFloat = 0
        let isHorizontal = bounds.width >= bounds.height

        for item in data {
            let val = max(0.0, extractY(item))
            let fraction = CGFloat(val / totalValue)
            let pct = (val / totalValue) * 100.0

            let tileRect: CGRect
            if isHorizontal {
                let length = bounds.width * fraction
                tileRect = CGRect(x: bounds.origin.x + offset, y: bounds.origin.y, width: length, height: bounds.height)
                offset += length
            } else {
                let length = bounds.height * fraction
                tileRect = CGRect(x: bounds.origin.x, y: bounds.origin.y + offset, width: bounds.width, height: length)
                offset += length
            }
            tiles.append(TreeTile(id: "tile_\(tiles.count)", item: item, rect: tileRect, percentage: pct))
        }

        return tiles
    }
}
