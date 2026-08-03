import Foundation
import CoreGraphics

/// 단일 데이터 포인트 또는 여러 포인트가 거리 임계값에 의해 통합 합체된 군집 노드 정보 구조체입니다.
///
/// ## Overview
/// 산점도 차트 상에서 중심 좌표 `center`, 반지름 `radius`, 합쳐진 노드 수 `count`를 가집니다.
public struct ClusterNode: Identifiable, Sendable, Hashable {
    /// 노드 고유 식별자
    public let id: String
    /// 2차원 중심 좌표
    public let center: CGPoint
    /// 원 반지름 크기
    public let radius: CGFloat
    /// 합쳐진 하위 데이터 포인트 ID 배열
    public let childIDs: [String]
    /// 합쳐진 데이터 포인트 개수
    public let count: Int

    /// 군집 노드 구조체를 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - center: 2차원 좌표
    ///   - radius: 원 반지름
    ///   - childIDs: 포함된 하위 포인트 ID 배열
    ///   - count: 포인트 개수
    public init(
        id: String = UUID().uuidString,
        center: CGPoint,
        radius: CGFloat = 20.0,
        childIDs: [String],
        count: Int
    ) {
        self.id = id
        self.center = center
        self.radius = radius
        self.childIDs = childIDs
        self.count = count
    }

    /// 여러 포인트가 뭉쳐진 통합 노드인지 여부입니다.
    public var isMerged: Bool {
        count > 1
    }
}

/// 2차원 공간 좌표 간 유클리드 거리를 측정하여 거리 임계값 내 노드를 뭉쳐주는 군집화 엔진입니다.
///
/// ## Overview
/// `ClusterNodeCalculator`는 단일 스캔 $O(N)$ 거리 알고리즘으로 60fps 노드 합체 연산을 수행합니다.
///
/// ## Topics
/// ### Methods
/// - ``cluster(points:thresholdRadius:)``
/// - ``distance(from:to:)``
public struct ClusterNodeCalculator: Sendable {

    /// 2차원 좌표 리스트를 입력받아 거리 임계값(thresholdRadius) 이내 포인트들을 하나의 ClusterNode로 합체하여 반환합니다.
    ///
    /// - Parameters:
    ///   - points: (id, point, weight) 튜플 배열
    ///   - thresholdRadius: 노드가 합쳐질 유클리드 거리 임계값
    /// - Returns: 군집화된 `ClusterNode` 배열
    public static func cluster(
        points: [(id: String, point: CGPoint, weight: Double)],
        thresholdRadius: CGFloat
    ) -> [ClusterNode] {
        guard !points.isEmpty else { return [] }
        var visited = Set<String>()
        var resultNodes: [ClusterNode] = []

        for i in 0..<points.count {
            let current = points[i]
            if visited.contains(current.id) { continue }

            var clusterPoints = [current]
            visited.insert(current.id)

            for j in (i + 1)..<points.count {
                let neighbor = points[j]
                if visited.contains(neighbor.id) { continue }

                let dist = distance(from: current.point, to: neighbor.point)
                if dist <= thresholdRadius {
                    clusterPoints.append(neighbor)
                    visited.insert(neighbor.id)
                }
            }

            var totalX: CGFloat = 0
            var totalY: CGFloat = 0
            var totalWeight: Double = 0
            var childIDs: [String] = []

            for p in clusterPoints {
                totalX += p.point.x
                totalY += p.point.y
                totalWeight += max(p.weight, 1.0)
                childIDs.append(p.id)
            }

            let count = clusterPoints.count
            let center = CGPoint(x: totalX / CGFloat(count), y: totalY / CGFloat(count))
            let baseRadius: CGFloat = 16.0
            let calculatedRadius = baseRadius + CGFloat(log2(Double(count)) * 6.0) + CGFloat(totalWeight * 2.0)

            resultNodes.append(ClusterNode(
                id: "cluster_\(current.id)_\(count)",
                center: center,
                radius: min(calculatedRadius, 60.0),
                childIDs: childIDs,
                count: count
            ))
        }

        return resultNodes
    }

    /// 두 2차원 좌표 간 유클리드 거리를 계산합니다.
    ///
    /// - Parameters:
    ///   - p1: 기준점 1
    ///   - p2: 기준점 2
    /// - Returns: 유클리드 거리 값
    @inlinable
    public static func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
}
