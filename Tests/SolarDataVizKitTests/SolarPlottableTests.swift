import XCTest
import Foundation
import CoreGraphics
@testable import SolarDataVizKit

final class SolarPlottableTests: XCTestCase {
    
    func testIntPlottable() {
        let value: Int = 42
        XCTAssertEqual(value.asPlotValue, 42.0)
    }
    
    func testDoublePlottable() {
        let value: Double = 3.14159
        XCTAssertEqual(value.asPlotValue, 3.14159)
    }
    
    func testCGFloatPlottable() {
        let value: CGFloat = 100.5
        XCTAssertEqual(value.asPlotValue, 100.5)
    }
    
    func testDatePlottable() {
        let referenceDate = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(referenceDate.asPlotValue, 0.0)
        
        let customDate = Date(timeIntervalSince1970: 3600)
        XCTAssertEqual(customDate.asPlotValue, 3600.0)
    }
    
    func testStringCategoricalPlottable() {
        let category: String = "Technology"
        // String uses stable DJB2 hash, producing a predictable Double value.
        let hashedValue = category.asPlotValue
        XCTAssertEqual(hashedValue, "Technology".asPlotValue)
        XCTAssertNotEqual(hashedValue, "Healthcare".asPlotValue)
        XCTAssertTrue(hashedValue > 0 || hashedValue <= 0, "Hash must return a valid Double")
    }
}
