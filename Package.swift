// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Forge",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "Forge",
            path: "Forge",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ForgeTests",
            dependencies: [
                "Forge",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/ForgeTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
