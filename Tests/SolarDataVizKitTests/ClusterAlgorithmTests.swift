import Testing
@testable import SolarDataVizKit
import CoreGraphics

@Suite("ClusterNodeCalculator Math Tests")
struct ClusterAlgorithmTests {

    @Test("Euclidean distance calculation test")
    func testDistanceCalculation() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 3, y: 4)

        let dist = ClusterNodeCalculator.distance(from: p1, to: p2)
        #expect(abs(dist - 5.0) < 0.001)
    }

    @Test("Clustering close points into merged node")
    func testClusteringClosePoints() {
        let points: [(id: String, point: CGPoint, weight: Double)] = [
            (id: "p1", point: CGPoint(x: 10, y: 10), weight: 1.0),
            (id: "p2", point: CGPoint(x: 15, y: 12), weight: 1.0),
            (id: "p3", point: CGPoint(x: 12, y: 14), weight: 1.0),
            (id: "p4", point: CGPoint(x: 100, y: 100), weight: 1.0)
        ]

        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 20.0)
        #expect(clusters.count == 2)

        let mergedNode = clusters.first { $0.isMerged }
        #expect(mergedNode != nil)
        if let mergedNode {
            #expect(mergedNode.count == 3)
            #expect(mergedNode.childIDs.count == 3)
            #expect(abs(mergedNode.center.x - 12.333) < 0.1)
        }
    }

    @Test("Far points should remain separate single nodes")
    func testFarPointsNoClustering() {
        let points: [(id: String, point: CGPoint, weight: Double)] = [
            (id: "p1", point: CGPoint(x: 10, y: 10), weight: 1.0),
            (id: "p2", point: CGPoint(x: 100, y: 100), weight: 1.0),
            (id: "p3", point: CGPoint(x: 200, y: 200), weight: 1.0)
        ]

        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 30.0)
        #expect(clusters.count == 3)
        #expect(clusters.allSatisfy { !$0.isMerged })
    }
}
