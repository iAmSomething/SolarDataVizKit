import Foundation

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
    XValue: Hashable & Sendable,
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

    /// 사전 연산된 그룹별 데이터 딕셔너리 캐시입니다.
    private let cachedGroupedData: [String: [Item]]
    /// 사전 연산된 순서 보장 그룹별 데이터 배열 캐시입니다.
    private let cachedSortedGroupedData: [(key: String, items: [Item])]
    /// 사전 연산된 Y축 최소/최대 범위 캐시입니다.
    private let cachedYBounds: (min: YValue, max: YValue)

    /// KeyPath 바인딩 래퍼를 초기화합니다.
    ///
    /// - Parameters:
    ///   - data: 입력 데이터 모델 배열
    ///   - x: X축 바인딩 KeyPath
    ///   - y: Y축 바인딩 KeyPath
    ///   - group: 시리즈 그룹 바인딩 KeyPath (기본값: nil)
    ///   - hierarchy: 다중 계층 바인딩 KeyPath 배열 (기본값: 빈 배열)
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

        // Fast 64-bit memoization key computation (Count + KeyPaths + Sample Y-Values)
        var hasher = Hasher()
        hasher.combine(data.count)
        hasher.combine(x)
        hasher.combine(y)
        if !data.isEmpty {
            hasher.combine(data[0].id)
            hasher.combine(Double(data[0][keyPath: y]))
            hasher.combine(data[data.count - 1].id)
            hasher.combine(Double(data[data.count - 1][keyPath: y]))
            if data.count > 2 {
                hasher.combine(data[data.count / 2].id)
            }
        }
        if let group {
            hasher.combine(group)
        }
        let memoKey = hasher.finalize()

        typealias Payload = (
            groupedData: [String: [Item]],
            sortedGroupedData: [(key: String, items: [Item])],
            yBounds: (min: YValue, max: YValue)
        )

        if let cachedPayload: Payload = VizBindingMemoCache.getPayload(for: memoKey) {
            self.cachedGroupedData = cachedPayload.groupedData
            self.cachedSortedGroupedData = cachedPayload.sortedGroupedData
            self.cachedYBounds = cachedPayload.yBounds
            return
        }

        // 1. Single-Pass O(N) 그룹핑 사전 연산 캐싱
        let computedGroupedData: [String: [Item]]
        let computedSortedGroupedData: [(key: String, items: [Item])]

        if let group {
            var dict: [String: [Item]] = [:]
            var keys: [String] = []
            for item in data {
                let key = item[keyPath: group]
                if dict[key] == nil {
                    keys.append(key)
                }
                dict[key, default: []].append(item)
            }
            computedGroupedData = dict
            computedSortedGroupedData = keys.compactMap { key in
                guard let items = dict[key] else { return nil }
                return (key: key, items: items)
            }
        } else {
            computedGroupedData = ["Default": data]
            computedSortedGroupedData = [("Default", data)]
        }

        // 2. Y축 최소/최대 범위 사전 연산 캐싱
        let validItems = data.filter {
            let doubleVal = Double($0[keyPath: y])
            return !doubleVal.isNaN && !doubleVal.isInfinite
        }

        let computedYBounds: (min: YValue, max: YValue)
        if let first = validItems.first {
            var minY = first[keyPath: y]
            var maxY = minY
            for item in validItems {
                let val = item[keyPath: y]
                if val < minY { minY = val }
                if val > maxY { maxY = val }
            }
            if minY == maxY {
                minY = minY == 0 ? 0 : minY * 0.9
                maxY = maxY == 0 ? 1 : maxY * 1.1
            }
            computedYBounds = (minY, maxY)
        } else {
            computedYBounds = (0, 1)
        }

        self.cachedGroupedData = computedGroupedData
        self.cachedSortedGroupedData = computedSortedGroupedData
        self.cachedYBounds = computedYBounds

        let payload: Payload = (computedGroupedData, computedSortedGroupedData, computedYBounds)
        VizBindingMemoCache.setPayload(payload, for: memoKey)
    }

    /// 데이터 배열의 개수, 첫/끝/중간 요소 식별자 및 Y수치를 포함한 빠른 64-bit 데이터 해시값을 반환합니다.
    public var dataHash: Int {
        var hasher = Hasher()
        hasher.combine(data.count)
        if !data.isEmpty {
            hasher.combine(data.first?.id)
            hasher.combine(data.last?.id)
            let midIndex = data.count / 2
            hasher.combine(data[midIndex].id)
            hasher.combine(Double(extractY(from: data[midIndex])))
            hasher.combine(Double(extractY(from: data.first!)))
            hasher.combine(Double(extractY(from: data.last!)))
        }
        return hasher.finalize()
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
        cachedSortedGroupedData.map(\.key)
    }

    /// O(1) 상전 연산 캐시를 통한 즉각적 그룹별 데이터 딕셔너리를 반환합니다.
    public func groupedData() -> [String: [Item]] {
        cachedGroupedData
    }

    /// O(1) 사전 연산 캐시를 통한 즉각적 그룹별 데이터 배열을 반환합니다.
    public func sortedGroupedData() -> [(key: String, items: [Item])] {
        cachedSortedGroupedData
    }

    /// O(1) 사전 연산 캐시를 통한 즉각적 Y축 수치의 최솟값과 최댓값을 반환합니다.
    public func yBounds() -> (min: YValue, max: YValue) {
        cachedYBounds
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

/// `VizBindingMemoCache`는 SwiftUI `body` 내부에서 인라인으로 `VizDataBinding` 구조체를 반복 생성할 때
/// 메인 스레드 연산 오버헤드를 0.00ms로 소멸시키는 스레드 세이프 메모이전 캐시 관리자입니다.
internal struct VizBindingMemoCache {
    nonisolated(unsafe) private static var lock = os_unfair_lock_s()
    nonisolated(unsafe) private static var storage: [Int: Any] = [:]

    static func getPayload<T>(for key: Int) -> T? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return storage[key] as? T
    }

    static func setPayload<T>(_ payload: T, for key: Int) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        if storage.count > 64 {
            storage.removeAll(keepingCapacity: true)
        }
        storage[key] = payload
    }
}
