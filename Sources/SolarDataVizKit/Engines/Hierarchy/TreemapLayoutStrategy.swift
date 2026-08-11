import Foundation
import CoreGraphics
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftUI)
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct SolarTreemapNativeLayout: Layout {
    public var tileRects: [CGRect]

    public init(tileRects: [CGRect]) {
        self.tileRects = tileRects
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 300, height: proposal.height ?? 300)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() {
            if index < tileRects.count {
                let rect = tileRects[index]
                subview.place(
                    at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                    proposal: ProposedViewSize(width: rect.width, height: rect.height)
                )
            }
        }
    }
}
#endif

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
        extractID: (@Sendable (Item) -> String)?,
        bounds: CGRect
    ) -> [TreeTile<Item>]
}

/// Bruls et al. 황금 비율 1:1 Squarified 트리맵 타일 분할 전략 구현체입니다.
public struct SquarifiedTreemapStrategy: TreemapLayoutStrategy {
    public init() {}

    public func computeTiles<Item>(
        data: [Item],
        extractY: @Sendable (Item) -> Double,
        extractID: (@Sendable (Item) -> String)? = nil,
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

        func worstAspectRatio(rowSum: Double, rowMax: Double, rowMin: Double, sideLength: CGFloat) -> Double {
            guard rowSum > 0, sideLength > 0, rowMin > 0 else { return .greatestFiniteMagnitude }
            let totalArea = Double(bounds.width * bounds.height)
            let sArea = (rowSum / totalValue) * totalArea
            let pMaxArea = (rowMax / totalValue) * totalArea
            let pMinArea = (rowMin / totalValue) * totalArea
            let w = Double(sideLength)
            let w2 = w * w
            let s2 = sArea * sArea
            guard s2 > 0, w2 > 0 else { return .greatestFiniteMagnitude }
            let aspect1 = (w2 * pMaxArea) / s2
            let aspect2 = s2 / (w2 * pMinArea)
            return max(aspect1, aspect2)
        }

        func layoutRow(row: [(item: Item, val: Double)], in rect: inout CGRect) {
            let rowTotal = row.reduce(0.0) { $0 + $1.val }
            let rowArea = (rowTotal / totalValue) * Double(bounds.width * bounds.height)
            let isHorizontal = rect.width >= rect.height
            let sideLength = isHorizontal ? rect.height : rect.width
            guard sideLength > 0 else { return }

            let rowThickness = CGFloat(rowArea) / sideLength
            guard rowThickness > 0 else { return }

            var offset: CGFloat = 0
            for elem in row {
                let elemFraction = CGFloat(elem.val / rowTotal)
                let pct = (elem.val / totalValue) * 100.0
                let elemLength = sideLength * elemFraction

                let tileRect: CGRect
                if isHorizontal {
                    tileRect = CGRect(x: rect.origin.x, y: rect.origin.y + offset, width: rowThickness, height: elemLength)
                } else {
                    tileRect = CGRect(x: rect.origin.x + offset, y: rect.origin.y, width: elemLength, height: rowThickness)
                }
                offset += elemLength
                let tileID = extractID?(elem.item) ?? "tile_\(tiles.count)"
                tiles.append(TreeTile(id: tileID, item: elem.item, rect: tileRect, percentage: pct))
            }

            if isHorizontal {
                rect.origin.x += rowThickness
                rect.size.width -= rowThickness
            } else {
                rect.origin.y += rowThickness
                rect.size.height -= rowThickness
            }
        }

        var rowSum = 0.0
        var rowMax = 0.0
        var rowMin = Double.greatestFiniteMagnitude

        for itemTuple in sorted {
            let sideLength = remainingRect.width >= remainingRect.height ? remainingRect.height : remainingRect.width
            if currentRow.isEmpty {
                currentRow.append(itemTuple)
                rowSum = itemTuple.val
                rowMax = itemTuple.val
                rowMin = itemTuple.val
            } else {
                let currentWorst = worstAspectRatio(rowSum: rowSum, rowMax: rowMax, rowMin: rowMin, sideLength: sideLength)

                let nextSum = rowSum + itemTuple.val
                let nextMax = max(rowMax, itemTuple.val)
                let nextMin = min(rowMin, itemTuple.val)
                let nextWorst = worstAspectRatio(rowSum: nextSum, rowMax: nextMax, rowMin: nextMin, sideLength: sideLength)

                if nextWorst <= currentWorst {
                    currentRow.append(itemTuple)
                    rowSum = nextSum
                    rowMax = nextMax
                    rowMin = nextMin
                } else {
                    layoutRow(row: currentRow, in: &remainingRect)
                    currentRow = [itemTuple]
                    rowSum = itemTuple.val
                    rowMax = itemTuple.val
                    rowMin = itemTuple.val
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
        extractID: (@Sendable (Item) -> String)? = nil,
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
            let tileID = extractID?(item) ?? "tile_\(tiles.count)"
            tiles.append(TreeTile(id: tileID, item: item, rect: tileRect, percentage: pct))
        }

        return tiles
    }
}
