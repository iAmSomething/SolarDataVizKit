import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit

final class ClusterScatterUITests: XCTestCase {

    @MainActor
    func testDensityHeatmapViewCanvasInitialization() throws {
        let nodes = [
            ClusterNode(center: CGPoint(x: 50, y: 50), radius: 20, childIDs: ["p1"], count: 1),
            ClusterNode(center: CGPoint(x: 100, y: 100), radius: 30, childIDs: ["p2", "p3"], count: 2)
        ]

        let heatmap = DensityHeatmapView(nodes: nodes)
        let canvas = try heatmap.inspect().canvas()
        XCTAssertNotNil(canvas, "DensityHeatmapView must render a high-performance Canvas for single-pass Metal GPU rasterization")
    }

    @MainActor
    func testSolarClusterScatterViewDynamicGeometryReader() throws {
        struct ScatterPoint: SolarVizDataPoint {
            let id: Int
            let xPos: Double
            let yPos: Double
        }

        let points = [
            ScatterPoint(id: 1, xPos: 10.0, yPos: 10.0),
            ScatterPoint(id: 2, xPos: 12.0, yPos: 12.0),
            ScatterPoint(id: 3, xPos: 90.0, yPos: 90.0)
        ]

        let binding = VizDataBinding(
            data: points,
            x: \.xPos,
            y: \.yPos
        )

        let scatterView = SolarClusterScatterView(
            binding: binding,
            clusterRadiusThreshold: 40.0
        )
        let geometry = try scatterView.inspect().geometryReader()
        XCTAssertNotNil(geometry, "SolarClusterScatterView must wrap canvas inside GeometryReader for responsive size extraction")
    }

    func testClusterNodeStatefulCentroidAndRadiusCalculations() async throws {
        let inputPoints = (0..<10).map { i in
            (id: "pt_\(i)", point: CGPoint(x: 100.0 + Double(i), y: 100.0 + Double(i)), weight: 1.0)
        }

        let nodes = await ClusterNodeCalculator.cluster(
            points: inputPoints,
            thresholdRadius: 50.0
        )

        XCTAssertEqual(nodes.count, 1, "All 10 points within 50.0px threshold radius must merge into exactly 1 cluster node")
        XCTAssertEqual(nodes[0].count, 10, "Merged cluster node count must equal 10")
        XCTAssertEqual(nodes[0].childIDs.count, 10, "Child IDs count must equal 10")
        XCTAssertGreaterThan(nodes[0].radius, 0.0, "Node radius must be non-zero")
    }
}
