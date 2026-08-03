#if canImport(UIKit)
import UIKit
#endif
import Foundation

/// 시각화 인터랙션(스크러빙, 교차점 도달, 클러스터 스냅 등) 시 생동감 있는 햅틱 피드백을 전달하는 드라이버입니다.
///
/// ## Overview
/// `@MainActor` 기반으로 UI 메인 스레드 안전성을 보장하며, `isEnabled` 플래그로 전역 햅틱 유무를 제어합니다.
///
/// ## Topics
/// ### Methods
/// - ``playSelection()``
/// - ``playImpact(style:)``
/// - ``playClusterSnap()``
/// - ``prepare()``
///
/// ## Example
/// ```swift
/// Task { @MainActor in
///     SolarVizHaptics.shared.playImpact(style: .medium)
/// }
/// ```
@MainActor
public final class SolarVizHaptics {
    /// 싱글톤 공유 인스턴스입니다.
    public static let shared = SolarVizHaptics()

    /// 햅틱 피드백 전역 활성화 상태 플래그입니다. (기본값: true)
    public var isEnabled: Bool = true

    /// 햅틱 충격 스타일 세기 옵션입니다.
    public enum ImpactStyle: Sendable {
        /// 가벼운 피드백
        case light
        /// 중간 강도 피드백
        case medium
        /// 강한 피드백
        case heavy
        /// 부드러운 탄성 피드백
        case soft
        /// 단단한 피드백
        case rigid
    }

    #if canImport(UIKit)
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    #endif

    private init() {}

    /// 터치 스크러빙 이동 중 데이터 포인트를 통과할 때 가벼운 선택 햅틱을 재생합니다.
    public func playSelection() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        if selectionGenerator == nil {
            selectionGenerator = UISelectionFeedbackGenerator()
        }
        selectionGenerator?.prepare()
        selectionGenerator?.selectionChanged()
        #endif
    }

    /// 데이터선 교차점이나 임계값 도달 시 묵직한 충격 피드백을 재생합니다.
    ///
    /// - Parameter style: 충격 세기 스타일 (기본값: .medium)
    public func playImpact(style: ImpactStyle = .medium) {
        guard isEnabled else { return }
        #if canImport(UIKit)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: uiStyle = .light
        case .medium: uiStyle = .medium
        case .heavy: uiStyle = .heavy
        case .soft: uiStyle = .soft
        case .rigid: uiStyle = .rigid
        }
        let generator = impactGenerators[uiStyle] ?? {
            let gen = UIImpactFeedbackGenerator(style: uiStyle)
            impactGenerators[uiStyle] = gen
            return gen
        }()
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    /// 클러스터 노드 합체/분리 시 탄성 피드백을 재생합니다.
    public func playClusterSnap() {
        playImpact(style: .soft)
    }

    /// 햅틱 엔진 구동 리소스를 사전 준비합니다.
    public func prepare() {
        guard isEnabled else { return }
        #if canImport(UIKit)
        if selectionGenerator == nil {
            selectionGenerator = UISelectionFeedbackGenerator()
        }
        selectionGenerator?.prepare()
        #endif
    }
}
