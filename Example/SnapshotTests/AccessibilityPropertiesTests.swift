import AccessibilitySnapshotCore
import FBSnapshotTestCase_Accessibility
import iOSSnapshotTestCase
import Paralayout

@testable import AccessibilitySnapshotDemo

final class AccessibilitySnapshotTests: SnapshotTestCase {
    func testBlockBasedAccessibility() {
        if #available(iOS 17.0, *) {
            let viewController = BlockBasedAccessibilityViewController()
            viewController.view.frame = UIScreen.main.bounds
            SnapshotVerifyAccessibility(viewController.view)
        }
    }

    func testViewDescription() {
        let viewPropertiesViewController = ViewAccessibilityPropertiesViewController()
        viewPropertiesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(viewPropertiesViewController.view)
    }

    func testLabelDescription() {
        let labelPropertiesViewController = LabelAccessibilityPropertiesViewController()
        labelPropertiesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(labelPropertiesViewController.view)
    }

    func testButtonTraits() {
        let buttonTraitsViewController = ButtonAccessibilityTraitsViewController()
        buttonTraitsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(buttonTraitsViewController.view)
    }

    func testNavBarBackButtonTraitsWithTitles() {
        let navBarBackButtonTraitsViewController = NavBarBackButtonAccessibilityTraitsViewController(titles: ["First", "Second"])
        navBarBackButtonTraitsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(navBarBackButtonTraitsViewController.view)
    }

    func testNavBarBackButtonTraitsWithoutTitles() {
        let navBarBackButtonTraitsViewController = NavBarBackButtonAccessibilityTraitsViewController()
        navBarBackButtonTraitsViewController.view.frame = UIScreen.main.bounds

        SnapshotVerifyAccessibility(navBarBackButtonTraitsViewController.view)
    }

    func testSwitchControls() {
        let switchControlViewController = SwitchControlViewController()
        switchControlViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(switchControlViewController.view)
    }

    func testDescriptionEdgeCases() {
        let descriptionEdgeCasesViewController = DescriptionEdgeCasesViewController()
        descriptionEdgeCasesViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(descriptionEdgeCasesViewController.view)
    }

    func testAccessibilityPaths() {
        let accessibilityPathViewController = AccessibilityPathViewController()
        accessibilityPathViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(accessibilityPathViewController.view)
    }

    func testTabBars() {
        let tabBarViewController = TabBarViewController()
        tabBarViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(tabBarViewController.view)
    }

    func testCustomActions() {
        let customActionsViewController = AccessibilityCustomActionsViewController()
        customActionsViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(customActionsViewController.view)
    }

    func testCustomRotors_overriden() {
        let customRotorsViewController = AccessibilityCustomRotorsViewController()
        customRotorsViewController.view.frame = UIScreen.main.bounds

        let configuration = AccessibilitySnapshotConfiguration(viewRenderingMode: viewRenderingMode, includesCustomRotors: .whenOverridden)

        SnapshotVerifyAccessibility(customRotorsViewController.view, snapshotConfiguration: configuration)
    }

    func testCustomRotors_always() {
        let customRotorsViewController = AccessibilityCustomRotorsViewController()
        customRotorsViewController.view.frame = UIScreen.main.bounds

        let configuration = AccessibilitySnapshotConfiguration(viewRenderingMode: viewRenderingMode, includesCustomRotors: .always)

        SnapshotVerifyAccessibility(customRotorsViewController.view, snapshotConfiguration: configuration)
    }

    @available(iOS 14.0, *)
    func testCustomContent() throws {
        try XCTSkipUnless(
            ProcessInfo().operatingSystemVersion.majorVersion >= 14,
            "This test only supports iOS 14 and later"
        )

        let customContentViewController = AccessibilityCustomContentViewController()
        customContentViewController.view.frame = UIScreen.main.bounds
        SnapshotVerifyAccessibility(customContentViewController.view)
    }

    func testLargeView() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1400, height: 1400))
        view.backgroundColor = .white

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.align(withSuperview: .center)

        if ProcessInfo().operatingSystemVersion.majorVersion != 13 {
            SnapshotVerifyAccessibility(
                view,
                identifier: "monochrome",
                snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .monochrome)
            )
        }

        SnapshotVerifyAccessibility(
            view,
            identifier: "polychrome",
            snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .fullColor)
        )
    }

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewThatRequiresTiling() throws {
        let view = GradientBackgroundView(
            frame: CGRect(x: 0, y: 0, width: 3000, height: 3000),
            showSafeAreaInsets: true
        )

        usingDrawViewHierarchyInRect {
            SnapshotVerifyAccessibility(
                view,
                snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .fullColor)
            )
        }
    }

    func testViewInViewControllerHierarchy() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.align(withSuperview: .center)

        let viewController = UIViewController()
        viewController.view = view

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(view)

        SnapshotVerifyAccessibility(view)

        // Verify that the original state was restored correctly.
        XCTAssertEqual(view.superview, parent.view)
        XCTAssertEqual(viewController.parent, parent)
    }

    func testViewAsSubviewOfViewInViewControllerHierarchy() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let label = UILabel()
        label.text = "Hello world"
        label.textColor = .red
        view.addSubview(label)

        label.sizeToFit()
        label.align(withSuperview: .center)

        let viewController = UIViewController()
        viewController.view.addSubview(view)

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(viewController.view)

        SnapshotVerifyAccessibility(view)

        // Verify that the original state was restored correctly.
        XCTAssertEqual(view.superview, viewController.view)
    }

    // This test is currently disabled due to a bug in iOSSnapshotTestCase. See cashapp/AccessibilitySnapshot#75.
    func testLargeViewInViewControllerThatRequiresTiling() {
        let view = GradientBackgroundView(
            frame: CGRect(x: 0, y: 0, width: 3000, height: 3000),
            showSafeAreaInsets: true
        )

        let viewController = UIViewController()
        viewController.additionalSafeAreaInsets = .init(top: 600, left: 1000, bottom: 300, right: 100)
        viewController.view = view

        let parent = UIViewController()
        parent.addChild(viewController)
        parent.view.addSubview(view)

        usingDrawViewHierarchyInRect {
            SnapshotVerifyAccessibility(
                view,
                snapshotConfiguration: .init(viewRenderingMode: viewRenderingMode, colorRenderingMode: .fullColor)
            )
        }
    }

    /// Renders a view tall enough to require several vertical tiles, whose content is laid out relative to its top
    /// safe area inset. The tiled rendering path must preserve the safe area so that the rendered content lines up
    /// with the parsed accessibility markers.
    ///
    /// Unlike the tests above, only the contained view's rendering uses `.drawHierarchyInRect` (the mode that tiles);
    /// the outer snapshot comparison uses the default layer rendering, so this is not affected by the
    /// iOSSnapshotTestCase bug described in cashapp/AccessibilitySnapshot#75.
    func testTallViewInViewControllerThatRequiresTiling() {
        let view = SafeAreaAnchoredTallView(frame: CGRect(x: 0, y: 0, width: 390, height: 3280))

        let viewController = UIViewController()
        viewController.view = view
        viewController.additionalSafeAreaInsets = .init(top: 100, left: 0, bottom: 0, right: 0)

        SnapshotVerifyAccessibility(
            view,
            snapshotConfiguration: .init(viewRenderingMode: .drawHierarchyInRect, colorRenderingMode: .fullColor)
        )
    }

    // MARK: - Private Methods

    private func usingDrawViewHierarchyInRect(_ test: () -> Void) {
        let oldValue = usesDrawViewHierarchyInRect
        usesDrawViewHierarchyInRect = true
        test()
        usesDrawViewHierarchyInRect = oldValue
    }

    // MARK: - Private Types

    /// A tall view whose content is anchored to its top safe area inset: the region above the safe area is filled
    /// with a red band, a header sits at the safe area boundary, and numbered rows follow at fixed offsets below it.
    /// If the safe area is lost while rendering, every element shifts up by the full inset height.
    private final class SafeAreaAnchoredTallView: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .white

            unsafeAreaBand.backgroundColor = .systemRed
            unsafeAreaBand.isAccessibilityElement = false
            addSubview(unsafeAreaBand)

            header.text = "Header"
            header.textAlignment = .center
            header.textColor = .white
            header.backgroundColor = .black
            addSubview(header)

            for index in 0 ..< 8 {
                let row = UILabel()
                row.text = "Row \(index + 1)"
                row.textAlignment = .center
                row.textColor = .white
                row.backgroundColor = .systemBlue
                rows.append(row)
                addSubview(row)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let unsafeAreaBand: UIView = .init()

        private let header: UILabel = .init()

        private var rows: [UILabel] = []

        // MARK: - UIView

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let safeAreaTop = safeAreaInsets.top
            unsafeAreaBand.frame = CGRect(x: 0, y: 0, width: bounds.width, height: safeAreaTop)
            header.frame = CGRect(x: 0, y: safeAreaTop, width: bounds.width, height: 44)

            for (index, row) in rows.enumerated() {
                row.frame = CGRect(
                    x: 16,
                    y: safeAreaTop + 100 + CGFloat(index) * 380,
                    width: bounds.width - 32,
                    height: 44
                )
            }
        }
    }

    private final class GradientBackgroundView: UIView {
        // MARK: - Life Cycle

        init(frame: CGRect, showSafeAreaInsets: Bool) {
            super.init(frame: frame)

            gradientLayer.colors = [UIColor.blue.cgColor, UIColor.white.cgColor]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer(gradientLayer)

            label.text = "Hello world"
            label.textColor = .red
            label.backgroundColor = .black
            addSubview(label)

            safeAreaView.layer.borderColor = UIColor.red.cgColor
            safeAreaView.layer.borderWidth = 1
            safeAreaView.isHidden = !showSafeAreaInsets
            addSubview(safeAreaView)

            layoutMargins = .init(top: 8, left: 8, bottom: 8, right: 8)
            insetsLayoutMarginsFromSafeArea = true

            layoutMarginsView.layer.borderColor = UIColor.green.cgColor
            layoutMarginsView.layer.borderWidth = 0.5
            layoutMarginsView.isHidden = !showSafeAreaInsets
            addSubview(layoutMarginsView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let gradientLayer: CAGradientLayer = .init()

        private let label: UILabel = .init()

        private let safeAreaView: UIView = .init()

        private let layoutMarginsView: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            gradientLayer.frame = bounds

            let insetBounds = bounds.inset(by: safeAreaInsets)

            label.sizeToFit()
            label.center = CGPoint(x: insetBounds.midX, y: insetBounds.midY)

            safeAreaView.frame = insetBounds
            layoutMarginsView.frame = bounds.inset(by: layoutMargins)
        }
    }
}
