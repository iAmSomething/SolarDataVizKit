import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct DummySizeGuardItem: Identifiable, Sendable {
    let id: String
    let value: Double
}

final class MinimumSizeGuardTests: XCTestCase {
    
    let dummyData = [DummySizeGuardItem(id: "10", value: 10.0)]
    
    @MainActor
    func testTreeMapViewHandlesZeroSizeWithoutCrash() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarTreeMapView(binding: binding)
            .frame(width: 0, height: 0)
        
        XCTAssertNotNil(view)
    }

    @MainActor
    func testComparisonChartViewHandlesZeroSizeWithoutCrash() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarComparisonChartView(
            binding: binding,
            seriesA: "A", 
            seriesB: "B"
        ).frame(width: 0, height: 0)
        
        XCTAssertNotNil(view)
    }

    @MainActor
    func testSunburstViewHandlesZeroSizeWithoutCrash() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarSunburstView(binding: binding)
            .frame(width: 0, height: 0)
        
        XCTAssertNotNil(view)
    }

    @MainActor
    func testClusterScatterViewHandlesZeroSizeWithoutCrash() {
        let binding = VizDataBinding(data: dummyData, x: \.id, y: \.value)
        let view = SolarClusterScatterView(binding: binding)
            .frame(width: 0, height: 0)
        
        XCTAssertNotNil(view)
    }
}
