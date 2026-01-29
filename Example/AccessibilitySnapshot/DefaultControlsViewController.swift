import Paralayout
import UIKit

final class DefaultControlsViewController: AccessibilityViewController {
    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }
}

// MARK: -

private extension DefaultControlsViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            pageControl.numberOfPages = 3
            pageControl.pageIndicatorTintColor = .lightGray
            pageControl.currentPageIndicatorTintColor = .black

            segmentedControl.insertSegment(withTitle: "Segment A", at: 0, animated: false)
            segmentedControl.insertSegment(withTitle: "Segment B", at: 1, animated: false)
            segmentedControl.insertSegment(withTitle: "Segment C", at: 2, animated: false)

            slider.minimumValue = 0
            slider.maximumValue = 100
            slider.value = 75

            stepper.minimumValue = -1
            stepper.maximumValue = 1
            stepper.value = 0

            controls.forEach { addSubview($0) }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let datePicker: UIDatePicker = .init()

        private let pageControl: UIPageControl = .init()

        private let segmentedControl: UISegmentedControl = .init()

        private let slider: UISlider = .init()

        private let stepper: UIStepper = .init()

        private var controls: [UIControl] {
            return [
                datePicker,
                pageControl,
                segmentedControl,
                slider,
                stepper,
            ]
        }

        // MARK: - UIView

        override func layoutSubviews() {
            controls.forEach { $0.sizeToFit() }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [statusBarHeight.fixed, 1.flexible]
            for subview in controls {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }
    }
}
