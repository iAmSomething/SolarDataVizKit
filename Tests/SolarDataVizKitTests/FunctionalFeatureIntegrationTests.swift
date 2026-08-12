import XCTest
import SwiftUI
@testable import SolarDataVizKit

final class FunctionalFeatureIntegrationTests: XCTestCase {

    // MARK: - 1. E2E Multi-Level Hierarchy Sunburst Arc Computation Feature Test

    func testEndToEndMultiLevelSunburstArcComputation() {
        struct FinancialRecord: SolarVizDataPoint {
            let id: String
            let company: String
            let division: String
            let team: String
            let revenue: Double

            var xValue: String { team }
            var yValue: Double { revenue }
        }

        let records = [
            FinancialRecord(id: "1", company: "SolarCorp", division: "Tech", team: "AI", revenue: 500.0),
            FinancialRecord(id: "2", company: "SolarCorp", division: "Tech", team: "Cloud", revenue: 300.0),
            FinancialRecord(id: "3", company: "SolarCorp", division: "Finance", team: "Audit", revenue: 200.0)
        ]

        let binding = VizDataBinding(
            data: records,
            x: \.team,
            y: \.revenue,
            hierarchy: [\.company, \.division, \.team]
        )

        let tree = binding.buildHierarchyTree()
        XCTAssertEqual(tree.name, "Root")
        XCTAssertEqual(tree.value, 1000.0)
        XCTAssertEqual(tree.children.count, 1) // SolarCorp

        let solarCorpNode = tree.children[0]
        XCTAssertEqual(solarCorpNode.name, "SolarCorp")
        XCTAssertEqual(solarCorpNode.children.count, 2) // Tech, Finance

        let techNode = solarCorpNode.children.first { $0.name == "Tech" }
        XCTAssertNotNil(techNode)
        XCTAssertEqual(techNode?.value, 800.0)
        XCTAssertEqual(techNode?.children.count, 2) // AI, Cloud
    }

    // MARK: - 2. Dynamic Layout Strategy Switching Feature Test

    @MainActor
    func testDynamicLayoutStrategySwitching() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "A", yValue: 60.0, category: "C", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 40.0, category: "C", subCategory: "S")
        ]

        let _ = VizDataBinding(data: items, x: \.xLabel, y: \.yValue)
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 100)

        let squarifiedTiles = SquarifiedTreemapStrategy().computeTiles(
            data: items,
            extractY: { $0.yValue },
            bounds: bounds
        )

        let sliceTiles = SliceAndDiceTreemapStrategy().computeTiles(
            data: items,
            extractY: { $0.yValue },
            bounds: bounds
        )

        XCTAssertEqual(squarifiedTiles.count, 2)
        XCTAssertEqual(sliceTiles.count, 2)

        // Verify total surface area matches bounds area
        let squarifiedArea = squarifiedTiles.reduce(0.0) { $0 + Double($1.rect.width * $1.rect.height) }
        let sliceArea = sliceTiles.reduce(0.0) { $0 + Double($1.rect.width * $1.rect.height) }
        XCTAssertEqual(squarifiedArea, 20000.0, accuracy: 0.1)
        XCTAssertEqual(sliceArea, 20000.0, accuracy: 0.1)
    }

    // MARK: - 3. Interactive Comparison Cross Haptics Feature Test

    func testComparisonHapticsIntersectionFeature() {
        let seriesA = [
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 50),
            CGPoint(x: 20, y: 10)
        ]
        let seriesB = [
            CGPoint(x: 0, y: 30),
            CGPoint(x: 10, y: 20),
            CGPoint(x: 20, y: 40)
        ]

        let crosses = IntersectionPathCalculator.findIntersections(seriesA: seriesA, seriesB: seriesB)
        XCTAssertEqual(crosses.count, 2, "Curve cross detection must locate both intersection points for haptic feedback triggers")

        let regions = IntersectionPathCalculator.computeRegions(seriesA: seriesA, seriesB: seriesB)
        XCTAssertGreaterThanOrEqual(regions.count, 2, "Shading region calculator must decompose intersecting areas into filled sub-paths")
    }

    // MARK: - 4. Spatial Grid Scatter Clustering Feature Test

    func testSpatialGridClusteringPointContainmentFeature() {
        let points: [(id: String, point: CGPoint, weight: Double)] = [
            (id: "p1", point: CGPoint(x: 100, y: 100), weight: 2.0),
            (id: "p2", point: CGPoint(x: 105, y: 102), weight: 1.0),
            (id: "p3", point: CGPoint(x: 102, y: 108), weight: 3.0)
        ]

        let nodes = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 20.0)
        XCTAssertEqual(nodes.count, 1, "Close points must cluster into a single node")

        let cluster = nodes[0]
        XCTAssertEqual(cluster.count, 3)
        XCTAssertTrue(cluster.childIDs.contains("p1"))
        XCTAssertTrue(cluster.childIDs.contains("p2"))
        XCTAssertTrue(cluster.childIDs.contains("p3"))
    }
}
