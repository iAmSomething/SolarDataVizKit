import Foundation

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
@MainActor
public final class SolarVizLayoutCache {
    /// 싱글톤 공유 인스턴스입니다.
    public static let shared = SolarVizLayoutCache()

    /// 최대 보관 허용 캐시 항목 개수 (LRU 퇴출 기준)
    public var maxCapacity: Int = 100

    private var clusterCache: [String: [ClusterNode]] = [:]
    private var clusterLRUKeys: [String] = []

    private var intersectionCache: [String: [IntersectionRegion]] = [:]
    private var intersectionLRUKeys: [String] = []

    private init() {}

    /// 군집화 연산 결과를 캐시에서 조회합니다.
    ///
    /// - Parameter key: 복합 해시 키 문자열
    /// - Returns: 캐시된 클러스터 노드 배열 (없으면 nil)
    public func getClusterNodes(forKey key: String) -> [ClusterNode]? {
        guard let nodes = clusterCache[key] else { return nil }
        // LRU 순서 갱신 (최근 사용된 키를 가장 뒤로 이동)
        if let idx = clusterLRUKeys.firstIndex(of: key) {
            clusterLRUKeys.remove(at: idx)
            clusterLRUKeys.append(key)
        }
        return nodes
    }

    /// 군집화 연산 결과를 캐시에 저장합니다 (용량 초과 시 LRU 퇴출).
    ///
    /// - Parameters:
    ///   - nodes: 저장할 클러스터 노드 배열
    ///   - key: 복합 해시 키 문자열
    public func setClusterNodes(_ nodes: [ClusterNode], forKey key: String) {
        if clusterCache[key] == nil {
            if clusterLRUKeys.count >= maxCapacity {
                let evictedKey = clusterLRUKeys.removeFirst()
                clusterCache.removeValue(forKey: evictedKey)
            }
            clusterLRUKeys.append(key)
        }
        clusterCache[key] = nodes
    }

    /// 교차 구간 연산 결과를 캐시에서 조회합니다.
    ///
    /// - Parameter key: 복합 해시 키 문자열
    /// - Returns: 캐시된 교차 영역 배열 (없으면 nil)
    public func getIntersectionRegions(forKey key: String) -> [IntersectionRegion]? {
        guard let regions = intersectionCache[key] else { return nil }
        if let idx = intersectionLRUKeys.firstIndex(of: key) {
            intersectionLRUKeys.remove(at: idx)
            intersectionLRUKeys.append(key)
        }
        return regions
    }

    /// 교차 구간 연산 결과를 캐시에 저장합니다 (용량 초과 시 LRU 퇴출).
    ///
    /// - Parameters:
    ///   - regions: 저장할 교차 영역 배열
    ///   - key: 복합 해시 키 문자열
    public func setIntersectionRegions(_ regions: [IntersectionRegion], forKey key: String) {
        if intersectionCache[key] == nil {
            if intersectionLRUKeys.count >= maxCapacity {
                let evictedKey = intersectionLRUKeys.removeFirst()
                intersectionCache.removeValue(forKey: evictedKey)
            }
            intersectionLRUKeys.append(key)
        }
        intersectionCache[key] = regions
    }

    /// 인메모리에 보관된 모든 캐시를 비웁니다.
    public func clearAll() {
        clusterCache.removeAll()
        clusterLRUKeys.removeAll()
        intersectionCache.removeAll()
        intersectionLRUKeys.removeAll()
    }
}
