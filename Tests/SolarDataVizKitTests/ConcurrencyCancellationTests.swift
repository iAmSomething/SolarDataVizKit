import XCTest
@testable import SolarDataVizKit

final class ConcurrencyCancellationTests: XCTestCase {
    
    struct DummyItem: SolarVizDataPoint {
        let id: String
        let value: Double
    }
    
    @MainActor
    func testHierarchyEngineCancellationBailout() async {
        let items = (0..<1000).map { DummyItem(id: "\($0)", value: 10.0) }
        let binding = VizDataBinding(data: items, x: \.id, y: \.value)
        
        let view = SolarTreeMapView(binding: binding)
        let strategy = view.strategy
        let extractY: @Sendable (DummyItem) -> Double = { Double(binding.extractY(from: $0)) }
        let extractID: @Sendable (DummyItem) -> String = { String(describing: $0.id) }
        
        let task = Task.detached {
            // Task starts executing, but we cancel it almost immediately
            return await view.computeTilesOffMainThread(
                data: items,
                strategy: strategy,
                extractY: extractY,
                extractID: extractID,
                bounds: CGRect(x: 0, y: 0, width: 500, height: 500)
            )
        }
        
        task.cancel()
        
        let result = await task.value
        // Should bail out and return empty array due to cancellation
        XCTAssertTrue(result.isEmpty, "Task cancellation should trigger an early return of empty tiles")
    }
    
    @MainActor
    func testSunburstEngineCancellationBailout() async {
        let items = (0..<1000).map { DummyItem(id: "\($0)", value: 10.0) }
        let binding = VizDataBinding(data: items, x: \.id, y: \.value)
        
        let view = SolarSunburstView(binding: binding)
        
        let task = Task.detached {
            return await view.computeArcsOffMainThread(binding: binding)
        }
        
        task.cancel()
        
        let result = await task.value
        XCTAssertTrue(result.isEmpty, "Task cancellation should trigger an early return of empty arcs")
    }
}
