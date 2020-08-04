//
//  Copyright 2020 Square Inc.
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

final class TextFieldCursorTests: SnapshotTestCase {

    func testHidesTextFieldCursor() {
        let textField = UITextField()
        textField.accessibilityLabel = "Enter Text"
        textField.placeholder = "Enter Text"
        textField.tintColor = .black

        let container = ContainerView(subview: textField)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)

        // Since this is fixing flaky behavior, call to `SnapshotVerifyAccessibility`
        // may not fail if this regresses, so also explicitly test that the call to
        // `SnapshotVerifyAccessibility` cleared the tint color of the text field.
        XCTAssertEqual(textField.tintColor, .clear)
    }


}
