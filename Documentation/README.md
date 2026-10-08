AccessibilitySnapshot is split into two layers: the core accessibility parser and an integration layer using a snapshotting engine. This is reflected in the package's library structure:

- **`AccessibilitySnapshotCore`** - The core accessibility parser
- **`AccessibilitySnapshot`** - Integration with [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing)

The `AccessibilitySnapshotCore` library contains the accessibility parser and utilities for generating a container view to snapshot that includes a legend showing each of the accessibility elements in the view. The [Core Architecture](Core-Architecture.md) page contains more details on the different components that make up this library.

The other two libraries contain integration layers built on top of the parser that provide simple snapshotting via iOSSnapshotTestCase and SnapshotTesting, respectively. Instructions for getting started with these can be found in the [Usage](https://github.com/cashapp/AccessibilitySnapshot/blob/main/README.md#usage) section of the README.

Alternative integration layers can be built on top of the core parser by depending only on `AccessibilitySnapshotCore`. A list of these can be found in the [Extensions](https://github.com/cashapp/AccessibilitySnapshot/blob/main/README.md#extensions) section of the README.
