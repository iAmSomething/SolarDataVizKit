// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolarDataVizKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SolarDataVizKit",
            targets: ["SolarDataVizKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.11")
    ],
    targets: [
        .target(
            name: "SolarDataVizKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SolarDataVizKitTests",
            dependencies: [
                "SolarDataVizKit",
                .product(name: "ViewInspector", package: "ViewInspector")
            ]
        )
    ]
)
