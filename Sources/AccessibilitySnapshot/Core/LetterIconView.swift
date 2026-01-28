import UIKit

extension AccessibilitySnapshotView {
    final class LetterIconView: UIView {
        // MARK: - Life Cycle

        init(letter: Character, size: CGSize) {
            self.letter = letter
            iconSize = size

            super.init(frame: CGRect(origin: .zero, size: size))

            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let letter: Character
        private let iconSize: CGSize

        // MARK: - UIView

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return iconSize
        }

        override var intrinsicContentSize: CGSize {
            return iconSize
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)

            let cornerRadius = min(iconSize.width, iconSize.height) * 0.2
            let strokeWidth: CGFloat = 1.0

            // Inset the rect to account for stroke width so it doesn't get clipped
            let insetRect = rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)

            // Draw rounded rectangle border (stroke only, no fill)
            let path = UIBezierPath(roundedRect: insetRect, cornerRadius: cornerRadius)
            path.lineWidth = strokeWidth
            UIColor.darkGray.setStroke()
            path.stroke()

            // Draw the letter - scale font size proportionally to icon size
            let fontSize = min(iconSize.width, iconSize.height) * 0.6
            let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.darkGray,
            ]
            let text = String(letter)
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
