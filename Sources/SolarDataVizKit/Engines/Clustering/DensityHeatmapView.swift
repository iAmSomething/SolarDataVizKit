import SwiftUI

/// ## Quick View
/// `DensityHeatmapView`는 산점도 상의 군집 노드 밀집도 지역을 가우시안 블러 및 틴트 그래디언트 핫스팟으로 시각화하는 오버레이 뷰입니다.
///
/// - **특징**:
///   - **Gaussian Blur Hotspots**: 노드가 밀집할수록 더 강렬한 틴트 그래디언트 핫스팟 오버레이 연출.
///   - **Theme Integrated**: `SolarVizTheme` 액센트 색상 계열의 서브 파형 시각화.
///
/// ## 사용 예시
/// ```swift
/// DensityHeatmapView(nodes: clusterNodes, theme: .darkCarbon)
/// ```
public struct DensityHeatmapView: View {
    public let nodes: [ClusterNode]
    public let theme: SolarVizTheme

    public init(nodes: [ClusterNode], theme: SolarVizTheme = .darkCarbon) {
        self.nodes = nodes
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            ForEach(nodes) { node in
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.accentColor.opacity(node.isMerged ? 0.35 : 0.15),
                        theme.accentColor.opacity(0.0)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: node.radius * 2.5
                )
                .frame(width: node.radius * 5.0, height: node.radius * 5.0)
                .position(node.center)
                .blur(radius: 8)
            }
        }
    }
}
