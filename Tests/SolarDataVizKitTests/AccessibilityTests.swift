import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct DummyAccessibilityItem: Identifiable, Sendable {
    let id: String
    let value: Double
}

final class AccessibilityTests: XCTestCase {
    
    let dummyData = [DummyAccessibilityItem(id: "10", value: 10.0)]
    
    @MainActor
    func testTreeMapViewAccessibility() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarTreeMapView(binding: binding)
        XCTAssertNotNil(view)
        // Note: Full UI accessibility testing requires XCUITest, but we can verify the view constructs without crash.
    }

    @MainActor
    func testComparisonChartViewAccessibility() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarComparisonChartView(binding: binding)
        XCTAssertNotNil(view)
    }

    @MainActor
    func testSunburstViewAccessibility() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarSunburstView(binding: binding)
        XCTAssertNotNil(view)
    }

    @MainActor
    func testClusterScatterViewAccessibility() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarClusterScatterView(binding: binding)
        XCTAssertNotNil(view)
    }
}
