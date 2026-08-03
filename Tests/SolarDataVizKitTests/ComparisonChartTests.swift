import XCTest
import SwiftUI
@testable import SolarDataVizKit

struct ChartTestModel: SolarVizDataPoint {
    let id: String
    let label: String
    let revenue: Double
    let category: String
}

final class ComparisonChartTests: XCTestCase {

    @MainActor
    func testDeltaCalculation() {
        let overlay = DeltaTooltipOverlay(
            xLabel: "Q1",
            valueA: 150.0,
            valueB: 100.0,
            labelA: "This Year",
            labelB: "Last Year",
            theme: .darkCarbon
        )

        XCTAssertEqual(overlay.xLabel, "Q1")
        XCTAssertEqual(overlay.valueA, 150.0)
        XCTAssertEqual(overlay.valueB, 100.0)
    }

    func testGroupedComparisonBinding() {
        let items = [
            ChartTestModel(id: "1", label: "Jan", revenue: 100.0, category: "Series A"),
            ChartTestModel(id: "2", label: "Feb", revenue: 200.0, category: "Series A"),
            ChartTestModel(id: "3", label: "Jan", revenue: 120.0, category: "Series B"),
            ChartTestModel(id: "4", label: "Feb", revenue: 180.0, category: "Series B")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.label,
            y: \.revenue,
            group: \.category
        )

        let grouped = binding.groupedData()
        XCTAssertEqual(grouped["Series A"]?.count, 2)
        XCTAssertEqual(grouped["Series B"]?.count, 2)
    }
}
