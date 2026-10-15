import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase

@testable import AccessibilitySnapshotDemo

final class ModalTests: SnapshotTestCase {
    func testSingleModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testSingleDirectlySpecifiedModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewIsAccessible
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testSingleInaccessibleModal() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 0,
            modalAccessibilityMode: .viewIsInaccessible
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testTwoModals() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 2,
            containerCount: 0,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testTwoContainers() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 0,
            containerCount: 2,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testOneModalOneContainer() {
        let modalAccessibilityViewController = ModalAccessibilityViewController(
            topLevelCount: 1,
            containerCount: 1,
            modalAccessibilityMode: .viewContainsAccessibleElement
        )
        modalAccessibilityViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(modalAccessibilityViewController.view)
    }

    func testPopover() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let presenter = UIViewController()
        presenter.view.backgroundColor = .white
        let background = UIButton(type: .system)
        background.setTitle("Background", for: .normal)
        background.frame = CGRect(x: 20, y: 200, width: 160, height: 44)
        presenter.view.addSubview(background)
        window.rootViewController = presenter
        window.makeKeyAndVisible()

        let popover = PopoverContentViewController()
        popover.modalPresentationStyle = .popover
        popover.popoverPresentationController?.sourceView = background
        popover.popoverPresentationController?.sourceRect = background.bounds
        popover.popoverPresentationController?.delegate = popover
        let presented = expectation(description: "Popover presented")
        presenter.present(popover, animated: false) { presented.fulfill() }
        wait(for: [presented], timeout: 5)

        // The popover's container view holds the modal dimming view and the popover view.
        if let containerView = popover.popoverPresentationController?.containerView {
            SnapshotVerifyAccessibility(containerView)
        } else {
            XCTFail("Expected the popover to have a container view")
        }

        // Wait for UIKit to finish the dismissal before the window is released.
        let dismissed = expectation(description: "Popover dismissed")
        presenter.dismiss(animated: false) { dismissed.fulfill() }
        wait(for: [dismissed], timeout: 5)
        window.isHidden = true
    }
}

// MARK: -

private final class PopoverContentViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let button = UIButton(type: .system)
        button.setTitle("Popover Action", for: .normal)
        button.frame = CGRect(x: 20, y: 20, width: 160, height: 44)
        view.addSubview(button)
        preferredContentSize = CGSize(width: 200, height: 100)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}
