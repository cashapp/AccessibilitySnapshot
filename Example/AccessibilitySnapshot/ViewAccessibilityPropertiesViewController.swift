import Paralayout
import UIKit

//  ┌──────────────────────────────────────────────────────────────────────────────┐
//  │                                                                              │
//  │                        View Accessibility Properties                         │
//  │                                                                              │
//  ├────┬─────────┬─────────┬─────────┬─────────┬─────────────────────────────────┤
//  │ ## │  label  │  value  │  hint   │ element │      VoiceOver Description      │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 01 │         │         │         │  true   │ ""                              │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 02 │    X    │         │         │  true   │ "Label"                         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 03 │         │    X    │         │  true   │ "Value"                         │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 04 │         │         │    X    │  true   │ "Hint"                          │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 05 │    X    │    X    │         │  true   │ "Label: Value"                  │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 06 │    X    │         │    X    │  true   │ "Label", "Hint"                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 07 │         │    X    │    X    │  true   │ "Value", "Hint"                 │
//  ├────┼─────────┼─────────┼─────────┼─────────┼─────────────────────────────────┤
//  │ 08 │    X    │    X    │    X    │  true   │ "Label: Value", "Hint"          │
//  └────┴─────────┴─────────┴─────────┴─────────┴─────────────────────────────────┘
final class ViewAccessibilityPropertiesViewController: AccessibilityViewController {
    // MARK: - Private Properties

    private let views = (0 ..< 8).map { _ in UIView() }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in views {
            subview.backgroundColor = .lightGray
            subview.isAccessibilityElement = true
            view.addSubview(subview)
        }

        // View with no accessibility description.
        views[0].accessibilityLabel = nil
        views[0].accessibilityValue = nil
        views[0].accessibilityHint = nil

        // View with label.
        views[1].accessibilityLabel = "Label"
        views[1].accessibilityValue = nil
        views[1].accessibilityHint = nil

        // View with value.
        views[2].accessibilityLabel = nil
        views[2].accessibilityValue = "Value"
        views[2].accessibilityHint = nil

        // View with hint.
        views[3].accessibilityLabel = nil
        views[3].accessibilityValue = nil
        views[3].accessibilityHint = "Hint"

        // View with label and value.
        views[4].accessibilityLabel = "Label"
        views[4].accessibilityValue = "Value"
        views[4].accessibilityHint = nil

        // View with label and hint.
        views[5].accessibilityLabel = "Label"
        views[5].accessibilityValue = nil
        views[5].accessibilityHint = "Hint"

        // View with value and hint.
        views[6].accessibilityLabel = nil
        views[6].accessibilityValue = "Value"
        views[6].accessibilityHint = "Hint"

        // View with label, value, and hint.
        views[7].accessibilityLabel = "Label"
        views[7].accessibilityValue = "Value"
        views[7].accessibilityHint = "Hint"
    }
}

extension ViewAccessibilityPropertiesViewController {
    final class View: UIView {
        // MARK: - UIView

        override func layoutSubviews() {
            for subview in subviews {
                subview.bounds.size = CGSize(width: 30, height: 30)
                subview.layer.cornerRadius = 15
            }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [statusBarHeight.fixed, 1.flexible]
            for subview in subviews {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }
    }
}
