import XCTest
import CoreGraphics
@testable import SolarDataVizKit

final class LayoutCacheTests: XCTestCase {

    @MainActor
    func testClusterNodeCaching() {
        let cache = SolarVizLayoutCache.shared
        cache.clearAll()

        let nodes = [
            ClusterNode(center: CGPoint(x: 10, y: 10), radius: 15, childIDs: ["1"], count: 1)
        ]

        let key = "test_key_123"
        XCTAssertNil(cache.getClusterNodes(forKey: key))

        cache.setClusterNodes(nodes, forKey: key)
        let cached = cache.getClusterNodes(forKey: key)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }

    @MainActor
    func testIntersectionRegionCaching() {
        let cache = SolarVizLayoutCache.shared
        cache.clearAll()

        let regions = [
            IntersectionRegion(pointsA: [CGPoint(x: 0, y: 0)], pointsB: [CGPoint(x: 0, y: 0)], isASuperior: true)
        ]

        let key = "intersection_key_456"
        cache.setIntersectionRegions(regions, forKey: key)
        let cached = cache.getIntersectionRegions(forKey: key)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }
}
