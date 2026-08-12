import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct TestItem: SolarVizDataPoint {
    let id: Int
    let month: String
    let amount: Double
    let category: String
}

final class DataBindingTests: XCTestCase {

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
        XCTAssertEqual(binding.extractX(from: items[0]), "Jan")
        XCTAssertEqual(binding.extractY(from: items[1]), 250.0)
        XCTAssertEqual(binding.extractGroup(from: items[2]), "Marketing")

        // Grouping test
        let grouped = binding.groupedData()
        XCTAssertEqual(grouped.keys.count, 2)
        XCTAssertEqual(grouped["Sales"]?.count, 2)
        XCTAssertEqual(grouped["Marketing"]?.count, 2)

        // Bounds test
        let bounds = binding.yBounds()
        XCTAssertEqual(bounds.min, 80.0)
        XCTAssertEqual(bounds.max, 300.0)

        // Normalization test
        let normMin = binding.normalizeY(value: 80.0, in: bounds)
        let normMax = binding.normalizeY(value: 300.0, in: bounds)
        let normMid = binding.normalizeY(value: 190.0, in: bounds)

        XCTAssertLessThan(abs(normMin - 0.0), 0.001)
        XCTAssertLessThan(abs(normMax - 1.0), 0.001)
        XCTAssertLessThan(abs(normMid - 0.5), 0.001)
    }

    func testSolarVizThemeTokens() {
        let darkTheme = SolarVizTheme.darkCarbon
        XCTAssertEqual(darkTheme.name, "Dark Carbon")
        XCTAssertEqual(darkTheme.cornerRadius, 12.0)
        XCTAssertGreaterThanOrEqual(darkTheme.seriesColors.count, 5)

        let lightTheme = SolarVizTheme.minimalLight
        XCTAssertEqual(lightTheme.name, "Minimal Light")
        XCTAssertGreaterThanOrEqual(lightTheme.seriesColors.count, 4)
    }

    func testDefaultDataPoint() {
        let dp = SolarDefaultDataPoint(xLabel: "Q1", value: 42.0, groupIdentifier: "2026")
        XCTAssertEqual(dp.xLabel, "Q1")
        XCTAssertEqual(dp.value, 42.0)
        XCTAssertEqual(dp.groupIdentifier, "2026")
    }

    func testNormalizeYZeroDivisionDefense() {
        let items = [
            TestItem(id: 1, month: "Jan", amount: 100.0, category: "Sales"),
            TestItem(id: 2, month: "Feb", amount: 100.0, category: "Sales")
        ]
        
        let binding = VizDataBinding(
            data: items,
            x: \.month,
            y: \.amount
        )
        
        // Even if bounds.max == bounds.min artificially, normalizeY must not crash or return NaN/Infinity
        let norm = binding.normalizeY(value: 100.0, in: (min: 100.0, max: 100.0))
        XCTAssertEqual(norm, 0.5, "When variance is zero, normalizeY must default to 0.5 center placement to avoid zero-division Infinity/NaN")
    }
}
