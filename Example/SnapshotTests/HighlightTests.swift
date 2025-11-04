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

final class HighlightTests: SnapshotTestCase {

    func testColors() {
        let view = AccessibleContainerView(count: 8, innerMargin: 10)
        view.sizeToFit()

        SnapshotVerifyAccessibility(view)
    }

    func testOverlap() {
        let view = AccessibleContainerView(count: 8, innerMargin: -5)
        view.sizeToFit()

        SnapshotVerifyAccessibility(view)
    }

    func testColorInSnapshot() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()

        SnapshotVerifyAccessibility(view, snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .fullColor))
    }

}
