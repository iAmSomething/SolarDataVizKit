import Testing
@testable import SolarDataVizKit
import SwiftUI

struct ChartTestModel: SolarVizDataPoint {
    let id: String
    let label: String
    let revenue: Double
    let category: String
}

@Suite("Comparison Chart Component Tests")
struct ComparisonChartTests {

    @Test("Delta calculation formatting logic")
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

        #expect(overlay.xLabel == "Q1")
        #expect(overlay.valueA == 150.0)
        #expect(overlay.valueB == 100.0)
    }

    @Test("Grouped dataset binding for comparison series")
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
        #expect(grouped["Series A"]?.count == 2)
        #expect(grouped["Series B"]?.count == 2)
    }
}
