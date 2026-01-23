import AccessibilitySnapshotParser
import UIKit

// MARK: - Shared Metrics

private enum KeyCapMetrics {
    static let height: CGFloat = 22
    static let minWidth: CGFloat = 24
    static let horizontalPadding: CGFloat = 6
    static let cornerRadius: CGFloat = 4
    static let spacing: CGFloat = 4
    static let font = UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
    static let backgroundColor = UIColor(white: 0.88, alpha: 1.0)
    static let borderColor = UIColor(white: 0.75, alpha: 1.0)
    static let borderWidth: CGFloat = 0.5
}

/// A view that displays a single keyboard shortcut legend entry with keycap-style keys.
final class KeyboardShortcutLegendView: UIView {
    // MARK: - Private Types

    private enum Metrics {
        static let keyCapsToTitleSpacing: CGFloat = 10
        static let titleToHintSpacing: CGFloat = 2
        static let titleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let hintFont = UIFont.italicSystemFont(ofSize: 12)
    }

    // MARK: - Private Properties

    private let shortcut: KeyboardShortcut
    private var keyCapViews: [KeyCapView] = []
    private let titleLabel: UILabel = .init()
    private let hintLabel: UILabel = .init()

    // MARK: - Life Cycle

    init(shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
        super.init(frame: .zero)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    private func setUpViews() {
        for symbol in shortcut.modifierSymbols {
            let keyCapView = KeyCapView(symbol: symbol)
            addSubview(keyCapView)
            keyCapViews.append(keyCapView)
        }

        let mainKeyView = KeyCapView(symbol: shortcut.keySymbol)
        addSubview(mainKeyView)
        keyCapViews.append(mainKeyView)

        // Set up title label
        let titleText = shortcut.title ?? shortcut.displayTitle
        titleLabel.text = titleText
        titleLabel.font = Metrics.titleFont
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        // Set up hint label - show discoverabilityTitle if available and different from title
        let hintText = shortcut.discoverabilityTitle
        if let hintText = hintText, !hintText.isEmpty, hintText != titleText {
            hintLabel.text = hintText
            hintLabel.font = Metrics.hintFont
            hintLabel.textColor = .init(white: 0.4, alpha: 1.0)
            hintLabel.numberOfLines = 0
            addSubview(hintLabel)
        }
    }

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = calculateLayout(for: size)
        return CGSize(
            width: layout.keyCapsWidth + Metrics.keyCapsToTitleSpacing + max(layout.titleSize.width, layout.hintSize.width),
            height: max(KeyCapMetrics.height, layout.textHeight)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var currentX: CGFloat = 0
        for keyCapView in keyCapViews {
            let keyCapSize = keyCapView.sizeThatFits(bounds.size)
            keyCapView.frame = CGRect(
                x: currentX,
                y: (bounds.height - keyCapSize.height) / 2,
                width: keyCapSize.width,
                height: keyCapSize.height
            )
            currentX += keyCapSize.width + KeyCapMetrics.spacing
        }

        let layout = calculateLayout(for: bounds.size)
        let textStartY = (bounds.height - layout.textHeight) / 2
        let textX = layout.keyCapsWidth + Metrics.keyCapsToTitleSpacing

        titleLabel.frame = CGRect(
            x: textX,
            y: textStartY,
            width: layout.titleSize.width,
            height: layout.titleSize.height
        )

        if hintLabel.superview != nil {
            hintLabel.frame = CGRect(
                x: textX,
                y: titleLabel.frame.maxY + Metrics.titleToHintSpacing,
                width: layout.hintSize.width,
                height: layout.hintSize.height
            )
        }
    }

    // MARK: - Private Layout Helpers

    private struct LayoutInfo {
        let keyCapsWidth: CGFloat
        let titleSize: CGSize
        let hintSize: CGSize
        let textHeight: CGFloat
    }

    private func calculateLayout(for size: CGSize) -> LayoutInfo {
        var keyCapsWidth: CGFloat = 0
        for keyCapView in keyCapViews {
            keyCapsWidth += keyCapView.sizeThatFits(size).width + KeyCapMetrics.spacing
        }
        keyCapsWidth -= KeyCapMetrics.spacing

        let availableTitleWidth = size.width - keyCapsWidth - Metrics.keyCapsToTitleSpacing
        let constraintSize = CGSize(width: availableTitleWidth, height: .greatestFiniteMagnitude)

        let titleSize = titleLabel.sizeThatFits(constraintSize)
        let hintSize = hintLabel.superview != nil ? hintLabel.sizeThatFits(constraintSize) : .zero
        let textHeight = titleSize.height + (hintSize.height > 0 ? Metrics.titleToHintSpacing + hintSize.height : 0)

        return LayoutInfo(keyCapsWidth: keyCapsWidth, titleSize: titleSize, hintSize: hintSize, textHeight: textHeight)
    }
}

// MARK: - KeyboardShortcutSectionHeaderView

/// A view that displays a section header for a group of keyboard shortcuts.
final class KeyboardShortcutSectionHeaderView: UIView {
    // MARK: - Private Types

    private enum Metrics {
        static let font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let textColor = UIColor(white: 0.4, alpha: 1.0)
        static let topPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 4
    }

    // MARK: - Private Properties

    private let titleLabel: UILabel = .init()

    // MARK: - Life Cycle

    init(title: String) {
        super.init(frame: .zero)

        titleLabel.text = title.uppercased()
        titleLabel.font = Metrics.font
        titleLabel.textColor = Metrics.textColor
        addSubview(titleLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = titleLabel.sizeThatFits(size)
        return CGSize(
            width: labelSize.width,
            height: labelSize.height + Metrics.topPadding + Metrics.bottomPadding
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let labelSize = titleLabel.sizeThatFits(bounds.size)
        titleLabel.frame = CGRect(
            x: 0,
            y: Metrics.topPadding,
            width: labelSize.width,
            height: labelSize.height
        )
    }
}

// MARK: - KeyCapView

/// A view that renders a single key cap with a rounded rectangle background.
private final class KeyCapView: UIView {
    // MARK: - Private Properties

    private let symbolLabel: UILabel = .init()
    private let backgroundView: UIView = .init()

    // MARK: - Life Cycle

    init(symbol: String) {
        super.init(frame: .zero)

        backgroundView.backgroundColor = KeyCapMetrics.backgroundColor
        backgroundView.layer.cornerRadius = KeyCapMetrics.cornerRadius
        backgroundView.layer.borderColor = KeyCapMetrics.borderColor.cgColor
        backgroundView.layer.borderWidth = KeyCapMetrics.borderWidth
        addSubview(backgroundView)

        symbolLabel.text = symbol
        symbolLabel.font = KeyCapMetrics.font
        symbolLabel.textColor = .black
        symbolLabel.textAlignment = .center
        addSubview(symbolLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = symbolLabel.sizeThatFits(size)
        let width = max(KeyCapMetrics.minWidth, labelSize.width + KeyCapMetrics.horizontalPadding * 2)
        return CGSize(width: width, height: KeyCapMetrics.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        symbolLabel.frame = bounds
    }
}
