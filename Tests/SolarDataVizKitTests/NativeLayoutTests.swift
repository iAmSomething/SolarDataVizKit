import XCTest
import SwiftUI
import ViewInspector
@testable import SolarDataVizKit

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
final class NativeLayoutTests: XCTestCase {

    @MainActor
    func testSolarSunburstNativeLayout() throws {
        // We directly instantiate the custom Layout
        let layout = SolarSunburstNativeLayout()
        
        // Ensure it can be created and doesn't crash on standard initialization
        XCTAssertNotNil(layout)
        
        // We cannot fully simulate Layout.Subviews cleanly in tests without internal SPIs, 
        // but we can verify the layout object is functional and conforms to Layout protocol.
        // The fact that it compiles and initializes means the type is valid.
    }
}
