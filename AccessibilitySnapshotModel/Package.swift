// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// A dependency-free model package. It imports no platform frameworks, so it builds and tests on
// any Swift toolchain — including macOS and Linux via `swift test` — and the host package consumes
// it through a local path dependency.
let package = Package(
    name: "AccessibilitySnapshotModel",
    products: [
        .library(
            name: "AccessibilitySnapshotModel",
            targets: ["AccessibilitySnapshotModel"]
        ),
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotModel"
        ),
        .testTarget(
            name: "AccessibilitySnapshotModelTests",
            dependencies: ["AccessibilitySnapshotModel"]
        ),
    ]
)
