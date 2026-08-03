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

        let total = binding.data.reduce(0.0) { $0 + $1.value }
        XCTAssertEqual(total, 1000.0)

        let p1 = (items[0].value / total) * 100.0
        let p2 = (items[1].value / total) * 100.0
        let p3 = (items[2].value / total) * 100.0

        XCTAssertEqual(p1, 50.0)
        XCTAssertEqual(p2, 30.0)
        XCTAssertEqual(p3, 20.0)
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

        let total = binding.data.reduce(0.0) { $0 + $1.value }
        let sweep1 = (items[0].value / total) * 360.0
        let sweep2 = (items[1].value / total) * 360.0

        XCTAssertEqual(sweep1, 144.0)
        XCTAssertEqual(sweep2, 216.0)
        XCTAssertEqual(sweep1 + sweep2, 360.0)
    }
}
