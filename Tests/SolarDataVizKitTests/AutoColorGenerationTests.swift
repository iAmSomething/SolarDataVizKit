import XCTest
import SwiftUI
@testable import SolarDataVizKit

final class AutoColorGenerationTests: XCTestCase {

    func testColorForSeriesReturnsPresetColorWhenAvailable() {
        let theme = SolarVizTheme.darkCarbon  // seriesColors 5개
        let color0 = theme.colorForSeries(at: 0, totalCount: 3)
        XCTAssertEqual(color0, theme.seriesColors[0])
    }

    func testColorForSeriesGeneratesHSLWhenExhausted() {
        let theme = SolarVizTheme.darkCarbon  // seriesColors 5개
        let color7 = theme.colorForSeries(at: 7, totalCount: 10)
        // 프리셋 색상이 아닌 자동 생성된 색상
        XCTAssertFalse(theme.seriesColors.contains(color7))
    }

    func testColorForSeriesWithEmptySeriesColorsReturnAccent() {
        let emptyTheme = SolarVizTheme(
            name: "Empty", backgroundColor: .black,
            primaryTextColor: .white, secondaryTextColor: .gray,
            borderColor: .gray, accentColor: .orange,
            seriesColors: []
        )
        let color = emptyTheme.colorForSeries(at: 0, totalCount: 1)
        XCTAssertEqual(color, .orange)
    }

    func testAllGeneratedColorsAreUnique() {
        let theme = SolarVizTheme.darkCarbon
        let colors = (0..<20).map { theme.colorForSeries(at: $0, totalCount: 20) }
        let uniqueDescriptions = Set(colors.map { String(describing: $0) })
        XCTAssertEqual(uniqueDescriptions.count, 20, "20개 시리즈의 색상은 모두 고유해야 합니다")
    }
}
