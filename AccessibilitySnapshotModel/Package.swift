// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// A model package with Foundation-based speech formatting and localization resources.
// It builds and tests without UIKit on macOS and Linux via `swift test`.
let package = Package(
    name: "AccessibilitySnapshotModel",
    defaultLocalization: "en",
    products: [
        .library(
            name: "AccessibilitySnapshotModel",
            targets: ["AccessibilitySnapshotModel"]
        ),
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotModel",
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "AccessibilitySnapshotModelTests",
            dependencies: ["AccessibilitySnapshotModel"]
        ),
    ]
)
