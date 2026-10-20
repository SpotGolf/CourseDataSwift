// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "CourseDataSwift",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .watchOS(.v27)
    ],
    products: [
        .library(name: "CourseDataSwift", targets: ["CourseDataSwift"])
    ],
    targets: [
        .target(
            name: "CourseDataSwift",
            path: "Sources"
        ),
        .testTarget(
            name: "CourseDataSwiftTests",
            dependencies: ["CourseDataSwift"],
            path: "Tests"
        )
    ]
)
