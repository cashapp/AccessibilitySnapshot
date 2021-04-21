//
//  Copyright 2021 Square Inc.
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

import Paralayout
import UIKit

final class TextInputsViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let textFieldEmpty: UITextField = .init()

    private let textFieldWithPlaceholder: UITextField = .init()

    private let textFieldWithText: UITextField = .init()

    private let textViewEmpty: UITextView = .init()

    private let textViewWithText: UITextView = .init()

    private var textInputViews: [UIView] {
        return [
            textFieldEmpty,
            textFieldWithPlaceholder,
            textFieldWithText,
            textViewEmpty,
            textViewWithText,
        ]
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldWithPlaceholder.placeholder = "Some placeholder text"

        textFieldWithText.text = "Hello from Text Field"

        textViewWithText.text = "Hello from Text View"

        textInputViews.forEach {
            $0.layer.borderWidth = 1.0
            $0.layer.borderColor = UIColor.lightGray.cgColor
            view.addSubview($0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        textInputViews.forEach { $0.frame.size = CGSize(width: 250, height: 30) }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in textInputViews {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)

        textViewWithText.accessibilityFrame = textViewWithText.frame
    }

}
