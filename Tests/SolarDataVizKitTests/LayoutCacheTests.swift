import Testing
@testable import SolarDataVizKit
import CoreGraphics

@Suite("SolarVizLayoutCache Core Tests")
struct LayoutCacheTests {

    @Test("ClusterNode caching and retrieval test")
    @MainActor
    func testClusterNodeCaching() {
        let cache = SolarVizLayoutCache.shared
        cache.clearAll()

        let nodes = [
            ClusterNode(center: CGPoint(x: 10, y: 10), radius: 15, childIDs: ["1"], count: 1)
        ]

        let key = "test_key_123"
        #expect(cache.getClusterNodes(forKey: key) == nil)

        cache.setClusterNodes(nodes, forKey: key)
        let cached = cache.getClusterNodes(forKey: key)
        #expect(cached != nil)
        #expect(cached?.count == 1)
    }

    @Test("IntersectionRegion caching and retrieval test")
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
        #expect(cached != nil)
        #expect(cached?.count == 1)
    }
}
