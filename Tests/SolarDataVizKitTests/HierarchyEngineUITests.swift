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
        let geometry = try treeMapView.inspect().geometryReader()
        XCTAssertNotNil(geometry, "SolarTreeMapView must render inside a dynamic GeometryReader for responsive tile tiling")
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
        let geometry = try sunburstView.inspect().geometryReader()
        XCTAssertNotNil(geometry, "SolarSunburstView must render inside a dynamic GeometryReader for radial arc calculations")
    }

    func testSunburstStatefulArcSweepCalculations() throws {
        struct TestCategoryItem: SolarVizDataPoint {
            let id: Int
            let categoryName: String
            let subItemName: String
            let amount: Double
        }

        let items = [
            TestCategoryItem(id: 1, categoryName: "Engineering", subItemName: "iOS", amount: 300.0),
            TestCategoryItem(id: 2, categoryName: "Engineering", subItemName: "macOS", amount: 100.0),
            TestCategoryItem(id: 3, categoryName: "Marketing", subItemName: "Ads", amount: 400.0)
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.subItemName,
            y: \.amount,
            group: \.categoryName
        )

        let rootNode = binding.buildHierarchyTree()
        XCTAssertEqual(rootNode.children.count, 2, "Hierarchy root node must contain exactly 2 top-level group categories (Engineering, Marketing)")
        
        let engineeringNode = rootNode.children.first(where: { $0.name == "Engineering" })
        XCTAssertNotNil(engineeringNode, "Engineering parent category node must exist")
        XCTAssertEqual(engineeringNode?.value, 400.0, "Engineering category total aggregated value must equal 300 + 100 = 400.0")
        XCTAssertEqual(engineeringNode?.children.count, 2, "Engineering category must contain 2 child items (iOS, macOS)")
    }
}
