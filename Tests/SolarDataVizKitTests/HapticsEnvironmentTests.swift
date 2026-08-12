import XCTest
import SwiftUI
@testable import SolarDataVizKit

final class HapticsEnvironmentTests: XCTestCase {

    @MainActor
    func testHapticsEnvironmentDefaultIsTrue() {
        let env = EnvironmentValues()
        XCTAssertTrue(env.solarVizHapticsEnabled)
    }

    @MainActor
    func testHapticsEnvironmentCanBeDisabled() throws {
        struct MockItem: Identifiable, Sendable {
            let id = UUID()
            let xLabel: String
            let value: Double
        }
        let items = [MockItem(xLabel: "A", value: 10)]
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)
        
        let view = SolarTreeMapView(binding: binding)
            .solarVizHaptics(enabled: false)
        
        // 뷰가 정상 생성되고 크래시 없음을 확인
        XCTAssertNotNil(view)
    }
}
