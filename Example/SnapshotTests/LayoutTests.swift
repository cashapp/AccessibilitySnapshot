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
import UIKit

final class LayoutTests: SnapshotTestCase {

    func testSmallView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.backgroundColor = .white

        addAccessibleViews(to: view)

        SnapshotVerifyAccessibility(view)
    }

    func testLargeView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        view.backgroundColor = .white

        addAccessibleViews(to: view)

        SnapshotVerifyAccessibility(view)
    }

    func testWideView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 20))
        view.backgroundColor = .white

        addAccessibleViews(to: view)

        SnapshotVerifyAccessibility(view)
    }

    func testTallView() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 400))
        view.backgroundColor = .white

        addAccessibleViews(to: view)

        SnapshotVerifyAccessibility(view)
    }

    // MARK: - Private Methods

    private func addAccessibleViews(to view: UIView) {
        let frame = CGRect(
            x: view.bounds.width / 4,
            y: view.bounds.height / 4,
            width: view.bounds.width / 2,
            height: view.bounds.height / 2
        )

        let accessibilityView1 = UIView(frame: frame)
        accessibilityView1.accessibilityLabel = "First subview"
        accessibilityView1.isAccessibilityElement = true
        view.addSubview(accessibilityView1)

        let accessibilityView2 = UIView(frame: frame)
        accessibilityView2.accessibilityLabel = "Second subview"
        accessibilityView2.isAccessibilityElement = true
        view.addSubview(accessibilityView2)

        let accessibilityView3 = UIView(frame: frame)
        accessibilityView3.accessibilityLabel = "Third subview"
        accessibilityView3.isAccessibilityElement = true
        view.addSubview(accessibilityView3)

        let accessibilityView4 = UIView(frame: frame)
        accessibilityView4.accessibilityLabel = "Fourth subview"
        accessibilityView4.isAccessibilityElement = true
        view.addSubview(accessibilityView4)
    }

}
