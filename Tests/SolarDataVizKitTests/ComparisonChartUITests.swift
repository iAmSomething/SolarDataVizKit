import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit


final class ComparisonChartUITests: XCTestCase {

    @MainActor
    func testDeltaTooltipOverlayViewHierarchy() throws {
        let tooltip = DeltaTooltipOverlay(
            xLabel: "Feb 2026",
            valueA: 250.0,
            valueB: 180.0,
            labelA: "2026 Sales",
            labelB: "2025 Sales",
            theme: .darkCarbon
        )

        // Inspect VStack container
        let vStack = try tooltip.inspect().vStack()
        XCTAssertEqual(try vStack.text(0).string(), "Feb 2026")

        // Inspect inner values HStack
        let hStack = try vStack.hStack(1)
        let groupA = try hStack.vStack(0)
        XCTAssertEqual(try groupA.text(0).string(), "2026 Sales")
        XCTAssertEqual(try groupA.text(1).string(), "250.0")

        let groupB = try hStack.vStack(2)
        XCTAssertEqual(try groupB.text(0).string(), "2025 Sales")
        XCTAssertEqual(try groupB.text(1).string(), "180.0")

        // Inspect Positive Badge Text
        let badgeHStack = try vStack.hStack(2)
        XCTAssertEqual(try badgeHStack.text(0).string(), "▲")
        XCTAssertTrue(try badgeHStack.text(1).string().contains("+38.9%"))
    }

    @MainActor
    func testNegativeDeltaTooltipOverlayUI() throws {
        let tooltip = DeltaTooltipOverlay(
            xLabel: "March 2026",
            valueA: 80.0,
            valueB: 100.0,
            labelA: "Current",
            labelB: "Target",
            theme: .minimalLight
        )

        let vStack = try tooltip.inspect().vStack()
        let badgeHStack = try vStack.hStack(2)
        XCTAssertEqual(try badgeHStack.text(0).string(), "▼")
        XCTAssertTrue(try badgeHStack.text(1).string().contains("-20.0%"))
    }

    @MainActor
    func testSolarComparisonChartViewUIRendering() throws {
        let items = [
            SolarDefaultDataPoint(xLabel: "Q1", value: 100.0, groupIdentifier: "Series A"),
            SolarDefaultDataPoint(xLabel: "Q2", value: 200.0, groupIdentifier: "Series A"),
            SolarDefaultDataPoint(xLabel: "Q1", value: 120.0, groupIdentifier: "Series B"),
            SolarDefaultDataPoint(xLabel: "Q2", value: 180.0, groupIdentifier: "Series B")
        ]

        let binding = VizDataBinding(
            data: items,
            x: \.xLabel,
            y: \.value,
            group: \.groupIdentifier
        )

        let chartView = SolarComparisonChartView(
            binding: binding,
            seriesA: "Series A",
            seriesB: "Series B"
        )

        let outerVStack = try chartView.inspect().find(ViewType.VStack.self)
        // Check Legend Header
        let legendHStack = try outerVStack.hStack(0)
        let itemA = try legendHStack.hStack(0)
        XCTAssertEqual(try itemA.text(1).string(), "Series A")

        let itemB = try legendHStack.hStack(1)
        XCTAssertEqual(try itemB.text(1).string(), "Series B")
    }

    #if canImport(UIKit)
    @MainActor
    func testSolarVizHostingViewUIKitIntegration() {
        let items = [
            SolarDefaultDataPoint(xLabel: "Q1", value: 50.0, groupIdentifier: "A")
        ]
        let binding = VizDataBinding(data: items, x: \.xLabel, y: \.value)
        let chartView = SolarComparisonChartView(binding: binding)

        let hostingView = SolarVizHostingView(rootView: chartView)
        XCTAssertNotNil(hostingView)
        XCTAssertEqual(hostingView.subviews.count, 1)

        // Test cleanup on removeFromSuperview
        let parentView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        parentView.addSubview(hostingView)
        XCTAssertEqual(parentView.subviews.count, 1)

        hostingView.removeFromSuperview()
        XCTAssertEqual(parentView.subviews.count, 0)
    }
    #endif
}
