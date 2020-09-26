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
        .library(name: "AccessibilitySnapshot", targets: ["AccessibilitySnapshot"]),
    ],
    dependencies: [
        /*
         facebook/fishhook (https://github.com/facebook/fishhook) does not currently support Swift Package Manager.
         
         A pull request is open (https://github.com/facebook/fishhook/pull/78) to add support at which point this dependency will be changed to the parent repository.
         */
        .package(url: "https://github.com/tsuiyuenhong/fishhook.git", .branch("support_spm"))
    ],
    targets: [
        .target(
            name: "AccessibilitySnapshot-ObjC",
            dependencies: ["fishhook"]
        ),
                
        .target(
            name: "AccessibilitySnapshot",
            dependencies: ["AccessibilitySnapshot-ObjC"]
        ),
        
        .testTarget(name: "UnitTests", dependencies: ["AccessibilitySnapshot"])
    ]
)
