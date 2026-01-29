import UIKit

class ElementFrameComparisonController: AccessibilityViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let frameHeader = MyLabel("Adjusting the accessibility frame vertically by > 8.0 alters the sort order")
        frameHeader.accessibilityTraits = [.staticText, .header]

        let pathHeader = MyLabel("Accessibility path is ignored entirely for sorting purposes")
        pathHeader.accessibilityTraits = [.staticText, .header]

        let spacing = 20.0

        // 8 seems to be the magic number for VoiceOver to consider it
        // to be vertically "above" other views
        let voiceoverMagicNumber = 8.0

        let frames = UIStackView(arrangedSubviews: [
            // Label where the accessibilityFrame will be the view's frame
            // translated vertically by 8 pt down
            MyLabel(
                "frame down",
                accessibilityLabel: "Third",
                accessibilityFrame: .rect {
                    var rect = $0
                    rect.origin.y += voiceoverMagicNumber
                    return rect
                }
            ),

            // Label where the accessibilityFrame is unmodified
            MyLabel("unchanged", accessibilityLabel: "Second"),

            // Label where the accessibilityFrame will be the view's frame
            // translated vertically by 8 pt up
            MyLabel(
                "frame up",
                accessibilityLabel: "First",
                accessibilityFrame: .rect {
                    var rect = $0
                    rect.origin.y -= voiceoverMagicNumber
                    return rect
                }
            ),
        ])

        let paths = UIStackView(arrangedSubviews: [
            // Label where the accessibilityPath will be the view's frame
            // translated vertically by 8 pt down
            MyLabel(
                "path down",
                accessibilityLabel: "Fourth",
                accessibilityFrame: .path {
                    var rect = $0
                    rect.origin.y += voiceoverMagicNumber
                    return UIBezierPath(roundedRect: rect, cornerRadius: 5)
                }
            ),

            // Label where the accessibilityPath is unmodified
            MyLabel(
                "path unchanged",
                accessibilityLabel: "Fifth",
                accessibilityFrame: .path {
                    UIBezierPath(roundedRect: $0, cornerRadius: 5)
                }
            ),

            // Label where the accessibilityPath will be the view's frame
            // translated vertically by 8 pt up
            MyLabel(
                "path up",
                accessibilityLabel: "Sixth",
                accessibilityFrame: .path {
                    var rect = $0
                    rect.origin.y -= voiceoverMagicNumber
                    return UIBezierPath(roundedRect: rect, cornerRadius: 5)
                }
            ),

        ])

        frames.axis = .horizontal
        paths.axis = .horizontal

        frames.spacing = spacing
        paths.spacing = spacing

        view.addSubview(frameHeader)
        view.addSubview(frames)

        view.addSubview(pathHeader)
        view.addSubview(paths)

        frameHeader.translatesAutoresizingMaskIntoConstraints = false
        frames.translatesAutoresizingMaskIntoConstraints = false

        pathHeader.translatesAutoresizingMaskIntoConstraints = false
        paths.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            frameHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: spacing),
            frameHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            frames.topAnchor.constraint(equalTo: frameHeader.bottomAnchor, constant: spacing),
            frames.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frames.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            pathHeader.topAnchor.constraint(equalTo: frames.bottomAnchor, constant: spacing),
            pathHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            paths.topAnchor.constraint(equalTo: pathHeader.bottomAnchor, constant: spacing),
            paths.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paths.trailingAnchor.constraint(equalTo: view.trailingAnchor),

        ])
    }
}

enum AccessibilityFrame {
    case `default`
    case path((CGRect) -> UIBezierPath)
    case rect((CGRect) -> CGRect)
}

class MyLabel: UILabel {
    private let _accessibilityFrame: AccessibilityFrame

    init(_ text: String, align: NSTextAlignment = .left, accessibilityLabel: String? = nil, accessibilityFrame: AccessibilityFrame = .default) {
        _accessibilityFrame = accessibilityFrame
        super.init(frame: .zero)
        self.text = text
        textAlignment = align
        backgroundColor = .gray.withAlphaComponent(0.2)
        if let accessibilityLabel {
            self.accessibilityLabel = accessibilityLabel
        }

        numberOfLines = 0
        lineBreakMode = .byWordWrapping
    }

    required init?(coder: NSCoder) { nil }

    override var accessibilityPath: UIBezierPath? {
        set { _ = newValue }
        get {
            switch _accessibilityFrame {
            case .default, .rect:
                return nil

            case let .path(transform):
                guard let superview else { return nil }
                return UIAccessibility.convertToScreenCoordinates(transform(frame), in: superview)
            }
        }
    }

    override var accessibilityFrame: CGRect {
        set { _ = newValue }
        get {
            switch _accessibilityFrame {
            case .default, .path:
                return super.accessibilityFrame

            case let .rect(transform):
                guard let superview else { return super.accessibilityFrame }
                return UIAccessibility.convertToScreenCoordinates(transform(frame), in: superview)
            }
        }
    }
}
