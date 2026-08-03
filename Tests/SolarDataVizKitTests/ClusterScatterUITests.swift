import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit

final class ClusterScatterUITests: XCTestCase {

    @MainActor
    func testDensityHeatmapViewUIRendering() throws {
        let nodes = [
            ClusterNode(center: CGPoint(x: 50, y: 50), radius: 20, childIDs: ["p1"], count: 1),
            ClusterNode(center: CGPoint(x: 100, y: 100), radius: 30, childIDs: ["p2", "p3"], count: 2)
        ]

        let heatmap = DensityHeatmapView(nodes: nodes, theme: .darkCarbon)
        let zStack = try heatmap.inspect().zStack()
        XCTAssertEqual(try zStack.forEach(0).count, 2)
    }

    @MainActor
    func testSolarClusterScatterViewUIRendering() throws {
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
            clusterRadiusThreshold: 50.0
        )

        XCTAssertNotNil(scatterView)
    }
}
