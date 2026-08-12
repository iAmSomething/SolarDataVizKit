import XCTest
import CoreGraphics
#if os(iOS) || os(tvOS)
import UIKit
#endif
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

#if os(iOS) || os(tvOS)
    func testMemoryWarningPurgesCache() async throws {
        let cache = SolarVizLayoutCache.shared
        await cache.clearAll()
        
        let nodes = [
            ClusterNode(center: CGPoint(x: 10, y: 10), radius: 15, childIDs: ["1"], count: 1)
        ]
        let key = "memory_warning_key"
        await cache.setClusterNodes(nodes, forKey: key)
        
        let cachedBefore = await cache.getClusterNodes(forKey: key)
        XCTAssertNotNil(cachedBefore, "Cache should store data successfully")
        
        // Post the memory warning notification
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Give the async stream time to process the notification
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let cachedAfter = await cache.getClusterNodes(forKey: key)
        XCTAssertNil(cachedAfter, "Cache must be cleared after receiving a memory warning")
    }
#endif
}
