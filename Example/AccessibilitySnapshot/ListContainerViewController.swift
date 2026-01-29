import Paralayout
import UIKit

final class ListContainerViewController: AccessibilityViewController {
    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }
}

// MARK: -

private extension ListContainerViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            views = (1 ..< 5).map {
                let label = UILabel()
                label.text = "Label \($0)"
                return label
            }

            super.init(frame: frame)

            views.forEach(addSubview)

            accessibilityElements = views
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let views: [UILabel]

        // MARK: - UIView

        override func layoutSubviews() {
            views.forEach { $0.sizeToFit() }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [statusBarHeight.fixed, 1.flexible]
            for subview in views {
                distributionSpecifiers.append(subview.distributionItemUsingCapInsets)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }

        // MARK: - UIAccessibility

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get {
                return .list
            }
            set {
                // No-op.
            }
        }
    }
}
