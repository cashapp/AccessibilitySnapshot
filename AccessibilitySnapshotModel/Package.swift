// swift-tools-version:5.7

import PackageDescription

// Standalone manifest for the portable, UIKit-free accessibility model.
//
// The model is intentionally free of UIKit / CoreGraphics so it can build and be tested on any
// platform (macOS, Linux) — see the "Model Tests (macOS)" CI job, which runs
// `swift test --package-path AccessibilitySnapshotModel`. Without this manifest, that command
// resolves the repository-root `Package.swift`, which pulls in the UIKit-dependent snapshot
// targets and fails to build on macOS with `'UIKit/UIKit.h' file not found`.
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
            name: "AccessibilitySnapshotModel",
            path: "Sources/AccessibilitySnapshotModel"
        ),
        .testTarget(
            name: "AccessibilitySnapshotModelTests",
            dependencies: ["AccessibilitySnapshotModel"],
            path: "Tests/AccessibilitySnapshotModelTests"
        ),
    ]
)
