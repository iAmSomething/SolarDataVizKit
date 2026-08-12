import Foundation
import SwiftUI

/// 사용자의 도메인 모델을 수정하지 않고 KeyPath로 차트 축과 범례에 매핑하는 래퍼 바인딩 구조체입니다.
///
/// ## Overview
/// `VizDataBinding`은 도메인 모델과 시각화 엔진 간의 결합도를 낮추어주는 핵심 래퍼입니다.
/// 기존 모델의 프로퍼티 키패스(`\.date`, `\.amount`)를 지정하여 차트 엔진에 바인딩합니다.
///
/// - Note: `VizDataBinding`은 스레드 세이프 규칙을 준수하여 Swift 6 환경에 최적화되어 있습니다.
///
/// ## Example
/// ```swift
/// let binding = VizDataBinding(
///     data: myExpenses,
///     x: \.month,
///     y: \.amount,
///     group: \.category
/// )
/// ```
/// - Note: Swift 표준 라이브러리의 `KeyPath` 클래스는 타입 정의상 `Sendable` 프로토콜을 명시적으로 채택하지 않으나,
/// `VizDataBinding` 내부의 모든 프로퍼티는 불변(`let`)이며 타입 파라미터 `Item`, `XValue`, `YValue`가 모두 `Sendable`을 준수하므로
/// `@unchecked Sendable`을 통해 스레드 세이프티를 완벽히 보장합니다.
public struct VizDataBinding<
    Item: Identifiable & Sendable,
    XValue: SolarPlottable,
    YValue: BinaryFloatingPoint & Sendable
>: @unchecked Sendable {
    /// 시각화할 데이터 모델 배열입니다.
    public let data: [Item]
    /// X축 값으로 추출할 KeyPath입니다.
    public let xKeyPath: KeyPath<Item, XValue>
    /// Y축 수치로 추출할 KeyPath입니다.
    public let yKeyPath: KeyPath<Item, YValue>
    /// 시리즈/그룹 식별용 KeyPath (선택사항)입니다.
    public let groupKeyPath: KeyPath<Item, String>?
    /// 다단계 계층구조 식별용 KeyPath 배열입니다 (선택사항).
    public let hierarchyKeyPaths: [KeyPath<Item, String>]
    /// 데이터 바인딩 객체의 고유 버전 토큰 (O(1) 갱신 감지용)
    public let versionToken: UUID

    /// KeyPath 바인딩 래퍼를 초기화합니다.
    public init(
        data: [Item],
        x: KeyPath<Item, XValue>,
        y: KeyPath<Item, YValue>,
        group: KeyPath<Item, String>? = nil,
        hierarchy: [KeyPath<Item, String>] = []
    ) {
        self.data = data
        self.xKeyPath = x
        self.yKeyPath = y
        self.groupKeyPath = group
        self.hierarchyKeyPaths = hierarchy.isEmpty ? (group != nil ? [group!] : []) : hierarchy
        self.versionToken = UUID()
    }

    /// 데이터 바인딩 객체의 빠른 64-bit 해시값을 반환합니다. (하위 호환성 유지)
    public var dataHash: Int {
        versionToken.hashValue
    }

    /// 특정 데이터 항목에서 X축 값을 추출합니다.
    @inlinable
    public func extractX(from item: Item) -> XValue {
        item[keyPath: xKeyPath]
    }

    /// 특정 데이터 항목에서 Y축 수치를 추출합니다.
    @inlinable
    public func extractY(from item: Item) -> YValue {
        item[keyPath: yKeyPath]
    }

    /// 특정 데이터 항목에서 속한 그룹 이름을 추출합니다.
    @inlinable
    public func extractGroup(from item: Item) -> String {
        guard let groupKeyPath else { return "Default" }
        return item[keyPath: groupKeyPath]
    }

    /// 전체 그룹 키를 최초 삽입 순서대로 보장하여 반환합니다 (Flickering 방지).
    public var sortedGroupKeys: [String] {
        sortedGroupedData().map(\.key)
    }

    /// 그룹별 데이터 딕셔너리를 연산하여 반환합니다.
    public func groupedData() -> [String: [Item]] {
        guard let groupKeyPath else { return ["Default": data] }
        var dict: [String: [Item]] = [:]
        for item in data {
            let key = item[keyPath: groupKeyPath]
            dict[key, default: []].append(item)
        }
        return dict
    }

    /// 순서 보장 그룹별 데이터 배열을 연산하여 반환합니다.
    public func sortedGroupedData() -> [(key: String, items: [Item])] {
        guard let groupKeyPath else { return [("Default", data)] }
        var dict: [String: [Item]] = [:]
        var keys: [String] = []
        for item in data {
            let key = item[keyPath: groupKeyPath]
            if dict[key] == nil {
                keys.append(key)
            }
            dict[key, default: []].append(item)
        }
        return keys.compactMap { key in
            guard let items = dict[key] else { return nil }
            return (key: key, items: items)
        }
    }

    /// Y축 수치의 최솟값과 최댓값을 연산하여 반환합니다.
    public func yBounds() -> (min: YValue, max: YValue) {
        let validItems = data.filter {
            let doubleVal = Double($0[keyPath: yKeyPath])
            return !doubleVal.isNaN && !doubleVal.isInfinite
        }
        guard let first = validItems.first else { return (0, 1) }
        var minY = first[keyPath: yKeyPath]
        var maxY = minY
        for item in validItems {
            let val = item[keyPath: yKeyPath]
            if val < minY { minY = val }
            if val > maxY { maxY = val }
        }
        if minY == maxY {
            minY = minY == 0 ? 0 : minY * 0.9
            maxY = maxY == 0 ? 1 : maxY * 1.1
        }
        return (minY, maxY)
    }

    /// Normalized Sunburst Arc 배열을 연산하여 반환합니다.
    public func sunburstArcs() -> [SunburstArc<Item>] {
        VizDataBinding.computeNormalizedSunburstArcs(
            data: data,
            xKeyPath: xKeyPath,
            yKeyPath: yKeyPath,
            sortedGroupedData: sortedGroupedData()
        )
    }

    /// 2-Level Hierarchical Sunburst Ring Algorithm (Responsive Normalized Ratios)
    private static func computeNormalizedSunburstArcs(
        data: [Item],
        xKeyPath: KeyPath<Item, XValue>,
        yKeyPath: KeyPath<Item, YValue>,
        sortedGroupedData: [(key: String, items: [Item])]
    ) -> [SunburstArc<Item>] {
        guard !data.isEmpty else { return [] }
        let totalValue = data.reduce(0.0) { $0 + max(0.0, Double($1[keyPath: yKeyPath])) }
        guard totalValue > 0 else { return [] }

        var arcs: [SunburstArc<Item>] = []
        var currentAngle: Double = -90.0 // Start at 12 o'clock

        let innerRingR0Ratio: CGFloat = 0.30
        let innerRingR1Ratio: CGFloat = 0.58

        let outerRingR0Ratio: CGFloat = 0.62
        let outerRingR1Ratio: CGFloat = 0.90

        for (groupIndex, groupTuple) in sortedGroupedData.enumerated() {
            let groupName = groupTuple.key
            let groupItems = groupTuple.items
            let groupSum = groupItems.reduce(0.0) { $0 + max(0.0, Double($1[keyPath: yKeyPath])) }
            guard groupSum > 0 else { continue }

            let groupSweep = (groupSum / totalValue) * 360.0
            let groupStartAngle = currentAngle
            let groupEndAngle = currentAngle + groupSweep
            let groupPct = (groupSum / totalValue) * 100.0

            // 1. Parent Level Arc (Inner Ring) - Stable Index-Free Unique ID
            if let firstItem = groupItems.first {
                arcs.append(SunburstArc(
                    id: "sunburst_parent_\(groupName)",
                    item: firstItem,
                    startAngle: Angle(degrees: groupStartAngle),
                    endAngle: Angle(degrees: groupEndAngle),
                    innerRadiusRatio: innerRingR0Ratio,
                    outerRadiusRatio: innerRingR1Ratio,
                    label: groupName,
                    percentage: groupPct,
                    groupIndex: groupIndex,
                    isChild: false,
                    childIndex: 0
                ))
            }

            // 2. Child Level Arcs (Outer Ring) - Stable Index-Free Unique ID
            var childAngle = groupStartAngle
            for (itemIndex, item) in groupItems.enumerated() {
                let val = max(0.0, Double(item[keyPath: yKeyPath]))
                let itemSweep = (val / groupSum) * groupSweep
                let itemStartA = Angle(degrees: childAngle)
                let itemEndA = Angle(degrees: childAngle + itemSweep)
                childAngle += itemSweep

                let itemPct = (val / totalValue) * 100.0
                let itemLabel = String(describing: item[keyPath: xKeyPath])

                arcs.append(SunburstArc(
                    id: "sunburst_child_\(item.id)",
                    item: item,
                    startAngle: itemStartA,
                    endAngle: itemEndA,
                    innerRadiusRatio: outerRingR0Ratio,
                    outerRadiusRatio: outerRingR1Ratio,
                    label: itemLabel,
                    percentage: itemPct,
                    groupIndex: groupIndex,
                    isChild: true,
                    childIndex: itemIndex
                ))
            }

            currentAngle += groupSweep
        }

        return arcs
    }

    /// 지정된 Y 값을 [0.0, 1.0] 범위의 정규화 수치로 변환합니다.
    ///
    /// - Parameters:
    ///   - value: 정규화할 Y 값
    ///   - range: Y축 최소/최대 범위 튜플
    /// - Returns: [0.0, 1.0] 사이의 정규화된 값
    public func normalizeY(value: YValue, in range: (min: YValue, max: YValue)) -> Double {
        let span = range.max - range.min
        guard span > 0 else { return 0.5 }
        let normalized = (value - range.min) / span
        return min(max(Double(normalized), 0.0), 1.0)
    }

    /// hierarchyKeyPaths 배열을 순회하여 N-계층 트리 구조(HierarchyNode)를 재귀적으로 구축합니다.
    public func buildHierarchyTree() -> HierarchyNode<Item> {
        let paths = hierarchyKeyPaths.isEmpty ? (groupKeyPath != nil ? [groupKeyPath!] : []) : hierarchyKeyPaths
        guard !paths.isEmpty else {
            let total = data.reduce(0.0) { $0 + max(0.0, Double(extractY(from: $1))) }
            let leaves = data.map { item in
                HierarchyNode(
                    id: "leaf_\(String(describing: item.id))",
                    name: String(describing: extractX(from: item)),
                    value: max(0.0, Double(extractY(from: item))),
                    level: 1,
                    item: item
                )
            }
            return HierarchyNode(id: "root", name: "Root", value: total, level: 0, children: leaves)
        }

        func buildSubtree(items: [Item], depth: Int, parentPath: String) -> [HierarchyNode<Item>] {
            guard depth < paths.count else {
                return items.map { item in
                    let name = String(describing: extractX(from: item))
                    return HierarchyNode(
                        id: "\(parentPath)_leaf_\(String(describing: item.id))",
                        name: name,
                        value: max(0.0, Double(extractY(from: item))),
                        level: depth + 1,
                        item: item
                    )
                }
            }

            let kp = paths[depth]
            var groups: [String: [Item]] = [:]
            var groupKeys: [String] = []

            for item in items {
                let key = item[keyPath: kp]
                if groups[key] == nil { groupKeys.append(key) }
                groups[key, default: []].append(item)
            }

            return groupKeys.compactMap { key in
                guard let groupItems = groups[key] else { return nil }
                let currentPath = "\(parentPath)_\(key)"
                let children = buildSubtree(items: groupItems, depth: depth + 1, parentPath: currentPath)
                let groupTotal = children.reduce(0.0) { $0 + $1.value }
                return HierarchyNode(
                    id: "node_l\(depth + 1)_\(currentPath)",
                    name: key,
                    value: groupTotal,
                    level: depth + 1,
                    children: children
                )
            }
        }

        let rootChildren = buildSubtree(items: data, depth: 0, parentPath: "root")
        let rootTotal = rootChildren.reduce(0.0) { $0 + $1.value }
        return HierarchyNode(id: "root", name: "Root", value: rootTotal, level: 0, children: rootChildren)
    }
}

/// 다단계 계층 트리 구조를 표현하는 노드 모델입니다.
public struct HierarchyNode<Item: Sendable>: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let value: Double
    public let level: Int
    public let children: [HierarchyNode<Item>]
    public let item: Item?

    public init(
        id: String? = nil,
        name: String,
        value: Double,
        level: Int = 0,
        children: [HierarchyNode<Item>] = [],
        item: Item? = nil
    ) {
        self.id = id ?? "node_l\(level)_\(name)"
        self.name = name
        self.value = value
        self.level = level
        self.children = children
        self.item = item
    }

    public var isLeaf: Bool { children.isEmpty }
}
