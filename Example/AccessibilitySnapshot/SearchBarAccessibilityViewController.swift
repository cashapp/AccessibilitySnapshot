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

    // MARK: - Private Properties

    private var rootView: View {
        return view as! View
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

            let label = UILabel()
            label.text = "Content below search bar"
            label.isAccessibilityElement = true
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
