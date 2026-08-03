import SwiftUI

/// SolarDataVizKit 차트 컴포넌트에 통합 적용되는 디자인 시스템 테마 토큰 구조체입니다.
///
/// ## Overview
/// `SolarVizTheme`는 배경색, 텍스트 색상, 테두리, 액센트 컬러, 다중 시리즈 색상 팔레트 및 글래스모피즘 효과 토큰을 정의합니다.
///
/// ## Presets
/// - ``darkCarbon``: Dark Warm-Tech 기본 웜 카본 블랙 테마
/// - ``minimalLight``: Clean Minimal 수놓은 라이트 테마
/// - ``neonCyber``: 네온 사이버 다크 테마
///
/// ## Example
/// ```swift
/// MyChartView(...)
///     .solarVizTheme(.darkCarbon)
/// ```
public struct SolarVizTheme: Sendable, Hashable {
    /// 테마 이름
    public let name: String
    /// 배경 색상
    public let backgroundColor: Color
    /// 기본 텍스트 색상
    public let primaryTextColor: Color
    /// 보조 텍스트 색상
    public let secondaryTextColor: Color
    /// 테두리 색상
    public let borderColor: Color
    /// 액센트 강조 색상
    public let accentColor: Color
    /// 다중 시리즈 비교 색상 팔레트
    public let seriesColors: [Color]
    /// 차트 모서리 곡률 (기본값: 12.0)
    public let cornerRadius: CGFloat
    /// 글래스모피즘 불투명도 (기본값: 0.85)
    public let glassmorphismOpacity: Double
    /// 그리드 라인 두께 (기본값: 1.0)
    public let gridLineWidth: CGFloat

    /// 새로운 커스텀 시각화 테마를 정의합니다.
    ///
    /// - Parameters:
    ///   - name: 테마 식별 이름
    ///   - backgroundColor: 차트 배경색
    ///   - primaryTextColor: 제목/주요 수치 색상
    ///   - secondaryTextColor: 축/보조 라벨 색상
    ///   - borderColor: 구분선/테두리 색상
    ///   - accentColor: 하이라이트 액센트 색상
    ///   - seriesColors: 데이터 시리즈 색상 팔레트 배열
    ///   - cornerRadius: 차트 모서리 라운딩 곡률
    ///   - glassmorphismOpacity: 툴팁 배경 투명도
    ///   - gridLineWidth: 눈금 그리드선 두께
    public init(
        name: String,
        backgroundColor: Color,
        primaryTextColor: Color,
        secondaryTextColor: Color,
        borderColor: Color,
        accentColor: Color,
        seriesColors: [Color],
        cornerRadius: CGFloat = 12.0,
        glassmorphismOpacity: Double = 0.85,
        gridLineWidth: CGFloat = 1.0
    ) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.borderColor = borderColor
        self.accentColor = accentColor
        self.seriesColors = seriesColors
        self.cornerRadius = cornerRadius
        self.glassmorphismOpacity = glassmorphismOpacity
        self.gridLineWidth = gridLineWidth
    }
}

// MARK: - Built-in Presets
extension SolarVizTheme {
    /// Dark Warm-Tech 기본 웜 카본 블랙 테마입니다. (#0b0a09, #f5f4f2, #ff6b00)
    public static let darkCarbon = SolarVizTheme(
        name: "Dark Carbon",
        backgroundColor: Color(red: 11/255, green: 10/255, blue: 9/255),
        primaryTextColor: Color(red: 245/255, green: 244/255, blue: 242/255),
        secondaryTextColor: Color(red: 138/255, green: 136/255, blue: 133/255),
        borderColor: Color(red: 31/255, green: 30/255, blue: 28/255),
        accentColor: Color(red: 255/255, green: 107/255, blue: 0/255),
        seriesColors: [
            Color(red: 255/255, green: 107/255, blue: 0/255),
            Color(red: 56/255, green: 189/255, blue: 248/255),
            Color(red: 168/255, green: 85/255, blue: 247/255),
            Color(red: 236/255, green: 72/255, blue: 153/255),
            Color(red: 34/255, green: 197/255, blue: 94/255)
        ],
        cornerRadius: 12.0,
        glassmorphismOpacity: 0.88,
        gridLineWidth: 1.0
    )

    /// Clean Minimal 라이트 테마입니다.
    public static let minimalLight = SolarVizTheme(
        name: "Minimal Light",
        backgroundColor: Color(red: 250/255, green: 250/255, blue: 249/255),
        primaryTextColor: Color(red: 28/255, green: 25/255, blue: 23/255),
        secondaryTextColor: Color(red: 120/255, green: 113/255, blue: 108/255),
        borderColor: Color(red: 229/255, green: 229/255, blue: 224/255),
        accentColor: Color(red: 234/255, green: 88/255, blue: 12/255),
        seriesColors: [
            Color(red: 234/255, green: 88/255, blue: 12/255),
            Color(red: 2/255, green: 132/255, blue: 199/255),
            Color(red: 147/255, green: 51/255, blue: 234/255),
            Color(red: 16/255, green: 185/255, blue: 129/255)
        ],
        cornerRadius: 12.0,
        glassmorphismOpacity: 0.90,
        gridLineWidth: 1.0
    )

    /// 네온 사이버 다크 테마입니다.
    public static let neonCyber = SolarVizTheme(
        name: "Neon Cyber",
        backgroundColor: Color(red: 10/255, green: 10/255, blue: 18/255),
        primaryTextColor: Color(red: 240/255, green: 240/255, blue: 255/255),
        secondaryTextColor: Color(red: 140/255, green: 145/255, blue: 170/255),
        borderColor: Color(red: 35/255, green: 40/255, blue: 70/255),
        accentColor: Color(red: 0/255, green: 245/255, blue: 212/255),
        seriesColors: [
            Color(red: 0/255, green: 245/255, blue: 212/255),
            Color(red: 255/255, green: 0/255, blue: 110/255),
            Color(red: 255/255, green: 190/255, blue: 11/255),
            Color(red: 131/255, green: 56/255, blue: 236/255)
        ],
        cornerRadius: 14.0,
        glassmorphismOpacity: 0.80,
        gridLineWidth: 1.2
    )
}

private struct SolarVizThemeKey: EnvironmentKey {
    static let defaultValue: SolarVizTheme = .darkCarbon
}

extension EnvironmentValues {
    /// SwiftUI 환경에 저장된 SolarVizTheme 인스턴스입니다.
    public var solarVizTheme: SolarVizTheme {
        get { self[SolarVizThemeKey.self] }
        set { self[SolarVizThemeKey.self] = newValue }
    }
}

extension View {
    /// SolarDataVizKit 시각화 차트에 테마를 적용합니다.
    ///
    /// - Parameter theme: 적용할 시각화 테마 (예: `.darkCarbon`, `.minimalLight`)
    /// - Returns: 테마가 반영된 SwiftUI View
    public func solarVizTheme(_ theme: SolarVizTheme) -> some View {
        environment(\.solarVizTheme, theme)
    }
}
