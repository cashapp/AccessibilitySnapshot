//
//  Copyright 2024 Block Inc.
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

@testable import AccessibilitySnapshotDemo

class FeatureShowcaseSnapshotTestCase: SnapshotTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Feature showcase requires iOS 16 or newer.")
        }
    }

}

@available(iOS 16.0, *)
final class FeatureShowcaseSnapshotTests: FeatureShowcaseSnapshotTestCase {

    func testFeatureShowcaseView() {
        let configuration = AccessibilitySnapshotConfiguration(
            viewRenderingMode: .drawHierarchyInRect,
            includesInputLabels: .whenOverridden,
            includesCustomRotors: .always
        )

        SnapshotVerifyAccessibility(
            AccessibilityFeatureShowcaseView(),
            size: UIScreen.main.bounds.size,
            snapshotConfiguration: configuration
        )
    }

}
