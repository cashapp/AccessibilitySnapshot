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

import AccessibilitySnapshot
import FBSnapshotTestCase

final class TextInputsTests: SnapshotTestCase {

    // MARK: - UITextField

    func testTextField() {
        let textField = UITextField()

        let container = ContainerView(view: textField)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testTextFieldWithPlaceholder() {
        let textField = UITextField()
        textField.placeholder = "Enter text here"

        let container = ContainerView(view: textField)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testTextFieldWithText() {
        let textField = UITextField()
        textField.text = "I am a text field"

        let container = ContainerView(view: textField)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    // MARK: - UITextView

    func testTextView() {
        let textView = UITextView()

        let container = ContainerView(view: textView)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

    func testTextViewWithText() {
        let textView = UITextView()
        textView.text = "I am a text view"

        let container = ContainerView(view: textView)
        container.frame.size = container.sizeThatFits(UIScreen.main.bounds.size)

        SnapshotVerifyAccessibility(container)
    }

}

// MARK: -

private final class ContainerView: UIView {

    // MARK: - Life Cycle

    init(view: UIView) {
        self.view = view

        super.init(frame: .zero)

        backgroundColor = .white

        addSubview(view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let view: UIView

    // MARK: - UIView

    override func layoutSubviews() {
        view.frame.size = view.sizeThatFits(bounds.insetBy(dx: 10, dy: 10).size)
        view.alignToSuperview(.center)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let viewSize = view.sizeThatFits(size)
        return CGSize(width: size.width, height: viewSize.height + 20)
    }

}
