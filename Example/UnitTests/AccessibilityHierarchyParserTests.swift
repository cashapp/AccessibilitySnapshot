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

import AccessibilitySnapshotCore
import UIKit
import XCTest

final class AccessibilityHierarchyParserTests: XCTestCase {

    func testUserInterfaceLayoutDirection() {
        let gridView = UIView(frame: .init(x: 0, y: 0, width: 20, height: 20))

        let elementA = UIView(frame: .init(x: 0, y: 0, width: 10, height: 10))
        elementA.isAccessibilityElement = true
        elementA.accessibilityLabel = "A"
        elementA.accessibilityFrame = elementA.frame
        gridView.addSubview(elementA)

        let elementB = UIView(frame: .init(x: 10, y: 0, width: 10, height: 10))
        elementB.isAccessibilityElement = true
        elementB.accessibilityLabel = "B"
        elementB.accessibilityFrame = elementB.frame
        gridView.addSubview(elementB)

        let elementC = UIView(frame: .init(x: 0, y: 10, width: 10, height: 10))
        elementC.isAccessibilityElement = true
        elementC.accessibilityLabel = "C"
        elementC.accessibilityFrame = elementC.frame
        gridView.addSubview(elementC)

        let elementD = UIView(frame: .init(x: 10, y: 10, width: 10, height: 10))
        elementD.isAccessibilityElement = true
        elementD.accessibilityLabel = "D"
        elementD.accessibilityFrame = elementD.frame
        gridView.addSubview(elementD)

        let parser = AccessibilityHierarchyParser()

        let ltrElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .leftToRight)
        ).map { $0.description }
        XCTAssertEqual(ltrElements, ["A", "B", "C", "D"])

        let rtlElements = parser.parseAccessibilityElements(
            in: gridView,
            userInterfaceLayoutDirectionProvider: TestUserInterfaceLayoutDirectionProvider(userInterfaceLayoutDirection: .rightToLeft)
        ).map { $0.description }
        XCTAssertEqual(rtlElements, ["B", "A", "D", "C"])
    }

}

// MARK: -

private struct TestUserInterfaceLayoutDirectionProvider: UserInterfaceLayoutDirectionProviding {

    var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection

}
