import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct DummyLoadingItem: Identifiable, Sendable {
    let id: String
    let value: Double
}

final class LoadingStatePlaceholderTests: XCTestCase {
    
    @MainActor
    func testTreeMapPlaceholder() {
        let binding = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let view = SolarTreeMapView(binding: binding) {
            Text("Loading...")
        }
        XCTAssertNotNil(view)
    }

    @MainActor
    func testSunburstPlaceholder() {
        let binding = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let view = SolarSunburstView(binding: binding) {
            Text("Loading...")
        }
        XCTAssertNotNil(view)
    }

    @MainActor
    func testComparisonChartPlaceholder() {
        let binding = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let view = SolarComparisonChartView(
            binding: binding,
            seriesA: "A",
            seriesB: "B"
        ) {
            Text("Loading...")
        }
        XCTAssertNotNil(view)
    }

    @MainActor
    func testDualComparisonChartPlaceholder() {
        let bindingA = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let bindingB = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let view = SolarDualComparisonChartView(bindingA: bindingA, bindingB: bindingB) {
            Text("Loading...")
        }
        XCTAssertNotNil(view)
    }

    @MainActor
    func testClusterScatterPlaceholder() {
        let binding = VizDataBinding<DummyLoadingItem, String, Double>(data: [], x: \.id, y: \.value)
        let view = SolarClusterScatterView(binding: binding) {
            Text("Loading...")
        }
        XCTAssertNotNil(view)
    }
}
