import XCTest
import CoreGraphics
@testable import SolarDataVizKit

struct HierarchyTestModel: SolarVizDataPoint {
    let id: String
    let name: String
    let value: Double
}

final class HierarchyEngineTests: XCTestCase {

    func testTreeMapTilePercentages() {
        let items = [
            HierarchyTestModel(id: "1", name: "Stocks", value: 500.0),
            HierarchyTestModel(id: "2", name: "Bonds", value: 300.0),
            HierarchyTestModel(id: "3", name: "Cash", value: 200.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.name,
            y: \.value
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let strategy = SquarifiedTreemapStrategy()
        let tiles = strategy.computeTiles(
            data: items,
            extractY: { $0.value },
            extractID: { $0.id },
            bounds: bounds
        )
        
        XCTAssertEqual(tiles.count, 3)
        XCTAssertEqual(tiles[0].percentage, 50.0, accuracy: 0.1)
        XCTAssertEqual(tiles[1].percentage, 30.0, accuracy: 0.1)
        XCTAssertEqual(tiles[2].percentage, 20.0, accuracy: 0.1)
        
        // Check for area matching and non-overlapping
        var totalArea: CGFloat = 0.0
        for i in 0..<tiles.count {
            totalArea += (tiles[i].rect.width * tiles[i].rect.height)
            for j in (i + 1)..<tiles.count {
                // Ignore zero area overlap (like edges touching) by checking intersection area
                let intersection = tiles[i].rect.intersection(tiles[j].rect)
                XCTAssertTrue(intersection.isNull || intersection.isEmpty || (intersection.width * intersection.height) < 0.1, "Tiles should not overlap significantly")
            }
        }
        
        let expectedTotalArea = bounds.width * bounds.height
        XCTAssertEqual(totalArea, expectedTotalArea, accuracy: 1.0, "Total area of all tiles must equal the bounds area")
    }

    func testSunburstArcSweep() {
        let items = [
            HierarchyTestModel(id: "1", name: "Housing", value: 40.0),
            HierarchyTestModel(id: "2", name: "Food", value: 60.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.name,
            y: \.value
        )

        let arcs = binding.sunburstArcs()
        XCTAssertGreaterThan(arcs.count, 0)
        
        let parentArc = arcs.first { !$0.isChild }
        XCTAssertEqual(parentArc?.startAngle.degrees, -90.0, "Root/Parent arc must start exactly at 12 o'clock (-90.0 degrees)")
        
        let housingArcs = arcs.filter { $0.item.name == "Housing" && $0.isChild }
        let foodArcs = arcs.filter { $0.item.name == "Food" && $0.isChild }
        
        XCTAssertEqual(housingArcs.count, 1)
        XCTAssertEqual(foodArcs.count, 1)
        
        XCTAssertEqual(housingArcs[0].percentage, 40.0, accuracy: 0.1)
        XCTAssertEqual(foodArcs[0].percentage, 60.0, accuracy: 0.1)
        
        let sweep1: Double = housingArcs[0].endAngle.degrees - housingArcs[0].startAngle.degrees
        let sweep2: Double = foodArcs[0].endAngle.degrees - foodArcs[0].startAngle.degrees

        XCTAssertEqual(sweep1, 144.0, accuracy: 0.1)
        XCTAssertEqual(sweep2, 216.0, accuracy: 0.1)
        XCTAssertEqual(sweep1 + sweep2, 360.0, accuracy: 0.1)
    }

    func testBuildHierarchyTreeFlatData() {
        let items = [
            HierarchyTestModel(id: "1", name: "A", value: 10.0),
            HierarchyTestModel(id: "2", name: "B", value: 20.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.name,
            y: \.value
        )
        // No groupKeyPath is specified, so it is flat data.

        let root = binding.buildHierarchyTree()
        XCTAssertEqual(root.name, "Root")
        XCTAssertEqual(root.children.count, 2, "Flat data should place all items directly under the root")
        XCTAssertEqual(root.children[0].children.count, 0, "Flat nodes should not have nested groups")
        XCTAssertEqual(root.children[1].children.count, 0, "Flat nodes should not have nested groups")
    }
}
