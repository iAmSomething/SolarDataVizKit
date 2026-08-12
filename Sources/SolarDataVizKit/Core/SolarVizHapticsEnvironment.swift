import SwiftUI

private struct SolarVizHapticsEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true  // 기본값: 활성화
}

extension EnvironmentValues {
    public var solarVizHapticsEnabled: Bool {
        get { self[SolarVizHapticsEnabledKey.self] }
        set { self[SolarVizHapticsEnabledKey.self] = newValue }
    }
}

extension View {
    /// 차트 인터랙션 햅틱 피드백의 활성/비활성을 제어합니다.
    public func solarVizHaptics(enabled: Bool) -> some View {
        environment(\.solarVizHapticsEnabled, enabled)
    }
}
