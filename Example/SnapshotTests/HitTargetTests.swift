import AccessibilitySnapshotCore
import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
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
    func testTableHitTarget() {
        do { try XCTSkipUnless(
            ProcessInfo().operatingSystemVersion.majorVersion >= 14,
            "This test only supports iOS 14 and later"
        ) } catch {
            XCTFail(String(describing: error))
        }

        let viewController = TableViewController()
        viewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyWithHitTargets(
            viewController.view,
            maxPermissibleMissedRegionWidth: 1,
            maxPermissibleMissedRegionHeight: 1
        )
    }

    func testPerformance() {
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
