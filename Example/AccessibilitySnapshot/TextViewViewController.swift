import Paralayout
import UIKit

final class TextViewViewController: AccessibilityViewController {
    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }
}

// MARK: -

private extension TextViewViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            textViewWithText.text = "Hello from Text View"

            textInputViews.forEach {
                $0.layer.borderWidth = 1.0
                $0.layer.borderColor = UIColor.lightGray.cgColor
                addSubview($0)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let textViewEmpty: UITextView = .init()

        private let textViewFirstResponder: UITextView = .init()

        private let textViewWithText: UITextView = .init()

        private var textInputViews: [UIView] {
            return [
                textViewEmpty,
                textViewFirstResponder,
                textViewWithText,
            ]
        }

        // MARK: - UIView

        override func layoutSubviews() {
            textInputViews.forEach { $0.frame.size = CGSize(width: 250, height: 30) }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [statusBarHeight.fixed, 1.flexible]
            for subview in textInputViews {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)

            textViewFirstResponder.becomeFirstResponder()
        }
    }
}
