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

import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ElementOrderTests: SnapshotTestCase {
    func testScatter() {
        let elementOrderViewController = ElementOrderViewController(configurations: .scatter)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testGrid() {
        let elementOrderViewController = ElementOrderViewController(configurations: .grid)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testContainerInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .containerInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testZeroSizedContainerInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .zeroSizedContainerInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testGroupedViewsInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .groupedViewsInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testUngroupedViewsInElementStack() {
        let elementOrderViewController = ElementOrderViewController(configurations: .ungroupedViewsInElementStack)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }

    func testUngroupedViewsInAccessibleParent() {
        let elementOrderViewController = ElementOrderViewController(configurations: .ungroupedViewsInAccessibleParent)
        elementOrderViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(elementOrderViewController.view)
    }
}
