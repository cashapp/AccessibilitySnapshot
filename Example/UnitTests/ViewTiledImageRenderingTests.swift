@testable import AccessibilitySnapshotCore
import UIKit
import XCTest

/// Tests that tiled rendering (views larger than the tile size) preserves layout that depends on the view's safe
/// area. Rendering in tiles temporarily restructures the view hierarchy, which historically left the view's safe
/// area stale at zero, so any safe-area-driven layout rendered shifted relative to where the view's accessibility
/// elements are parsed.
final class ViewTiledImageRenderingTests: XCTestCase {
    // MARK: - Tests

    func testTiledRenderingPreservesSafeAreaLayout_viewOwnedByViewController() throws {
        let (view, window) = try makeHostedProbeView()
        defer { window.isHidden = true }

        let viewController = UIViewController()
        viewController.view = view

        try assertTiledRenderMatchesOriginalLayout(of: view)
    }

    func testTiledRenderingPreservesSafeAreaLayout_plainView() throws {
        let (view, window) = try makeHostedProbeView()
        defer { window.isHidden = true }

        try assertTiledRenderMatchesOriginalLayout(of: view)

        // The temporary view controller used during rendering must not remain in the responder chain.
        XCTAssertFalse(view.next is UIViewController)
    }

    func testTiledRenderingPreservesAdditionalSafeAreaInsets() throws {
        let additionalSafeAreaInsets = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)

        // The view controller's additional insets must be in place before the view joins the window so that UIKit
        // factors them into the view's safe area when it is first computed.
        let viewController = UIViewController()
        let (view, window) = try makeHostedProbeView { view in
            viewController.view = view
            viewController.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
        defer { window.isHidden = true }

        // Precondition: the additional insets are reflected in the view's safe area before rendering.
        XCTAssertEqual(view.safeAreaInsets.top, window.safeAreaInsets.top + additionalSafeAreaInsets.top)

        try assertTiledRenderMatchesOriginalLayout(of: view)

        // The view controller's own insets must survive the render unchanged.
        XCTAssertEqual(viewController.additionalSafeAreaInsets, additionalSafeAreaInsets)
    }

    // MARK: - Private Methods

    /// Creates a probe view tall enough to require tiled rendering, hosted in a visible window so it has a nonzero
    /// top safe area inset.
    ///
    /// - parameter installInViewController: An optional closure that installs the view in a view controller before
    /// the view joins the window.
    private func makeHostedProbeView(
        installInViewController: ((UIView) -> Void)? = nil
    ) throws -> (SafeAreaSensitiveView, UIWindow) {
        let screenBounds = UIScreen.main.bounds
        let window = UIWindow(frame: screenBounds)
        window.makeKeyAndVisible()

        let view = SafeAreaSensitiveView(
            frame: CGRect(x: 0, y: 0, width: screenBounds.width, height: 3280)
        )
        installInViewController?(view)
        window.addSubview(view)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.current.run(until: Date())

        try XCTSkipIf(
            view.safeAreaInsets.top == 0,
            "This test requires an environment that provides a nonzero top safe area inset"
        )

        return (view, window)
    }

    /// Renders the view through the tiled rendering path and asserts that the safe-area-driven stripes appear in the
    /// image at the same positions they occupy in the original hierarchy — one stripe in the first tile and one
    /// beyond the first tile boundary — and that the view's layout is restored afterwards.
    private func assertTiledRenderMatchesOriginalLayout(
        of view: SafeAreaSensitiveView,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.current.run(until: Date())

        let originalSafeAreaInsets = view.safeAreaInsets
        let originalHeaderY = view.header.frame.minY
        let originalDeepStripeY = view.deepStripe.frame.minY

        let image = try view.renderToImage(
            configuration: .init(renderMode: .drawHierarchyInRect, colorMode: .fullColor)
        )

        let headerImageY = try XCTUnwrap(
            firstRow(matching: { $0.red > 200 && $0.green < 50 && $0.blue < 50 }, in: image),
            "Expected to find the red header stripe in the rendered image",
            file: file,
            line: line
        )
        let deepStripeImageY = try XCTUnwrap(
            firstRow(matching: { $0.blue > 200 && $0.green < 50 && $0.red < 50 }, in: image),
            "Expected to find the blue deep stripe in the rendered image",
            file: file,
            line: line
        )

        XCTAssertEqual(
            CGFloat(headerImageY) / image.scale,
            originalHeaderY,
            accuracy: 1,
            "The header stripe rendered at a different position than it occupies in the original hierarchy",
            file: file,
            line: line
        )
        XCTAssertEqual(
            CGFloat(deepStripeImageY) / image.scale,
            originalDeepStripeY,
            accuracy: 1,
            "The deep stripe rendered at a different position than it occupies in the original hierarchy",
            file: file,
            line: line
        )

        // The original layout must be restored after rendering.
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.current.run(until: Date())
        XCTAssertEqual(view.safeAreaInsets, originalSafeAreaInsets, file: file, line: line)
        XCTAssertEqual(view.header.frame.minY, originalHeaderY, file: file, line: line)
    }

    /// Returns the topmost pixel row in the image's center column whose color matches the predicate.
    private func firstRow(
        matching predicate: ((red: Int, green: Int, blue: Int)) -> Bool,
        in image: UIImage
    ) -> Int? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let column = width / 2

        var columnPixels = [UInt8](repeating: 0, count: height * 4)
        guard
            let context = CGContext(
                data: &columnPixels,
                width: 1,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        // Draw the image shifted so that the center column lands in this single-column context.
        context.draw(cgImage, in: CGRect(x: -column, y: 0, width: width, height: height))

        for row in 0 ..< height {
            let offset = row * 4
            let pixel = (
                red: Int(columnPixels[offset]),
                green: Int(columnPixels[offset + 1]),
                blue: Int(columnPixels[offset + 2])
            )
            if predicate(pixel) {
                return row
            }
        }

        return nil
    }

    // MARK: - Private Types

    /// A view that positions two colored stripes relative to its top safe area inset: a red header at the inset and a
    /// blue stripe far enough down to land beyond the first 2000pt rendering tile.
    private final class SafeAreaSensitiveView: UIView {
        // MARK: - Life Cycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .white
            header.backgroundColor = .red
            deepStripe.backgroundColor = .blue
            addSubview(header)
            addSubview(deepStripe)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties

        let header: UIView = .init()

        let deepStripe: UIView = .init()

        // MARK: - UIView

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            setNeedsLayout()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            header.frame = CGRect(x: 0, y: safeAreaInsets.top, width: bounds.width, height: 44)
            deepStripe.frame = CGRect(x: 0, y: safeAreaInsets.top + 2400, width: bounds.width, height: 44)
        }
    }
}
