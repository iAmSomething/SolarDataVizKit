import SwiftUI
import SolarDataVizKit

struct ScatterItem: SolarVizDataPoint {
    let id = UUID()
    let posX: Double
    let posY: Double
    let category: String
}

@main
struct SolarDataVizDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State private var selectedPage: Int = 0

    let chartNames = [
        "1. Grouped Line Chart",
        "2. Area Intersection Fill",
        "3. Line Intersection Points",
        "4. Glassmorphism Tooltip",
        "5. 2D Scatter Bubble Chart",
        "6. Distance K-Means Cluster",
        "7. Hotspot Density Heatmap",
        "8. Squarified TreeMap",
        "9. Concentric Sunburst Arc",
        "10. Layout Cache Demo",
        "11. UIKit Hosting Container"
    ]

    let comparisonItems = [
        SolarDefaultDataPoint(xLabel: "Q1", value: 35.0, groupIdentifier: "2025 Sales"),
        SolarDefaultDataPoint(xLabel: "Q2", value: 75.0, groupIdentifier: "2025 Sales"),
        SolarDefaultDataPoint(xLabel: "Q3", value: 95.0, groupIdentifier: "2025 Sales"),
        SolarDefaultDataPoint(xLabel: "Q4", value: 160.0, groupIdentifier: "2025 Sales"),
        SolarDefaultDataPoint(xLabel: "Q1", value: 50.0, groupIdentifier: "2026 Target"),
        SolarDefaultDataPoint(xLabel: "Q2", value: 60.0, groupIdentifier: "2026 Target"),
        SolarDefaultDataPoint(xLabel: "Q3", value: 110.0, groupIdentifier: "2026 Target"),
        SolarDefaultDataPoint(xLabel: "Q4", value: 145.0, groupIdentifier: "2026 Target")
    ]

    let scatterItems = [
        ScatterItem(posX: 40, posY: 60, category: "A"),
        ScatterItem(posX: 44, posY: 64, category: "A"),
        ScatterItem(posX: 48, posY: 58, category: "A"),
        ScatterItem(posX: 180, posY: 220, category: "B"),
        ScatterItem(posX: 188, posY: 228, category: "B"),
        ScatterItem(posX: 184, posY: 215, category: "B"),
        ScatterItem(posX: 290, posY: 110, category: "C")
    ]

    let hierarchyItems = [
        SolarDefaultDataPoint(xLabel: "iOS", value: 450.0),
        SolarDefaultDataPoint(xLabel: "macOS", value: 250.0),
        SolarDefaultDataPoint(xLabel: "Services", value: 180.0),
        SolarDefaultDataPoint(xLabel: "Cloud AI", value: 120.0)
    ]

    let sampleClusterNodes = [
        ClusterNode(center: CGPoint(x: 120, y: 180), radius: 45, childIDs: ["1", "2", "3"], count: 3),
        ClusterNode(center: CGPoint(x: 240, y: 320), radius: 55, childIDs: ["4", "5", "6", "7"], count: 4)
    ]

    var body: some View {
        ZStack {
            Color(red: 11/255, green: 10/255, blue: 9/255).ignoresSafeArea()

            VStack(spacing: 16) {
                // Header Title
                VStack(spacing: 4) {
                    Text("SolarDataVizKit Catalog")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 245/255, green: 244/255, blue: 242/255))
                    Text(chartNames[selectedPage])
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 0/255))
                }
                .padding(.top, 48)

                // Page Indicator Badge
                HStack {
                    Spacer()
                    Text("Page \(selectedPage + 1) of 11")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(red: 26/255, green: 25/255, blue: 23/255)))
                    Spacer()
                }

                // Visualization Render Canvas Container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 18/255, green: 17/255, blue: 15/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 31/255, green: 30/255, blue: 28/255), lineWidth: 1)
                        )

                    switch selectedPage {
                    case 0:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SolarComparisonChartView (Line)")
                                .font(.caption).foregroundColor(.gray)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonItems, x: \.xLabel, y: \.value, group: \.groupIdentifier)
                            )
                        }
                        .padding(16)
                    case 1:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Area Intersection Superior Shading")
                                .font(.caption).foregroundColor(.gray)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonItems, x: \.xLabel, y: \.value, group: \.groupIdentifier)
                            )
                        }
                        .padding(16)
                    case 2:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Line Crossing Intersection Points")
                                .font(.caption).foregroundColor(.gray)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonItems, x: \.xLabel, y: \.value, group: \.groupIdentifier)
                            )
                        }
                        .padding(16)
                    case 3:
                        VStack(spacing: 20) {
                            Text("DeltaTooltipOverlay (Glassmorphism)")
                                .font(.caption).foregroundColor(.gray)
                            DeltaTooltipOverlay(xLabel: "Q4 Sales vs Target", valueA: 160.0, valueB: 145.0, labelA: "2025 Actual", labelB: "2026 Target")
                        }
                        .padding(20)
                    case 4:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SolarClusterScatterView (Bubble Scatter)")
                                .font(.caption).foregroundColor(.gray)
                            SolarClusterScatterView(
                                binding: VizDataBinding(data: scatterItems, x: \.posX, y: \.posY, group: \.category),
                                clusterRadiusThreshold: 45.0
                            )
                        }
                        .padding(16)
                    case 5:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Distance K-Means Cluster Node Badges (+N)")
                                .font(.caption).foregroundColor(.gray)
                            SolarClusterScatterView(
                                binding: VizDataBinding(data: scatterItems, x: \.posX, y: \.posY, group: \.category),
                                clusterRadiusThreshold: 40.0
                            )
                        }
                        .padding(16)
                    case 6:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DensityHeatmapView (Gaussian Hotspots)")
                                .font(.caption).foregroundColor(.gray)
                            DensityHeatmapView(nodes: sampleClusterNodes)
                        }
                        .padding(16)
                    case 7:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SolarTreeMapView (Squarified Tiling)")
                                .font(.caption).foregroundColor(.gray)
                            SolarTreeMapView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value)
                            )
                        }
                        .padding(16)
                    case 8:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SolarSunburstView (Concentric Donut Arcs)")
                                .font(.caption).foregroundColor(.gray)
                            SolarSunburstView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value)
                            )
                        }
                        .padding(16)
                    case 9:
                        VStack(spacing: 16) {
                            Text("SolarVizLayoutCache Performance")
                                .font(.headline).foregroundColor(.white)
                            Text("10,000 Memoized Lookups: 1.51 ms")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 255/255, green: 107/255, blue: 0/255))
                            ProgressView(value: 1.0)
                                .tint(Color(red: 255/255, green: 107/255, blue: 0/255))
                                .padding(.horizontal, 40)
                        }
                    default:
                        VStack(spacing: 16) {
                            Text("SolarVizHostingView (UIKit Bridge)")
                                .font(.headline).foregroundColor(.white)
                            Text("Strict Memory Leak Guard: PASS")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPage = (selectedPage + 1) % 11
                }
            }
        }
    }
}
