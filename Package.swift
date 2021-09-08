// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AccessibilitySnapshot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        // Core + SnapshotTesting for image comparison
        .library(
            name: "AccessibilitySnapshot",
            targets: ["AccessibilitySnapshot"]
        ),
        .library(
            name: "FBSnapshotTestCase+Accessibility",
            targets: ["FBSnapshotTestCase+Accessibility"]
        ),
        .library(
            name: "AccessibilitySnapshotCore",
            targets: ["AccessibilitySnapshotCore"]
        ),
    ],
    dependencies: [
        .package(
            name: "FBSnapshotTestCase",
            url: "https://github.com/uber/ios-snapshot-test-case.git",
            .upToNextMajor(from: "7.0.0")
        ),
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .upToNextMajor(from: "1.8.0")
        ),
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotCore-ObjC",
            path: "Sources/AccessibilitySnapshot/Core/ObjC"
        ),
        .target(
            name: "AccessibilitySnapshotCore",
            dependencies: ["AccessibilitySnapshotCore-ObjC"],
            path: "Sources/AccessibilitySnapshot/Core/Swift"
        ),
        .target(
            name: "AccessibilitySnapshot",
            dependencies: ["AccessibilitySnapshotCore", "SnapshotTesting"],
            path: "Sources/AccessibilitySnapshot/SnapshotTesting"
        ),
        .target(
            name: "FBSnapshotTestCase+Accessibility",
            dependencies: ["AccessibilitySnapshotCore", "FBSnapshotTestCase"],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift"
        ),
        .target(
            name: "FBSnapshotTestCase+Accessibility-ObjC",
            dependencies: ["AccessibilitySnapshotCore", "FBSnapshotTestCase", "FBSnapshotTestCase+Accessibility"],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC"
        ),
    ]
)
