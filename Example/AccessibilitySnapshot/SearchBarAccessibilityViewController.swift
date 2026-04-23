import UIKit

/// Demonstrates a UINavigationController with a UISearchController attached, where the search
/// bar is rendered through SwiftUI bridging views that include a zero-frame wrapper.
final class SearchBarAccessibilityViewController: AccessibilityViewController {
    // MARK: - Life Cycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View()
    }
}

// MARK: -

extension SearchBarAccessibilityViewController {
    final class ContentViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Search Demo"
            view.backgroundColor = .white

            let searchController = UISearchController(searchResultsController: nil)
            searchController.obscuresBackgroundDuringPresentation = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false

            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 12
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(stackView)

            for i in 1 ... 3 {
                let label = UILabel()
                label.text = "Item \(i)"
                label.isAccessibilityElement = true
                stackView.addArrangedSubview(label)
            }

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            ])
        }
    }
}

extension SearchBarAccessibilityViewController {
    final class View: UIView {
        // MARK: - Life Cycle

        init() {
            super.init(frame: .zero)
            addSubview(navView)
            navController.viewControllers = [ContentViewController()]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        let navController = UINavigationController()
        var navView: UIView {
            navController.view
        }

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()
            navView.frame = bounds
        }
    }
}
