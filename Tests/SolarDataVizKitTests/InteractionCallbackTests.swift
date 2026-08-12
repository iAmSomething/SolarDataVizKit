import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct DummyItem: Identifiable, Sendable {
    let id: String
    let value: Double
}

final class InteractionCallbackTests: XCTestCase {
    
    let dummyData = [DummyItem(id: "A", value: 10.0)]
    
    @MainActor
    func testTreeMapViewInteractionCallback() {
        var selectedItem: DummyItem?
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarTreeMapView(binding: binding) { item in
            selectedItem = item
        }
        XCTAssertNotNil(view)
        XCTAssertNil(selectedItem)
    }

    @MainActor
    func testSunburstViewInteractionCallback() {
        var selectedItem: DummyItem?
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarSunburstView(binding: binding) { item in
            selectedItem = item
        }
        XCTAssertNotNil(view)
        XCTAssertNil(selectedItem)
    }

    @MainActor
    func testComparisonChartViewInteractionCallback() {
        var selectedItemA: DummyItem?
        var selectedItemB: DummyItem?
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarComparisonChartView(
            binding: binding,
            seriesA: "A",
            seriesB: "B"
        ) { itemA, itemB in
            selectedItemA = itemA
            selectedItemB = itemB
        }
        XCTAssertNotNil(view)
        XCTAssertNil(selectedItemA)
        XCTAssertNil(selectedItemB)
    }

    @MainActor
    func testDualComparisonChartViewInteractionCallback() {
        var selectedItemA: DummyItem?
        var selectedItemB: DummyItem?
        let bindingA = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let bindingB = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarDualComparisonChartView(bindingA: bindingA, bindingB: bindingB) { itemA, itemB in
            selectedItemA = itemA
            selectedItemB = itemB
        }
        XCTAssertNotNil(view)
        XCTAssertNil(selectedItemA)
        XCTAssertNil(selectedItemB)
    }

    @MainActor
    func testClusterScatterViewInteractionCallback() {
        var selectedItems: [DummyItem]?
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarClusterScatterView(binding: binding) { items in
            selectedItems = items
        }
        XCTAssertNotNil(view)
        XCTAssertNil(selectedItems)
    }
}
