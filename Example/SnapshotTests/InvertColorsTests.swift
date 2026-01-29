import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class InvertColorsTests: SnapshotTestCase {
    func testInvertColors() {
        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds

        FBSnapshotVerifyView(viewController.view, identifier: "disabled")

        SnapshotVerifyWithInvertedColors(viewController.view)

        // Run the plain snapshot a second time to ensure that the view was restored to its original state.
        FBSnapshotVerifyView(viewController.view, identifier: "disabled")
    }

    func testInvertColorsWithIdentifier() {
        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds

        SnapshotVerifyWithInvertedColors(viewController.view, identifier: "someIdentifier")
    }
}
