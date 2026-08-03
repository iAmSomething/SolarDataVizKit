import XCTest
import CoreGraphics
@testable import SolarDataVizKit

final class IntersectionCalculatorTests: XCTestCase {

    func testLineSegmentIntersection() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 10)

        let p3 = CGPoint(x: 0, y: 10)
        let p4 = CGPoint(x: 10, y: 0)

        let cross = IntersectionPathCalculator.lineSegmentIntersection(p1: p1, p2: p2, p3: p3, p4: p4)
        XCTAssertNotNil(cross)
        if let cross {
            XCTAssertLessThan(abs(cross.x - 5.0), 0.001)
            XCTAssertLessThan(abs(cross.y - 5.0), 0.001)
        }
    }

    func testParallelLineSegments() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 0)

        let p3 = CGPoint(x: 0, y: 5)
        let p4 = CGPoint(x: 10, y: 5)

        let cross = IntersectionPathCalculator.lineSegmentIntersection(p1: p1, p2: p2, p3: p3, p4: p4)
        XCTAssertNil(cross)
    }

    func testFindIntersections() {
        let seriesA = [
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 20, y: 10)
        ]

        let seriesB = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 20, y: 0)
        ]

        let crosses = IntersectionPathCalculator.findIntersections(seriesA: seriesA, seriesB: seriesB)
        XCTAssertEqual(crosses.count, 2)
    }

    func testComputeRegions() {
        let seriesA = [
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 0)
        ]

        let seriesB = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10)
        ]

        let regions = IntersectionPathCalculator.computeRegions(seriesA: seriesA, seriesB: seriesB)
        XCTAssertFalse(regions.isEmpty)
    }
}
