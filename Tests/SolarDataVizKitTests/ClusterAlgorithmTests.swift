import XCTest
import CoreGraphics
@testable import SolarDataVizKit

final class ClusterAlgorithmTests: XCTestCase {

    func testDistanceCalculation() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 3, y: 4)

        let dist = ClusterNodeCalculator.distance(from: p1, to: p2)
        XCTAssertLessThan(abs(dist - 5.0), 0.001)
    }

    func testClusteringClosePoints() {
        let points: [(id: String, point: CGPoint, weight: Double)] = [
            (id: "p1", point: CGPoint(x: 10, y: 10), weight: 1.0),
            (id: "p2", point: CGPoint(x: 15, y: 12), weight: 1.0),
            (id: "p3", point: CGPoint(x: 12, y: 14), weight: 1.0),
            (id: "p4", point: CGPoint(x: 100, y: 100), weight: 1.0)
        ]

        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 20.0)
        XCTAssertEqual(clusters.count, 2)

        let mergedNode = clusters.first { $0.isMerged }
        XCTAssertNotNil(mergedNode)
        if let mergedNode {
            XCTAssertEqual(mergedNode.count, 3)
            XCTAssertEqual(mergedNode.childIDs.count, 3)
            XCTAssertLessThan(abs(mergedNode.center.x - 12.333), 0.1)
        }
    }

    func testFarPointsNoClustering() {
        let points: [(id: String, point: CGPoint, weight: Double)] = [
            (id: "p1", point: CGPoint(x: 10, y: 10), weight: 1.0),
            (id: "p2", point: CGPoint(x: 100, y: 100), weight: 1.0),
            (id: "p3", point: CGPoint(x: 200, y: 200), weight: 1.0)
        ]

        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 30.0)
        XCTAssertEqual(clusters.count, 3)
        XCTAssertTrue(clusters.allSatisfy { !$0.isMerged })
    }

    func testTaskCancellationDefense() async {
        let points: [(id: String, point: CGPoint, weight: Double)] = (0..<1000).map { i in
            (id: "p\(i)", point: CGPoint(x: Double.random(in: 0...1000), y: Double.random(in: 0...1000)), weight: 1.0)
        }
        
        let task = Task.detached {
            return ClusterNodeCalculator.cluster(points: points, thresholdRadius: 10.0)
        }
        
        // Immediately cancel the task
        task.cancel()
        
        let result = await task.value
        // If cancellation is caught early in the engine, it should return empty array []
        XCTAssertEqual(result.count, 0, "Cancelled cluster calculation should return an empty array")
    }
}
