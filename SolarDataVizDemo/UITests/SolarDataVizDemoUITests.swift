import XCTest

final class SolarDataVizDemoUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - 1. End-to-End Tab Navigation Test

    func testEndToEndTabBarNavigationAndChartInteraction() throws {
        let headerTitle = app.staticTexts["SolarDataVizKit"]
        XCTAssertTrue(headerTitle.waitForExistence(timeout: 5.0), "Header title SolarDataVizKit must exist")

        let comparisonTab = app.buttons["Comparison"]
        XCTAssertTrue(comparisonTab.exists)
        comparisonTab.tap()
        XCTAssertTrue(app.staticTexts["Grouped Comparison Engine"].exists)

        let clusteringTab = app.buttons["Clustering"]
        XCTAssertTrue(clusteringTab.exists)
        clusteringTab.tap()
        XCTAssertTrue(app.staticTexts["Distance Cluster Scatter Engine"].exists)

        let treemapTab = app.buttons["TreeMap"]
        XCTAssertTrue(treemapTab.exists)
        treemapTab.tap()
        XCTAssertTrue(app.staticTexts["Squarified TreeMap Engine"].exists)

        let sunburstTab = app.buttons["Sunburst"]
        XCTAssertTrue(sunburstTab.exists)
        sunburstTab.tap()
        XCTAssertTrue(app.staticTexts["Concentric Sunburst Arc Engine"].exists)
    }

    // MARK: - 2. Comparison Chart Pan Gesture Drag Scrubbing Test

    func testComparisonPanGestureScrubbing() throws {
        let comparisonTab = app.buttons["Comparison"]
        XCTAssertTrue(comparisonTab.waitForExistence(timeout: 5.0))
        comparisonTab.tap()

        let chartContainer = app.otherElements.firstMatch
        XCTAssertTrue(chartContainer.exists)

        // Perform interactive horizontal Pan/Drag scrubbing gesture across chart coordinates
        let startCoordinate = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let endCoordinate = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
    }

    // MARK: - 3. Clustering Engine Interactive Gesture Test

    func testClusteringScatterInteractiveTaps() throws {
        let clusteringTab = app.buttons["Clustering"]
        XCTAssertTrue(clusteringTab.waitForExistence(timeout: 5.0))
        clusteringTab.tap()

        let canvas = app.otherElements.firstMatch
        XCTAssertTrue(canvas.exists)

        // Tap center of scatter cluster area to trigger interactive node selection
        let centerPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        centerPoint.tap()
    }

    // MARK: - 4. TreeMap Tile Interactive Selection Tap Test

    func testTreemapTileSelectionTaps() throws {
        let treemapTab = app.buttons["TreeMap"]
        XCTAssertTrue(treemapTab.waitForExistence(timeout: 5.0))
        treemapTab.tap()

        let tileArea = app.otherElements.firstMatch
        XCTAssertTrue(tileArea.exists)

        // Tap top-left tile and bottom-right tile to test selection highlight overlays
        tileArea.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).tap()
        tileArea.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7)).tap()
    }

    // MARK: - 5. Sunburst Concentric Arc Interactive Selection Tap Test

    func testSunburstArcSelectionTaps() throws {
        let sunburstTab = app.buttons["Sunburst"]
        XCTAssertTrue(sunburstTab.waitForExistence(timeout: 5.0))
        sunburstTab.tap()

        let arcContainer = app.otherElements.firstMatch
        XCTAssertTrue(arcContainer.exists)

        // Tap inner ring and outer ring arc coordinates
        arcContainer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        arcContainer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
    }
}
