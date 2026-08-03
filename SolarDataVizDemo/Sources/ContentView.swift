import SwiftUI
import SolarDataVizKit

struct DemoDataPoint: SolarVizDataPoint {
    let id: String
    let xLabel: String
    let value: Double
    let category: String
}

@main
struct SolarDataVizDemoApp: App {
    var initialIndex: Int {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--chart-idx"), idx + 1 < args.count {
            return Int(args[idx + 1]) ?? 0
        }
        if let idx = args.firstIndex(of: "--tab"), idx + 1 < args.count {
            let name = args[idx + 1].lowercased()
            switch name {
            case "comparison": return 0
            case "clustering": return 4
            case "treemap": return 7
            case "sunburst": return 8
            default: return 0
            }
        }
        return 0
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selectedChartIndex: initialIndex)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State var selectedChartIndex: Int

    init(selectedChartIndex: Int = 0) {
        _selectedChartIndex = State(initialValue: selectedChartIndex)
    }

    let chartTitles = [
        "1. Grouped Line Comparison",
        "2. Heterogenous Dual Comparison",
        "3. Line Intersection Regions",
        "4. Dynamic Touch Delta Tooltip",
        "5. Distance Cluster Scatter",
        "6. Gaussian Density Heatmap",
        "7. Cluster Node Aggregator",
        "8. Squarified TreeMap Hierarchy",
        "9. Concentric Sunburst Donut",
        "10. Slice & Dice TreeMap Layout",
        "11. UIKit Hosting Wrapper"
    ]

    var comparisonData: [SolarDefaultDataPoint] {
        let seriesA = (0..<10).map { i in
            SolarDefaultDataPoint(xLabel: "M\(i)", value: Double(10 + i * 5), groupIdentifier: "Series A")
        }
        let seriesB = (0..<10).map { i in
            SolarDefaultDataPoint(xLabel: "M\(i)", value: Double(15 + i * 3), groupIdentifier: "Series B")
        }
        return seriesA + seriesB
    }

    var scatterItems: [DemoDataPoint] {
        (0..<40).map { i in
            DemoDataPoint(
                id: "\(i)",
                xLabel: "Pt_\(i)",
                value: Double(20 + (i * 17) % 180),
                category: "Group_\(i % 3)"
            )
        }
    }

    var hierarchyItems: [DemoDataPoint] {
        [
            DemoDataPoint(id: "1", xLabel: "iOS", value: 450.0, category: "Engineering"),
            DemoDataPoint(id: "2", xLabel: "macOS", value: 250.0, category: "Engineering"),
            DemoDataPoint(id: "3", xLabel: "Services", value: 180.0, category: "Cloud"),
            DemoDataPoint(id: "4", xLabel: "Cloud AI", value: 120.0, category: "Cloud")
        ]
    }

    var initialDragIndex: Int? {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--drag-index"), idx + 1 < args.count {
            return Int(args[idx + 1])
        }
        return nil
    }

    var initialSelectID: String? {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--select-id"), idx + 1 < args.count {
            return args[idx + 1]
        }
        return nil
    }

    var body: some View {
        ZStack {
            Color(red: 11/255, green: 10/255, blue: 9/255).ignoresSafeArea()

            VStack(spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SolarDataVizKit")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 245/255, green: 244/255, blue: 242/255))
                        Text("11 Core Visualization Engines Catalog")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 138/255, green: 136/255, blue: 133/255))
                    }
                    Spacer()
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 0/255))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // 11 Chart Engine Picker Menu
                Menu {
                    ForEach(0..<chartTitles.count, id: \.self) { idx in
                        Button(chartTitles[idx]) {
                            selectedChartIndex = idx
                        }
                    }
                } label: {
                    HStack {
                        Text(chartTitles[selectedChartIndex])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 26/255, green: 25/255, blue: 23/255))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 45/255, green: 43/255, blue: 40/255), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)

                // Visualization Canvas Container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 18/255, green: 17/255, blue: 15/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 31/255, green: 30/255, blue: 28/255), lineWidth: 1)
                        )

                    switch selectedChartIndex {
                    case 0:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 1: Grouped Comparison Line Chart")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonData, x: \.xLabel, y: \.value, group: \.groupIdentifier),
                                initialSelectedIndex: initialDragIndex
                            )
                        }
                        .padding(16)
                    case 1:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 2: Heterogenous Dual Comparison Chart")
                                .font(.headline).foregroundColor(.white)
                            SolarDualComparisonChartView(
                                bindingA: VizDataBinding(data: comparisonData.filter { $0.groupIdentifier == "Series A" }, x: \.xLabel, y: \.value),
                                bindingB: VizDataBinding(data: comparisonData.filter { $0.groupIdentifier == "Series B" }, x: \.xLabel, y: \.value),
                                labelA: "Sales",
                                labelB: "Expenses"
                            )
                        }
                        .padding(16)
                    case 2:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 3: Line Intersection Regions Calculator")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonData, x: \.xLabel, y: \.value, group: \.groupIdentifier)
                            )
                        }
                        .padding(16)
                    case 3:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 4: Dynamic Touch Delta Tooltip")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: comparisonData, x: \.xLabel, y: \.value, group: \.groupIdentifier),
                                initialSelectedIndex: 8
                            )
                        }
                        .padding(16)
                    case 4:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 5: Distance Cluster Scatter Plot")
                                .font(.headline).foregroundColor(.white)
                            SolarClusterScatterView(
                                binding: VizDataBinding(data: scatterItems, x: \.xLabel, y: \.value, group: \.category)
                            )
                        }
                        .padding(16)
                    case 5:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 6: Gaussian Density Heatmap Overlay")
                                .font(.headline).foregroundColor(.white)
                            DensityHeatmapView(
                                nodes: [
                                    ClusterNode(id: "n1", center: CGPoint(x: 120, y: 100), radius: 25, childIDs: ["1"], count: 10),
                                    ClusterNode(id: "n2", center: CGPoint(x: 180, y: 160), radius: 35, childIDs: ["2"], count: 18)
                                ]
                            )
                        }
                        .padding(16)
                    case 6:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 7: Centroid Cluster Node Aggregator")
                                .font(.headline).foregroundColor(.white)
                            SolarClusterScatterView(
                                binding: VizDataBinding(data: scatterItems, x: \.xLabel, y: \.value, group: \.category)
                            )
                        }
                        .padding(16)
                    case 7:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 8: Squarified TreeMap Hierarchy")
                                .font(.headline).foregroundColor(.white)
                            SolarTreeMapView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value),
                                initialSelectedTileID: initialSelectID
                            )
                        }
                        .padding(16)
                    case 8:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 9: Concentric Sunburst Arc Donut")
                                .font(.headline).foregroundColor(.white)
                            SolarSunburstView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value, group: \.category),
                                initialSelectedArcID: initialSelectID
                            )
                        }
                        .padding(16)
                    case 9:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 10: Slice & Dice TreeMap Strategy")
                                .font(.headline).foregroundColor(.white)
                            SolarTreeMapView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value)
                            )
                        }
                        .padding(16)
                    default:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 11: UIKit UIViewController Hosting Wrapper")
                                .font(.headline).foregroundColor(.white)
                            SolarTreeMapView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value)
                            )
                        }
                        .padding(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
