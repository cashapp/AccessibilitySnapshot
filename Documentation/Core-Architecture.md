The core accessibility parsing and presentation logic lives in the `Core` subspec. In most cases, consumers will interact with an integration layer built on top of the core parser that performs the actual snapshot recording and comparison. The following are the primary classes in the public API of the core parser with which the integration layer will interact.

* `AnimationSnapshotView` - This is a container view around the view being snapshotted. It contains a snapshot of the view and the views that make up the highlights and legend.

The `AnimationSnapshotView` is the only class the integration layer needs to interact with to output snapshot images of the accessibility hierarchy. For non-view-based integrations, the `AccessibilityHierarchyParser` is the main integration point.

* `AccessibilityHierarchyParser` - This is where all of the parsing logic lives. It has a single exposed method that returns an array of accessibility markers.

* `ASAccessibilityEnabler` - This class enabled accessibility on the simulator. The logic in this class is triggered in the `+load` method, so there shouldn't generally be work in the integration layer to activate it. If the logic in this class isn't run, many of the accessibility properties won't be automatically populated by UIKit, resulting in missing data.

In addition to the accessibility hierarchy parsing logic, the `Core` subspec also contains a few points of interaction for snapshotting with inverted colors and (the currently in-progress #4) dynamic type:

* `UIAccessibilityStatusUtility` - This is used to mock the Invert Colors setting.

* `UIView.drawHierarchyWithInvertedColors(in:using:)` - This extension does the actual drawing.

* `UIView+DynamicTypeSnapshotting`/`UIApplication+DynamicTypeSnapshotting` - These are used to mock the Dynamic Type setting.
