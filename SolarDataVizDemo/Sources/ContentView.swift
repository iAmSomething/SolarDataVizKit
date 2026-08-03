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

    private var initialBayesPreset: Int {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--bayes-preset"), idx + 1 < args.count {
            return Int(args[idx + 1]) ?? 0
        }
        return 0
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selectedChartIndex: initialIndex, initialBayesPreset: initialBayesPreset)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State var selectedChartIndex: Int
    @State private var bayesianPresetIndex: Int

    init(selectedChartIndex: Int = 0, initialBayesPreset: Int = 0) {
        _selectedChartIndex = State(initialValue: selectedChartIndex)
        _bayesianPresetIndex = State(initialValue: initialBayesPreset)
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
        "11. UIKit Hosting Wrapper",
        "12. Bayesian Numerical Trend & Uncertainty Band"
    ]
    var bayesianFriendlyData: [SolarDefaultDataPoint] {
        let xs = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let ys = [12.0, 19.0, 22.0, 35.0, 41.0, 50.0, 58.0, 69.0, 75.0, 91.0]
        return xs.indices.map { SolarDefaultDataPoint(xLabel: String(xs[$0]), value: ys[$0]) }
    }

    var bayesianEvilVolatileData: [SolarDefaultDataPoint] {
        let xs = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let ys = [5.0, 85.0, 12.0, 140.0, 25.0, 190.0, 30.0, 220.0, 45.0, 310.0]
        return xs.indices.map { SolarDefaultDataPoint(xLabel: String(xs[$0]), value: ys[$0]) }
    }

    var bayesianZeroVarianceData: [SolarDefaultDataPoint] {
        let xs = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let ys = [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0]
        return xs.indices.map { SolarDefaultDataPoint(xLabel: String(xs[$0]), value: ys[$0]) }
    }

    var groupedComparisonData: [SolarDefaultDataPoint] {
        let rev = [40.0, 55.0, 65.0, 80.0, 75.0, 95.0, 110.0, 105.0, 125.0, 140.0]
        let exp = [30.0, 42.0, 50.0, 60.0, 70.0, 78.0, 85.0, 90.0, 98.0, 105.0]
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct"]

        var list: [SolarDefaultDataPoint] = []
        for i in 0..<months.count {
            list.append(SolarDefaultDataPoint(xLabel: months[i], value: rev[i], groupIdentifier: "Revenue ($K)"))
            list.append(SolarDefaultDataPoint(xLabel: months[i], value: exp[i], groupIdentifier: "Expenses ($K)"))
        }
        return list
    }

    var dualSalesData: [SolarDefaultDataPoint] {
        let months = ["Q1", "Q2", "Q3", "Q4"]
        let sales = [120.0, 240.0, 380.0, 450.0]
        return months.indices.map { SolarDefaultDataPoint(xLabel: months[$0], value: sales[$0], groupIdentifier: "Sales") }
    }

    var dualUsersData: [SolarDefaultDataPoint] {
        let months = ["Q1", "Q2", "Q3", "Q4"]
        let users = [15.0, 42.0, 75.0, 98.0]
        return months.indices.map { SolarDefaultDataPoint(xLabel: months[$0], value: users[$0], groupIdentifier: "Users") }
    }

    var intersectionWaveData: [SolarDefaultDataPoint] {
        let months = ["M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8"]
        let waveA = [10.0, 80.0, 20.0, 90.0, 30.0, 85.0, 40.0, 95.0]
        let waveB = [70.0, 15.0, 75.0, 25.0, 80.0, 35.0, 85.0, 45.0]

        var list: [SolarDefaultDataPoint] = []
        for i in 0..<months.count {
            list.append(SolarDefaultDataPoint(xLabel: months[i], value: waveA[i], groupIdentifier: "Series Alpha"))
            list.append(SolarDefaultDataPoint(xLabel: months[i], value: waveB[i], groupIdentifier: "Series Beta"))
        }
        return list
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
                            Text("Engine 1: Grouped Line Comparison Chart")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: groupedComparisonData, x: \.xLabel, y: \.value, group: \.groupIdentifier),
                                seriesA: "Revenue ($K)",
                                seriesB: "Expenses ($K)",
                                initialSelectedIndex: initialDragIndex
                            )
                        }
                        .padding(16)
                    case 1:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 2: Heterogenous Dual Comparison Chart")
                                .font(.headline).foregroundColor(.white)
                            SolarDualComparisonChartView(
                                bindingA: VizDataBinding(data: dualSalesData, x: \.xLabel, y: \.value),
                                bindingB: VizDataBinding(data: dualUsersData, x: \.xLabel, y: \.value),
                                labelA: "Quarterly Sales ($K)",
                                labelB: "Active Users (K)"
                            )
                        }
                        .padding(16)
                    case 2:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 3: Line Intersection Regions Calculator")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: intersectionWaveData, x: \.xLabel, y: \.value, group: \.groupIdentifier),
                                seriesA: "Series Alpha",
                                seriesB: "Series Beta",
                                showIntersectionRegions: true
                            )
                        }
                        .padding(16)
                    case 3:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 4: Dynamic Touch Delta Tooltip")
                                .font(.headline).foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(data: groupedComparisonData, x: \.xLabel, y: \.value, group: \.groupIdentifier),
                                seriesA: "Revenue ($K)",
                                seriesB: "Expenses ($K)",
                                initialSelectedIndex: 5
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
                    case 10:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Engine 11: UIKit UIViewController Hosting Wrapper")
                                .font(.headline).foregroundColor(.white)
                            SolarTreeMapView(
                                binding: VizDataBinding(data: hierarchyItems, x: \.xLabel, y: \.value)
                            )
                        }
                        .padding(16)
                    default:
                        let currentData = bayesianPresetIndex == 0 ? bayesianFriendlyData : (bayesianPresetIndex == 1 ? bayesianEvilVolatileData : bayesianZeroVarianceData)
                        let presetTitle = bayesianPresetIndex == 0 ? "1. Friendly Growth Trend" : (bayesianPresetIndex == 1 ? "2. Evil Volatile Outlier Spikes" : "3. Zero-Variance Flat Line Defense")

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Engine 12: Bayesian Numerical Trend")
                                    .font(.headline).foregroundColor(.white)
                                Spacer()
                                Text(presetTitle)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }

                            HStack(spacing: 8) {
                                Button("Friendly") { bayesianPresetIndex = 0 }
                                    .buttonStyle(.borderedProminent)
                                    .tint(bayesianPresetIndex == 0 ? .orange : .gray)

                                Button("Evil Spikes") { bayesianPresetIndex = 1 }
                                    .buttonStyle(.borderedProminent)
                                    .tint(bayesianPresetIndex == 1 ? .red : .gray)

                                Button("Zero Var") { bayesianPresetIndex = 2 }
                                    .buttonStyle(.borderedProminent)
                                    .tint(bayesianPresetIndex == 2 ? .blue : .gray)
                            }
                            .font(.system(size: 11, weight: .bold))

                            SolarBayesianTrendView(
                                binding: VizDataBinding(data: currentData, x: \.value, y: \.value),
                                title: presetTitle
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
