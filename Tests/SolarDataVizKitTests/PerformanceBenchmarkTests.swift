import XCTest
import CoreGraphics
@testable import SolarDataVizKit

struct BenchmarkItem: SolarVizDataPoint {
    let id: String
    let xValue: Double
    let yValue: Double
    let category: String
}

final class PerformanceBenchmarkTests: XCTestCase {

    private func generateRandomItems(count: Int, categoriesCount: Int = 2) -> [BenchmarkItem] {
        var items: [BenchmarkItem] = []
        items.reserveCapacity(count)

        for i in 0..<count {
            let catIndex = i % categoriesCount
            items.append(BenchmarkItem(
                id: "item_\(i)",
                xValue: Double(i),
                yValue: Double.random(in: -1000.0...10000.0),
                category: "Series_\(catIndex)"
            ))
        }
        return items
    }

    private func generateRandom2DPoints(count: Int) -> [(id: String, point: CGPoint, weight: Double)] {
        var points: [(id: String, point: CGPoint, weight: Double)] = []
        points.reserveCapacity(count)

        for i in 0..<count {
            points.append((
                id: "pt_\(i)",
                point: CGPoint(x: CGFloat.random(in: 0...1000), y: CGFloat.random(in: 0...1000)),
                weight: Double.random(in: 1.0...5.0)
            ))
        }
        return points
    }

    // MARK: - 1. VizDataBinding Ultra Large-Scale (100,000 Points)

    func testVizDataBindingPerformance100K() {
        let items = generateRandomItems(count: 100_000, categoriesCount: 5)
        let binding = VizDataBinding(
            data: items,
            x: \.xValue,
            y: \.yValue,
            group: \.category
        )

        let start = CFAbsoluteTimeGetCurrent()
        let bounds = binding.yBounds()
        let grouped = binding.groupedData()
        let elapsedMS = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        print("⚡ [Benchmark 100K VizDataBinding] bounds=\(bounds.min)...\(bounds.max), groups=\(grouped.count), Time: \(String(format: "%.2f", elapsedMS)) ms")
        XCTAssertLessThan(elapsedMS, 500.0, "100K item binding calculation must complete under 500ms in debug test mode")
    }

    // MARK: - 2. Intersection Engine Benchmark (5,000 Points)

    func testIntersectionPathCalculatorPerformance5K() {
        let count = 5_000
        var seriesA: [CGPoint] = []
        var seriesB: [CGPoint] = []
        seriesA.reserveCapacity(count)
        seriesB.reserveCapacity(count)

        for i in 0..<count {
            let x = CGFloat(i)
            seriesA.append(CGPoint(x: x, y: sin(CGFloat(i) * 0.1) * 100))
            seriesB.append(CGPoint(x: x, y: cos(CGFloat(i) * 0.1) * 100))
        }

        let start = CFAbsoluteTimeGetCurrent()
        let crosses = IntersectionPathCalculator.findIntersections(seriesA: seriesA, seriesB: seriesB)
        let elapsedMS = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        print("⚡ [Benchmark 5K Line Intersections] Found \(crosses.count) cross points in \(String(format: "%.2f", elapsedMS)) ms")
        XCTAssertLessThan(elapsedMS, 50.0, "5K line intersections must complete under 50ms for real-time 60fps rendering")
    }

    // MARK: - 3. Clustering Engine Benchmark (1,000 Points)

    func testClusterNodeCalculatorPerformance1K() {
        let points = generateRandom2DPoints(count: 1_000)

        let start = CFAbsoluteTimeGetCurrent()
        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 30.0)
        let elapsedMS = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        print("⚡ [Benchmark 1K Scatter Clustering] Merged into \(clusters.count) nodes in \(String(format: "%.2f", elapsedMS)) ms")
        XCTAssertLessThan(elapsedMS, 20.0, "1K scatter clustering must complete under 20ms for smooth 60fps interaction")
    }

    // MARK: - 4. Layout Cache Hit Benchmark (10,000 Queries)

    func testLayoutCacheHitPerformance() async {
        let cache = SolarVizLayoutCache.shared
        await cache.clearAll()

        let nodes = (0..<1000).map { i in
            ClusterNode(center: CGPoint(x: i, y: i), radius: 20, childIDs: ["\(i)"], count: 1)
        }
        let key = "benchmark_key_1000"
        await cache.setClusterNodes(nodes, forKey: key)

        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10_000 {
            let _ = await cache.getClusterNodes(forKey: key)
        }
        let elapsedMS = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        print("⚡ [Benchmark 10,000 Cache Hits] 10,000 lookups completed in \(String(format: "%.2f", elapsedMS)) ms")
        XCTAssertLessThan(elapsedMS, 50.0, "10,000 layout cache lookups must take less than 50.0ms total")
    }
}
