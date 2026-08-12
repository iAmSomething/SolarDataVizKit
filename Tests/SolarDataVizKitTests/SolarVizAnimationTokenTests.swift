import XCTest
import SwiftUI
@testable import SolarDataVizKit

final class SolarVizAnimationTokenTests: XCTestCase {
    
    func testAnimationTokensAreDistinct() {
        // Each token should be distinctly defined. We can compare descriptions to ensure they are at least not accidentally aliased to the exact same value/reference.
        let dataLoad = String(describing: SolarVizAnimation.dataLoad)
        let layoutReflow = String(describing: SolarVizAnimation.layoutReflow)
        let tooltip = String(describing: SolarVizAnimation.tooltip)
        
        XCTAssertNotEqual(dataLoad, layoutReflow)
        XCTAssertNotEqual(dataLoad, tooltip)
        XCTAssertNotEqual(layoutReflow, tooltip)
    }
}
