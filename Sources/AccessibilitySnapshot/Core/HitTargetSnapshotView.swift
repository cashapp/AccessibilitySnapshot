import UIKit

public final class HitTargetSnapshotView: SnapshotAndLegendView {
    // MARK: - Life Cycle

    public init(
        baseView: UIView,
        useMonochromeSnapshot: Bool,
        viewRenderingMode: ViewRenderingMode,
        colors: [UIColor] = [],
        maxPermissibleMissedRegionWidth: CGFloat = 0,
        maxPermissibleMissedRegionHeight: CGFloat = 0
    ) throws {
        // Some implementations of hit testing rely on the window, so install the view in a window if needed.
        let requiresWindow = (baseView.window == nil && !(baseView is UIWindow))
        if requiresWindow {
            let window = UIApplication.shared.firstKeyWindow ?? UIWindow(frame: UIScreen.main.bounds)
            window.addSubview(baseView)
        }

        baseView.layoutIfNeeded()

        let (snapshotImage, orderedViewColorPairs) = try HitTargetSnapshotUtility.generateSnapshotImage(
            for: baseView,
            useMonochromeSnapshot: useMonochromeSnapshot,
            viewRenderingMode: viewRenderingMode,
            colors: colors,
            maxPermissibleMissedRegionWidth: maxPermissibleMissedRegionWidth,
            maxPermissibleMissedRegionHeight: maxPermissibleMissedRegionHeight
        )

        if requiresWindow {
            baseView.removeFromSuperview()
        }

        _legendViews = orderedViewColorPairs.map { color, hitView in
            LegendView(markerColor: color, hitView: hitView)
        }

        super.init(frame: .zero)

        snapshotView.image = snapshotImage
        snapshotView.bounds.size = baseView.bounds.size

        legendViews.forEach { addSubview($0) }

        backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SnapshotAndLegendView

    override public var legendViews: [UIView] {
        return _legendViews
    }

    override public var minimumLegendWidth: CGFloat {
        return LegendView.Metrics.minimumWidth
    }

    // MARK: - Private Properties

    private let _legendViews: [LegendView]
}

// MARK: -

private extension HitTargetSnapshotView {
    final class LegendView: UIView {
        // MARK: - Life Cycle

        init(markerColor: UIColor, hitView: UIView) {
            super.init(frame: .zero)

            markerView.backgroundColor = markerColor.withAlphaComponent(0.3)
            addSubview(markerView)

            if let accessibilityIdentifier = hitView.accessibilityIdentifier, !accessibilityIdentifier.isEmpty {
                descriptionLabel.text = accessibilityIdentifier
                descriptionLabel.textColor = .black
                descriptionLabel.font = .systemFont(ofSize: 12)
            } else {
                descriptionLabel.text = "<\(String(describing: type(of: hitView)))>"
                descriptionLabel.textColor = .black
                descriptionLabel.font = .italicSystemFont(ofSize: 12)
            }
            descriptionLabel.numberOfLines = 0
            addSubview(descriptionLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let markerView: UIView = .init()

        private let descriptionLabel: UILabel = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            markerView.frame = CGRect(x: 0, y: 0, width: LegendLayoutMetrics.markerSize, height: LegendLayoutMetrics.markerSize)

            let descriptionLayoutBounds = bounds.inset(
                by: .init(top: 0, left: LegendLayoutMetrics.markerSize + LegendLayoutMetrics.markerToLabelSpacing, bottom: 0, right: 0)
            )
            let firstLineHeight = descriptionLabel
                .textRect(forBounds: descriptionLayoutBounds, limitedToNumberOfLines: 1)
                .height
            let labelVerticalInset = (LegendLayoutMetrics.markerSize - firstLineHeight) / 2

            descriptionLabel.bounds.size = descriptionLabel.sizeThatFits(descriptionLayoutBounds.size)
            descriptionLabel.frame.origin = .init(
                x: descriptionLayoutBounds.minX,
                y: descriptionLayoutBounds.minY + labelVerticalInset
            )
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let descriptionLayoutBounds = CGRect(origin: .zero, size: size).inset(
                by: .init(top: 0, left: LegendLayoutMetrics.markerSize + LegendLayoutMetrics.markerToLabelSpacing, bottom: 0, right: 0)
            )
            let firstLineHeight = descriptionLabel
                .textRect(forBounds: descriptionLayoutBounds, limitedToNumberOfLines: 1)
                .height
            let labelVerticalInset = (LegendLayoutMetrics.markerSize - firstLineHeight) / 2
            let labelSize = descriptionLabel.sizeThatFits(descriptionLayoutBounds.size)

            return CGSize(width: size.width, height: max(LegendLayoutMetrics.markerSize, labelVerticalInset + labelSize.height))
        }

        // MARK: - Private Types

        fileprivate enum Metrics {
            static let minimumWidth: CGFloat = 240
        }
    }
}
