import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit

final class HierarchyEngineUITests: XCTestCase {

    @MainActor
    func testSolarTreeMapViewUIRendering() throws {
        struct TileItem: SolarVizDataPoint {
            let id: Int
            let category: String
            let amount: Double
        }

        let items = [
            TileItem(id: 1, category: "Tech", amount: 400.0),
            TileItem(id: 2, category: "Health", amount: 200.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.category,
            y: \.amount
        )

        let treeMapView = SolarTreeMapView(binding: binding)
        XCTAssertNotNil(treeMapView)
    }

    @MainActor
    func testSolarSunburstViewUIRendering() throws {
        struct ArcItem: SolarVizDataPoint {
            let id: Int
            let name: String
            let val: Double
        }

        let items = [
            ArcItem(id: 1, name: "Food", val: 50.0),
            ArcItem(id: 2, name: "Rent", val: 50.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.name,
            y: \.val
        )

        let sunburstView = SolarSunburstView(binding: binding)
        XCTAssertNotNil(sunburstView)
    }
}
