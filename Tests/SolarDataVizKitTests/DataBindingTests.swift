import Testing
@testable import SolarDataVizKit
import SwiftUI

struct TestItem: SolarVizDataPoint {
    let id: Int
    let month: String
    let amount: Double
    let category: String
}

@Suite("SolarDataVizKit Phase 1 Core Tests")
struct DataBindingTests {

    @Test("VizDataBinding KeyPath extraction and bounds calculation")
    func testVizDataBindingKeyPathsAndBounds() {
        let items = [
            TestItem(id: 1, month: "Jan", amount: 100.0, category: "Sales"),
            TestItem(id: 2, month: "Feb", amount: 250.0, category: "Sales"),
            TestItem(id: 3, month: "Jan", amount: 80.0, category: "Marketing"),
            TestItem(id: 4, month: "Feb", amount: 300.0, category: "Marketing")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.month,
            y: \.amount,
            group: \.category
        )

        // Extraction test
        #expect(binding.extractX(from: items[0]) == "Jan")
        #expect(binding.extractY(from: items[1]) == 250.0)
        #expect(binding.extractGroup(from: items[2]) == "Marketing")

        // Grouping test
        let grouped = binding.groupedData()
        #expect(grouped.keys.count == 2)
        #expect(grouped["Sales"]?.count == 2)
        #expect(grouped["Marketing"]?.count == 2)

        // Bounds test
        let bounds = binding.yBounds()
        #expect(bounds.min == 80.0)
        #expect(bounds.max == 300.0)

        // Normalization test
        let normMin = binding.normalizeY(value: 80.0, in: bounds)
        let normMax = binding.normalizeY(value: 300.0, in: bounds)
        let normMid = binding.normalizeY(value: 190.0, in: bounds)

        #expect(abs(normMin - 0.0) < 0.001)
        #expect(abs(normMax - 1.0) < 0.001)
        #expect(abs(normMid - 0.5) < 0.001)
    }

    @Test("SolarVizTheme presets test")
    func testSolarVizThemeTokens() {
        let darkTheme = SolarVizTheme.darkCarbon
        #expect(darkTheme.name == "Dark Carbon")
        #expect(darkTheme.cornerRadius == 12.0)
        #expect(darkTheme.seriesColors.count >= 5)

        let lightTheme = SolarVizTheme.minimalLight
        #expect(lightTheme.name == "Minimal Light")
        #expect(lightTheme.seriesColors.count >= 4)
    }

    @Test("Default data point wrapper test")
    func testDefaultDataPoint() {
        let dp = SolarDefaultDataPoint(xLabel: "Q1", value: 42.0, groupIdentifier: "2026")
        #expect(dp.xLabel == "Q1")
        #expect(dp.value == 42.0)
        #expect(dp.groupIdentifier == "2026")
    }
}
