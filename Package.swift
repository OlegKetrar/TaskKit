// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TaskKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
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
