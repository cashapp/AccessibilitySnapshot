// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if TUIST
    import ProjectDescription

    let iOSProducts = ["iOSSnapshotTestCase", "iOSSnapshotTestCaseCore", "Paralayout"]

    // Xcode 27 rejects iOS deployment targets below 15.0, which these packages still declare.
    let deploymentTargetSetting: SettingsDictionary = ["IPHONEOS_DEPLOYMENT_TARGET": "15.0"]

    let packageSettings = PackageSettings(
        productDestinations: Dictionary(uniqueKeysWithValues: iOSProducts.map { ($0, Destinations.iOS) }),
        targetSettings: [
            "iOSSnapshotTestCase": deploymentTargetSetting.merging(["ENABLE_TESTING_SEARCH_PATHS": "YES"]) { $1 },
            "iOSSnapshotTestCaseCore": deploymentTargetSetting,
            "Paralayout": deploymentTargetSetting,
            "SnapshotTesting": deploymentTargetSetting,
        ]
    )
#endif

let package = Package(
    name: "AccessibilitySnapshot",
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
