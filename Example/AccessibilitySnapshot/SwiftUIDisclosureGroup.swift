import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct SwiftUIDisclosureGroup: View {
    @State private var isExpanded = true
    @State private var isCollapsed = false

    var body: some View {
        List {
            // MARK: - Normal DisclosureGroups (SwiftUI)

            Section("SwiftUI DisclosureGroup") {
                DisclosureGroup("Expanded Section", isExpanded: $isExpanded) {
                    Text("Item 1")
                    Text("Item 2")
                }

                DisclosureGroup("Collapsed Section", isExpanded: $isCollapsed) {
                    Text("Hidden Item")
                }
            }

            // MARK: - Interactive mutation tests

            if #available(iOS 18.0, *) {
                Section("Interactive Mutation Tests") {
                    MutationTestRow().frame(height: 300)
                }
            }
        }
    }
}

// MARK: - Interactive mutation test view (no override — reads Apple's real behavior)

@available(iOS 18.0, *)
private struct MutationTestRow: UIViewRepresentable {
    func makeUIView(context: Context) -> MutationTestContainerView {
        return MutationTestContainerView()
    }

    func updateUIView(_ uiView: MutationTestContainerView, context: Context) {}
}

@available(iOS 18.0, *)
private class MutationTestContainerView: UIView {
    // Plain UIView — NO override of _accessibilityExpandedStatus
    private let testView = UIView()
    private let logLabel = UILabel()
    private var logLines: [String] = []

    private let privateGetSel = NSSelectorFromString("_accessibilityExpandedStatus")
    private let privateSetSel = NSSelectorFromString("_setAccessibilityExpandedStatus:")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func readPrivate() -> Int {
        guard testView.responds(to: privateGetSel) else { return -1 }
        let imp = testView.method(for: privateGetSel)
        typealias Fn = @convention(c) (AnyObject, Selector) -> Int
        let fn = unsafeBitCast(imp, to: Fn.self)
        return fn(testView, privateGetSel)
    }

    private func writePrivate(_ value: Int) -> Bool {
        guard testView.responds(to: privateSetSel) else { return false }
        let imp = testView.method(for: privateSetSel)
        typealias Fn = @convention(c) (AnyObject, Selector, Int) -> Void
        let fn = unsafeBitCast(imp, to: Fn.self)
        fn(testView, privateSetSel, value)
        return true
    }

    private func readPublic() -> Int {
        return testView.accessibilityExpandedStatus.rawValue
    }

    private func log(_ msg: String) {
        logLines.append(msg)
        logLabel.text = logLines.joined(separator: "\n")
    }

    private func logState(_ prefix: String) {
        log("\(prefix) → pub=\(readPublic()) priv=\(readPrivate())")
    }

    private func setup() {
        testView.isAccessibilityElement = true
        testView.accessibilityLabel = "Test Target"

        // Check if private setter exists
        let hasPrivateSetter = testView.responds(to: privateSetSel)

        logLabel.numberOfLines = 0
        logLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logLabel)
        NSLayoutConstraint.activate([
            logLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            logLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            logLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        func btn(_ title: String, _ action: @escaping () -> Void) -> UIButton {
            let b = UIButton(type: .system)
            b.setTitle(title, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 12)
            b.addAction(UIAction { _ in action() }, for: .touchUpInside)
            return b
        }

        // Row 1: Public setter
        let row1 = UIStackView(arrangedSubviews: [
            btn("pub=expanded") { [weak self] in
                self?.testView.accessibilityExpandedStatus = .expanded
                self?.logState("pub=expanded")
            },
            btn("pub=collapsed") { [weak self] in
                self?.testView.accessibilityExpandedStatus = .collapsed
                self?.logState("pub=collapsed")
            },
            btn("pub=unsupported") { [weak self] in
                self?.testView.accessibilityExpandedStatus = .unsupported
                self?.logState("pub=unsupported")
            },
        ])
        row1.distribution = .fillEqually

        // Row 2: Private setter (if it exists)
        let row2 = UIStackView(arrangedSubviews: [
            btn("_priv=1(exp)") { [weak self] in
                guard let self else { return }
                if self.writePrivate(1) {
                    self.logState("_priv=1")
                } else {
                    self.log("_setAccessibilityExpandedStatus: NOT FOUND")
                }
            },
            btn("_priv=2(col)") { [weak self] in
                guard let self else { return }
                if self.writePrivate(2) {
                    self.logState("_priv=2")
                } else {
                    self.log("_setAccessibilityExpandedStatus: NOT FOUND")
                }
            },
            btn("_priv=0(unsup)") { [weak self] in
                guard let self else { return }
                if self.writePrivate(0) {
                    self.logState("_priv=0")
                } else {
                    self.log("_setAccessibilityExpandedStatus: NOT FOUND")
                }
            },
        ])
        row2.distribution = .fillEqually

        // Row 3: Read / Clear
        let row3 = UIStackView(arrangedSubviews: [
            btn("Read State") { [weak self] in
                self?.logState("Read")
            },
            btn("Clear Log") { [weak self] in
                self?.logLines = []
                self?.logLabel.text = ""
            },
        ])
        row3.distribution = .fillEqually

        stack.addArrangedSubview(row1)
        stack.addArrangedSubview(row2)
        stack.addArrangedSubview(row3)

        log("_setAccessibilityExpandedStatus exists: \(hasPrivateSetter)")
        logState("Initial")
    }
}
