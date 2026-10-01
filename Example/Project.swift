import ProjectDescription

// MARK: - Constants

// Xcode 27 rejects iOS deployment targets below 15.0.
let deploymentTargets: DeploymentTargets = .iOS("15.0")

// MARK: - Host Variants

/// The demo app that hosts the snapshot and unit tests comes in two variants, since the iOS 27 SDK requires the scene
/// life cycle and the hosting window affects how snapshots render (a window that isn't attached to a scene reports no
/// status bar, for example). Each variant gets its own app, test targets, and schemes.
enum HostVariant: CaseIterable {
    /// The app delegate owns the window. Used with toolchains before Xcode 27.
    case legacy

    /// A scene delegate owns the window. Required from Xcode 27 on.
    case scenes

    var suffix: String {
        switch self {
        case .legacy: return ""
        case .scenes: return "Scenes"
        }
    }

    var appName: String { "AccessibilitySnapshotDemo\(suffix)" }
    var snapshotTestsName: String { "SnapshotTests\(suffix)" }
    var unitTestsName: String { "UnitTests\(suffix)" }

    var appSources: SourceFilesList {
        switch self {
        case .legacy:
            return ["AccessibilitySnapshot/**/*.swift"]
        case .scenes:
            return .sourceFilesList(globs: [
                .glob("AccessibilitySnapshot/**/*.swift", excluding: ["AccessibilitySnapshot/AppDelegate.swift"]),
                .glob("AccessibilitySnapshotScenes/**/*.swift"),
            ])
        }
    }

    var sceneConfigurations: Plist.Value {
        switch self {
        case .legacy:
            return [:]
        case .scenes:
            return [
                "UIWindowSceneSessionRoleApplication": [
                    [
                        "UISceneConfigurationName": "Default Configuration",
                        "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                    ],
                ],
            ]
        }
    }
}

// MARK: - Helpers

/// Creates the demo app and the test targets it hosts for a host variant.
func makeDemoTargets(for variant: HostVariant) -> [Target] {
    return [
        .target(
            name: variant.appName,
            destinations: .iOS,
            product: .app,
            bundleId: "com.cashapp.\(variant.appName)",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "UIMainStoryboardFile": "",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": variant.sceneConfigurations,
                ],
            ]),
            sources: variant.appSources,
            resources: [
                "AccessibilitySnapshot/**/*.xib",
                "AccessibilitySnapshot/**/*.strings",
                "AccessibilitySnapshot/**/*.xcassets",
            ],
            dependencies: [
                .external(name: "Paralayout"),
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotPreviews"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "TUIST_BUILD",
                    "DEVELOPMENT_TEAM": SettingValue.string(Environment.developmentTeam.getString(default: "")),
                    // Both variants share a module name so the tests' `@testable import AccessibilitySnapshotDemo`
                    // resolves against whichever variant hosts them.
                    "PRODUCT_MODULE_NAME": "AccessibilitySnapshotDemo",
                ]
            )
        ),

        .target(
            name: variant.snapshotTestsName,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.cashapp.\(variant.snapshotTestsName)",
            deploymentTargets: deploymentTargets,
            sources: ["SnapshotTests/**/*.{swift,m}"],
            headers: .headers(
                project: ["SnapshotTests/Supporting Files/*.h"]
            ),
            dependencies: [
                .target(name: variant.appName),
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

        .target(
            name: variant.unitTestsName,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.cashapp.\(variant.unitTestsName)",
            deploymentTargets: deploymentTargets,
            infoPlist: .file(path: "UnitTests/Supporting Files/Info.plist"),
            sources: ["UnitTests/**/*.{swift,m}"],
            headers: .headers(
                project: ["UnitTests/Supporting Files/*.h"]
            ),
            dependencies: [
                .target(name: variant.appName),
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotParser"),
                .target(name: "AccessibilitySnapshotParser_ObjC"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_OBJC_BRIDGING_HEADER": "$(SRCROOT)/UnitTests/Supporting Files/UnitTests-Bridging-Header.h",
                    "OTHER_LDFLAGS": "$(inherited) -ObjC",
                ]
            )
        ),
    ]
}

/// Creates a scheme for a host variant's demo app with a specific language
func makeLanguageScheme(language: String, languageCode: String, variant: HostVariant) -> Scheme {
    return .scheme(
        name: "\(variant.appName) (\(languageCode))",
        shared: true,
        buildAction: .buildAction(targets: [
            .target(variant.appName),
        ]),
        testAction: .targets(
            [
                .testableTarget(target: .target(variant.snapshotTestsName)),
                .testableTarget(target: .target(variant.unitTestsName)),
            ],
            expandVariableFromTarget: .target(variant.appName),
            skippedTests: [
                "AccessibilityContainersTests/testDataTableWithUndefinedColumns()",
                "AccessibilityContainersTests/testDataTableWithUndefinedRowsAndColumns()",
                "AccessibilitySnapshotTests/testLargeViewInViewControllerThatRequiresTiling()",
                "AccessibilitySnapshotTests/testLargeViewThatRequiresTiling()",
                "DefaultControlsTests/testDatePicker()",
                "HitTargetTests/testPerformance()",
            ]
        ),
        runAction: .runAction(
            configuration: .debug,
            executable: .target(variant.appName),
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
            name: "AccessibilitySnapshotModel",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotModel",
            deploymentTargets: deploymentTargets,
            sources: ["../AccessibilitySnapshotModel/Sources/AccessibilitySnapshotModel/**/*.swift"]
        ),

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
                .target(name: "AccessibilitySnapshotModel"),
                .target(name: "AccessibilitySnapshotParser_ObjC"),
            ]
        ),

        .target(
            name: "AccessibilitySnapshotCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotCore",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/Core/**/*.swift"],
            resources: [
                "../Sources/AccessibilitySnapshot/Core/Assets/**/*",
            ],
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
                .target(name: "AccessibilitySnapshotPreviews"),
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
                .target(name: "AccessibilitySnapshotPreviews"),
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

        .target(
            name: "AccessibilitySnapshotPreviews",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.cashapp.AccessibilitySnapshotPreviews",
            deploymentTargets: deploymentTargets,
            sources: ["../Sources/AccessibilitySnapshot/AccessibilitySnapshotPreviews/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotCore"),
                .target(name: "AccessibilitySnapshotParser"),
            ]
        ),

        // MARK: - AccessibilitySnapshotPreviews Demo App

        .target(
            name: "AccessibilitySnapshotPreviewsDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.cashapp.AccessibilitySnapshotPreviewsDemo",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [:],
                ],
            ]),
            sources: ["AccessibilitySnapshotPreviewsDemo/**/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotPreviews"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": SettingValue.string(Environment.developmentTeam.getString(default: "")),
                ]
            )
        ),

        // MARK: - AccessibilitySnapshotPreviews Tests

        .target(
            name: "AccessibilitySnapshotPreviewsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.cashapp.AccessibilitySnapshotPreviewsTests",
            deploymentTargets: .iOS("18.0"),
            sources: ["AccessibilitySnapshotPreviewsTests/**/*.swift"],
            dependencies: [
                .target(name: "AccessibilitySnapshotPreviewsDemo"),
                .target(name: "FBSnapshotTestCase_Accessibility"),
                .external(name: "iOSSnapshotTestCase"),
                .xctest,
            ],
            settings: .settings(
                base: [
                    "ENABLE_TESTING_SEARCH_PATHS": "YES",
                ]
            )
        ),

        // MARK: - Demo Apps, Snapshot Tests, and Unit Tests

    ] + HostVariant.allCases.flatMap { makeDemoTargets(for: $0) },
    schemes: HostVariant.allCases.flatMap { variant in
        [
            ("English", "en"),
            ("German", "de"),
            ("Russian", "ru"),
        ].map { makeLanguageScheme(language: $0.0, languageCode: $0.1, variant: variant) }
    } + [
        .scheme(
            name: "AccessibilitySnapshotPreviewsDemo",
            shared: true,
            buildAction: .buildAction(targets: [
                .target("AccessibilitySnapshotPreviewsDemo"),
            ]),
            testAction: .targets(
                [
                    .testableTarget(target: .target("AccessibilitySnapshotPreviewsTests")),
                ],
                expandVariableFromTarget: .target("AccessibilitySnapshotPreviewsDemo")
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: .target("AccessibilitySnapshotPreviewsDemo"),
                arguments: .arguments(
                    environmentVariables: [
                        "FB_REFERENCE_IMAGE_DIR": .environmentVariable(value: "$(SOURCE_ROOT)/AccessibilitySnapshotPreviewsTests/ReferenceImages/", isEnabled: true),
                    ]
                )
            )
        ),
    ]
)
