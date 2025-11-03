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

import SwiftUI
import AccessibilitySnapshotParser
import AccessibilitySnapshotCore

extension View {
    public func accessibilityPreview(renderSize: CGSize? = nil) -> some View {
        SwiftUIAccessibilitySnapshotView(content: { self }, viewRenderingMode: .drawHierarchyInRect, renderSize: renderSize)
    }
}

/// A SwiftUI container view that displays a snapshot of a view and overlays it with accessibility markers,
/// as well as shows a legend of accessibility descriptions underneath.
///
/// The overlays and legend will be added when `parseAccessibility()` is called.
public struct SwiftUIAccessibilitySnapshotView<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let viewRenderingMode: ViewRenderingMode
    private let markerColors: [Color]
    private let accessibilityContentDisplayMode: AccessibilityContentDisplayMode
    private let showUserInputLabels: Bool
    private let renderSize: CGSize

    @State private var displayMarkers: [DisplayMarker] = []
    @State private var snapshotImage: UIImage?
    @State private var renderError: Error?

    // MARK: - Initialization

    /// Initializes a new snapshot container view.
    ///
    /// - Parameters:
    ///   - content: The view that should be snapshotted, and for which the accessibility markers should be generated
    ///   - viewRenderingMode: The method to use when snapshotting the content
    ///   - markerColors: An array of colors to use for the highlighted regions
    ///   - accessibilityContentDisplayMode: Controls when to show indicators for elements' accessibility activation points
    ///   - showUserInputLabels: Controls when to show elements' accessibility user input labels
    public init(
        @ViewBuilder content: () -> Content,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [Color] = MarkerColors.defaultSwiftUIColors,
        accessibilityContentDisplayMode: AccessibilityContentDisplayMode = .whenOverridden,
        showUserInputLabels: Bool = false,
        renderSize: CGSize?
    ) {
        self.content = content()
        self.viewRenderingMode = viewRenderingMode
        self.markerColors = markerColors.isEmpty ? MarkerColors.defaultSwiftUIColors : markerColors
        self.accessibilityContentDisplayMode = accessibilityContentDisplayMode
        self.showUserInputLabels = showUserInputLabels
        self.renderSize = renderSize ?? UIScreen.main.bounds.size
    }

    // MARK: - Body

    public var body: some View {
        VStack {
            if let snapshotImage = snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .aspectRatio(renderSize.aspectRatio, contentMode: .fit)
                    .overlay(
                        GeometryReader { proxy in
                            let scale = proxy.size.scaledTo(renderSize)
                            ZStack {
                                ForEach(displayMarkers.indices, id: \.self) { index in
                                    MarkerOverlayView(
                                        marker: displayMarkers[index].marker,
                                        color: markerColors[index % markerColors.count],
                                        accessibilityContentDisplayMode: accessibilityContentDisplayMode
                                    )
                                    .offset(x: -renderSize.width/2*(1 - scale))
                                    .offset(y: -renderSize.height/2*(1 - scale))
                                    .scaleEffect(scale)

                                }
                            }
                        }
                    )

            } else if let renderError {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(renderError.localizedDescription)
                }
                content
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("\(displayMarkers.count) \(displayMarkers.count == 1 ? "element" : "elements")")
                ForEach(displayMarkers.indices, id: \.self) { index in
                    let marker = displayMarkers[index]
                    SwiftUILegendView(
                        marker: marker.marker,
                        color: markerColors[index % markerColors.count],
                        showUserInputLabels: showUserInputLabels
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            do {
                try parseAccessibility(useMonochromeSnapshot: false)
            } catch {
                self.renderError = error
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Public Methods

    /// Parse the content's accessibility and add appropriate visual elements to represent it.
    ///
    /// - Parameter useMonochromeSnapshot: Whether to render the snapshot in monochrome
    /// - Throws: Throws a `RenderError` when the view fails to render a snapshot
    public func parseAccessibility(useMonochromeSnapshot: Bool) throws {
        let adjustedContent = content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)

        let hostingController = UIHostingController(rootView: adjustedContent)
        hostingController.view.frame = CGRect(origin: .zero, size: renderSize)

        snapshotImage = try hostingController.view.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )
        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(in: hostingController.view)

        displayMarkers = markers.map { marker in
            DisplayMarker(marker: marker)
        }
    }
}

// MARK: - Supporting Types

private struct DisplayMarker {
    let marker: AccessibilityMarker
}

private struct MarkerOverlayView: View {
    let marker: AccessibilityMarker
    let color: Color
    let accessibilityContentDisplayMode: AccessibilityContentDisplayMode

    var body: some View {
        ZStack {
            switch marker.shape {
            case let .frame(rect):
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

            case let .path(path):
                Path(path.cgPath)
                    .stroke(color.opacity(0.3), lineWidth: 4)

                if shouldShowActivationPoint {
                    Image("Crosshairs", bundle: .accessibilitySnapshotResources)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(color)
                        .position(marker.activationPoint)
                }
            }
        }
    }

    private var shouldShowActivationPoint: Bool {
        switch accessibilityContentDisplayMode {
        case .always:
            return true
        case .whenOverridden:
            return !marker.usesDefaultActivationPoint
        case .never:
            return false
        }
    }
}

private struct SwiftUILegendView: View {

    enum Metrics {

        static let minimumWidth: CGFloat = 240

        static let markerSize: CGFloat = 14

    }

    let marker: AccessibilityMarker
    let color: Color
    let showUserInputLabels: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(marker.description)")
                    .font(.body)
                    .multilineTextAlignment(.leading)

                if showUserInputLabels, let userInputLabel = marker.userInputLabels {
                    Text("Voice Control: \"\(userInputLabel)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Constants

public extension MarkerColors {
    static let defaultSwiftUIColors: [Color] = defaultColors.map { Color($0) }
}

extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }

    func scaledTo(_ size: CGSize) -> CGFloat {
        min(self.width / size.width, self.height / size.height)
    }
}

extension UIBezierPath {
    func scale(by factor: CGFloat) -> UIBezierPath {
        let copy = self.copy() as! UIBezierPath
        copy.apply(.init(scaleX: factor, y: factor))
        return copy
    }
}
