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

import UIKit

final class RootViewController: UITableViewController {

    // MARK: - Private Properties

    private let accessibilityScreens: [(String, (UIViewController) -> UIViewController)]

    // MARK: - Life Cycle

    init() {
        var accessibilityScreens = [
            ("View Accessibility Properties", { _ in return ViewAccessibilityPropertiesViewController() }),
            ("Label Accessibility Properties", { _ in return LabelAccessibilityPropertiesViewController() }),
            ("Button Accessibility Traits", { _ in return ButtonAccessibilityTraitsViewController() }),
            ("Default UIKit Controls", { _ in return DefaultControlsViewController() }),
            ("UISwitch Controls", { _ in return SwitchControlViewController() }),
            ("Tab Bar", { _ in return TabBarViewController() }),
            ("Description Edge Cases", { _ in return DescriptionEdgeCasesViewController() }),
            ("Element Selection", { presentingViewController in
                return ElementSelectionViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Element Order", { presentingViewController in
                return ElementOrderViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Element Order with Semantic Content", { _ in return UserIntefaceDirectionViewController() }),
            ("Modal Accessibility Views", { presentingViewController in
                return ModalAccessibilityViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Accessibility Paths", { _ in return AccessibilityPathViewController() }),
            ("Accessibility Activation Point", { _ in return ActivationPointViewController() }),
            ("Dynamic Type", { _ in return DynamicTypeViewController() }),
        ]

        if #available(iOS 11, *) {
            accessibilityScreens.append(("Data Table", { presentingViewController in
                return DataTableViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }))
            accessibilityScreens.append(("List Container", { _ in return ListContainerViewController() }))
            accessibilityScreens.append(("Landmark Container", { _ in return LandmarkContainerViewController() }))
            accessibilityScreens.append(("Invert Colors", { _ in return InvertColorsViewController() }))
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
        present(viewController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
