import ProjectDescription

// MARK: - Constants

let deploymentTargets: DeploymentTargets = .iOS("13.0")

// MARK: - Helpers

/// Creates a scheme for the demo app with a specific language
func makeLanguageScheme(language: String, languageCode: String) -> Scheme {
    return .scheme(
        name: "AccessibilitySnapshotDemo (\(languageCode))",
        shared: true,
        buildAction: .buildAction(targets: [
            .target("AccessibilitySnapshotDemo"),
        ]),
        testAction: .targets(
            [
                .testableTarget(target: .target("SnapshotTests")),
                .testableTarget(target: .target("UnitTests")),
            ],
            expandVariableFromTarget: .target("AccessibilitySnapshotDemo"),
            skippedTests: [
                "AccessibilityContainersTests/testDataTableWithUndefinedColumns()",
                "AccessibilityContainersTests/testDataTableWithUndefinedRowsAndColumns()",
                "AccessibilitySnapshotTests/testLargeViewInViewControllerThatRequiresTiling()",
                "AccessibilitySnapshotTests/testLargeViewThatRequiresTiling()",
                "DefaultControlsTests/testDatePicker()",
                "HitTargetTests/testPerformance()",
                "TextAccessibilityTests",
            ]
        ),
        runAction: .runAction(
            configuration: .debug,
            executable: .target("AccessibilitySnapshotDemo"),
            arguments: .arguments(
                environmentVariables: [
                    "FB_REFERENCE_IMAGE_DIR": .environmentVariable(value: "$(SOURCE_ROOT)/SnapshotTests/ReferenceImages/", isEnabled: true),
                ]
            ),
            options: .options(language: .init(identifier: languageCode))
        )
    )
}

// MARK: - Project

let project = Project(
    name: "AccessibilitySnapshot",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["en", "de", "ru"],
        developmentRegion: "en"
    ),
    targets: [
        // MARK: - Library Targets

        .target(
            name: "AccessibilitySnapshotParser_ObjC",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotParser-ObjC",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/Parser/ObjC/**/*.{h,m}"],
            headers: .headers(
                public: ["../Sources/AccessibilitySnapshot/Parser/ObjC/include/*.h"]
            ),
            settings: .settings(
                base: [
                    "CLANG_ENABLE_MODULES": "YES",
                    "DEFINES_MODULE": "NO",
                    "MODULEMAP_FILE": "$(SRCROOT)/../Tuist/ModuleMaps/Parser/module.modulemap",
                ]
            )
        ),

        .target(
            name: "AccessibilitySnapshotParser",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotParser",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/Parser/Swift/Classes/**/*.swift"],
            resources: [
                "../Sources/AccessibilitySnapshot/Parser/Swift/Assets/**/*",
            ],
            dependencies: [
                .target(name: "AccessibilitySnapshotParser_ObjC"),
            ]
        ),

        .target(
            name: "AccessibilitySnapshotCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotCore",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/Core/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotParser"),
            ]
        ),

        .target(
            name: "AccessibilitySnapshot",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshot",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/SnapshotTesting/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotParser_ObjC"),
                .external(name: "SnapshotTesting"),
            ],
            settings: .settings(
                base: [
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                ]
            )
        ),

        .target(
            name: "FBSnapshotTestCase_Accessibility",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.FBSnapshotTestCase-Accessibility",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/iOSSnapshotTestCase/Swift/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotParser_ObjC"),
                .external(name: "iOSSnapshotTestCase"),
            ],
            settings: .settings(
                base: [
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                ]
            )
        ),

        .target(
            name: "FBSnapshotTestCase_Accessibility_ObjC",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.FBSnapshotTestCase-Accessibility-ObjC",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC/**/*.{h,m}"],
            headers: .headers(
                public: ["../Sources/AccessibilitySnapshot/iOSSnapshotTestCase/ObjC/include/*.h"]
            ),
            dependencies: [
                .target(name: "FBSnapshotTestCase_Accessibility"),
            ],
            settings: .settings(
                base: [
                    "CLANG_ENABLE_MODULES": "YES",
                    "DEFINES_MODULE": "NO",
                    "MODULEMAP_FILE": "$(SRCROOT)/../Tuist/ModuleMaps/iOSSnapshotTestCase/module.modulemap",
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                ]
            )
        ),

        // MARK: - Demo App

        .target(
            name: "AccessibilitySnapshotDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.cashapp.AccessibilitySnapshotDemo",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "UIMainStoryboardFile": "",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [:],
                ],
            ]),
            sources: ["AccessibilitySnapshot/**/*.swift"],
            resources: [
                "AccessibilitySnapshot/**/*.xib",
                "AccessibilitySnapshot/**/*.strings",
                "AccessibilitySnapshot/**/*.xcassets",
            ],
            dependencies: [
                .external(name: "Paralayout"),
                .target(name: "AccessibilitySnapshotCore"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "TUIST_BUILD",
                ]
            )
        ),

        // MARK: - Snapshot Tests

        .target(
            name: "SnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.cashapp.SnapshotTests",
            deploymentTargets: deploymentTargets,
            sources: ["SnapshotTests/**/*.{swift,m}"],
            headers: .headers(
                project: ["SnapshotTests/Supporting Files/*.h"]
            ),
            dependencies: [
                .target(name: "AccessibilitySnapshotDemo"),
                .target(name: "AccessibilitySnapshot"),
                .target(name: "FBSnapshotTestCase_Accessibility"),
                .target(name: "FBSnapshotTestCase_Accessibility_ObjC"),
                .external(name: "iOSSnapshotTestCase"),
                .xctest,
            ],
            settings: .settings(
                base: [
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(SRCROOT)/SnapshotTests/Supporting Files/SnapshotTests-Bridging-Header.h",
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                    "OTHER_LDFLAGS": "$(inherited) -ObjC",
                ]
            )
        ),

        // MARK: - Unit Tests

        .target(
            name: "UnitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.cashapp.UnitTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .file(path: "UnitTests/Supporting Files/Info.plist"),
            sources: ["UnitTests/**/*.{swift,m}"],
            headers: .headers(
                project: ["UnitTests/Supporting Files/*.h"]
            ),
            dependencies: [
                .target(name: "AccessibilitySnapshotDemo"),
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotParser"),
                .target(name: "AccessibilitySnapshotParser_ObjC"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(SRCROOT)/UnitTests/Supporting Files/UnitTests-Bridging-Header.h",
                    "OTHER_LDFLAGS": "$(inherited) -ObjC"
                ]
            )
        ),
    ],
    schemes: [
        ("English", "en"),
        ("German", "de"),
        ("Russian", "ru"),
    ].map { makeLanguageScheme(language: $0.0, languageCode: $0.1) }
)
