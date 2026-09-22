// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CourseDataSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
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
