//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import UIKit

final class RootViewController: UITableViewController {
    // MARK: - Private Properties

    private let accessibilityScreens: [(String, (UIViewController) -> UIViewController)]

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
        if #available(iOS 17.0, *) {
            accessibilityScreens.append(("Block based accessors", { _ in BlockBasedAccessibilityViewController() }))
        }
        self.accessibilityScreens = accessibilityScreens

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessibilityScreens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        cell.textLabel?.text = accessibilityScreens[indexPath.row].0

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = accessibilityScreens[indexPath.row].1(self)
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
