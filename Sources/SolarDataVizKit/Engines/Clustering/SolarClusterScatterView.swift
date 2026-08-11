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
    XValue: Hashable & Sendable,
    YValue: BinaryFloatingPoint & Sendable
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let clusterRadiusThreshold: CGFloat

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @State private var previousClusterCount: Int = 0
    @State private var nodes: [ClusterNode] = []
    @State private var heatmapNodes: [ClusterNode] = []

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
                // Density Heatmap Layer (Single-pass Canvas rasterization with 0 body sorting)
                DensityHeatmapView(nodes: heatmapNodes)

                // Cluster Nodes Layer
                ForEach(nodes) { node in
                    clusterNodeView(node: node, theme: theme)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: nodes)
            .onChange(of: nodes.count) { newCount in
                if previousClusterCount != 0 && previousClusterCount != newCount {
                    Task { @MainActor in
                        SolarVizHaptics.shared.playClusterSnap()
                    }
                }
                previousClusterCount = newCount
            }
            .task(id: "\(binding.dataHash)_\(clusterRadiusThreshold)_\(size.width)x\(size.height)") {
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

    @ViewBuilder
    private func clusterNodeView(node: ClusterNode, theme: SolarVizTheme) -> some View {
        let radius = node.radius
        let count = node.count
        let isMerged = node.isMerged

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            theme.accentColor,
                            theme.accentColor.opacity(0.6)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)

            if isMerged {
                let fontSize = max(radius * 0.5, 10.0)
                let badgeText = "+\(count)"
                Text(badgeText)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(theme.primaryTextColor)
            }
        }
        .position(node.center)
    }

    private func updateClustersOffMainThread(size: CGSize) async {
        guard size.width > 0, size.height > 0 else { return }

        let cacheKey = "cluster_\(binding.dataHash)_\(clusterRadiusThreshold)_\(Int(size.width))x\(Int(size.height))"
        if let cached = SolarVizLayoutCache.shared.getClusterNodes(forKey: cacheKey) {
            self.nodes = cached
            return
        }

        let localBinding = self.binding
        let radius = clusterRadiusThreshold
        let boundsY = binding.yBounds()

        // Offload clustering to background thread supporting both Numeric and Categorical (String/Date) XValues
        let (calculatedNodes, sortedHeatmap) = await Task.detached(priority: .userInitiated) { () -> ([ClusterNode], [ClusterNode]) in
            let allNums = localBinding.data.compactMap { Double(String(describing: localBinding.extractX(from: $0))) }
            let minVal = allNums.min() ?? 0.0
            let maxVal = allNums.max() ?? 1.0
            let span = maxVal - minVal

            let distinctX = Array(Set(localBinding.data.map { localBinding.extractX(from: $0) }))
            let points = localBinding.data.enumerated().map { (idx, item) -> (id: String, point: CGPoint, weight: Double) in
                let rawX = localBinding.extractX(from: item)
                let normX: Double

                if let numX = Double(String(describing: rawX)) {
                    normX = span > 0 ? (numX - minVal) / span : 0.5
                } else {
                    let catIdx = distinctX.firstIndex(of: rawX) ?? 0
                    let count = max(distinctX.count, 1)
                    normX = count > 1 ? Double(catIdx) / Double(count - 1) : 0.5
                }

                let normY = localBinding.normalizeY(value: localBinding.extractY(from: item), in: boundsY)
                let posX = 30 + CGFloat(normX) * (size.width - 60)
                let posY = size.height - 30 - CGFloat(normY) * (size.height - 60)
                return (id: String(describing: item.id), point: CGPoint(x: posX, y: posY), weight: 1.0)
            }
            let resNodes = ClusterNodeCalculator.cluster(points: points, thresholdRadius: radius)
            let resHeatmap = Array(resNodes.sorted(by: { $0.count > $1.count }).prefix(250))
            return (resNodes, resHeatmap)
        }.value

        SolarVizLayoutCache.shared.setClusterNodes(calculatedNodes, forKey: cacheKey)
        withAnimation(.easeOut(duration: 0.3)) {
            self.nodes = calculatedNodes
            self.heatmapNodes = sortedHeatmap
        }
    }
}
