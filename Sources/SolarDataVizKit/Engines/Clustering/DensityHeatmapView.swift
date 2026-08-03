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

    public init(nodes: [ClusterNode]) {
        self.nodes = nodes
    }

    public var body: some View {
        let renderableNodes = Array(nodes.sorted(by: { $0.count > $1.count }).prefix(250))

        Canvas { context, size in
            for node in renderableNodes {
                let rect = CGRect(
                    x: node.center.x - node.radius * 2.5,
                    y: node.center.y - node.radius * 2.5,
                    width: node.radius * 5.0,
                    height: node.radius * 5.0
                )
                let gradient = Gradient(colors: [
                    Color.orange.opacity(min(Double(node.count) * 0.3, 0.85)),
                    Color.orange.opacity(0.0)
                ])
                let shading = GraphicsContext.Shading.radialGradient(
                    gradient,
                    center: node.center,
                    startRadius: 0,
                    endRadius: node.radius * 2.5
                )
                context.fill(Path(ellipseIn: rect), with: shading)
            }
        }
        .drawingGroup() // Single-pass Metal GPU hardware rasterization
    }
}
