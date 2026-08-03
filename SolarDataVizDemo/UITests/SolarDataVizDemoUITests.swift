import XCTest

final class SolarDataVizDemoUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testEndToEndTabBarNavigationAndChartInteraction() throws {
        // 1. Verify Header Title Existence
        let headerTitle = app.staticTexts["SolarDataVizKit"]
        XCTAssertTrue(headerTitle.waitForExistence(timeout: 5.0), "Header title SolarDataVizKit must exist")

        // 2. Test Comparison Chart Segment
        let comparisonTab = app.buttons["Comparison"]
        XCTAssertTrue(comparisonTab.exists)
        comparisonTab.tap()

        let comparisonChartHeader = app.staticTexts["Grouped Comparison Engine"]
        XCTAssertTrue(comparisonChartHeader.exists)

        // 3. Test Clustering Segment
        let clusteringTab = app.buttons["Clustering"]
        XCTAssertTrue(clusteringTab.exists)
        clusteringTab.tap()

        let clusteringHeader = app.staticTexts["Distance Cluster Scatter Engine"]
        XCTAssertTrue(clusteringHeader.exists)

        // 4. Test TreeMap Segment
        let treemapTab = app.buttons["TreeMap"]
        XCTAssertTrue(treemapTab.exists)
        treemapTab.tap()

        let treemapHeader = app.staticTexts["Squarified TreeMap Engine"]
        XCTAssertTrue(treemapHeader.exists)

        // 5. Test Sunburst Segment
        let sunburstTab = app.buttons["Sunburst"]
        XCTAssertTrue(sunburstTab.exists)
        sunburstTab.tap()

        let sunburstHeader = app.staticTexts["Concentric Sunburst Arc Engine"]
        XCTAssertTrue(sunburstHeader.exists)
    }
}
