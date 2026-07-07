import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import SwiftUI

@testable import AccessibilitySnapshotDemo

final class ScrollViewTests: SnapshotTestCase {
    // MARK: - UIKit UITableView

    func testTableViewScrolledToTop() {
        let vc = ScrollViewAccessibilityViewController(scrollPosition: .top)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    func testTableViewScrolledToMiddle() {
        let vc = ScrollViewAccessibilityViewController(scrollPosition: .middle)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    func testTableViewScrolledToBottom() {
        let vc = ScrollViewAccessibilityViewController(scrollPosition: .bottom)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    // MARK: - UIKit UICollectionView

    func testCollectionViewScrolledToTop() {
        let vc = CollectionViewAccessibilityViewController(scrollPosition: .top)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    func testCollectionViewScrolledToMiddle() {
        let vc = CollectionViewAccessibilityViewController(scrollPosition: .middle)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    func testCollectionViewScrolledToBottom() {
        let vc = CollectionViewAccessibilityViewController(scrollPosition: .bottom)
        vc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        vc.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(vc.view)
    }

    // MARK: - SwiftUI List (backed by UICollectionView)

    @available(iOS 15.0, *)
    func testSwiftUIListScrolledToTop() {
        let view = SwiftUIScrollView(scrollPosition: .top)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }

    @available(iOS 15.0, *)
    func testSwiftUIListScrolledToMiddle() {
        let view = SwiftUIScrollView(scrollPosition: .middle)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }

    @available(iOS 15.0, *)
    func testSwiftUIListScrolledToBottom() {
        let view = SwiftUIScrollView(scrollPosition: .bottom)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }

    // MARK: - SwiftUI LazyVStack in ScrollView (not backed by UICollectionView)

    @available(iOS 15.0, *)
    func testLazyVStackScrolledToTop() {
        let view = SwiftUILazyScrollView(scrollPosition: .top)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }

    @available(iOS 15.0, *)
    func testLazyVStackScrolledToMiddle() {
        let view = SwiftUILazyScrollView(scrollPosition: .middle)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }

    @available(iOS 15.0, *)
    func testLazyVStackScrolledToBottom() {
        let view = SwiftUILazyScrollView(scrollPosition: .bottom)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        host.view.layoutIfNeeded()
        SnapshotVerifyAccessibility(host.view)
    }
}
