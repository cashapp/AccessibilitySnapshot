// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AccessibilitySnapshot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .visionOS(.v1),
    ],
    products: [
        // Core + SnapshotTesting for image comparison
        .library(
            name: "AccessibilitySnapshot",
            targets: ["AccessibilitySnapshot"]
        ),
        .library(
            name: "FBSnapshotTestCase-Accessibility",
            targets: [
                "FBSnapshotTestCase-Accessibility",
                "FBSnapshotTestCase-Accessibility-ObjC",
            ]
        ),
        .library(
            name: "AccessibilitySnapshotCore",
            targets: ["AccessibilitySnapshotCore"]
        ),
        .library(
            name: "AccessibilitySnapshotParser",
            targets: ["AccessibilitySnapshotParser"]
        ),
        .library(
            name: "AccessibilitySnapshotPreviews",
            targets: ["AccessibilitySnapshotPreviews"]
        ),
    ],
    dependencies: [
        .package(path: "AccessibilitySnapshotModel"),
        .package(
            url: "https://github.com/uber/ios-snapshot-test-case.git",
            .upToNextMajor(from: "8.0.0")
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .upToNextMajor(from: "1.10.0")
        ),
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotParser-ObjC",
            path: "Sources/AccessibilitySnapshot/Parser/ObjC"
        ),
        .target(
            name: "AccessibilitySnapshotParser",
            dependencies: [
                .product(name: "AccessibilitySnapshotModel", package: "AccessibilitySnapshotModel"),
                "AccessibilitySnapshotParser-ObjC",
            ],
            path: "Sources/AccessibilitySnapshot/Parser/Swift",
            resources: [.process("Assets")]
        ),
        .target(
            name: "AccessibilitySnapshotCore",
            dependencies: ["AccessibilitySnapshotParser"],
            path: "Sources/AccessibilitySnapshot/Core",
            resources: [.process("Assets")]
        ),
        .target(
            name: "AccessibilitySnapshotPreviews",
            dependencies: ["AccessibilitySnapshotCore", "AccessibilitySnapshotParser"],
            path: "Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews"
        ),
        .target(
            name: "AccessibilitySnapshot",
            dependencies: [
                "AccessibilitySnapshotCore",
                "AccessibilitySnapshotParser-ObjC",
                "AccessibilitySnapshotPreviews",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Sources/AccessibilitySnapshot/SnapshotTesting"
        ),
        .target(
            name: "FBSnapshotTestCase-Accessibility",
            dependencies: [
                "AccessibilitySnapshotCore",
                "AccessibilitySnapshotParser-ObjC",
                "AccessibilitySnapshotPreviews",
                .product(name: "iOSSnapshotTestCase", package: "ios-snapshot-test-case"),
            ],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift"
        ),
        .target(
            name: "FBSnapshotTestCase-Accessibility-ObjC",
            dependencies: [
                "AccessibilitySnapshotCore",
                .product(name: "iOSSnapshotTestCase", package: "ios-snapshot-test-case"),
                "FBSnapshotTestCase-Accessibility",
            ],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC"
        ),
    ]
)
