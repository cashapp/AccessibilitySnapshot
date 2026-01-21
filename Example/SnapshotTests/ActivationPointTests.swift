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

final class ActivationPointTests: SnapshotTestCase {

    func testActivationPointDisabled() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view, showActivationPoints: .never)
    }

    func testActivationPointEnabledWhenOverridden() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view, showActivationPoints: .whenOverridden)
    }

    func testActivationPointEnabled() {
        let viewController = ActivationPointViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewController.view, showActivationPoints: .always)
    }

}
