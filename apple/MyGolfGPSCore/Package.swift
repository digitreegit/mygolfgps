// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyGolfGPSCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "MyGolfGPSCore", targets: ["MyGolfGPSCore"]),
    ],
    targets: [
        .target(
            name: "MyGolfGPSCore",
            path: "Sources/MyGolfGPSCore"
        ),
        .testTarget(
            name: "MyGolfGPSCoreTests",
            dependencies: ["MyGolfGPSCore"],
            path: "Tests/MyGolfGPSCoreTests"
        ),
    ]
)
