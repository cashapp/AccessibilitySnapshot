// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AccessibilitySnapshot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        // Core + SnapshotTesting for image comparison
        .library(
            name: "AccessibilitySnapshot",
            targets: ["AccessibilitySnapshot"]
        ),
        .library(
            name: "FBSnapshotTestCase+Accessibility",
            targets: [
                "FBSnapshotTestCase+Accessibility",
                "FBSnapshotTestCase+Accessibility-ObjC",
            ]
        ),
        .library(
            name: "AccessibilitySnapshotCore",
            targets: ["AccessibilitySnapshotCore"]
        ),
    ],
    dependencies: [
        .package(
            name: "iOSSnapshotTestCase",
            url: "https://github.com/uber/ios-snapshot-test-case.git",
            .upToNextMajor(from: "8.0.0")
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
            dependencies: ["AccessibilitySnapshotCore", "iOSSnapshotTestCase"],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift"
        ),
        .target(
            name: "FBSnapshotTestCase+Accessibility-ObjC",
            dependencies: ["AccessibilitySnapshotCore", "iOSSnapshotTestCase", "FBSnapshotTestCase+Accessibility"],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC"
        ),
    ]
)
