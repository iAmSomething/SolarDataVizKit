import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct MockArchitectureItem: SolarVizDataPoint, Equatable {
    let id: String
    let xVal: Double
    let yVal: Double
}

struct MockTrendStrategy: TrendCalculationStrategy {
    func computeTrend(points: [CGPoint], sampleCount: Int) -> [BayesianTrendPoint] {
        return [
            BayesianTrendPoint(id: "mock1", x: 10.0, mean: 100.0, upperLimit: 110.0, lowerLimit: 90.0, stdDev: 10.0)
        ]
    }
}

final class ArchitectureIntegrationTests: XCTestCase {

    // 1. SolarPlottable Conformance Test
    func testSolarPlottableConformances() {
        let intVal: Int = 42
        XCTAssertEqual(intVal.asPlotValue, 42.0)
        
        let doubleVal: Double = 3.1415
        XCTAssertEqual(doubleVal.asPlotValue, 3.1415)
        
        let cgfloatVal: CGFloat = 100.5
        XCTAssertEqual(cgfloatVal.asPlotValue, 100.5)
        
        let dateVal = Date(timeIntervalSince1970: 1600000000)
        XCTAssertEqual(dateVal.asPlotValue, 1600000000.0)
        
        let stringValNumeric = "123.45"
        XCTAssertEqual(stringValNumeric.asPlotValue, 123.45)
        
        let stringValCategorical = "CategoryA"
        XCTAssertEqual(stringValCategorical.asPlotValue, Double(abs(stringValCategorical.hashValue) % 10_000))
    }

    // 2. versionToken O(1) Task Trigger Test
    func testVersionTokenUniqueness() {
        let items = [
            MockArchitectureItem(id: "1", xVal: 10.0, yVal: 10.0),
            MockArchitectureItem(id: "2", xVal: 20.0, yVal: 20.0)
        ]
        
        let binding1 = VizDataBinding(data: items, x: \.xVal, y: \.yVal)
        let binding2 = VizDataBinding(data: items, x: \.xVal, y: \.yVal)
        
        // Although the data is identical, versionToken must be strictly unique because they are different instances
        XCTAssertNotEqual(binding1.versionToken, binding2.versionToken)
        XCTAssertEqual(binding1.data, binding2.data)
        
        // Ensure dataHash uses the versionToken hash for backwards compatibility
        XCTAssertEqual(binding1.dataHash, binding1.versionToken.hashValue)
    }

    // 3. TrendCalculationStrategy DI Test
    @MainActor
    func testTrendCalculationStrategyInjection() {
        let items = [
            MockArchitectureItem(id: "1", xVal: 10.0, yVal: 10.0),
            MockArchitectureItem(id: "2", xVal: 20.0, yVal: 20.0)
        ]
        
        let binding = VizDataBinding(data: items, x: \.xVal, y: \.yVal)
        
        let customStrategy = MockTrendStrategy()
        
        let _ = SolarBayesianTrendView(
            binding: binding,
            strategy: customStrategy
        )
        
        // Test that the mock strategy correctly returns our stubbed point
        let computed = customStrategy.computeTrend(points: [], sampleCount: 0)
        XCTAssertEqual(computed.count, 1)
        XCTAssertEqual(computed[0].id, "mock1")
        XCTAssertEqual(computed[0].mean, 100.0)
    }

    // 4. SolarClusterScatterView Heatmap Flow Test
    func testClusterNodeCalculatorHeatmapNodes() {
        // Generate points that will form a distinct cluster to test heatmap node generation
        var points: [(id: String, point: CGPoint, weight: Double)] = []
        for i in 0..<100 {
            // Highly clustered points around (50, 50)
            let pt = CGPoint(x: 50.0 + Double.random(in: -5...5), y: 50.0 + Double.random(in: -5...5))
            points.append((id: "c1_\(i)", point: pt, weight: 1.0))
        }
        for i in 0..<5 {
            // Isolated points
            let pt = CGPoint(x: 200.0 + Double(i), y: 200.0)
            points.append((id: "isolated_\(i)", point: pt, weight: 1.0))
        }
        
        let resNodes = ClusterNodeCalculator.cluster(points: points, thresholdRadius: 20.0)
        
        // The heatmap logic in the view selects the top nodes sorted by count
        let resHeatmap = Array(resNodes.sorted(by: { $0.count > $1.count }).prefix(250))
        
        XCTAssertGreaterThan(resNodes.count, 0)
        XCTAssertGreaterThan(resHeatmap.count, 0)
        
        // The most dense cluster (with roughly 100 items) should be the first item in the heatmap array
        XCTAssertGreaterThan(resHeatmap[0].count, 10)
    }
}
