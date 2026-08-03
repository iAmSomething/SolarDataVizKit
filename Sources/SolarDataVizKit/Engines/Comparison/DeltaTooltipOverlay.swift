import SwiftUI

/// ## Quick View
/// `DeltaTooltipOverlay`는 스크러빙 터치 위치에서 두 데이터 시리즈 간 수치 차이(Delta)를 글래스모피즘 팝오버로 시각화하는 오버레이 뷰입니다.
///
/// - **특징**:
///   - **Live Delta Formatting**: 상승(`▲ +15.4%`) 및 하강(`▼ -5.2%`) 차이값을 다이나믹 색상과 함께 실시간 포맷팅.
///   - **Glassmorphism Spec**: 서브 픽셀 미세 테두리 오버레이(`rgba(255,255,255,0.12)`) 및 가우시안 블러 배경.
///
/// ## 사용 예시
/// ```swift
/// DeltaTooltipOverlay(
///     xLabel: "Jan 2026",
///     valueA: 150.0,
///     valueB: 120.0,
///     labelA: "This Month",
///     labelB: "Last Month",
///     theme: .darkCarbon
/// )
/// ```
public struct DeltaTooltipOverlay: View {
    public let xLabel: String
    public let valueA: Double
    public let valueB: Double
    public let labelA: String
    public let labelB: String
    public let theme: SolarVizTheme

    public init(
        xLabel: String,
        valueA: Double,
        valueB: Double,
        labelA: String = "Series A",
        labelB: String = "Series B",
        theme: SolarVizTheme = .darkCarbon
    ) {
        self.xLabel = xLabel
        self.valueA = valueA
        self.valueB = valueB
        self.labelA = labelA
        self.labelB = labelB
        self.theme = theme
    }

    private var diff: Double {
        valueA - valueB
    }

    private var percentageDiff: Double {
        if valueB == 0 {
            if valueA > 0 { return 100.0 }
            if valueA < 0 { return -100.0 }
            return 0.0
        }
        return ((valueA - valueB) / abs(valueB)) * 100.0
    }

    private var isPositive: Bool {
        diff >= 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(xLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(theme.secondaryTextColor)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(labelA)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                    Text(String(format: "%.1f", valueA))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryTextColor)
                }

                Divider()
                    .frame(height: 24)
                    .background(theme.borderColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(labelB)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryTextColor)
                    Text(String(format: "%.1f", valueB))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryTextColor)
                }
            }

            HStack(spacing: 4) {
                Text(isPositive ? "▲" : "▼")
                    .font(.system(size: 11, weight: .bold))
                Text(String(format: "%@%.1f%% (%@%.1f)", isPositive ? "+" : "", percentageDiff, isPositive ? "+" : "", diff))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundColor(isPositive ? Color.green : Color.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill((isPositive ? Color.green : Color.red).opacity(0.15))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.backgroundColor.opacity(theme.glassmorphismOpacity))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
