// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AccessibilitySnapshot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        // Core + SnapshotTesting for image comparison
        .library(
            name: "AccessibilitySnapshot",
            targets: ["AccessibilitySnapshot"]
        ),
        
        .library(
            name: "AccessibilitySnapshotCore",
            targets: ["AccessibilitySnapshotCore"]
        ),
    ],
    dependencies: [
        /*
         fishhook (https://github.com/facebook/fishhook) does not currently support Swift Package Manager.
         
         A pull request is open (https://github.com/facebook/fishhook/pull/78) to add support at which point this dependency will be changed to the parent repository.
         */
        .package(
            url: "https://github.com/Sherlouk/fishhook.git",
            .revision("82375ca9b43fab575d8d42a930cf617184c47ac1")
        ),
        
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            .upToNextMajor(from: "1.8.0")
        )
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshotCore-ObjC",
            dependencies: ["fishhook"],
            swiftSettings: [
                .define("SWIFT_PACKAGE_MANAGER")
            ]
        ),
                
        .target(
            name: "AccessibilitySnapshotCore",
            dependencies: ["AccessibilitySnapshotCore-ObjC"]
        ),
        
        .target(
            name: "AccessibilitySnapshot",
            dependencies: ["AccessibilitySnapshotCore", "SnapshotTesting"],
            path: "Sources/AccessibilitySnapshot/SnapshotTesting"
        ),
        
        .testTarget(
            name: "UnitTests",
            dependencies: ["AccessibilitySnapshotCore"]
        )
    ]
)
