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

    /// KeyPath 바인딩 래퍼를 초기화합니다.
    ///
    /// - Parameters:
    ///   - data: 입력 데이터 모델 배열
    ///   - x: X축 바인딩 KeyPath
    ///   - y: Y축 바인딩 KeyPath
    ///   - group: 시리즈 그룹 바인딩 KeyPath (기본값: nil)
    public init(
        data: [Item],
        x: KeyPath<Item, XValue>,
        y: KeyPath<Item, YValue>,
        group: KeyPath<Item, String>? = nil
    ) {
        self.data = data
        self.xKeyPath = x
        self.yKeyPath = y
        self.groupKeyPath = group
    }

    /// 특정 데이터 항목에서 X축 값을 추출합니다.
    ///
    /// - Parameter item: 대상 데이터 포인트
    /// - Returns: 키패스로 바인딩된 X축 값
    @inlinable
    public func extractX(from item: Item) -> XValue {
        item[keyPath: xKeyPath]
    }

    /// 특정 데이터 항목에서 Y축 수치를 추출합니다.
    ///
    /// - Parameter item: 대상 데이터 포인트
    /// - Returns: 키패스로 바인딩된 Y축 수치
    @inlinable
    public func extractY(from item: Item) -> YValue {
        item[keyPath: yKeyPath]
    }

    /// 특정 데이터 항목에서 속한 그룹 이름을 추출합니다.
    ///
    /// - Parameter item: 대상 데이터 포인트
    /// - Returns: 속한 그룹 이름 (그룹 키패드가 없을 경우 "Default")
    @inlinable
    public func extractGroup(from item: Item) -> String {
        guard let groupKeyPath else { return "Default" }
        return item[keyPath: groupKeyPath]
    }

    /// 전체 데이터를 속한 그룹/시리즈별로 분류하여 반환합니다.
    ///
    /// - Returns: 그룹 이름을 키로 하는 딕셔너리
    public func groupedData() -> [String: [Item]] {
        guard let groupKeyPath else {
            return ["Default": data]
        }
        var dict: [String: [Item]] = [:]
        for item in data {
            let key = item[keyPath: groupKeyPath]
            dict[key, default: []].append(item)
        }
        return dict
    }

    /// 전체 데이터에서 Y축 수치의 최솟값과 최댓값을 구합니다.
    ///
    /// - Returns: (min, max) 튜플
    public func yBounds() -> (min: YValue, max: YValue) {
        guard !data.isEmpty else { return (0, 1) }
        var minY = data[0][keyPath: yKeyPath]
        var maxY = minY

        for item in data {
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
        return Double(normalized)
    }
}
