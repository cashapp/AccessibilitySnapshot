//
//  Copyright 2023 Block Inc.
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
import Paralayout

@testable import AccessibilitySnapshotDemo

final class HitTargetTests: SnapshotTestCase {

    func testButtonHitTarget() {
        let buttonTraitsViewController = ButtonAccessibilityTraitsViewController()
        buttonTraitsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyWithHitTargets(
            buttonTraitsViewController.view,
            maxPermissibleMissedRegionWidth: 1,
            maxPermissibleMissedRegionHeight: 1
        )
    }

    @available(iOS 14, *)
    func testTableHitTarget() throws {
        try XCTSkipUnless(
            ProcessInfo().operatingSystemVersion.majorVersion >= 14,
            "This test only supports iOS 14 and later"
        )

        let viewController = TableViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyWithHitTargets(
            viewController.view,
            maxPermissibleMissedRegionWidth: 1,
            maxPermissibleMissedRegionHeight: 1
        )
    }

    func testPerformance() throws {
        let buttonTraitsViewController = ButtonAccessibilityTraitsViewController()
        buttonTraitsViewController.view.frame = UIScreen.main.bounds

        measure {
            do {
                _ = try HitTargetSnapshotUtility.generateSnapshotImage(
                    for: buttonTraitsViewController.view,
                    useMonochromeSnapshot: true,
                    viewRenderingMode: .drawHierarchyInRect,
                    maxPermissibleMissedRegionWidth: 4,
                    maxPermissibleMissedRegionHeight: 4
                )
            } catch {
                XCTFail("Utility should not fail to generate snapshot image")
            }
        }
    }

}

// MARK: -

@available(iOS 14, *)
private final class TableViewController: UITableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        var config = cell.defaultContentConfiguration()
        config.text = "Hello World"
        cell.contentConfiguration = config

        cell.accessoryView = UISwitch()

        return cell
    }

}
