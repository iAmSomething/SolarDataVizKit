import SwiftUI

/// ## Quick View
/// `SolarClusterScatterView`는 2차원 산점도(Scatter Plot) 및 가변 버블 차트 상에서 근접 노드가 스프링 애니메이션으로 합쳐지는 클러스터링 시각화 컴포넌트입니다.
///
/// - **특징**:
///   - **Fluid Spring Morphing**: 노드가 뭉치고 분리될 때 물리 스프링 연출과 `+N` 숫자 뱃지 노출.
///   - **Cluster Snap Haptics**: 노드가 통합 합체되거나 분리될 때 탄성 `playClusterSnap()` 햅틱 피드백 발사.
///   - **Density Heatmap Integration**: 밀집 구역 핫스팟 배경 렌더링 지원.
///
/// ## 사용 예시
/// ```swift
/// SolarClusterScatterView(
///     binding: myScatterBinding,
///     clusterRadiusThreshold: 45.0
/// )
/// .solarVizTheme(.darkCarbon)
/// ```
public struct SolarClusterScatterView<
    Item: Identifiable & Sendable,
    XValue: BinaryFloatingPoint & Sendable,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let clusterRadiusThreshold: CGFloat

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var previousClusterCount: Int = 0
    @State private var nodes: [ClusterNode] = []

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        clusterRadiusThreshold: CGFloat = 40.0
    ) {
        self.binding = binding
        self.clusterRadiusThreshold = clusterRadiusThreshold
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Density Heatmap Layer
                DensityHeatmapView(nodes: nodes, theme: theme)

                // Cluster Nodes Layer
                ForEach(nodes) { node in
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.accentColor,
                                        theme.seriesColors.first ?? theme.accentColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: theme.accentColor.opacity(0.4), radius: node.isMerged ? 6 : 3)

                        if node.isMerged {
                            Text("+\(node.count)")
                                .font(.system(size: max(10, node.radius * 0.45), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: node.radius * 2, height: node.radius * 2)
                    .position(node.center)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(node.isMerged ? "Merged cluster node" : "Single data point")
                    .accessibilityValue("\(node.count) items")
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: nodes.count)
            .onChange(of: nodes.count) { newCount in
                if previousClusterCount != 0 && previousClusterCount != newCount {
                    Task { @MainActor in
                        SolarVizHaptics.shared.playClusterSnap()
                    }
                }
                previousClusterCount = newCount
            }
            .task(id: "\(binding.data.count)_\(clusterRadiusThreshold)_\(size.width)x\(size.height)") {
                await updateClustersOffMainThread(size: size)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .fill(environmentTheme.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: environmentTheme.cornerRadius)
                .stroke(environmentTheme.borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Cluster Scatter Plot")
        .accessibilityValue("\(nodes.count) cluster nodes, \(binding.data.count) total points")
    }

    private func updateClustersOffMainThread(size: CGSize) async {
        guard size.width > 0, size.height > 0 else { return }

        let cacheKey = "cluster_\(binding.data.count)_\(clusterRadiusThreshold)_\(Int(size.width))x\(Int(size.height))"
        if let cached = SolarVizLayoutCache.shared.getClusterNodes(forKey: cacheKey) {
            self.nodes = cached
            return
        }

        let localBinding = self.binding
        let radius = clusterRadiusThreshold
        let boundsX = xBounds()
        let boundsY = binding.yBounds()

        // Offload O(N^2) clustering to detached background thread
        let calculated = await Task.detached(priority: .userInitiated) { () -> [ClusterNode] in
            let points = localBinding.data.map { item -> (id: String, point: CGPoint, weight: Double) in
                let rawX = localBinding.extractX(from: item)
                let spanX = boundsX.max - boundsX.min
                let normX = spanX > 0 ? Double((rawX - boundsX.min) / spanX) : 0.5
                let normY = localBinding.normalizeY(value: localBinding.extractY(from: item), in: boundsY)

                let posX = 30 + CGFloat(normX) * (size.width - 60)
                let posY = size.height - 30 - CGFloat(normY) * (size.height - 60)
                return (id: String(describing: item.id), point: CGPoint(x: posX, y: posY), weight: 1.0)
            }
            return ClusterNodeCalculator.cluster(points: points, thresholdRadius: radius)
        }.value

        SolarVizLayoutCache.shared.setClusterNodes(calculated, forKey: cacheKey)
        self.nodes = calculated
    }

    private func xBounds() -> (min: XValue, max: XValue) {
        guard !binding.data.isEmpty else { return (0, 1) }
        var minX = binding.extractX(from: binding.data[0])
        var maxX = minX

        for item in binding.data {
            let val = binding.extractX(from: item)
            if val < minX { minX = val }
            if val > maxX { maxX = val }
        }
        if minX == maxX {
            minX = minX == 0 ? 0 : minX * 0.9
            maxX = maxX == 0 ? 1 : maxX * 1.1
        }
        return (minX, maxX)
    }

    private func normalize(val: XValue, min: XValue, max: XValue) -> Double {
        let span = max - min
        guard span > 0 else { return 0.5 }
        return Double((val - min) / span)
    }
}
