import Testing
@testable import SolarDataVizKit
import CoreGraphics

@Suite("IntersectionPathCalculator Math Tests")
struct IntersectionCalculatorTests {

    @Test("Direct 2D line segment intersection point calculation")
    func testLineSegmentIntersection() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 10)

        let p3 = CGPoint(x: 0, y: 10)
        let p4 = CGPoint(x: 10, y: 0)

        let cross = IntersectionPathCalculator.lineSegmentIntersection(p1: p1, p2: p2, p3: p3, p4: p4)
        #expect(cross != nil)
        if let cross {
            #expect(abs(cross.x - 5.0) < 0.001)
            #expect(abs(cross.y - 5.0) < 0.001)
        }
    }

    @Test("Parallel line segments should return nil")
    func testParallelLineSegments() {
        let p1 = CGPoint(x: 0, y: 0)
        let p2 = CGPoint(x: 10, y: 0)

        let p3 = CGPoint(x: 0, y: 5)
        let p4 = CGPoint(x: 10, y: 5)

        let cross = IntersectionPathCalculator.lineSegmentIntersection(p1: p1, p2: p2, p3: p3, p4: p4)
        #expect(cross == nil)
    }

    @Test("Finding all intersection points across two series")
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
        #expect(crosses.count == 2)
    }

    @Test("Compute regions between two series")
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
        #expect(!regions.isEmpty)
    }
}
