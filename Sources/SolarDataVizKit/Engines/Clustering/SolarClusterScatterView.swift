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
    XValue: SolarPlottable,
    YValue: BinaryFloatingPoint & Sendable,
    Placeholder: View
>: View {
    public let binding: VizDataBinding<Item, XValue, YValue>
    public let clusterRadiusThreshold: CGFloat

    @Environment(\.solarVizTheme) private var environmentTheme: SolarVizTheme
    @Environment(\.solarVizHapticsEnabled) private var hapticsEnabled
    @State private var previousClusterCount: Int = 0
    @State private var nodes: [ClusterNode] = []
    @State private var heatmapNodes: [ClusterNode] = []
    
    private let placeholder: () -> Placeholder
    public var onNodeSelected: (([Item]) -> Void)?

    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        clusterRadiusThreshold: CGFloat = 40.0,
        onNodeSelected: (([Item]) -> Void)? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.binding = binding
        self.clusterRadiusThreshold = clusterRadiusThreshold
        self.onNodeSelected = onNodeSelected
        self.placeholder = placeholder
    }

    public var body: some View {
        let theme = environmentTheme

        GeometryReader { geometry in
            Group {
                if geometry.size.width > 10 && geometry.size.height > 10 {
                    if nodes.isEmpty {
                        placeholder()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        ZStack {
                            // Density Heatmap Layer (Single-pass Canvas rasterization with 0 body sorting)
                            DensityHeatmapView(nodes: heatmapNodes)

                            // Cluster Nodes Layer
                            ForEach(nodes) { node in
                                clusterNodeView(node: node, theme: theme)
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: nodes)
            .onChange(of: nodes.count) { newCount in
                if previousClusterCount != 0 && previousClusterCount != newCount {
                    Task { @MainActor in
                    if hapticsEnabled {
                        SolarVizHaptics.shared.playClusterSnap()
                    }
                    }
                }
                previousClusterCount = newCount
            }
            .task(id: "\(binding.versionToken)_\(clusterRadiusThreshold)_\(geometry.size.width)x\(geometry.size.height)") {
                await updateClustersOffMainThread(size: geometry.size)
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
        .accessibilityLabel("Cluster")
        .accessibilityValue("\(count) items")
        .frame(width: radius * 2, height: radius * 2)
        .position(node.center)
        .onTapGesture {
            // Reconstruct items from bindings
            let items = binding.data.filter { item in
                let nodeIDs = node.childIDs
                return nodeIDs.contains(String(describing: item.id))
            }
            onNodeSelected?(items)
            Task { @MainActor in
                if hapticsEnabled {
                    SolarVizHaptics.shared.playSelection()
                }
            }
        }
    }

    private func updateClustersOffMainThread(size: CGSize) async {
        guard size.width > 0, size.height > 0 else { return }

        let cacheKey = "cluster_\(binding.versionToken)_\(clusterRadiusThreshold)_\(Int(size.width))x\(Int(size.height))"
        if let cached = await SolarVizLayoutCache.shared.getClusterNodes(forKey: cacheKey) {
            self.nodes = cached
            return
        }

        let localBinding = self.binding
        let radius = clusterRadiusThreshold
        let boundsY = binding.yBounds()

        // Offload clustering to background thread supporting both Numeric and Categorical (String/Date) XValues
        let (calculatedNodes, sortedHeatmap) = await Task.detached(priority: .userInitiated) { () -> ([ClusterNode], [ClusterNode]) in
            let allNums = localBinding.data.map { localBinding.extractX(from: $0).asPlotValue }
            let minVal = allNums.min() ?? 0.0
            let maxVal = allNums.max() ?? 1.0
            let span = maxVal - minVal

            let distinctX = Array(Set(localBinding.data.map { localBinding.extractX(from: $0) }))
            let points = localBinding.data.enumerated().map { (idx, item) -> (id: String, point: CGPoint, weight: Double) in
                let rawX = localBinding.extractX(from: item)
                let normX: Double
                let numX = rawX.asPlotValue
                if span > 0 {
                    normX = (numX - minVal) / span
                } else {
                    normX = 0.5
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

        await SolarVizLayoutCache.shared.setClusterNodes(calculatedNodes, forKey: cacheKey)
        withAnimation(SolarVizAnimation.clusterMerge) {
            self.nodes = calculatedNodes
            self.heatmapNodes = sortedHeatmap
        }
    }
}

// MARK: - Backward Compatibility Init
extension SolarClusterScatterView where Placeholder == EmptyView {
    public init(
        binding: VizDataBinding<Item, XValue, YValue>,
        clusterRadiusThreshold: CGFloat = 40.0,
        onNodeSelected: (([Item]) -> Void)? = nil
    ) {
        self.init(binding: binding, clusterRadiusThreshold: clusterRadiusThreshold, onNodeSelected: onNodeSelected, placeholder: { EmptyView() })
    }
}
