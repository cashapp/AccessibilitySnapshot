import Paralayout
import UIKit

final class NavBarBackButtonAccessibilityTraitsViewController: AccessibilityViewController {
    // MARK: - Public Properties

    init(titles: [String?] = [nil, nil]) {
        self.titles = titles
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var titles: [String?]

    // MARK: - Private Properties

    private var rootView: View {
        return view as! View
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View(titles: titles)
    }
}

// MARK: -

extension NavBarBackButtonAccessibilityTraitsViewController {
    final class Child: UIViewController {
        init(_ title: String? = nil) {
            super.init(nibName: nil, bundle: nil)
            self.title = title
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        let label = UILabel()

        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.hidesBackButton = false

            label.text = "Back Button Accessibility Traits - "
            label.text?.append(hasTitle ? "With Titles" : "Without Titles")
            view.addSubview(label)
        }

        private var hasTitle: Bool {
            title != nil
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            label.sizeToFit()
            let x = (view.bounds.width / 2) - (label.frame.size.width / 2)
            let y = (view.bounds.height / 2) - (label.frame.size.height / 2)
            label.frame = CGRect(origin: CGPoint(x: x, y: y), size: label.frame.size)
        }
    }
}

extension NavBarBackButtonAccessibilityTraitsViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        init(titles: [String?]) {
            self.titles = titles
            super.init(frame: .zero)
            addSubview(navView)
            navController.viewControllers = titles.map { Child($0) }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        var titles: [String?]

        let navController = UINavigationController()
        var navView: UIView {
            navController.view
        }

        // MARK: - Private Properties

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()
            navView.frame = bounds
        }
    }
}
