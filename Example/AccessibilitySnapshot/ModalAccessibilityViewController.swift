import Paralayout
import UIKit

final class ModalAccessibilityViewController: AccessibilityViewController {
    // MARK: - Life Cycle

    enum Configuration {
        case singleModal
        case singleDirectModal
        case singleInaccessibleModal
        case twoModals
        case modalWithForeground
    }

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let configuration: Configuration

    // MARK: - UIViewController

    override func loadView() {
        view = buildView(for: configuration)
    }

    private func buildView(for configuration: Configuration) -> UIView {
        let root = UIView()
        root.backgroundColor = .white

        let backgroundLabel = makeLabel("Background", color: .darkGray)
        let backgroundRow = makeRow([
            makeButton("Settings"),
            makeButton("Profile"),
            makeButton("Help"),
        ])

        let backgroundLayer = makeLayer(
            color: UIColor(white: 0.93, alpha: 1),
            label: backgroundLabel,
            content: backgroundRow
        )
        root.addSubview(backgroundLayer)

        switch configuration {
        case .singleModal:
            let modalContent = makeRow([
                makeButton("Cancel"),
                makeButton("Confirm"),
            ])
            let modalLabel = makeLabel("Modal", color: .white)
            let modalLayer = makeLayer(
                color: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1),
                label: modalLabel,
                content: modalContent,
                isModal: true
            )
            root.addSubview(modalLayer)

        case .singleDirectModal:
            let modalLayer = UIView()
            modalLayer.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
            modalLayer.layer.cornerRadius = 12
            modalLayer.accessibilityViewIsModal = true
            modalLayer.isAccessibilityElement = true
            modalLayer.accessibilityLabel = "Alert Dialog"
            root.addSubview(modalLayer)

        case .singleInaccessibleModal:
            let modalLayer = UIView()
            modalLayer.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
            modalLayer.layer.cornerRadius = 12
            modalLayer.accessibilityViewIsModal = true
            modalLayer.isAccessibilityElement = false
            root.addSubview(modalLayer)

        case .twoModals:
            let modal1Content = makeRow([makeButton("OK")])
            let modal1Label = makeLabel("Modal 1", color: .white)
            let modal1 = makeLayer(
                color: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1),
                label: modal1Label,
                content: modal1Content,
                isModal: true
            )
            root.addSubview(modal1)

            let modal2Content = makeRow([makeButton("Dismiss")])
            let modal2Label = makeLabel("Modal 2", color: .white)
            let modal2 = makeLayer(
                color: UIColor(red: 0.6, green: 0.2, blue: 0.6, alpha: 1),
                label: modal2Label,
                content: modal2Content,
                isModal: true
            )
            root.addSubview(modal2)

        case .modalWithForeground:
            let modalContent = makeRow([
                makeButton("Cancel"),
                makeButton("Confirm"),
            ])
            let modalLabel = makeLabel("Modal", color: .white)
            let modalLayer = makeLayer(
                color: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1),
                label: modalLabel,
                content: modalContent,
                isModal: true
            )
            root.addSubview(modalLayer)

            let fgContent = makeRow([
                makeButton("Option A"),
                makeButton("Option B"),
            ])
            let fgLabel = makeLabel("Above Modal", color: .white)
            let fgLayer = makeLayer(
                color: UIColor(red: 0.1, green: 0.7, blue: 0.4, alpha: 1),
                label: fgLabel,
                content: fgContent
            )
            root.addSubview(fgLayer)
        }

        root.setNeedsLayout()
        return root
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounds = view.bounds
        let insets = UIEdgeInsets(top: 60, left: 20, bottom: 60, right: 20)
        let usable = bounds.inset(by: insets)

        let subviews = view.subviews
        guard !subviews.isEmpty else { return }

        let layerHeight = min(120, (usable.height - CGFloat(subviews.count - 1) * 20) / CGFloat(subviews.count))
        var y = usable.minY

        for subview in subviews {
            subview.frame = CGRect(x: usable.minX, y: y, width: usable.width, height: layerHeight)
            subview.layoutIfNeeded()
            y += layerHeight + 20
        }
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = color
        return label
    }

    private func makeButton(_ title: String) -> UIView {
        let button = UIView()
        button.backgroundColor = UIColor(white: 1, alpha: 0.25)
        button.layer.cornerRadius = 8

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .center
        button.addSubview(label)

        button.isAccessibilityElement = true
        button.accessibilityLabel = title

        return button
    }

    private func makeRow(_ buttons: [UIView]) -> UIView {
        let row = UIView()
        buttons.forEach(row.addSubview)
        return row
    }

    private func makeLayer(color: UIColor, label: UILabel, content: UIView, isModal: Bool = false) -> UIView {
        let layer = LayerView()
        layer.backgroundColor = color
        layer.layer.cornerRadius = 12
        layer.clipsToBounds = true
        layer.accessibilityViewIsModal = isModal

        layer.addSubview(label)
        layer.addSubview(content)
        layer.headerLabel = label
        layer.contentRow = content

        return layer
    }
}

// MARK: - LayerView

private final class LayerView: UIView {
    var headerLabel: UILabel?
    var contentRow: UIView?

    override func layoutSubviews() {
        super.layoutSubviews()

        let padding: CGFloat = 12

        if let header = headerLabel {
            header.sizeToFit()
            header.frame.origin = CGPoint(x: padding, y: padding)
        }

        guard let row = contentRow else { return }
        let buttons = row.subviews
        guard !buttons.isEmpty else { return }

        let headerBottom = (headerLabel?.frame.maxY ?? 0) + 8
        let rowY = headerBottom
        let rowHeight = bounds.height - rowY - padding
        row.frame = CGRect(x: padding, y: rowY, width: bounds.width - padding * 2, height: rowHeight)

        let buttonWidth = (row.bounds.width - CGFloat(buttons.count - 1) * 8) / CGFloat(buttons.count)
        var x: CGFloat = 0
        for button in buttons {
            button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: row.bounds.height)
            if let label = button.subviews.first as? UILabel {
                label.frame = button.bounds
            }
            button.accessibilityFrame = button.convert(button.bounds, to: nil)
            x += buttonWidth + 8
        }
    }
}

// MARK: - Demo Selection

extension ModalAccessibilityViewController {
    static func makeConfigurationSelectionViewController(
        presentingViewController: UIViewController
    ) -> UIViewController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let configs: [(String, Configuration)] = [
            ("Single Modal", .singleModal),
            ("Single Direct Modal", .singleDirectModal),
            ("Single Inaccessible Modal", .singleInaccessibleModal),
            ("Two Modals", .twoModals),
            ("Modal with Foreground", .modalWithForeground),
        ]

        for (title, config) in configs {
            alertController.addAction(.init(title: title, style: .default, handler: { _ in
                let vc = ModalAccessibilityViewController(configuration: config)
                presentingViewController.present(vc, animated: true)
            }))
        }

        return alertController
    }
}
