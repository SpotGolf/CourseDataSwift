// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CourseData",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "CourseData", targets: ["CourseData"])
    ],
    targets: [
        .target(
            name: "CourseData",
            path: "Sources"
        ),
        .testTarget(
            name: "CourseDataTests",
            dependencies: ["CourseData"],
            path: "Tests"
        )
    ]
)
