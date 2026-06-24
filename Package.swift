// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AccessibilitySnapshot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
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
            name: "AccessibilitySnapshotModel",
            targets: ["AccessibilitySnapshotModel"]
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
        .package(
            name: "iOSSnapshotTestCase",
            url: "https://github.com/uber/ios-snapshot-test-case.git",
            .upToNextMajor(from: "8.0.0")
        ),
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .upToNextMajor(from: "1.10.0")
        ),
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotModel",
            path: "AccessibilitySnapshotModel/Sources/AccessibilitySnapshotModel"
        ),
        .target(
            name: "AccessibilitySnapshotParser-ObjC",
            path: "Sources/AccessibilitySnapshot/Parser/ObjC"
        ),
        .target(
            name: "AccessibilitySnapshotParser",
            dependencies: ["AccessibilitySnapshotModel", "AccessibilitySnapshotParser-ObjC"],
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
                "SnapshotTesting",
            ],
            path: "Sources/AccessibilitySnapshot/SnapshotTesting"
        ),
        .target(
            name: "FBSnapshotTestCase-Accessibility",
            dependencies: [
                "AccessibilitySnapshotCore",
                "AccessibilitySnapshotParser-ObjC",
                "AccessibilitySnapshotPreviews",
                "iOSSnapshotTestCase",
            ],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift"
        ),
        .target(
            name: "FBSnapshotTestCase-Accessibility-ObjC",
            dependencies: ["AccessibilitySnapshotCore", "iOSSnapshotTestCase", "FBSnapshotTestCase-Accessibility"],
            path: "Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC"
        ),
    ]
)
