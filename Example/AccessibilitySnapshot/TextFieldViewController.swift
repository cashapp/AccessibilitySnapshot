import Paralayout
import UIKit

final class TextFieldViewController: AccessibilityViewController {
    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }
}

// MARK: -

private extension TextFieldViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            textFieldWithPlaceholder.placeholder = "Some placeholder text"

            textFieldWithText.text = "Hello from Text Field"

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

        private let textFieldEmpty: UITextField = .init()

        private let textFieldFirstResponder: UITextField = .init()

        private let textFieldWithPlaceholder: UITextField = .init()

        private let textFieldWithText: UITextField = .init()

        private var textInputViews: [UIView] {
            return [
                textFieldEmpty,
                textFieldFirstResponder,
                textFieldWithPlaceholder,
                textFieldWithText,
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

            textFieldFirstResponder.becomeFirstResponder()
        }
    }
}
