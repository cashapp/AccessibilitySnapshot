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
            ("View Accessibility Properties", { _ in return ViewAccessibilityPropertiesViewController() }),
            ("Label Accessibility Properties", { _ in return LabelAccessibilityPropertiesViewController() }),
            ("Nav Bar Back Button Accessibility Traits", { _ in return NavBarBackButtonAccessibilityTraitsViewController() }),
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
            ("Element Frame Comparison", { _ in return ElementFrameComparisonController() }),
            ("Element Order with Semantic Content", { _ in return UserIntefaceDirectionViewController() }),
            ("Modal Accessibility Views", { presentingViewController in
                return ModalAccessibilityViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("Accessibility Paths", { _ in return AccessibilityPathViewController() }),
            ("Accessibility Activation Point", { _ in return ActivationPointViewController() }),
            ("Accessibility Custom Actions", { _ in return AccessibilityCustomActionsViewController() }),
            ("Data Table", { presentingViewController in
                return DataTableViewController.makeConfigurationSelectionViewController(
                    presentingViewController: presentingViewController
                )
            }),
            ("List Container", { _ in return ListContainerViewController() }),
            ("Landmark Container", { _ in return LandmarkContainerViewController() }),
            ("Invert Colors", { _ in return InvertColorsViewController() }),
            ("User Input Labels", { _ in return UserInputLabelsViewController() }),
            ("Text Field", { _ in return TextFieldViewController() }),
            ("Text View", { _ in return TextViewViewController() }),
            ("SwiftUI Text Entry", { _ in return UIHostingController(rootView: SwiftUITextEntry()) }),
        ]
        if #available(iOS 14.0, *) {
            accessibilityScreens.append( ("Accessibility Custom Content", { _ in return AccessibilityCustomContentViewController() }))
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
        present(viewController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
