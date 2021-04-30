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

import AccessibilitySnapshot
import FBSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class InvertColorsTests: SnapshotTestCase {

    func testInvertColors() {
        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds

        SnapshotVerifyWithInvertedColors(viewController.view)
    }

    func testInvertColorsWithIdentifier() {
//        let label = UILabel(frame: .zero)
//        label.text = "Hello World"
//        label.sizeToFit()
//
//        let view = UIView(frame: UIScreen.main.bounds)
//        view.backgroundColor = .lightGray
//        view.addSubview(label)
//
//        label.center = view.center
//
//        FBSnapshotVerifyView(view, identifier: "someIdentifier")
////        FBSnapshotVerifyView(view.colorInvert(), identifier: "invertedColors")
//        SnapshotVerifyWithInvertedColors(view, identifier: "invertedColors")
//
//        // Ensures the view has not been modified after calling SnapshotVerifyWithInvertedColors
//        FBSnapshotVerifyView(view, identifier: "someIdentifier")

        let viewController = InvertColorsViewController()
        viewController.view.frame = UIScreen.main.bounds

        FBSnapshotVerifyView(viewController.view, identifier: "originalColors")

        SnapshotVerifyWithInvertedColors(viewController.view, identifier: "invertedColors")

        // Ensures the view has not been modified after calling SnapshotVerifyWithInvertedColors
        FBSnapshotVerifyView(viewController.view, identifier: "originalColors")

    }

}
