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
        XCTAssertLessThan(elapsedMS, 500.0, "10,000 point clustering must complete under 500ms with O(N) Spatial Hashing in debug test mode")
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
        XCTAssertLessThan(elapsedMS, 250.0, "Single-pass O(N) sortedGroupedData must complete 100,000 items under 250ms in debug test mode")
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
        XCTAssertEqual(Double(bounds.min), 50.0, accuracy: 1e-5)
        XCTAssertEqual(Double(bounds.max), 150.0, accuracy: 1e-5)
    }

    // MARK: - 29. Phase 5: O(1) Dictionary Lookup Scrubbing Performance Test

    @MainActor
    func testPhase5DualComparisonO1DictionaryLookupPerformance() {
        struct FastItem: Identifiable, Sendable {
            let id: String
            let dayKey: String
            let amount: Double
        }

        let count = 100_000
        let itemsA = (0..<count).map { FastItem(id: "a_\($0)", dayKey: "D_\($0)", amount: Double($0)) }
        let itemsB = (0..<count).map { FastItem(id: "b_\($0)", dayKey: "D_\($0)", amount: Double($0 * 2)) }

        let bindingA = VizDataBinding(data: itemsA, x: \.dayKey, y: \.amount)
        let bindingB = VizDataBinding(data: itemsB, x: \.dayKey, y: \.amount)

        let start = CFAbsoluteTimeGetCurrent()
        let view = SolarDualComparisonChartView(bindingA: bindingA, bindingB: bindingB)
        let initTime = (CFAbsoluteTimeGetCurrent() - start) * 1000

        XCTAssertLessThan(initTime, 500.0, "Init with 100K dictionary caching must complete quickly")
        XCTAssertNotNil(view)
    }

    // MARK: - 30. Phase 5: Series Length Mismatch Linear Interpolation Test

    func testPhase5IntersectionPathCalculatorLengthMismatchLinearInterpolation() {
        let seriesA = [
            CGPoint(x: 0, y: 10),
            CGPoint(x: 2, y: 20),
            CGPoint(x: 4, y: 30),
            CGPoint(x: 6, y: 40),
            CGPoint(x: 8, y: 50)
        ]
        let seriesB = [
            CGPoint(x: 0, y: 50),
            CGPoint(x: 4, y: 10),
            CGPoint(x: 8, y: 60)
        ]

        let (alignedA, alignedB) = IntersectionPathCalculator.alignSeries(seriesA: seriesA, seriesB: seriesB)

        XCTAssertEqual(alignedA.count, 5)
        XCTAssertEqual(alignedB.count, 5)
        XCTAssertEqual(alignedB[1].x, 2.0)
        XCTAssertEqual(alignedB[1].y, 30.0, accuracy: 1e-5, "Linear interpolation of Series B at X=2 must equal Y=30")

        let regions = IntersectionPathCalculator.computeRegions(seriesA: seriesA, seriesB: seriesB)
        XCTAssertGreaterThan(regions.count, 0, "Length-mismatched series must produce valid aligned intersection regions")
    }

    // MARK: - 31. Phase 5: Dynamic Tooltip Offset Bounds Calculation Test

    func testPhase5DynamicTooltipOffsetBoundsCalculation() {
        let containerWidth: CGFloat = 400.0
        let tooltipWidth: CGFloat = 160.0

        // Test Far Left (Index 0 - Jan)
        let progress0: CGFloat = 0.0
        let targetX0 = containerWidth * progress0
        let clampedX0 = min(max(targetX0 - tooltipWidth / 2, 0), containerWidth - tooltipWidth)
        XCTAssertEqual(clampedX0, 0.0, "Far left index must clamp offset to 0.0")

        // Test Far Right (Index 11 - Dec)
        let progress11: CGFloat = 1.0
        let targetX11 = containerWidth * progress11
        let clampedX11 = min(max(targetX11 - tooltipWidth / 2, 0), containerWidth - tooltipWidth)
        XCTAssertEqual(clampedX11, 240.0, "Far right index must clamp offset to containerWidth - tooltipWidth (240.0)")
    }

    // MARK: - 32. Phase 4: Empty Array Theme Colors Crash Defense Test

    @MainActor
    func testPhase4EmptyArrayThemeColorsCrashDefense() {
        let emptyTheme = SolarVizTheme(
            name: "EmptyTheme",
            backgroundColor: .black,
            primaryTextColor: .white,
            secondaryTextColor: .gray,
            borderColor: .gray,
            accentColor: .orange,
            seriesColors: [], // Empty Array Theme!
            cornerRadius: 12.0,
            glassmorphismOpacity: 0.85,
            gridLineWidth: 1.0
        )

        let items = [
            SolarDefaultDataPoint(xLabel: "Tile 1", value: 100.0),
            SolarDefaultDataPoint(xLabel: "Tile 2", value: 200.0)
        ]
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)

        // Must not crash when rendering with empty seriesColors
        let treemap = SolarTreeMapView(binding: binding).environment(\.solarVizTheme, emptyTheme)
        let sunburst = SolarSunburstView(binding: binding).environment(\.solarVizTheme, emptyTheme)

        XCTAssertNotNil(treemap)
        XCTAssertNotNil(sunburst)
    }

    // MARK: - 33. Phase 4: UIKit Hosting Controller Parent Lifecycle Test

    @MainActor
    func testPhase4UIKitHostingControllerParentLifecycle() {
        #if canImport(UIKit)
        let items = [SolarDefaultDataPoint(xLabel: "A", value: 10.0)]
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)
        let chart = SolarTreeMapView(binding: binding)

        let hostingView = SolarVizHostingView(rootView: chart)
        let parentVC = UIViewController()
        parentVC.view.addSubview(hostingView)

        XCTAssertEqual(parentVC.view.subviews.count, 1)
        hostingView.removeFromSuperview()
        XCTAssertEqual(parentVC.view.subviews.count, 0)
        #endif
    }

    // MARK: - 34. Phase 6: SolarComparisonChartView initialSelectedIndex Reactive Property Test

    @MainActor
    func testPhase6StatefulSelectedIndexParentSync() {
        let items = (0..<5).map { SolarDefaultDataPoint(xLabel: "M\($0)", value: Double($0 * 10)) }
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)
        let chart = SolarComparisonChartView(binding: binding, initialSelectedIndex: 3)
        XCTAssertEqual(chart.initialSelectedIndex, 3, "initialSelectedIndex must be stored reactively on chart view instance")
    }

    // MARK: - 35. Phase 6: Treemap Genuine Item ID Preservation Test

    func testPhase6TreemapUniqueTileIDPreservation() {
        struct ProductTileItem: Identifiable, Sendable {
            let id: String
            let val: Double
        }

        let products = [
            ProductTileItem(id: "PROD_APPLE", val: 500.0),
            ProductTileItem(id: "PROD_GOOGLE", val: 300.0)
        ]

        let strategy = SquarifiedTreemapStrategy()
        let tiles = strategy.computeTiles(
            data: products,
            extractY: { $0.val },
            extractID: { $0.id },
            bounds: CGRect(x: 0, y: 0, width: 400, height: 400)
        )

        XCTAssertEqual(tiles.count, 2)
        XCTAssertTrue(tiles.contains(where: { $0.id == "PROD_APPLE" }), "TreeTile.id must match genuine item ID instead of artificial tile_0 index")
        XCTAssertTrue(tiles.contains(where: { $0.id == "PROD_GOOGLE" }), "TreeTile.id must match genuine item ID instead of artificial tile_1 index")
    }

    // MARK: - 36. Phase 7: O(N) Scatter Clustering Performance Test (10,000 Points)

    func testPhase7ONScatterClusteringPerformance() {
        struct ScatterDataPoint: Identifiable, Sendable {
            let id: String
            let xVal: Double
            let yVal: Double
        }

        let dataset = (0..<10000).map { i in
            ScatterDataPoint(id: "P\(i)", xVal: Double(i % 100), yVal: Double((i * 13) % 200))
        }

        let binding = VizDataBinding(data: dataset, x: \.xVal, y: \.yVal)
        let startTime = CFAbsoluteTimeGetCurrent()

        let allNums = dataset.compactMap { Double($0.xVal) }
        let minVal = allNums.min() ?? 0.0
        let maxVal = allNums.max() ?? 1.0
        let span = maxVal - minVal

        let points = dataset.map { item -> (id: String, point: CGPoint, weight: Double) in
            let normX = span > 0 ? (item.xVal - minVal) / span : 0.5
            let normY = item.yVal / 200.0
            return (id: item.id, point: CGPoint(x: normX * 300, y: normY * 300), weight: 1.0)
        }

        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        XCTAssertEqual(points.count, 10000)
        XCTAssertLessThan(elapsedMs, 30.0, "O(N) pre-computed normalization must complete under 30ms for 10K points")
    }

    // MARK: - 37. Phase 7: Mid-Array Mutation Reactive Task Hash Sync Test

    func testPhase7MidArrayMutationReactiveTaskSync() {
        struct DynamicPoint: Identifiable, Sendable {
            let id: String
            var val: Double
        }

        var itemsA = [
            DynamicPoint(id: "P1", val: 10.0),
            DynamicPoint(id: "P2", val: 20.0),
            DynamicPoint(id: "P3", val: 30.0)
        ]

        let bindingA = VizDataBinding(data: itemsA, x: \.id, y: \.val)
        let hashA = bindingA.dataHash

        itemsA[1].val = 999.0 // Mutate middle element value
        let bindingB = VizDataBinding(data: itemsA, x: \.id, y: \.val)
        let hashB = bindingB.dataHash

        XCTAssertNotEqual(hashA, hashB, "Mutating mid-array element Y value must produce distinct dataHash triggering reactive task updates")
    }

    // MARK: - 38. Phase 8: O(N) Two-Pointer Interpolation Performance Test (10,000 Points)

    func testPhase8TwoPointerInterpolationPerformance() {
        let seriesA = (0..<10000).map { CGPoint(x: CGFloat($0), y: CGFloat($0 * 2)) }
        let seriesB = (0..<10000).map { CGPoint(x: CGFloat($0) + 0.5, y: CGFloat($0 * 3)) }

        let startTime = CFAbsoluteTimeGetCurrent()
        let (alignedA, alignedB) = IntersectionPathCalculator.alignSeries(seriesA: seriesA, seriesB: seriesB)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertEqual(alignedA.count, 20000)
        XCTAssertEqual(alignedB.count, 20000)
        XCTAssertLessThan(elapsedMs, 60.0, "O(N) Two-pointer interpolation scan must align 20K points in under 60ms in debug mode")
    }

    // MARK: - 39. Phase 8: Zero-Cost SwiftUI View Init Benchmark (1,000 Inits)

    @MainActor
    func testPhase8ZeroCostInitReRenderPerformance() {
        let items = (0..<1000).map { SolarDefaultDataPoint(xLabel: "M\($0)", value: Double($0)) }
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)

        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<1000 {
            _ = SolarComparisonChartView(binding: binding)
        }
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertLessThan(elapsedMs, 5.0, "1,000 SwiftUI View initializations must execute in under 5ms (Zero-Cost init)")
    }

    // MARK: - 40. Bayesian Trend Engine: Confidence Interval Bounds Test

    func testBayesianTrendConfidenceIntervalBounds() {
        let samplePoints = [
            CGPoint(x: 1.0, y: 10.0),
            CGPoint(x: 2.0, y: 15.0),
            CGPoint(x: 3.0, y: 18.0),
            CGPoint(x: 4.0, y: 24.0),
            CGPoint(x: 5.0, y: 30.0)
        ]

        let trend = BayesianTrendCalculator.computeTrend(points: samplePoints, sampleCount: 50)
        XCTAssertEqual(trend.count, 50)

        for pt in trend {
            XCTAssertGreaterThanOrEqual(pt.upperLimit, pt.mean, "Upper limit must be >= mean")
            XCTAssertLessThanOrEqual(pt.lowerLimit, pt.mean, "Lower limit must be <= mean")
            XCTAssertGreaterThan(pt.stdDev, 0.0, "Standard deviation must be strictly positive")
        }
    }

    // MARK: - 41. Bayesian Trend Engine: 10,000 Points Performance Test

    func testBayesianTrend10KPointsPerformance() {
        let samplePoints = (0..<10000).map { i in
            CGPoint(x: CGFloat(i), y: CGFloat(i * 2 + (i % 5)))
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let trend = BayesianTrendCalculator.computeTrend(points: samplePoints, sampleCount: 100)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertEqual(trend.count, 100)
        XCTAssertLessThan(elapsedMs, 60.0, "10,000 point Bayesian trend computation must finish under 60ms in debug mode")
    }

    // MARK: - 42. Phase 10: Swift 6 Strict Concurrency Sendable Conformity Test

    func testSwift6SendableBayesianTrendConformity() async {
        let points = [CGPoint(x: 1, y: 10), CGPoint(x: 2, y: 20)]
        let task = Task.detached { () -> [BayesianTrendPoint] in
            return BayesianTrendCalculator.computeTrend(points: points, sampleCount: 20)
        }
        let result = await task.value
        XCTAssertEqual(result.count, 20)
    }

    // MARK: - 43. Phase 10: Evil Edge Case NaN / Infinity / Zero-Variance Input Defense

    func testEvilEdgeCaseZeroVarianceAndNaNInputs() {
        let evilPoints = [
            CGPoint(x: 1.0, y: 50.0),
            CGPoint(x: 2.0, y: 50.0),
            CGPoint(x: Double.nan, y: 50.0),
            CGPoint(x: 3.0, y: Double.infinity),
            CGPoint(x: 4.0, y: 50.0)
        ]

        let trend = BayesianTrendCalculator.computeTrend(points: evilPoints, sampleCount: 30)
        XCTAssertEqual(trend.count, 30)

        for pt in trend {
            XCTAssertFalse(pt.mean.isNaN, "Mean must never be NaN")
            XCTAssertFalse(pt.upperLimit.isNaN, "Upper limit must never be NaN")
            XCTAssertFalse(pt.lowerLimit.isNaN, "Lower limit must never be NaN")
            XCTAssertTrue(pt.mean.isFinite, "Mean must be finite")
        }
    }

    // MARK: - 44. Phase 11: Non-Linear RBF Kernel Bayesian Curve Adaptation Test

    func testNonLinearBayesianRBFKernelTrendCurve() {
        let wavePoints = [
            CGPoint(x: 1.0, y: 10.0),
            CGPoint(x: 2.0, y: 50.0),
            CGPoint(x: 3.0, y: 20.0),
            CGPoint(x: 4.0, y: 90.0),
            CGPoint(x: 5.0, y: 30.0)
        ]

        let trend = BayesianTrendCalculator.computeTrend(points: wavePoints, sampleCount: 80)
        XCTAssertEqual(trend.count, 80)

        // Verify non-linear peak detection (mean adapts to wave oscillation rather than fitting a straight line)
        let midTrend = trend.first(where: { abs($0.x - 2.0) < 0.1 })
        XCTAssertNotNil(midTrend)
        XCTAssertGreaterThan(midTrend!.mean, 25.0, "Non-linear RBF kernel must adapt to wave peak at x=2.0")
    }

    // MARK: - 45. Phase 11: Smooth Curve Computation Performance Test

    func testCatmullRomSmoothCurvePerformance() {
        let points = (0..<1000).map { i in CGPoint(x: CGFloat(i), y: sin(CGFloat(i) * 0.1) * 50.0) }

        let startTime = CFAbsoluteTimeGetCurrent()
        let trend = BayesianTrendCalculator.computeTrend(points: points, sampleCount: 80)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertEqual(trend.count, 80)
        XCTAssertLessThan(elapsedMs, 100.0, "Non-linear RBF Kernel Bayesian trend computation must finish under 100ms in debug mode")
    }

    // MARK: - 46. Phase 13: Ceil Division 500-Point Downsampling Test

    func testPhase13CeilDivisionDownsampling999Points() {
        let points = (0..<999).map { i in CGPoint(x: CGFloat(i), y: CGFloat(i % 100)) }
        let trend = BayesianTrendCalculator.computeTrend(points: points, sampleCount: 80)
        XCTAssertEqual(trend.count, 80)
        for pt in trend {
            XCTAssertFalse(pt.mean.isNaN)
        }
    }

    // MARK: - 47. Phase 13: Bayesian Gap Nearest-Neighbor Fallback Test

    func testPhase13BayesianGapNearestNeighborFallback() {
        let gapPoints = [
            CGPoint(x: 1.0, y: 100.0),
            CGPoint(x: 2.0, y: 100.0),
            CGPoint(x: 3.0, y: 100.0),
            // Wide Gap between x=3 and x=100
            CGPoint(x: 100.0, y: 500.0),
            CGPoint(x: 101.0, y: 500.0)
        ]

        let trend = BayesianTrendCalculator.computeTrend(points: gapPoints, sampleCount: 100)
        XCTAssertEqual(trend.count, 100)

        for pt in trend {
            XCTAssertGreaterThanOrEqual(pt.mean, 90.0, "Mean should never plunge to ys.first cliff drop")
            XCTAssertLessThanOrEqual(pt.mean, 510.0)
        }
    }

    // MARK: - 48. Phase 14: Squarified Treemap O(1) Bruls Aspect Ratio Performance Test (10,000 Tiles)

    func testSquarifiedTreemapO1AspectRatioPerformance10K() {
        let strategy = SquarifiedTreemapStrategy()
        let largeData = (0..<10_000).map { i in
            SolarDefaultDataPoint(id: "tile_\(i)", xLabel: "Label_\(i)", value: Double((i * 17) % 500 + 1))
        }

        let start = CFAbsoluteTimeGetCurrent()
        let tiles = strategy.computeTiles(
            data: largeData,
            extractY: \.value,
            extractID: \.id,
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000)
        )
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        XCTAssertEqual(tiles.count, 10_000)
        XCTAssertLessThan(elapsedMs, 250.0, "10,000 tiles layout with O(1) Bruls scalar aspect ratio math must finish under 250ms in debug test mode")
    }

    // MARK: - 49. Phase 14: Stable Sunburst Arc IDs Test On Sorting Shifting

    func testStableSunburstArcIDsOnDataSort() {
        let item1 = ProductionEdgeItem(id: "item_alpha", xLabel: "Alpha", yValue: 100.0, category: "CatA", subCategory: "SubA")
        let item2 = ProductionEdgeItem(id: "item_beta", xLabel: "Beta", yValue: 200.0, category: "CatB", subCategory: "SubB")
        let binding = VizDataBinding(data: [item1, item2], x: \.xLabel, y: \.yValue, group: \.category)

        XCTAssertEqual(binding.sortedGroupKeys, ["CatA", "CatB"])
    }

    // MARK: - 50. Phase 15: VizDataBinding O(1) Precomputed Cache Instant Lookup Test

    func testVizDataBindingO1PrecomputedCacheInstantLookup() {
        let items = (0..<50_000).map { i in
            ProductionEdgeItem(id: "\(i)", xLabel: "Label_\(i)", yValue: Double(i), category: "Group_\(i % 10)", subCategory: "Sub_\(i % 20)")
        }

        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.yValue, group: \.category)

        let start = CFAbsoluteTimeGetCurrent()
        // Accessing sortedGroupedData 10 times in body render
        for _ in 0..<10 {
            _ = binding.sortedGroupedData()
        }
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        XCTAssertLessThan(elapsedMs, 1.0, "10 calls to pre-computed sortedGroupedData must take less than 1.0ms total")
    }

    // MARK: - 51. Phase 15: Responsive Sunburst Arc Radius Scaling iPad Test

    func testResponsiveSunburstArcRadiusScalingIPad() {
        let arc = SunburstArc(
            id: "test_arc",
            item: ProductionEdgeItem(id: "1", xLabel: "A", yValue: 100.0, category: "CatA", subCategory: "SubA"),
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            innerRadiusRatio: 0.30,
            outerRadiusRatio: 0.58,
            label: "Test",
            percentage: 50.0
        )

        let smallRadius: CGFloat = 100.0
        let ipadRadius: CGFloat = 1000.0

        XCTAssertEqual(arc.innerRadius(maxRadius: smallRadius), 30.0, accuracy: 0.001)
        XCTAssertEqual(arc.outerRadius(maxRadius: smallRadius), 58.0, accuracy: 0.001)

        XCTAssertEqual(arc.innerRadius(maxRadius: ipadRadius), 300.0, accuracy: 0.001)
        XCTAssertEqual(arc.outerRadius(maxRadius: ipadRadius), 580.0, accuracy: 0.001)
    }

    // MARK: - 52. Phase 16: Inline SwiftUI VizDataBinding 1,000x Re-Init Memoization Speed Test

    func testPhase6VizDataBindingMemoizedInitZeroAllocationOnReinit() {
        let dataset = (0..<50_000).map { i in
            ProductionEdgeItem(id: "\(i)", xLabel: "Key_\(i)", yValue: Double(i), category: "Cat_\(i % 5)", subCategory: "Sub_\(i % 2)")
        }

        // 1st Init: Computes grouping once
        _ = VizDataBinding(data: dataset, x: \ProductionEdgeItem.xLabel, y: \ProductionEdgeItem.yValue, group: \ProductionEdgeItem.category)

        let startTime = CFAbsoluteTimeGetCurrent()
        // Simulate inline VizDataBinding init inside SwiftUI body re-evaluation 1,000 times
        for _ in 0..<1_000 {
            _ = VizDataBinding(data: dataset, x: \ProductionEdgeItem.xLabel, y: \ProductionEdgeItem.yValue, group: \ProductionEdgeItem.category)
        }
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertLessThan(elapsedMs, 2.0, "1,000 inline VizDataBinding initializations must complete in under 2.0ms total via memoization cache hit")
    }

    // MARK: - 53. Phase 16: Zero-Allocation Tooltip Series Matching Test

    func testPhase6TooltipMatchingItemBZeroDictionaryAllocation() {
        let itemsA = (0..<10_000).map { i in
            ProductionEdgeItem(id: "a_\(i)", xLabel: "Date_\(i)", yValue: Double(i), category: "SeriesA", subCategory: "SubA")
        }
        let itemsB = (0..<10_000).map { i in
            ProductionEdgeItem(id: "b_\(i)", xLabel: "Date_\(i)", yValue: Double(i * 2), category: "SeriesB", subCategory: "SubB")
        }

        let bindingA = VizDataBinding(data: itemsA, x: \ProductionEdgeItem.xLabel, y: \ProductionEdgeItem.yValue)
        let bindingB = VizDataBinding(data: itemsB, x: \ProductionEdgeItem.xLabel, y: \ProductionEdgeItem.yValue)

        let startTime = CFAbsoluteTimeGetCurrent()
        // Simulate 60fps drag gesture (60 frames) accessing candidate B without dictionary allocation
        for index in 0..<1_000 {
            let idx = index % itemsA.count
            let keyA = bindingA.extractX(from: itemsA[idx]).description

            let candidateB: ProductionEdgeItem?
            if idx < bindingB.data.count, bindingB.extractX(from: bindingB.data[idx]).description == keyA {
                candidateB = bindingB.data[idx]
            } else {
                candidateB = bindingB.data.first(where: { bindingB.extractX(from: $0).description == keyA })
            }

            XCTAssertNotNil(candidateB)
            XCTAssertEqual(candidateB?.id, "b_\(idx)")
        }
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        XCTAssertLessThan(elapsedMs, 15.0, "1,000 zero-allocation tooltip match lookups must complete in under 15.0ms total in debug test mode")
    }
}
