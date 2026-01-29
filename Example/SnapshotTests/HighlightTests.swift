import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import UIKit

final class HighlightTests: SnapshotTestCase {
    func testColors() {
        let view = AccessibleContainerView(count: 8, innerMargin: 10)
        view.sizeToFit()

        SnapshotVerifyAccessibility(view)
    }

    func testOverlap() {
        let view = AccessibleContainerView(count: 8, innerMargin: -5)
        view.sizeToFit()

        SnapshotVerifyAccessibility(view)
    }

    func testColorInSnapshot() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()

        SnapshotVerifyAccessibility(
            view,
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .fullColor)
        )
    }
}
