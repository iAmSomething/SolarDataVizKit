import Foundation
import CoreGraphics

/// 차트 축에 매핑될 수 있는 데이터의 자격 요건을 정의합니다. (Swift 6 Strict Concurrency Sendable 준수)
public protocol SolarPlottable: Hashable, Sendable, CustomStringConvertible {
    /// 수학 엔진이 계산할 수 있는 Double 형태의 수치로 변환합니다.
    var asPlotValue: Double { get }
}

extension Int: SolarPlottable { public var asPlotValue: Double { Double(self) } }
extension Double: SolarPlottable { public var asPlotValue: Double { self } }
extension Float: SolarPlottable { public var asPlotValue: Double { Double(self) } }
extension CGFloat: SolarPlottable { public var asPlotValue: Double { Double(self) } }
extension Date: SolarPlottable { public var asPlotValue: Double { self.timeIntervalSince1970 } }
extension String: SolarPlottable {
    public var asPlotValue: Double {
        Double(self) ?? Double(abs(self.hashValue) % 10_000)
    }
}

/// SolarDataVizKit의 모든 시각화 엔진에서 다루는 코어 데이터 포인트 프로토콜입니다.
///
/// ## Overview
/// `SolarVizDataPoint`는 사용자의 기존 도메인 모델을 시각화 뷰에 연결하는 근간 프로토콜입니다.
/// `Identifiable`, `Sendable`, `Hashable`을 결합하여 Swift 6 스레드 세이프티와 SwiftUI Diffing 최적화를 보장합니다.
///
/// ## Topics
/// ### Requirements
/// - ``id``
///
/// ## Example
/// ```swift
/// struct MonthlyExpense: SolarVizDataPoint {
///     let id = UUID()
///     let month: String
///     let amount: Double
/// }
/// ```
public protocol SolarVizDataPoint: Identifiable, Sendable, Hashable where ID: Hashable {
    /// 데이터 포인트의 고유 식별자입니다.
    var id: ID { get }
}

/// 그룹(시리즈) 범례 정보를 갖춘 확장 데이터 포인트 프로토콜입니다.
///
/// ## Overview
/// 다중 시리즈 비교 차트(Grouped Comparison Engine) 등에 활용되며 시리즈 이름을 식별합니다.
public protocol SolarGroupedVizDataPoint: SolarVizDataPoint {
    /// 데이터 포인트가 속한 시리즈/그룹 식별자 이름입니다.
    var groupIdentifier: String { get }
}

/// 기본 데이터 포인트 구현체로, 커스텀 모델 없이 빠르게 테스트하거나 정적 데이터를 다룰 때 사용합니다.
///
/// ## Overview
/// 별도의 데이터 모델 작성 없이 간단한 스니펫이나 데모용 차트를 생성할 때 사용하는 구조체입니다.
public struct SolarDefaultDataPoint: SolarVizDataPoint, SolarGroupedVizDataPoint {
    /// 데이터 고유 식별자
    public let id: String
    /// X축 라벨 이름
    public let xLabel: String
    /// Y축 수치 값
    public let value: Double
    /// 시리즈/그룹 이름
    public let groupIdentifier: String

    /// 새로운 정적 데이터 포인트를 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 고유 식별자 문자열 (기본값: UUID)
    ///   - xLabel: X축 표시 라벨
    ///   - value: Y축 수치
    ///   - groupIdentifier: 속한 그룹 이름 (기본값: "Default")
    public init(
        id: String = UUID().uuidString,
        xLabel: String,
        value: Double,
        groupIdentifier: String = "Default"
    ) {
        self.id = id
        self.xLabel = xLabel
        self.value = value
        self.groupIdentifier = groupIdentifier
    }
}
