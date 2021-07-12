// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TaskKit",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "TaskKit",
            targets: ["TaskKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TaskKit",
            dependencies: [],
            path: "Sources"),

        .testTarget(
            name: "TaskKitTests",
            dependencies: ["TaskKit"],
            path: "Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
