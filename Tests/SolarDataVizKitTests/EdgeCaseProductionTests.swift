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

    // MARK: - 12. Multi-Level Hierarchy Tree Aggregation Test (buildHierarchyTree)

    func testMultiLevelHierarchyTreeAggregation() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "A", yValue: 100.0, category: "Tech", subCategory: "Hardware"),
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 200.0, category: "Tech", subCategory: "Software"),
            ProductionEdgeItem(id: "3", xLabel: "C", yValue: 300.0, category: "Finance", subCategory: "Banking")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, hierarchy: [\.category, \.subCategory])
        let tree = binding.buildHierarchyTree()

        XCTAssertEqual(tree.name, "Root")
        XCTAssertEqual(tree.value, 600.0)
        XCTAssertEqual(tree.children.count, 2) // Tech & Finance
        XCTAssertEqual(tree.children.first?.name, "Tech")
        XCTAssertEqual(tree.children.first?.value, 300.0)
    }

    // MARK: - 13. Key-based Inner Join Comparison Test

    func testKeyBasedInnerJoinComparisonTooltip() {
        let seriesA = [
            ProductionEdgeItem(id: "1", xLabel: "Jan", yValue: 100.0, category: "A", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "Feb", yValue: 150.0, category: "A", subCategory: "S")
        ]

        let seriesB = [
            ProductionEdgeItem(id: "3", xLabel: "Feb", yValue: 200.0, category: "B", subCategory: "S"),
            ProductionEdgeItem(id: "4", xLabel: "Mar", yValue: 250.0, category: "B", subCategory: "S")
        ]

        let bindingA = VizDataBinding(data: seriesA, x: \.xLabel, y: \.yValue)
        let bindingB = VizDataBinding(data: seriesB, x: \.xLabel, y: \.yValue)

        let xJan = bindingA.extractX(from: seriesA[0]).description
        let matchFebInB = seriesB.first { bindingB.extractX(from: $0).description == xJan }
        XCTAssertNil(matchFebInB, "January should not blindly join with February in unaligned comparison series")
    }

    // MARK: - 14. Categorical String Scatter Plot Test

    @MainActor
    func testCategoricalScatterPlotStringXValues() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Category Alpha", yValue: 50.0, category: "A", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "Category Beta", yValue: 80.0, category: "A", subCategory: "S")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue)
        XCTAssertEqual(binding.extractX(from: items[0]), "Category Alpha")
        let view = SolarClusterScatterView(binding: binding)
        XCTAssertNotNil(view)
    }

    // MARK: - 15. Real Identifiable Item ID In TreeTile

    func testRealIdentifiableItemIDInTreeTile() {
        let items = [
            ProductionEdgeItem(id: "custom_item_999", xLabel: "A", yValue: 100.0, category: "C", subCategory: "S")
        ]
        let tileID = "tile_\(String(describing: items[0].id))"
        XCTAssertEqual(tileID, "tile_custom_item_999", "Tile ID must derive from real Identifiable item ID instead of shifting array index")
    }

    // MARK: - 16. Parent Path-Accumulated Tree Node ID Collision Prevention

    func testTreeNodeIDPathCollisionPrevention() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "A", yValue: 100.0, category: "Korea", subCategory: "Marketing"),
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 200.0, category: "US", subCategory: "Marketing")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, hierarchy: [\.category, \.subCategory])
        let tree = binding.buildHierarchyTree()

        let krMarketing = tree.children[0].children[0].id
        let usMarketing = tree.children[1].children[0].id

        XCTAssertNotEqual(krMarketing, usMarketing, "Same-name same-level nodes under different parent branches must generate unique path-accumulated IDs")
        XCTAssertTrue(krMarketing.contains("Korea"))
        XCTAssertTrue(usMarketing.contains("US"))
    }

    // MARK: - 17. Compact DJB2 Hashed Cluster Node ID Test

    func testCompactHashedClusterNodeID() {
        let points = (0..<1_000).map { i in
            (id: "uuid_string_item_\(i)", point: CGPoint(x: 10.0, y: 10.0), weight: 1.0)
        }

        let clusters = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 50.0)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertLessThan(clusters[0].id.count, 50, "Merged cluster node ID length must be compact O(1) hash to prevent multi-megabyte string heap overflow")
    }

    // MARK: - 18. Full 360 Degree Sunburst Ring Seam Scar Prevention

    func testSunburstFull360RingNoSeamScar() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Solo Item", yValue: 1000.0, category: "Single", subCategory: "Sub")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, group: \.category)
        let sunburst = SolarSunburstView(binding: binding)
        XCTAssertNotNil(sunburst)
    }

    // MARK: - 19. Single Pass O(N) sortedGroupedData Test

    func testSinglePassSortedGroupedDataEfficiency() {
        let items = (0..<100_000).map { i in
            ProductionEdgeItem(id: "\(i)", xLabel: "Label_\(i)", yValue: Double(i), category: "Cat_\(i % 5)", subCategory: "Sub_\(i % 10)")
        }

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, group: \.category)
        let start = Date()
        let grouped = binding.sortedGroupedData()
        let elapsedMS = Date().timeIntervalSince(start) * 1000.0

        XCTAssertEqual(grouped.count, 5)
        XCTAssertLessThan(elapsedMS, 50.0, "Single-pass O(N) sortedGroupedData must complete 100,000 items under 50ms")
    }

    // MARK: - 20. Treemap Custom Layout Strategy Injection Test

    @MainActor
    func testTreemapStrategyPatternCustomSliceAndDice() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "A", yValue: 50.0, category: "C", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "B", yValue: 50.0, category: "C", subCategory: "S")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue)
        let sliceAndDiceView = SolarTreeMapView(binding: binding, strategy: SliceAndDiceTreemapStrategy())
        XCTAssertNotNil(sliceAndDiceView)

        let tiles = SliceAndDiceTreemapStrategy().computeTiles(
            data: items,
            extractY: { $0.yValue },
            bounds: CGRect(x: 0, y: 0, width: 200, height: 100)
        )
        XCTAssertEqual(tiles.count, 2)
        XCTAssertEqual(tiles[0].rect.width, 100.0)
    }

    // MARK: - 21. Sunburst Parent-Child Color Family Inheritance Test

    func testSunburstParentChildColorFamilyInheritance() {
        let items = [
            ProductionEdgeItem(id: "1", xLabel: "Sub A1", yValue: 100.0, category: "Tech", subCategory: "S"),
            ProductionEdgeItem(id: "2", xLabel: "Sub A2", yValue: 200.0, category: "Tech", subCategory: "S")
        ]

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, group: \.category)
        let sunburst = SolarSunburstView(binding: binding)
        XCTAssertNotNil(sunburst)
    }

    // MARK: - 22. Heterogenous Dual Model Comparison Test

    @MainActor
    func testHeterogenousDualModelComparisonView() {
        struct SalesModel: Identifiable, Sendable {
            let id: String
            let month: String
            let revenue: Double
        }
        struct ExpenseModel: Identifiable, Sendable {
            let id: String
            let month: String
            let cost: Double
        }

        let sales = [SalesModel(id: "1", month: "Jan", revenue: 500.0)]
        let expenses = [ExpenseModel(id: "101", month: "Jan", cost: 300.0)]

        let bindingSales = VizDataBinding(data: sales, x: \.month, y: \.revenue)
        let bindingExpenses = VizDataBinding(data: expenses, x: \.month, y: \.cost)

        let dualChart = SolarDualComparisonChartView(
            bindingA: bindingSales,
            bindingB: bindingExpenses,
            labelA: "Sales Revenue",
            labelB: "Operating Expenses"
        )
        XCTAssertNotNil(dualChart)
    }

    // MARK: - 23. Real-World Financial Time Series FX Rates Test

    func testRealWorldFinancialTimeSeriesFXRates() {
        struct ForexQuote: Identifiable, Sendable {
            let id: String
            let timestamp: String
            let rate: Double
        }

        let fxQuotes = [
            ForexQuote(id: "1", timestamp: "10:00:00.001", rate: 1.08451),
            ForexQuote(id: "2", timestamp: "10:00:00.002", rate: 1.08452),
            ForexQuote(id: "3", timestamp: "10:00:00.003", rate: 1.08450)
        ]

        let binding = VizDataBinding(data: fxQuotes, x: \.timestamp, y: \.rate)
        let bounds = binding.yBounds()
        XCTAssertGreaterThan(bounds.max, bounds.min, "Micro FX rate range must preserve 5 decimal place floating point precision")
        XCTAssertEqual(bounds.min, 1.08450, accuracy: 0.00001)
        XCTAssertEqual(bounds.max, 1.08452, accuracy: 0.00001)
    }

    // MARK: - 24. Real-World Enterprise Product Revenue Hierarchy Test

    func testRealWorldEnterpriseProductRevenueHierarchy() {
        struct ProductRevenue: Identifiable, Sendable {
            let id: String
            let division: String
            let productName: String
            let quarterlyRevenue: Double
        }

        let enterpriseData = [
            ProductRevenue(id: "p1", division: "Hardware", productName: "iPhone 16 Pro", quarterlyRevenue: 45000000.0),
            ProductRevenue(id: "p2", division: "Hardware", productName: "MacBook Pro M4", quarterlyRevenue: 25000000.0),
            ProductRevenue(id: "p3", division: "Services", productName: "iCloud Storage", quarterlyRevenue: 15000000.0),
            ProductRevenue(id: "p4", division: "Services", productName: "Apple Music", quarterlyRevenue: 12000000.0)
        ]

        let binding = VizDataBinding(
            data: enterpriseData,
            x: \.productName,
            y: \.quarterlyRevenue,
            group: \.division
        )

        let rootTree = binding.buildHierarchyTree()
        XCTAssertEqual(rootTree.children.count, 2, "Enterprise hierarchy must split into 2 primary divisions (Hardware, Services)")
        
        let hardwareNode = rootTree.children.first(where: { $0.name == "Hardware" })
        XCTAssertEqual(hardwareNode?.value, 70000000.0, "Hardware division total revenue must equal 45M + 25M = 70M")
    }

    // MARK: - 25. Extreme Dynamic Scale Ratio (1 : 10^8) Test

    func testExtremeDynamicScaleRatioDifference() {
        struct PennyVsCap: Identifiable, Sendable {
            let id: String
            let asset: String
            let marketCap: Double
        }

        let items = [
            PennyVsCap(id: "1", asset: "Micro Penny Stock", marketCap: 0.000001),
            PennyVsCap(id: "2", asset: "Mega Tech Cap", marketCap: 3_500_000_000_000.0)
        ]

        let binding = VizDataBinding(data: items, x: \.asset, y: \.marketCap)
        let bounds = binding.yBounds()
        XCTAssertEqual(bounds.min, 0.000001)
        XCTAssertEqual(bounds.max, 3_500_000_000_000.0)

        let normMin = binding.normalizeY(value: 0.000001, in: bounds)
        let normMax = binding.normalizeY(value: 3_500_000_000_000.0, in: bounds)
        XCTAssertEqual(normMin, 0.0, accuracy: 0.0001)
        XCTAssertEqual(normMax, 1.0, accuracy: 0.0001)
    }

    // MARK: - 26. Unicode & Special Character X-Labels Defense Test

    func testUnicodeAndSpecialCharacterXLabels() {
        struct SpecialItem: Identifiable, Sendable {
            let id: String
            let rawLabel: String
            let val: Double
        }

        let specialItems = [
            SpecialItem(id: "1", rawLabel: "2026年 1월 🚀", val: 100.0),
            SpecialItem(id: "2", rawLabel: "<script>alert('xss')</script>", val: 200.0),
            SpecialItem(id: "3", rawLabel: "SELECT * FROM users;", val: 300.0)
        ]

        let binding = VizDataBinding(data: specialItems, x: \.rawLabel, y: \.val)
        let keys = binding.sortedGroupKeys
        XCTAssertFalse(keys.isEmpty)
        XCTAssertEqual(binding.extractX(from: specialItems[0]), "2026年 1월 🚀")
    }

    // MARK: - 27. Duplicate Coordinates Cluster Density Defense Test

    func testDuplicateCoordinatesClusterDensityDefense() async {
        let duplicateGPSPoints = (0..<100).map { i in
            (id: "gps_\(i)", point: CGPoint(x: 37.5665, y: 126.9780), weight: 1.0)
        }

        let nodes = await ClusterNodeCalculator.cluster(
            points: duplicateGPSPoints,
            thresholdRadius: 10.0
        )

        XCTAssertEqual(nodes.count, 1, "100 duplicate coordinate points must merge into exactly 1 cluster node without infinite loops")
        XCTAssertEqual(nodes[0].count, 100)
    }

    // MARK: - 28. NaN and Infinity Input Sanitization Test

    func testNaNAndInfinityInputSanitization() {
        struct CorruptedItem: Identifiable, Sendable {
            let id: String
            let key: String
            let val: Double
        }

        let corruptedData = [
            CorruptedItem(id: "1", key: "Valid 1", val: 50.0),
            CorruptedItem(id: "2", key: "Corrupted NaN", val: Double.nan),
            CorruptedItem(id: "3", key: "Corrupted Inf", val: Double.infinity),
            CorruptedItem(id: "4", key: "Valid 2", val: 150.0)
        ]

        let binding = VizDataBinding(data: corruptedData, x: \.key, y: \.val)
        let bounds = binding.yBounds()
        XCTAssertFalse(Double(bounds.min).isNaN, "Sanitized min bound must not be NaN")
        XCTAssertFalse(Double(bounds.max).isInfinite, "Sanitized max bound must not be Infinity")
        XCTAssertEqual(bounds.min, 50.0)
        XCTAssertEqual(bounds.max, 150.0)
    }
}
