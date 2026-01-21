// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if TUIST
import ProjectDescription

let iOSProducts = ["iOSSnapshotTestCase", "iOSSnapshotTestCaseCore", "Paralayout"]

let packageSettings = PackageSettings(
    productDestinations: Dictionary(uniqueKeysWithValues: iOSProducts.map { ($0, Destinations.iOS) }),
    targetSettings: [
        "iOSSnapshotTestCase": [
            "ENABLE_TESTING_SEARCH_PATHS": "YES"
        ],
    ]
)
#endif

let package = Package(
    name: "AccessibilitySnapshotTuist",
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
        .package(
            name: "Paralayout",
            url: "https://github.com/square/Paralayout.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ]
)