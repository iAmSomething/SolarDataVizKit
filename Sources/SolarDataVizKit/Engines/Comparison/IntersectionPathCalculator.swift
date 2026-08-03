import Foundation
import CoreGraphics

/// 두 데이터선이 교차하는 2차원 공간 좌표 정보 구조체입니다.
///
/// ## Overview
/// 2개 시리즈 선이 겹치는 교차점 위치 `point`와 각각의 인덱스 정보를 가지고 있습니다.
public struct IntersectionPoint: Sendable, Hashable {
    /// 교차 2차원 좌표 위치
    public let point: CGPoint
    /// 시리즈 A 내 선분 시작 인덱스
    public let indexA: Int
    /// 시리즈 B 내 선분 시작 인덱스
    public let indexB: Int

    /// 교차점 구조체를 생성합니다.
    ///
    /// - Parameters:
    ///   - point: 교차점 좌표
    ///   - indexA: 시리즈 A 인덱스
    ///   - indexB: 시리즈 B 인덱스
    public init(point: CGPoint, indexA: Int, indexB: Int) {
        self.point = point
        self.indexA = indexA
        self.indexB = indexB
    }
}

/// 두 선이 교차하며 형성하는 닫힌 다각형 영역 및 우위 정보 구조체입니다.
///
/// ## Overview
/// 교차점 사이의 영역을 다각형 패스로 채우고, 시리즈 A가 높은지 여부(`isASuperior`)를 구분합니다.
public struct IntersectionRegion: Sendable, Identifiable {
    /// 영역 식별자
    public let id: String
    /// 시리즈 A 구간 포인트들
    public let pointsA: [CGPoint]
    /// 시리즈 B 구간 포인트들
    public let pointsB: [CGPoint]
    /// 시리즈 A가 상단에 위치하는지 여부
    public let isASuperior: Bool

    /// 교차 영역 구조체를 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - pointsA: 시리즈 A 포인트 배열
    ///   - pointsB: 시리즈 B 포인트 배열
    ///   - isASuperior: 시리즈 A 우위 여부
    public init(
        id: String = UUID().uuidString,
        pointsA: [CGPoint],
        pointsB: [CGPoint],
        isASuperior: Bool
    ) {
        self.id = id
        self.pointsA = pointsA
        self.pointsB = pointsB
        self.isASuperior = isASuperior
    }
}

/// 2개 데이터 시리즈 간 교차점과 역전 영역을 선형 수식 계산하는 고성능 값 타입 엔진입니다.
///
/// ## Overview
/// `IntersectionPathCalculator`는 힙 할당 없이 스택 상에서 $O(N)$ 행렬식 수식을 연산합니다.
///
/// ## Topics
/// ### Methods
/// - ``findIntersections(seriesA:seriesB:)``
/// - ``lineSegmentIntersection(p1:p2:p3:p4:)``
/// - ``computeRegions(seriesA:seriesB:)``
///
/// ## Example
/// ```swift
/// let crosses = IntersectionPathCalculator.findIntersections(seriesA: pointsA, seriesB: pointsB)
/// ```
public struct IntersectionPathCalculator: Sendable {

    /// 두 데이터 포인트 배열 간의 교차점을 모두 찾아 반환합니다.
    ///
    /// - Parameters:
    ///   - seriesA: 시리즈 A의 2차원 좌표 배열
    ///   - seriesB: 시리즈 B의 2차원 좌표 배열
    /// - Returns: 교차점 `IntersectionPoint` 배열
    public static func findIntersections(seriesA: [CGPoint], seriesB: [CGPoint]) -> [IntersectionPoint] {
        guard seriesA.count >= 2, seriesB.count >= 2 else { return [] }
        var result: [IntersectionPoint] = []

        // Check if both series are monotonically increasing on X-axis
        let isMonotonicA = zip(seriesA, seriesA.dropFirst()).allSatisfy { $0.x <= $1.x }
        let isMonotonicB = zip(seriesB, seriesB.dropFirst()).allSatisfy { $0.x <= $1.x }
        let isMonotonic = isMonotonicA && isMonotonicB

        var startJ = 0
        for i in 0..<(seriesA.count - 1) {
            let a1 = seriesA[i]
            let a2 = seriesA[i + 1]
            let minAx = min(a1.x, a2.x)
            let maxAx = max(a1.x, a2.x)
            let minAy = min(a1.y, a2.y)
            let maxAy = max(a1.y, a2.y)

            if isMonotonic {
                while startJ < (seriesB.count - 1) && max(seriesB[startJ].x, seriesB[startJ + 1].x) < minAx {
                    startJ += 1
                }
            }

            let initialJ = isMonotonic ? startJ : 0
            for j in initialJ..<(seriesB.count - 1) {
                let b1 = seriesB[j]
                let b2 = seriesB[j + 1]
                let minBx = min(b1.x, b2.x)
                let maxBx = max(b1.x, b2.x)
                let minBy = min(b1.y, b2.y)
                let maxBy = max(b1.y, b2.y)

                if isMonotonic && minBx > maxAx {
                    break
                }

                // 2D X/Y Bounding box overlap check before doing floating point matrix math
                if !(maxAx < minBx || minAx > maxBx || maxAy < minBy || minAy > maxBy) {
                    if let intersection = lineSegmentIntersection(p1: a1, p2: a2, p3: b1, p4: b2) {
                        result.append(IntersectionPoint(point: intersection, indexA: i, indexB: j))
                    }
                }
            }
        }
        return result
    }

    /// 두 선분 (p1-p2)와 (p3-p4)의 교차점을 계산합니다. 교차하지 않으면 nil을 반환합니다.
    ///
    /// - Parameters:
    ///   - p1: 선분 1 시작점
    ///   - p2: 선분 1 끝점
    ///   - p3: 선분 2 시작점
    ///   - p4: 선분 2 끝점
    /// - Returns: 교차점 좌표 (없으면 nil)
    public static func lineSegmentIntersection(p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> CGPoint? {
        let denominator = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)
        guard abs(denominator) > 1e-12 else { return nil }

        let uA = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denominator
        let uB = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denominator

        if uA >= 0.0 && uA <= 1.0 && uB >= 0.0 && uB <= 1.0 {
            let x = p1.x + uA * (p2.x - p1.x)
            let y = p1.y + uA * (p2.y - p1.y)
            return CGPoint(x: x, y: y)
        }
        return nil
    }

    /// 교차점들을 기준으로 두 데이터 시리즈 사이의 구분 영역(Regions)을 생성합니다.
    ///
    /// - Parameters:
    ///   - seriesA: 시리즈 A 좌표 배열
    ///   - seriesB: 시리즈 B 좌표 배열
    /// - Returns: 닫힌 영역 `IntersectionRegion` 배열
    public static func computeRegions(seriesA: [CGPoint], seriesB: [CGPoint]) -> [IntersectionRegion] {
        guard seriesA.count > 1, seriesA.count == seriesB.count else { return [] }
        var regions: [IntersectionRegion] = []

        var currentA: [CGPoint] = []
        var currentB: [CGPoint] = []
        var currentIsASuperior: Bool?

        for i in 0..<seriesA.count {
            let ptA = seriesA[i]
            let ptB = seriesB[i]
            let isASuperiorNow = ptA.y <= ptB.y

            if let isASuperior = currentIsASuperior, isASuperior != isASuperiorNow {
                let prevA = seriesA[i - 1]
                let prevB = seriesB[i - 1]
                if let cross = lineSegmentIntersection(p1: prevA, p2: ptA, p3: prevB, p4: ptB) {
                    currentA.append(cross)
                    currentB.append(cross)

                    regions.append(IntersectionRegion(
                        pointsA: currentA,
                        pointsB: currentB,
                        isASuperior: isASuperior
                    ))

                    currentA = [cross, ptA]
                    currentB = [cross, ptB]
                } else {
                    currentA.append(ptA)
                    currentB.append(ptB)
                }
            } else {
                currentA.append(ptA)
                currentB.append(ptB)
            }
            currentIsASuperior = isASuperiorNow
        }

        if let isASuperior = currentIsASuperior, !currentA.isEmpty {
            regions.append(IntersectionRegion(
                pointsA: currentA,
                pointsB: currentB,
                isASuperior: isASuperior
            ))
        }

        return regions
    }
}
