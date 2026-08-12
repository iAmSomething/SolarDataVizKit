import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit

final class ScratchTests: XCTestCase {
    @MainActor
    func testTree() throws {
        struct TileItem: SolarVizDataPoint {
            let id: Int
            let category: String
            let amount: Double
        }
        let items = [
            TileItem(id: 1, category: "Tech", amount: 400.0),
            TileItem(id: 2, category: "Health", amount: 200.0)
        ]
        let binding = VizDataBinding(data: items, x: \.category, y: \.amount)
        let treeMapView = SolarTreeMapView(binding: binding).frame(width: 500, height: 500)
        
        let geo = try treeMapView.inspect().find(ViewType.GeometryReader.self)
        print("Geo found")
    }
}
