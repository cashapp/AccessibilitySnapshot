import AccessibilitySnapshotCore
import AccessibilitySnapshotModel
import AccessibilitySnapshotParser
@testable import AccessibilitySnapshotPreviews
import SwiftUI
import UIKit
import XCTest

@available(iOS 18.0, *)
@MainActor
final class OverlayAlignmentTests: XCTestCase {
    private let renderSize = CGSize(width: 300, height: 350)

    func testUIKitFrameMatchesParsedFrameInScreenCoordinates() throws {
        let root = UIView(frame: CGRect(origin: .zero, size: renderSize))
        let element = UIView(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "UIKit probe"
        root.addSubview(element)

        let window = host(root)
        defer { window.isHidden = true }

        let marker = try parsedMarker(label: "UIKit probe", in: root)
        assertEqual(
            element.convert(element.bounds, to: nil),
            root.convert(marker.shape.boundingBox, to: nil)
        )
    }

    func testSwiftUIFrameMatchesParsedPathInScreenCoordinates() throws {
        try assertSwiftUIAlignment(topSpacing: 100, wrapperInset: 0, safeAreaTop: 0)
    }

    func testSwiftUIFrameMatchesWithNonzeroSafeArea() throws {
        try assertSwiftUIAlignment(topSpacing: 100, wrapperInset: 0, safeAreaTop: 12)
    }

    func testSwiftUIFrameMatchesAfterInsetWrapperReparenting() throws {
        try assertSwiftUIAlignment(topSpacing: 100, wrapperInset: 8, safeAreaTop: 0)
    }

    func testSwiftUIFrameMatchesAfterTiledHierarchyRendering() throws {
        try assertSwiftUIAlignment(topSpacing: 2100, wrapperInset: 8, safeAreaTop: 12)
    }

    func testFrameOverlayPreservesMarkerCenterAndAppliesSymmetricOutset() throws {
        let markerFrame = CGRect(x: 50, y: 100, width: 200, height: 50)
        let overlayFrame = try resolvedOverlayFrame(for: .frame(AccessibilityRect(markerFrame)))
        let expectedFrame = markerFrame.insetBy(dx: -2, dy: -2)

        XCTAssertEqual(overlayFrame.midX, expectedFrame.midX, accuracy: 1)
        XCTAssertEqual(overlayFrame.midY, expectedFrame.midY, accuracy: 1)
        XCTAssertEqual(overlayFrame.width, expectedFrame.width, accuracy: 2)
        XCTAssertEqual(overlayFrame.height, expectedFrame.height, accuracy: 2)
    }

    func testRectangularPathOverlayPreservesMarkerCenterAndAppliesSymmetricOutset() throws {
        let markerFrame = CGRect(x: 50, y: 100, width: 200, height: 50)
        let path = UIBezierPath(rect: markerFrame)
        let shape = AccessibilityShape.path(AccessibilityPathElement.elements(from: path.cgPath))
        let overlayFrame = try resolvedOverlayFrame(for: shape)
        let expectedFrame = markerFrame.insetBy(dx: -2, dy: -2)

        XCTAssertEqual(overlayFrame.midX, expectedFrame.midX, accuracy: 1)
        XCTAssertEqual(overlayFrame.midY, expectedFrame.midY, accuracy: 1)
        XCTAssertEqual(overlayFrame.width, expectedFrame.width, accuracy: 2)
        XCTAssertEqual(overlayFrame.height, expectedFrame.height, accuracy: 2)
    }

    private func assertSwiftUIAlignment(
        topSpacing: CGFloat,
        wrapperInset: CGFloat,
        safeAreaTop: CGFloat
    ) throws {
        let anchor = AnchorBox()
        let contentHeight = max(renderSize.height, topSpacing + 150)
        let root = VStack(spacing: 0) {
            Color.clear.frame(height: topSpacing)
            AnchorView(box: anchor)
                .frame(width: 200, height: 50)
                .background(Color.black)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("SwiftUI probe")
            Spacer(minLength: 0)
        }
        .frame(width: renderSize.width, height: contentHeight, alignment: .top)
        .background(Color.white)

        let hosting = UIHostingController(rootView: root)
        hosting.additionalSafeAreaInsets.top = safeAreaTop
        hosting.view.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: contentHeight)
        let containedView: UIView
        if wrapperInset > 0 {
            let wrapper = UIView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: renderSize.width + wrapperInset * 2,
                    height: contentHeight + wrapperInset * 2
                )
            )
            wrapper.backgroundColor = .white
            hosting.view.frame.origin = CGPoint(x: wrapperInset, y: wrapperInset)
            wrapper.addSubview(hosting.view)
            containedView = wrapper
        } else {
            containedView = hosting.view
        }

        var liveFrame: CGRect?
        var markerFrame: CGRect?
        var renderedProbeFrame: CGRect?
        let container = CapturingSnapshotView(
            containedView: containedView,
            snapshotConfiguration: AccessibilitySnapshotConfiguration(
                viewRenderingMode: .drawHierarchyInRect,
                colorRenderingMode: .fullColor
            )
        ) { data in
            liveFrame = anchor.view?.convert(anchor.view?.bounds ?? .zero, to: nil)
            if let marker = data.markers.first(where: { $0.label == "SwiftUI probe" }) {
                markerFrame = containedView.convert(marker.shape.boundingBox, to: nil)
                renderedProbeFrame = self.blackPixelBounds(in: data.image)
                if let renderedProbeFrame {
                    XCTAssertEqual(
                        renderedProbeFrame.midX,
                        marker.shape.boundingBox.midX,
                        accuracy: 1
                    )
                    XCTAssertEqual(
                        renderedProbeFrame.midY,
                        marker.shape.boundingBox.midY,
                        accuracy: 1
                    )
                    XCTAssertLessThanOrEqual(
                        abs(renderedProbeFrame.width - marker.shape.boundingBox.width),
                        2
                    )
                    XCTAssertLessThanOrEqual(
                        abs(renderedProbeFrame.height - marker.shape.boundingBox.height),
                        2
                    )
                }
            }
        }

        let window = host(container)
        defer { window.isHidden = true }
        try container.parseAccessibility()

        let resolvedLiveFrame = try XCTUnwrap(liveFrame)
        assertEqual(resolvedLiveFrame.size, CGSize(width: 200, height: 50))
        XCTAssertNotNil(try XCTUnwrap(renderedProbeFrame))
        try assertEqual(resolvedLiveFrame, XCTUnwrap(markerFrame))
    }

    private func blackPixelBounds(in image: UIImage) -> CGRect? {
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let normalizedImage = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        guard let cgImage = normalizedImage.cgImage,
              let data = cgImage.dataProvider?.data,
              let pixels = CFDataGetBytePtr(data)
        else {
            return nil
        }

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = y * cgImage.bytesPerRow + x * bytesPerPixel
                let darkByteCount = (0 ..< bytesPerPixel)
                    .count { pixels[offset + $0] < 8 }
                if darkByteCount >= bytesPerPixel * 3 / 4 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }

    private func nonWhitePixelBounds(in image: UIImage) -> CGRect? {
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let normalizedImage = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        guard let cgImage = normalizedImage.cgImage,
              let data = cgImage.dataProvider?.data,
              let pixels = CFDataGetBytePtr(data)
        else {
            return nil
        }

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = y * cgImage.bytesPerRow + x * bytesPerPixel
                let differsFromWhite = (0 ..< bytesPerPixel).contains { component in
                    abs(Int(pixels[offset + component]) - Int(pixels[component])) > 2
                }
                if differsFromWhite {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }

    private func resolvedOverlayFrame(for shape: AccessibilityShape) throws -> CGRect {
        let root = ZStack(alignment: .topLeading) {
            Color.white
            ElementOverlay(
                index: 0,
                shape: shape,
                palette: .modern
            )
        }
        .frame(width: renderSize.width, height: renderSize.height)

        let hosting = UIHostingController(rootView: root)
        hosting.safeAreaRegions = []
        hosting.view.frame = CGRect(origin: .zero, size: renderSize)
        let window = host(hosting.view)
        defer { window.isHidden = true }

        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        let image = try hosting.view.renderToImage(
            configuration: .init(renderMode: .renderLayerInContext, colorMode: .fullColor)
        )
        return try XCTUnwrap(nonWhitePixelBounds(in: image))
    }

    private func parsedMarker(label: String, in root: UIView) throws -> AccessibilityMarker {
        let markers = AccessibilityHierarchyParser()
            .parseAccessibilityHierarchy(in: root)
            .flattenToElements()
        return try XCTUnwrap(markers.first { $0.label == label })
    }

    private func host(_ view: UIView) -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let rootViewController = UIViewController()
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        view.center = rootViewController.view.center
        rootViewController.view.addSubview(view)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.current.run(until: Date())
        return window
    }

    private func assertEqual(
        _ actual: CGRect,
        _ expected: CGRect,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertEqual(actual.origin, expected.origin, file: file, line: line)
        assertEqual(actual.size, expected.size, file: file, line: line)
    }

    private func assertEqual(
        _ actual: CGPoint,
        _ expected: CGPoint,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let accuracy = 1 / UIScreen.main.scale
        XCTAssertEqual(actual.x, expected.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.y, expected.y, accuracy: accuracy, file: file, line: line)
    }

    private func assertEqual(
        _ actual: CGSize,
        _ expected: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let accuracy = 1 / UIScreen.main.scale
        XCTAssertEqual(actual.width, expected.width, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: accuracy, file: file, line: line)
    }
}

@available(iOS 18.0, *)
private final class CapturingSnapshotView: AccessibilitySnapshotBaseView {
    private let capture: (ParsedAccessibilityData) -> Void

    init(
        containedView: UIView,
        snapshotConfiguration: AccessibilitySnapshotConfiguration,
        capture: @escaping (ParsedAccessibilityData) -> Void
    ) {
        self.capture = capture
        super.init(containedView: containedView, snapshotConfiguration: snapshotConfiguration)
    }

    override func render(data: ParsedAccessibilityData) {
        capture(data)
    }
}

@available(iOS 18.0, *)
@MainActor
private final class AnchorBox {
    weak var view: UIView?
}

@available(iOS 18.0, *)
private struct AnchorView: UIViewRepresentable {
    let box: AnchorBox

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        box.view = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        box.view = uiView
    }
}

private extension AccessibilityShape {
    var boundingBox: CGRect {
        switch self {
        case let .frame(rect):
            rect.cgRect
        case let .path(path):
            path.cgPath.boundingBox
        }
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
