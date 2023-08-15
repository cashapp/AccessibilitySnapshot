AccessibilitySnapshot is split into two layers: the core accessibility parser and an integration layer using a snapshotting engine. This is reflected in the pod's three subspecs: the `Core` subspec for the accessibility parser, and the `iOSSnapshotTestCase` and `SnapshotTesting` subspecs for the two available integration layers.

The `Core` subspec contains the accessibility parser and utilities for generating a container view to snapshot that includes a legend showing each of the accessibility elements in the view. The [Core Architecture](Core-Architecture.md) page contains more details on the different components that make up this subspec.

The other two subspecs contain integration layers built on top of the parser that provide simple snapshotting via the iOSSnapshotTestCase and SnapshotTesting framework, respectively. Instructions for getting started with these can be found in the [Usage](https://github.com/cashapp/AccessibilitySnapshot/blob/master/README.md#usage) section of the README.

Alternative integration layers can be built on top of the core parser by depending only on the `Core` subspec. A list of these can be found in the [Extensions](https://github.com/cashapp/AccessibilitySnapshot/blob/master/README.md#extensions) section of the README.
