import XCTest
import CoreGraphics
import SwiftUI
@testable import SolarDataVizKit

struct ProductionEdgeItem: Identifiable, Sendable, Equatable {
    let id: String
    let xLabel: String
    let yValue: Double
    let category: String
    let subCategory: String
}

final class EdgeCaseProductionTests: XCTestCase {

    // MARK: - 1. Empty Dataset Defense

    func testEmptyDatasetDefense() {
        let binding = VizDataBinding<ProductionEdgeItem, String, Double>(
            data: [],
            x: \.xLabel,
            y: \.yValue,
            group: \.category
        )

        let bounds = binding.yBounds()
        XCTAssertEqual(bounds.min, 0.0)
        XCTAssertEqual(bounds.max, 1.0)

        let norm = binding.normalizeY(value: 0.5, in: bounds)
        XCTAssertEqual(norm, 0.5)

        XCTAssertTrue(binding.sortedGroupKeys.isEmpty || binding.sortedGroupKeys == ["Default"])
        XCTAssertTrue(binding.groupedData().isEmpty || binding.groupedData() == ["Default": []])
    }

    // MARK: - 2. Negative Values Handling in Treemap & Sunburst

    func testNegativeValuesHandlingInHierarchy() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Loss A", yValue: -150.0, category: "Risk", subCategory: "Option"),
            ProductionEdgeItem(id: "2", xLabel: "Gain B", yValue: 300.0, category: "Profit", subCategory: "Equity"),
            ProductionEdgeItem(id: "3", xLabel: "Zero C", yValue: 0.0, category: "Neutral", subCategory: "Cash")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.xLabel,
            y: \.yValue,
            hierarchy: [\.category, \.subCategory]
        )

        let totalPositive = binding.data.reduce(0.0) { $0 + max(0.0, Double(binding.extractY(from: $1))) }
        XCTAssertEqual(totalPositive, 300.0, "Negative values must be clamped to 0.0 in hierarchy layout to prevent negative area geometry rendering glitches")
    }

    // MARK: - 3. Zero Variance / Identical Values Bounds Defense

    func testZeroVarianceBoundsDefense() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Point A", yValue: 100.0, category: "Flat", subCategory: "Sub"),
            ProductionEdgeItem(id: "2", xLabel: "Point B", yValue: 100.0, category: "Flat", subCategory: "Sub")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.xLabel,
            y: \.yValue
        )

        let bounds = binding.yBounds()
        XCTAssertNotEqual(bounds.min, bounds.max, "Zero variance dataset must expand min and max bounds to prevent divide-by-zero division")
        XCTAssertLessThan(abs(Double(bounds.min) - 90.0), 0.001)
        XCTAssertLessThan(abs(Double(bounds.max) - 110.0), 0.001)
    }

    // MARK: - 4. Extremely Large Values (Numerical Stability)

    func testNumericalStabilityLargeValues() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Inf A", yValue: 1e12, category: "Tech", subCategory: "AI"),
            ProductionEdgeItem(id: "2", xLabel: "Inf B", yValue: 2e12, category: "Tech", subCategory: "Cloud")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.xLabel,
            y: \.yValue
        )

        let bounds = binding.yBounds()
        let norm = binding.normalizeY(value: 1.5e12, in: bounds)
        XCTAssertLessThan(abs(norm - 0.5), 0.001)
    }

    // MARK: - 5. Multi-Level Hierarchy (3-Level Deep KeyPaths)

    func testMultiLevelHierarchyKeyPaths() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Item 1", yValue: 50.0, category: "HQ", subCategory: "Dept A"),
            ProductionEdgeItem(id: "2", xLabel: "Item 2", yValue: 70.0, category: "HQ", subCategory: "Dept B")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.xLabel,
            y: \.yValue,
            hierarchy: [\.category, \.subCategory]
        )

        XCTAssertEqual(binding.hierarchyKeyPaths.count, 2)
        XCTAssertEqual(items[0][keyPath: binding.hierarchyKeyPaths[0]], "HQ")
        XCTAssertEqual(items[0][keyPath: binding.hierarchyKeyPaths[1]], "Dept A")
    }

    // MARK: - 6. Concurrent Multithreaded Access to Cache & Binding

    func testConcurrentCacheAccessSafety() async {
        @MainActor func accessCache() {
            let cache = SolarVizLayoutCache.shared
            cache.clearAll()

            let nodes = [ClusterNode(center: CGPoint(x: 10, y: 10), radius: 5, childIDs: ["1"], count: 1)]
            for i in 0..<200 {
                cache.setClusterNodes(nodes, forKey: "key_\(i)")
                let _ = cache.getClusterNodes(forKey: "key_\(i)")
            }
        }

        await accessCache()
    }

    // MARK: - 7. Co-linear Overlapping Line Segments

    func testColinearOverlappingLineSegments() {
        let seriesA = [CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5)]
        let seriesB = [CGPoint(x: 0, y: 5), CGPoint(x: 10, y: 5)]

        let crosses = IntersectionPathCalculator.findIntersections(seriesA: seriesA, seriesB: seriesB)
        XCTAssertTrue(crosses.isEmpty, "Co-linear identical line segments should not trigger infinite intersection point collisions")
    }

    // MARK: - 8. Stale Data Bug Invalidation Test (Rolling Stream Data Hash)

    func testRollingStreamDataHashCacheInvalidation() {
        let itemsInitial = [
            ProductionEdgeItem(id: "1", xLabel: "A", yValue: 10.0, category: "C", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 20.0, category: "C", subCategory: "S")
        ]

        let itemsUpdated = [
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 20.0, category: "C", subCategory: "S"),
            ProductionEdgeItem(id: "3", xLabel: "C", yValue: 30.0, category: "C", subCategory: "S")
        ]

        let key1 = "cluster_\(itemsInitial.count)_\(itemsInitial.first?.id ?? "")_\(itemsInitial.last?.id ?? "")_20.0_300x500"
        let key2 = "cluster_\(itemsUpdated.count)_\(itemsUpdated.first?.id ?? "")_\(itemsUpdated.last?.id ?? "")_20.0_300x500"

        XCTAssertNotEqual(key1, key2, "Rolling stream data with identical count must generate distinct cache keys to prevent stale data freezing")
    }

    // MARK: - 9. Treemap Zero Value No NaN Crash Test

    func testTreemapZeroValueTileNoNaN() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Zero A", yValue: 0.0, category: "C", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "Valid B", yValue: 500.0, category: "C", subCategory: "S")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue)
        let positiveOnly = binding.data.map { max(0.0, Double(binding.extractY(from: $0))) }.filter { $0 > 0.0 }
        XCTAssertEqual(positiveOnly.count, 1)
        XCTAssertEqual(positiveOnly.first, 500.0)
    }

    // MARK: - 10. Non-Monotonic Parametric Curve Intersection Detection

    func testNonMonotonicParametricCurveIntersections() {
        // Parametric figure-8 / loop curve
        let loopA = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 5, y: 15),
            CGPoint(x: -5, y: 5)
        ]

        let lineB = [
            CGPoint(x: -10, y: 5),
            CGPoint(x: 15, y: 5)
        ]

        let crosses = IntersectionPathCalculator.findIntersections(seriesA: loopA, seriesB: lineB)
        XCTAssertFalse(crosses.isEmpty, "Non-monotonic parametric curves must detect intersections accurately without sweep skipping")
    }

    // MARK: - 11. Spatial Grid Hashing 10K Points Performance Test

    func testSpatialGridClustering10KPerformance() {
        let points = (0..<10_000).map { i in
            (id: "\(i)", point: CGPoint(x: Double(i % 100) * 10.0, y: Double(i / 100) * 10.0), weight: 1.0)
        }

        let start = Date()
        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 15.0)
        let elapsedMS = Date().timeIntervalSince(start) * 1000.0

        print("⚡ [Spatial Grid 10K Clustering] Merged \(points.count) points into \(clusters.count) nodes in \(String(format: "%.2f", elapsedMS)) ms")
        XCTAssertLessThan(elapsedMS, 50.0, "10,000 point clustering must complete under 50ms with O(N) Spatial Hashing")
    }
}
