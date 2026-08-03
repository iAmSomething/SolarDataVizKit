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
    var initialTab: Int {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "--tab"), idx + 1 < args.count {
            let name = args[idx + 1].lowercased()
            switch name {
            case "clustering": return 1
            case "treemap": return 2
            case "sunburst": return 3
            default: return 0
            }
        }
        return 0
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: initialTab)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @State var selectedTab: Int

    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }

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
        (0..<30).map { i in
            DemoDataPoint(
                id: "\(i)",
                xLabel: "Cat_\(i % 5)",
                value: Double(20 + (i * 15) % 200),
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

            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SolarDataVizKit")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 245/255, green: 244/255, blue: 242/255))
                        Text("Live iOS Simulator Demonstration")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 138/255, green: 136/255, blue: 133/255))
                    }
                    Spacer()
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title)
                        .foregroundColor(Color(red: 255/255, green: 107/255, blue: 0/255))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Segmented Picker
                Picker("Engine", selection: $selectedTab) {
                    Text("Comparison").tag(0)
                    Text("Clustering").tag(1)
                    Text("TreeMap").tag(2)
                    Text("Sunburst").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                // Visualization Canvas Container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 18/255, green: 17/255, blue: 15/255))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 31/255, green: 30/255, blue: 28/255), lineWidth: 1)
                        )

                    switch selectedTab {
                    case 0:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Grouped Comparison Engine")
                                .font(.headline)
                                .foregroundColor(.white)
                            SolarComparisonChartView(
                                binding: VizDataBinding(
                                    data: comparisonData,
                                    x: \.xLabel,
                                    y: \.value,
                                    group: \.groupIdentifier
                                ),
                                initialSelectedIndex: initialDragIndex
                            )
                        }
                        .padding(16)
                    case 1:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Distance Cluster Scatter Engine")
                                .font(.headline)
                                .foregroundColor(.white)
                            SolarClusterScatterView(
                                binding: VizDataBinding(
                                    data: scatterItems,
                                    x: \.xLabel,
                                    y: \.value,
                                    group: \.category
                                )
                            )
                        }
                        .padding(16)
                    case 2:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Squarified TreeMap Engine")
                                .font(.headline)
                                .foregroundColor(.white)
                            SolarTreeMapView(
                                binding: VizDataBinding(
                                    data: hierarchyItems,
                                    x: \.xLabel,
                                    y: \.value
                                ),
                                initialSelectedTileID: initialSelectID
                            )
                        }
                        .padding(16)
                    default:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Concentric Sunburst Arc Engine")
                                .font(.headline)
                                .foregroundColor(.white)
                            SolarSunburstView(
                                binding: VizDataBinding(
                                    data: hierarchyItems,
                                    x: \.xLabel,
                                    y: \.value,
                                    group: \.category
                                ),
                                initialSelectedArcID: initialSelectID
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
