// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// A model package with Foundation-based speech formatting and localization resources.
// It builds and tests without UIKit on macOS and Linux via `swift test`.
let package = Package(
    name: "AccessibilityHierarchyModel",
    defaultLocalization: "en",
    products: [
        .library(
            name: "AccessibilityHierarchyModel",
            targets: ["AccessibilityHierarchyModel"]
        ),
    ],
    targets: [
        .target(
            name: "AccessibilityHierarchyModel",
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "AccessibilityHierarchyModelTests",
            dependencies: ["AccessibilityHierarchyModel"]
        ),
    ]
)
