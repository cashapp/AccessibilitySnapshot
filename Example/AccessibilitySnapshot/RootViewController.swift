import SwiftUI
import UIKit

final class RootViewController: UITableViewController, UISearchResultsUpdating {
    // MARK: - Private Properties

    private let allScreens: [(String, (UIViewController) -> UIViewController)]
    private var filteredScreens: [(String, (UIViewController) -> UIViewController)]

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Life Cycle

    init() {
        var accessibilityScreens = [
            ("View Accessibility Properties", { _ in ViewAccessibilityPropertiesViewController() }),
            ("Label Accessibility Properties", { _ in LabelAccessibilityPropertiesViewController() }),
            ("Nav Bar Back Button Accessibility Traits", { _ in NavBarBackButtonAccessibilityTraitsViewController() }),
            ("Button Accessibility Traits", { _ in ButtonAccessibilityTraitsViewController() }),
            ("Default UIKit Controls", { _ in DefaultControlsViewController() }),
            ("UISwitch Controls", { _ in SwitchControlViewController() }),
            ("Tab Bar", { _ in TabBarViewController() }),
            ("Description Edge Cases", { _ in DescriptionEdgeCasesViewController() }),
            ("Element Selection", { presentingViewController in
                ElementSelectionViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Element Order", { presentingViewController in
                ElementOrderViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Element Frame Comparison", { _ in ElementFrameComparisonController() }),
            ("Element Order with Semantic Content", { _ in UserIntefaceDirectionViewController() }),
            ("Modal Accessibility Views", { presentingViewController in
                ModalAccessibilityViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Accessibility Paths", { _ in AccessibilityPathViewController() }),
            ("Accessibility Activation Point", { _ in ActivationPointViewController() }),
            ("Accessibility Custom Actions", { _ in AccessibilityCustomActionsViewController() }),
            ("Accessibility Custom Rotors", { _ in AccessibilityCustomRotorsViewController() }),
            ("Data Table", { presentingViewController in
                DataTableViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("List Container", { _ in ListContainerViewController() }),
            ("Landmark Container", { _ in LandmarkContainerViewController() }),
            ("Invert Colors", { _ in InvertColorsViewController() }),
            ("User Input Labels", { _ in UserInputLabelsViewController() }),
            ("Text Field", { _ in TextFieldViewController() }),
            ("Text View", { _ in TextViewViewController() }),
            ("SwiftUI Text Entry", { _ in UIHostingController(rootView: SwiftUITextEntry()) }),
        ]

        if #available(iOS 14.0, *) {
            accessibilityScreens.append(("Accessibility Custom Content", { _ in AccessibilityCustomContentViewController() }))
        }
        if #available(iOS 15.0, *) {
            accessibilityScreens.append(("Swipe Actions (SwiftUI)", { _ in UIHostingController(rootView: SwiftUISwipeActionsDemo()) }))
        }
        if #available(iOS 17.0, *) {
            accessibilityScreens.append(("Block based accessors", { _ in BlockBasedAccessibilityViewController() }))
        }
        accessibilityScreens.append(("Keyboard Shortcuts (With Categories)", { _ in KeyboardShortcutsViewController() }))
        accessibilityScreens.append(("Keyboard Shortcuts (Without Categories)", { _ in KeyboardShortcutsWithoutCategoriesViewController() }))

        if #available(iOS 14.0, *) {
            accessibilityScreens.append(("Keyboard Shortcuts (SwiftUI)", { _ in UIHostingController(rootView: SwiftUIKeyboardShortcuts()) }))
        }
        allScreens = accessibilityScreens
        filteredScreens = accessibilityScreens

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter demos"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        if query.isEmpty {
            filteredScreens = allScreens
        } else {
            filteredScreens = allScreens.filter { $0.0.localizedCaseInsensitiveContains(query) }
        }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredScreens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        cell.textLabel?.text = filteredScreens[indexPath.row].0

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = filteredScreens[indexPath.row].1(self)
        viewController.modalPresentationStyle = .fullScreen
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: .init(systemName: "xmark"), style: .plain, target: self, action: #selector(dismiss(_:)))
        present(navigationController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc
    func dismiss(_ sender: UIViewController) {
        dismiss(animated: true, completion: nil)
    }
}
