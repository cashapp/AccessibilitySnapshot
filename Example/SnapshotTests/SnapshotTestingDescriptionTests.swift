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
import SnapshotTesting
import XCTest

@testable import AccessibilitySnapshotDemo

/// Tests covering the integration between the core components of AccessibilitySnapshot and SnapshotTesting.
final class SnapshotTestingDescriptionTests: XCTestCase {

    // MARK: - Tests

    func testDefaultConfiguration() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(matching: viewController.view, as: .accessibilityDescription)
        
    }
    
    func testInline() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        _assertInlineSnapshot(matching: viewController.view, as: .accessibilityDescription, with: """
        Found 8 marker(s)
        
        No Fields
        
        Description: Label
        
        Description: Value
        
        Description: Hint
        
        Description: Label: Value
        
        Description: Label
        Hint: Hint
        
        Description: Value
        Hint: Hint
        
        Description: Label: Value
        Hint: Hint
        """)
    }
    
    func testSingleView() {
        let view = UILabel()
        view.text = "Hello World"
        view.textColor = .red
        view.sizeToFit()
        assertSnapshot(matching: view, as: .accessibilityDescription)
    }
    
    func testNoMarkers() {
        let view = UIView()
        view.isAccessibilityElement = false
        assertSnapshot(matching: view, as: .accessibilityDescription)
    }
    
    func testAllFieldsConfiguration() {
        let viewController = ViewAccessibilityPropertiesViewController()
        viewController.view.frame = UIScreen.main.bounds
        assertSnapshot(
            matching: viewController.view,
            as: .accessibilityDescription(fields: Snapshotting.AccessibilityFields.allCases)
        )
    }

}
