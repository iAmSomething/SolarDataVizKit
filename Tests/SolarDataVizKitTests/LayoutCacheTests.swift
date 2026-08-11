import XCTest
import CoreGraphics
@testable import SolarDataVizKit

final class LayoutCacheTests: XCTestCase {

    func testClusterNodeCaching() async {
        let cache = SolarVizLayoutCache.shared
        await cache.clearAll()

        let nodes = [
            ClusterNode(center: CGPoint(x: 10, y: 10), radius: 15, childIDs: ["1"], count: 1)
        ]

        let key = "test_key_123"
        let initial = await cache.getClusterNodes(forKey: key)
        XCTAssertNil(initial)

        await cache.setClusterNodes(nodes, forKey: key)
        let cached = await cache.getClusterNodes(forKey: key)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }

    func testIntersectionRegionCaching() async {
        let cache = SolarVizLayoutCache.shared
        await cache.clearAll()

        let regions = [
            IntersectionRegion(pointsA: [CGPoint(x: 0, y: 0)], pointsB: [CGPoint(x: 0, y: 0)], isASuperior: true)
        ]

        let key = "intersection_key_456"
        await cache.setIntersectionRegions(regions, forKey: key)
        let cached = await cache.getIntersectionRegions(forKey: key)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }
}
