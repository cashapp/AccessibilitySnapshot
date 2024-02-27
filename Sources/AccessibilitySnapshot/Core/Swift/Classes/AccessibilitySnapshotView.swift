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

import UIKit

public enum ActivationPointDisplayMode {

    /// Always show the accessibility activation point indicators.
    case always

    /// Only show the accessibility activation point indicator for an element when the activation point is different
    /// than the default activation point for that element.
    case whenOverridden

    /// Never show the accessibility activation point indicators.
    case never

}

// MARK: -

/// A container view that displays a snapshot of a view and overlays it with accessibility markers, as well as shows a
/// legend of accessibility descriptions underneath.
///
/// The overlays and legend will be added when `parseAccessibility()` is called. In order for the coordinates to be
/// calculated properly, the view must already be in the view hierarchy.
public final class AccessibilitySnapshotView: SnapshotAndLegendView {

    // MARK: - Life Cycle

    /// Initializes a new snapshot container view.
    ///
    /// - parameter containedView: The view that should be snapshotted, and for which the accessibility markers should
    /// be generated.
    /// - parameter viewRenderingMode: The method to use when snapshotting the `containedView`.
    /// - parameter markerColors: An array of colors to use for the highlighted regions. These colors will be used in
    /// order, repeating through the array as necessary.
    /// - parameter activationPointDisplayMode: Controls when to show indicators for elements' accessibility activation
    /// points.
    /// - parameter showUserInputLabels: Controls when to show elements' accessibility user input labels (used by Voice Control).
    public init(
        containedView: UIView,
        viewRenderingMode: ViewRenderingMode,
        markerColors: [UIColor] = defaultMarkerColors,
        activationPointDisplayMode: ActivationPointDisplayMode,
        showUserInputLabels: Bool
    ) {
        self.containedView = containedView
        self.viewRenderingMode = viewRenderingMode
        self.markerColors = markerColors.isEmpty ? AccessibilitySnapshotView.defaultMarkerColors : markerColors
        self.activationPointDisplayMode = activationPointDisplayMode
        self.showUserInputLabels = showUserInputLabels

        super.init(frame: containedView.bounds)

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SnapshotAndLegendView

    override var legendViews: [UIView] {
        return displayMarkers.map { $0.legendView }
    }

    override var minimumLegendWidth: CGFloat {
        return LegendView.Metrics.minimumWidth
    }

    // MARK: - Private Properties

    private let containedView: UIView

    private let viewRenderingMode: ViewRenderingMode

    private let markerColors: [UIColor]

    private let activationPointDisplayMode: ActivationPointDisplayMode

    private let showUserInputLabels: Bool

    private var displayMarkers: [DisplayMarker] = []

    // MARK: - Public Methods

    /// Parse the `containedView`'s accessibility and add appropriate visual elements to represent it.
    ///
    /// This must be called _after_ the view is in the view hierarchy.
    ///
    /// - Throws: Throws a `RenderError` when the view fails to render a snapshot of the `containedView`.
    public func parseAccessibility(useMonochromeSnapshot: Bool) throws {
        // Clean up any previous markers.
        self.displayMarkers.forEach {
            $0.legendView.removeFromSuperview()
            $0.overlayView.removeFromSuperview()
            $0.activationPointView?.removeFromSuperview()
        }

        let viewController = containedView.next as? UIViewController
        let originalParent = viewController?.parent
        let originalSuperviewAndIndex = containedView.superviewWithSubviewIndex()

        viewController?.removeFromParent()
        addSubview(containedView)

        defer {
            containedView.removeFromSuperview()

            if let (originalSuperview, originalSubviewIndex) = originalSuperviewAndIndex {
                originalSuperview.insertSubview(containedView, at: originalSubviewIndex)
            }

            if let viewController = viewController, let originalParent = originalParent {
                originalParent.addChild(viewController)
            }
        }

        // Force a layout pass after the view is in the hierarchy so that the conversion to screen coordinates works
        // correctly.
        containedView.setNeedsLayout()
        containedView.layoutIfNeeded()

        snapshotView.image = try containedView.renderToImage(
            monochrome: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode
        )
        snapshotView.bounds.size = containedView.bounds.size

        // Complete the layout pass after the view is restored to this container, in case it was modified during the
        // rendering process (i.e. when the rendering is tiled and stitched).
        containedView.layoutIfNeeded()

        let parser = AccessibilityHierarchyParser()
        let markers = parser.parseAccessibilityElements(in: containedView)

        var displayMarkers: [DisplayMarker] = []
        for (index, marker) in markers.enumerated() {
            let color = markerColors[index % markerColors.count]

            let legendView = LegendView(marker: marker, color: color, showUserInputLabels: showUserInputLabels)
            addSubview(legendView)

            let overlayView = UIView()
            snapshotView.addSubview(overlayView)

            switch marker.shape {
            case let .frame(rect):
                // The `overlayView` itself is used to highlight the region.
                overlayView.backgroundColor = color.withAlphaComponent(0.3)
                overlayView.frame = rect

            case let .path(path):
                // The `overlayView` acts as a container for the highlight path. Since the `path` is already relative to
                // the `snaphotView`, the `overlayView` takes up the entire size of its parent.
                overlayView.frame = snapshotView.bounds
                let overlayLayer = CAShapeLayer()
                overlayLayer.lineWidth = 4
                overlayLayer.strokeColor = color.withAlphaComponent(0.3).cgColor
                overlayLayer.fillColor = nil
                overlayLayer.path = path.cgPath
                overlayView.layer.addSublayer(overlayLayer)
            }

            var displayMarker = DisplayMarker(
                marker: marker,
                legendView: legendView,
                overlayView: overlayView,
                activationPointView: nil
            )

            switch activationPointDisplayMode {
            case .whenOverridden:
                if !marker.usesDefaultActivationPoint {
                    fallthrough
                }

            case .always:
                guard containedView.bounds.contains(marker.activationPoint) else {
                    break
                }

                let activationPointView = UIImageView(
                    image: UIImage(named: "Crosshairs", in: Bundle.accessibilitySnapshotResources, compatibleWith: nil)
                )
                activationPointView.bounds.size = .init(width: 16, height: 16)
                activationPointView.center = marker.activationPoint
                activationPointView.tintColor = color
                snapshotView.addSubview(activationPointView)
                displayMarker.activationPointView = activationPointView

            case .never:
                break // No-op.
            }

            displayMarkers.append(displayMarker)
        }
        self.displayMarkers = displayMarkers
    }

    // MARK: - Public Static Properties

    public static let defaultMarkerColors: [UIColor] = [ .cyan, .magenta, .green, .blue, .yellow, .purple, .orange ]

    // MARK: - Private Types

    private struct DisplayMarker {

        var marker: AccessibilityMarker

        var legendView: LegendView

        var overlayView: UIView

        var activationPointView: UIView?

    }

}

// MARK: -

extension AccessibilitySnapshotView {

    public enum ViewRenderingMode {

        /// Render the view's layer in a `CGContext` using the `render(in:)` method.
        case renderLayerInContext

        /// Draw the view's hierarchy after screen updates using the `drawHierarchy(in:afterScreenUpdates:)` method.
        case drawHierarchyInRect

    }

}

// MARK: -

private extension AccessibilitySnapshotView {

    final class LegendView: UIView {

        // MARK: - Life Cycle

        init(marker: AccessibilityMarker, color: UIColor, showUserInputLabels: Bool) {
            self.hintLabel = marker.hint.map {
                let label = UILabel()
                label.text = $0
                label.font = Metrics.hintLabelFont
                label.textColor = .init(white: 0.3, alpha: 1.0)
                label.numberOfLines = 0
                return label
            }

            // If our description and hint are both empty, but we have custom actions, we'll use the description label
            // to show the "Actions Available" text, since this makes our layout simpler when we align to the marker.
            let showActionsAvailableInDescription = (marker.description.isEmpty && !marker.customActions.isEmpty)

            self.customActionsView = {
                guard !marker.customActions.isEmpty else { return nil }
                
                return .init(
                    actionsAvailableText: showActionsAvailableInDescription
                        ? nil
                        : Strings.actionsAvailableText(for: marker.accessibilityLanguage),
                    customActions: marker.customActions
                )
            }()
            
            // If our description and hint are both empty, and we dont have custom actions, but we do have custom content, we'll use the description label
            // to show the "More Content Available" text, since this makes our layout simpler when we align to the marker.
            let showCustomContentInDescription = (marker.description.isEmpty && !showActionsAvailableInDescription && !marker.customContent.isEmpty)

            self.customContentView = {
                guard !marker.customContent.isEmpty else { return nil }
                
                return .init(
                    customContentText: showCustomContentInDescription
                        ? nil
                        : Strings.moreContentAvailableText(for: marker.accessibilityLanguage),
                    customContent: marker.customContent
                )
            }()
            
            self.userInputLabelsView = {
                guard showUserInputLabels, let userInputLabels = marker.userInputLabels, userInputLabels.count > 0 else { return nil }
                
                return .init(titles: userInputLabels, color: color)
            }()

            super.init(frame: .zero)

            markerView.backgroundColor = color.withAlphaComponent(0.3)
            addSubview(markerView)

            descriptionLabel.text =
                showCustomContentInDescription
                ? Strings.moreContentAvailableText(for: marker.accessibilityLanguage)
                : showActionsAvailableInDescription
                ? Strings.actionsAvailableText(for: marker.accessibilityLanguage)
                : marker.description
            
            descriptionLabel.font = Metrics.descriptionLabelFont
            descriptionLabel.textColor = .black
            descriptionLabel.numberOfLines = 0
            addSubview(descriptionLabel)

            hintLabel.map(addSubview)
            customActionsView.map(addSubview)
            customContentView.map(addSubview)
            userInputLabelsView.map(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let markerView: UIView = .init()

        private let descriptionLabel: UILabel = .init()

        private let hintLabel: UILabel?

        private let customActionsView: CustomActionsView?

        private let customContentView: CustomContentView?

        private let userInputLabelsView: PillsView?

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelSizeToFit = CGSize(
                width: size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height
            let markerSizeAboveDescriptionLabel = (Metrics.markerSize - descriptionLabelSingleLineHeight) / 2

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSize = descriptionLabel.sizeThatFits(labelSizeToFit)

            let hintLabelSize = hintLabel?.sizeThatFits(labelSizeToFit) ?? .zero

            let customActionsSize = customActionsView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let customContentSize = customContentView?.sizeThatFits(labelSizeToFit) ?? .zero
            
            let userInputLabelsViewSize = userInputLabelsView?.sizeThatFits(labelSizeToFit) ?? .zero

            let widthComponents = [
                Metrics.markerSize,
                Metrics.markerToLabelSpacing,
                max(
                    descriptionLabelSize.width,
                    hintLabelSize.width,
                    customActionsSize.width,
                    customContentSize.width,
                    userInputLabelsViewSize.width
                ),
            ]

            let heightComponents = [
                markerSizeAboveDescriptionLabel,
                descriptionLabelSize.height,
                (hintLabelSize.height == 0 ? 0 : hintLabelSize.height + Metrics.interSectionSpacing),
                (customActionsSize.height == 0 ? 0 : customActionsSize.height + Metrics.interSectionSpacing),
                (customContentSize.height == 0 ? 0 : customContentSize.height + Metrics.interSectionSpacing),
                (userInputLabelsViewSize.height == 0 ? 0 : userInputLabelsViewSize.height + Metrics.interSectionSpacing)
            ]

            return CGSize(
                width: widthComponents.reduce(0, +),
                height: max(
                    Metrics.markerSize,
                    heightComponents.reduce(0, +)
                )
            )
        }

        override func layoutSubviews() {
            markerView.frame = CGRect(x: 0, y: 0, width: Metrics.markerSize, height: Metrics.markerSize)

            let labelSizeToFit = CGSize(
                width: bounds.size.width - Metrics.markerSize - Metrics.markerToLabelSpacing,
                height: .greatestFiniteMagnitude
            )

            descriptionLabel.numberOfLines = 1
            let descriptionLabelSingleLineHeight = descriptionLabel.sizeThatFits(labelSizeToFit).height

            descriptionLabel.numberOfLines = 0
            let descriptionLabelSizeThatFits = descriptionLabel.sizeThatFits(labelSizeToFit)

            descriptionLabel.frame = .init(
                x: markerView.frame.maxX + Metrics.markerToLabelSpacing,
                y: markerView.frame.minY + (markerView.frame.height - descriptionLabelSingleLineHeight) / 2,
                width: descriptionLabelSizeThatFits.width,
                height: descriptionLabelSizeThatFits.height
            )

            if let hintLabel = hintLabel {
                hintLabel.bounds.size = hintLabel.sizeThatFits(labelSizeToFit)
                hintLabel.frame.origin = .init(
                    x: descriptionLabel.frame.minX,
                    y: descriptionLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }

            if let customActionsView = customActionsView {
                let alignmentLabel = hintLabel ?? descriptionLabel

                customActionsView.bounds.size = customActionsView.sizeThatFits(labelSizeToFit)
                customActionsView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let customContentView = customContentView {
                let alignmentLabel = customActionsView ?? hintLabel ?? descriptionLabel

                customContentView.bounds.size = customContentView.sizeThatFits(labelSizeToFit)
                customContentView.frame.origin = .init(
                    x: alignmentLabel.frame.minX,
                    y: alignmentLabel.frame.maxY + Metrics.interSectionSpacing
                )
            }
            
            if let userInputLabelsView = userInputLabelsView {
                let alignmentControl = customContentView ?? customActionsView ?? hintLabel ?? descriptionLabel
                
                userInputLabelsView.bounds.size = userInputLabelsView.sizeThatFits(labelSizeToFit)
                userInputLabelsView.frame.origin = CGPoint(
                    x: alignmentControl.frame.minX,
                    y: alignmentControl.frame.maxY + Metrics.interSectionSpacing
                )
            }
        }

        // MARK: - Private

        fileprivate enum Metrics {

            static let minimumWidth: CGFloat = 284

            static let markerSize: CGFloat = 14
            static let markerToLabelSpacing: CGFloat = 16
            static let interSectionSpacing: CGFloat = 4

            static let descriptionLabelFont = UIFont.systemFont(ofSize: 12)
            static let hintLabelFont = UIFont.italicSystemFont(ofSize: 12)

        }

        private enum Strings {

            static func actionsAvailableText(for locale: String?) -> String {
                return "Actions Available".localized(
                    key: "custom_actions.description",
                    comment: "Description for an accessibility element indicating that it has custom actions available",
                    locale: locale
                )
            }
            
            static func moreContentAvailableText(for locale: String?) -> String {
                return "More Content Available".localized(
                    key: "custom_content.description",
                    comment: "Description for an accessibility element indicating that it has additional custom content available",
                    locale: locale
                )
            }
        }

    }
    
    // MARK: -

    private final class CustomActionsView: UIView {

        // MARK: - Life Cycle

        init(actionsAvailableText: String?, customActions: [String]) {
            actionLabels = customActions.map {
                let iconLabel = UILabel()
                iconLabel.text = "↓"
                iconLabel.font = Metrics.font
                iconLabel.textColor = .black
                iconLabel.numberOfLines = 0

                let actionDescriptionLabel = UILabel()
                actionDescriptionLabel.text = $0
                actionDescriptionLabel.font = Metrics.font
                actionDescriptionLabel.textColor = .black
                actionDescriptionLabel.numberOfLines = 0

                return (iconLabel, actionDescriptionLabel)
            }

            if let actionsAvailableText = actionsAvailableText {
                let label = UILabel()
                label.text = actionsAvailableText
                label.font = Metrics.font
                label.textColor = .black
                self.actionsAvailableLabel = label

            } else {
                self.actionsAvailableLabel = nil
            }

            super.init(frame: .zero)

            actionsAvailableLabel.map(addSubview)

            actionLabels.forEach {
                addSubview($0)
                addSubview($1)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let actionsAvailableLabel: UILabel?

        private let actionLabels: [(UILabel, UILabel)]

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let actionsAvailableHeight = actionsAvailableLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing

            guard let (firstIconLabel, _) = actionLabels.first else {
                return .init(width: max(size.width, 0), height: actionsAvailableHeight)
            }

            let descriptionWidthToFit = [
                Metrics.actionIconInset,
                firstIconLabel.sizeThatFits(size).width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(size.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            let height = actionLabels
                .map { $1.sizeThatFits(descriptionSizeToFit).height }
                .reduce(actionsAvailableHeight) {
                    $0 + Metrics.verticalSpacing + $1
                }

            return .init(width: size.width, height: height)
        }

        override func layoutSubviews() {
            let firstPairYPosition: CGFloat
            if let actionsAvailableLabel = actionsAvailableLabel {
                actionsAvailableLabel.bounds.size = actionsAvailableLabel.sizeThatFits(bounds.size)
                actionsAvailableLabel.frame.origin = .zero

                firstPairYPosition = actionsAvailableLabel.frame.maxY + Metrics.verticalSpacing

            } else {
                firstPairYPosition = 0
            }

            guard let (firstIconLabel, firstDescriptionLabel) = actionLabels.first else {
                return
            }

            firstIconLabel.sizeToFit()

            // All of the icon labels should be the same size, so we only need to calculate the description width once.
            let descriptionWidthToFit = [
                Metrics.actionIconInset,
                firstIconLabel.bounds.width,
                Metrics.iconToDescriptionSpacing,
            ].reduce(bounds.width, -)
            let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

            firstDescriptionLabel.bounds.size = firstDescriptionLabel.sizeThatFits(descriptionSizeToFit)

            firstIconLabel.frame.origin = .init(x: Metrics.actionIconInset, y: firstPairYPosition)

            let descriptionXPosition = firstIconLabel.frame.maxX + Metrics.iconToDescriptionSpacing

            firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstPairYPosition)

            let zippedActionLabels = zip(actionLabels.dropFirst(), actionLabels)
            for ((iconLabel, descriptionLabel), (_, previousDescriptionLabel)) in zippedActionLabels {
                iconLabel.sizeToFit()
                descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)

                let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing

                iconLabel.frame.origin = .init(x: Metrics.actionIconInset, y: yPosition)
                descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)
            }
        }

        // MARK: - Private Types

        private enum Metrics {

            static let verticalSpacing: CGFloat = 4
            static let actionIconInset: CGFloat = 4
            static let iconToDescriptionSpacing: CGFloat = 4

            static let font: UIFont = .systemFont(ofSize: 12)

        }

    }

}


// MARK: -

private final class CustomContentView: UIView {

    // MARK: - Life Cycle
    
    init(customContentText: String?, customContent: [(String, String, Bool)]) {
        
        contentLabels = customContent.map { (label, value, isImportant) in
            let iconLabel = UILabel()
            iconLabel.text = "↓"
            iconLabel.font = Metrics.font
            iconLabel.numberOfLines = 0
            
            let customContentLabel = UILabel()
            customContentLabel.font = isImportant ? Metrics.boldFont : Metrics.font
            customContentLabel.numberOfLines = 0
            customContentLabel.text = {
                guard !value.isEmpty else { return label }
                return "\(label): \(value)"
            }()
            
            return (iconLabel, customContentLabel)
        }

        if let customContentText = customContentText {
            let label = UILabel()
            label.text = customContentText
            label.font = Metrics.font
            self.customContentLabel = label

        } else {
            self.customContentLabel = nil
        }

        super.init(frame: .zero)

        customContentLabel.map(addSubview)

        contentLabels.forEach {
            addSubview($0)
            addSubview($1)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let customContentLabel: UILabel?

    private let contentLabels: [(UILabel, UILabel)]

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let actionsAvailableHeight = customContentLabel?.sizeThatFits(size).height ?? -Metrics.verticalSpacing

        guard let (firstIconLabel, _) = contentLabels.first else {
            return .init(width: max(size.width, 0), height: actionsAvailableHeight)
        }

        let descriptionWidthToFit = [
            Metrics.contentIconInset,
            firstIconLabel.sizeThatFits(size).width,
            Metrics.iconToDescriptionSpacing,
        ].reduce(size.width, -)
        let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

        let height = contentLabels
            .map { $1.sizeThatFits(descriptionSizeToFit).height }
            .reduce(actionsAvailableHeight) {
                $0 + Metrics.verticalSpacing + $1
            }

        return .init(width: size.width, height: height)
    }

    override func layoutSubviews() {
        let firstPairYPosition: CGFloat
        if let actionsAvailableLabel = customContentLabel {
            actionsAvailableLabel.bounds.size = actionsAvailableLabel.sizeThatFits(bounds.size)
            actionsAvailableLabel.frame.origin = .zero

            firstPairYPosition = actionsAvailableLabel.frame.maxY + Metrics.verticalSpacing

        } else {
            firstPairYPosition = 0
        }

        guard let (firstIconLabel, firstDescriptionLabel) = contentLabels.first else {
            return
        }

        firstIconLabel.sizeToFit()

        // All of the icon labels should be the same size, so we only need to calculate the description width once.
        let descriptionWidthToFit = [
            Metrics.contentIconInset,
            firstIconLabel.bounds.width,
            Metrics.iconToDescriptionSpacing,
        ].reduce(bounds.width, -)
        let descriptionSizeToFit = CGSize(width: descriptionWidthToFit, height: .greatestFiniteMagnitude)

        firstDescriptionLabel.bounds.size = firstDescriptionLabel.sizeThatFits(descriptionSizeToFit)

        firstIconLabel.frame.origin = .init(x: Metrics.contentIconInset, y: firstPairYPosition)

        let descriptionXPosition = firstIconLabel.frame.maxX + Metrics.iconToDescriptionSpacing

        firstDescriptionLabel.frame.origin = .init(x: descriptionXPosition, y: firstPairYPosition)

        let zippedActionLabels = zip(contentLabels.dropFirst(), contentLabels)
        for ((iconLabel, descriptionLabel), (_, previousDescriptionLabel)) in zippedActionLabels {
            iconLabel.sizeToFit()
            descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionSizeToFit)

            let yPosition = previousDescriptionLabel.frame.maxY + Metrics.verticalSpacing

            iconLabel.frame.origin = .init(x: Metrics.contentIconInset, y: yPosition)
            descriptionLabel.frame.origin = .init(x: descriptionXPosition, y: yPosition)
        }
    }

    // MARK: - Private Types

    private enum Metrics {

        static let verticalSpacing: CGFloat = 4
        static let contentIconInset: CGFloat = 4
        static let iconToDescriptionSpacing: CGFloat = 4

        static let font: UIFont = .systemFont(ofSize: 12)
        static let boldFont: UIFont = .boldSystemFont(ofSize: 12)

    }
}

// MARK: -

private extension Bundle {

    private final class Sentinel {}

    static var accessibilitySnapshotResources: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let container = Bundle(for: Sentinel.self)
        let resources = container.url(forResource: "AccessibilitySnapshot", withExtension: "bundle")!
        return Bundle(url: resources)!
        #endif
    }()

}

// MARK: -

private extension UIView {

    func superviewWithSubviewIndex() -> (UIView, Int)? {
        guard let superview = superview else {
            return nil
        }

        guard let index = superview.subviews.firstIndex(of: self) else {
            fatalError("Internal inconsistency error: view has a superview, but is not a subview of the superview")
        }

        return (superview, index)
    }

}
