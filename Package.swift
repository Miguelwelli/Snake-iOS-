// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SnakeIOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SnakeIOS",
            targets: ["SnakeIOS"]
        ),
    ],
    targets: [
        .target(
            name: "SnakeIOS",
            dependencies: []
        ),
    ]
)
