import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// SwiftUI의 빈번한 body 재평가 시 차트 수식을 0ms 만에 재사용하기 위한 레이아웃 캐시 클래스입니다.
///
/// ## Overview
/// `SolarVizLayoutCache`는 데이터 해시 키와 뷰 해상도가 변하지 않았다면 이전 연산 결과(클러스터 노드, 교차 구간)를
/// 인메모리에 보관하여 CPU 사용률 0% 상태로 복원합니다.
///
/// ## Topics
/// ### Methods
/// - ``getClusterNodes(forKey:)``
/// - ``setClusterNodes(_:forKey:)``
/// - ``getIntersectionRegions(forKey:)``
/// - ``setIntersectionRegions(_:forKey:)``
/// - ``clearAll()``
///
/// ## Example
/// ```swift
/// if let nodes = SolarVizLayoutCache.shared.getClusterNodes(forKey: cacheKey) {
///     return nodes
/// }
/// ```
final class CacheBox<T>: NSObject {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

public actor SolarVizLayoutCache: Sendable {
    /// 싱글톤 공유 인스턴스입니다.
    public static let shared = SolarVizLayoutCache()

    private let clusterCache = NSCache<NSString, CacheBox<[ClusterNode]>>()
    private let intersectionCache = NSCache<NSString, CacheBox<[IntersectionRegion]>>()

    private init() {
        clusterCache.countLimit = 50
        intersectionCache.countLimit = 50

        #if os(iOS) || os(tvOS)
        Task {
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification) {
                await self.clearAll()
            }
        }
        #endif
    }

    /// 군집화 연산 결과를 캐시에서 조회합니다.
    ///
    /// - Parameter key: 복합 해시 키 문자열
    /// - Returns: 캐시된 클러스터 노드 배열 (없으면 nil)
    public func getClusterNodes(forKey key: String) -> [ClusterNode]? {
        clusterCache.object(forKey: key as NSString)?.value
    }

    /// 군집화 연산 결과를 캐시에 저장합니다.
    ///
    /// - Parameters:
    ///   - nodes: 저장할 클러스터 노드 배열
    ///   - key: 복합 해시 키 문자열
    public func setClusterNodes(_ nodes: [ClusterNode], forKey key: String) {
        clusterCache.setObject(CacheBox(nodes), forKey: key as NSString)
    }

    /// 교차 구간 연산 결과를 캐시에서 조회합니다.
    ///
    /// - Parameter key: 복합 해시 키 문자열
    /// - Returns: 캐시된 교차 영역 배열 (없으면 nil)
    public func getIntersectionRegions(forKey key: String) -> [IntersectionRegion]? {
        intersectionCache.object(forKey: key as NSString)?.value
    }

    /// 교차 구간 연산 결과를 캐시에 저장합니다.
    ///
    /// - Parameters:
    ///   - regions: 저장할 교차 영역 배열
    ///   - key: 복합 해시 키 문자열
    public func setIntersectionRegions(_ regions: [IntersectionRegion], forKey key: String) {
        intersectionCache.setObject(CacheBox(regions), forKey: key as NSString)
    }

    /// 인메모리에 보관된 모든 캐시를 비웁니다.
    public func clearAll() {
        clusterCache.removeAllObjects()
        intersectionCache.removeAllObjects()
    }
}
