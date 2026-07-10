import AccessibilitySnapshotParser
import UIKit

/// An opt-in legend row summarizing how many off-screen elements were trimmed from a single
/// scrollable container, bucketed above/below its viewport. Rendered per non-empty
/// `ScrollContainerSummary` when `AccessibilitySnapshotConfiguration.showsOffscreenElementCounts`
/// is enabled; the default legend is unchanged when it is not.
final class OffscreenCountsLegendView: UIView {
    // MARK: - Life Cycle

    init(summary: ScrollContainerSummary, locale: String? = nil) {
        super.init(frame: .zero)

        var lines: [String] = []
        let above = summary.trimmedAbove + (summary.trimmedElsewhere / 2)
        // `trimmedElsewhere` covers elements that could not be cleanly bucketed; split its odd
        // remainder toward "below" so the visible total still reflects everything trimmed.
        let below = summary.trimmedBelow + (summary.trimmedElsewhere - summary.trimmedElsewhere / 2)
        if above > 0 {
            lines.append(Strings.offscreenElementsAboveText(count: above, for: locale))
        }
        if below > 0 {
            lines.append(Strings.offscreenElementsBelowText(count: below, for: locale))
        }

        label.text = lines.joined(separator: "\n")
        label.font = Metrics.font
        label.textColor = .init(white: 0.3, alpha: 1.0)
        label.numberOfLines = 0
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let label = UILabel()

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inset = Metrics.markerSize + Metrics.markerToLabelSpacing
        let labelSize = label.sizeThatFits(CGSize(width: size.width - inset, height: .greatestFiniteMagnitude))
        return CGSize(width: size.width, height: max(Metrics.markerSize, labelSize.height))
    }

    override func layoutSubviews() {
        let inset = Metrics.markerSize + Metrics.markerToLabelSpacing
        let labelSize = label.sizeThatFits(CGSize(width: bounds.width - inset, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: inset, y: 0, width: labelSize.width, height: labelSize.height)
    }

    // MARK: - Private

    private enum Metrics {
        static var markerSize: CGFloat { LegendLayoutMetrics.markerSize }
        static var markerToLabelSpacing: CGFloat { LegendLayoutMetrics.markerToLabelSpacing }
        static let font = UIFont.italicSystemFont(ofSize: LegendLayoutMetrics.hintFontSize)
    }
}
