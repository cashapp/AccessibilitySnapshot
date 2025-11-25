//
//  Copyright 2024 Block Inc.
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
import UIKit

@available(iOS 16.0, *)
struct AccessibilityFeatureShowcaseView: View {

    private let cardColumns = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible(), spacing: 32),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Accessibility Snapshot Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityHidden(true)

                // Just a label
                Text("Basic label")
                    .font(.headline)

                // Label and value
                HStack(spacing: 4) {
                    Text("Basic label with value")
                        .bold()
                    Text("Here is the value")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Basic label with value"))
                .accessibilityValue(Text("Here is the value"))

                // Custom hint
                Text("Something with a hint")
                .accessibilityHint(Text("Here's the hint."))

                // Custom input labels
                Text("Custom input labels")
                    .accessibilityRespondsToUserInteraction()
                    .accessibilityInputLabels([Text("Custom Label 1"), Text("Another custom label")])

                // Header trait
                Text("A label marked as a header")
                    .accessibilityAddTraits(.isHeader)

                // Button trait
                Button("Something with the button trait", action: { })

                // Link trait
                Text("Something with the link trait")
                    .accessibilityAddTraits(.isLink)

                CustomActionFeatureCard()

                RotorTraitFeatureCard()
            }
            .padding(24)
        }
    }
}

@available(iOS 16.0, *)
private struct CustomActionFeatureCard: View {
    var body: some View {
        VStack {
            Text("Three buttons combined. The latter two become accessibility custom actions")
            HStack {
                Button("Primary button") { }
                Button("Reply") { }
                Button("Archive") { }
            }
        }
        .buttonStyle(.bordered)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 16.0, *)
private struct HeaderTraitFeatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Billing Details")
                .font(.title)
            Text("Header trait shows a pill in the legend.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Billing details section"))
        .accessibilityAddTraits(.isHeader)
    }
}

@available(iOS 16.0, *)
private struct ButtonTraitFeatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Send payment")
                .font(.headline)
            Text("Buttons inherit tappable styling and trait pills.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Send payment"))
        .accessibilityHint(Text("Double-tap to send the transfer."))
        .accessibilityAddTraits(.isButton)
    }
}

@available(iOS 16.0, *)
private struct LinkTraitFeatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Open support center")
                .font(.headline)
            Text("Links render with the link pill inside the legend.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Visit the support center"))
        .accessibilityHint(Text("Opens support.block.com"))
        .accessibilityAddTraits(.isLink)
    }
}

@available(iOS 16.0, *)
private struct UserInputLabelsFeatureCard: View {

    @State private var donationAmount: Int = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("$\(donationAmount) donation")
                .font(.headline)
            Text("Voice Control pills pull from these labels.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Donation amount"))
        .accessibilityValue(Text("$\(donationAmount) donation"))
        .accessibilityHint(Text("Adjust with the custom voice labels."))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                donationAmount = min(donationAmount + 5, 100)
            case .decrement:
                donationAmount = max(donationAmount - 5, 10)
            @unknown default:
                break
            }
        }
    }
}

@available(iOS 16.0, *)
private struct RotorTraitFeatureCard: View {
    var body: some View {
        RotorShowcaseCard()
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
    }
}

// MARK: - Rotor Showcase Backed by UIKit

@available(iOS 16.0, *)
private struct RotorShowcaseCard: UIViewRepresentable {
    func makeUIView(context: Context) -> RotorCardView {
        RotorCardView()
    }

    func updateUIView(_ uiView: RotorCardView, context: Context) { }
}

@available(iOS 16.0, *)
private final class RotorCardView: UIView {

    private typealias RotorEntry = (label: UILabel, element: UIAccessibilityElement)

    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let flaggedStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()

    private let peopleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()

    private var flaggedEntries: [RotorEntry] = []
    private var peopleEntries: [RotorEntry] = []

    private var flaggedRotor: UIAccessibilityCustomRotor!
    private var peopleRotor: UIAccessibilityCustomRotor!

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureView()
        configureStacks()
        configureEntries()
        configureRotors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get {
            [flaggedRotor, peopleRotor].compactMap { $0 }
        }
        set { }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
        updateAccessibilityFrames(for: flaggedEntries)
        updateAccessibilityFrames(for: peopleEntries)
    }

    private func configureView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "Custom rotors demo"
        accessibilityValue = "Flagged updates and People rotors are available."
        accessibilityHint = "Turn the rotor to jump between items in the lists."
    }

    private func configureStacks() {
        let titleLabel = UILabel()
        titleLabel.text = "Custom rotors"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2).bold()

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Rotors collect context like flagged work or specific teammates."
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(subtitleLabel)

        containerStack.addArrangedSubview(sectionLabel(text: "Flagged updates"))
        containerStack.addArrangedSubview(flaggedStack)

        containerStack.addArrangedSubview(sectionLabel(text: "People"))
        containerStack.addArrangedSubview(peopleStack)
    }

    private func configureEntries() {
        flaggedEntries = makeEntries(
            texts: [
                "Melissa — Needs approval",
                "Jordan — Missing receipt",
                "Priya — Waiting on brand review",
            ],
            prefix: "⚑"
        )
        flaggedEntries.forEach { flaggedStack.addArrangedSubview($0.label) }

        peopleEntries = makeEntries(
            texts: [
                "Jamir — Finance",
                "Mika — Product",
                "Sora — Design",
            ],
            prefix: "👤"
        )
        peopleEntries.forEach { peopleStack.addArrangedSubview($0.label) }
    }

    private func configureRotors() {
        flaggedRotor = UIAccessibilityCustomRotor(name: "Flagged updates") { [weak self] predicate in
            guard let self else { return nil }
            return self.result(for: predicate, entries: self.flaggedEntries)
        }

        peopleRotor = UIAccessibilityCustomRotor(name: "People") { [weak self] predicate in
            guard let self else { return nil }
            return self.result(for: predicate, entries: self.peopleEntries)
        }
    }

    private func makeEntries(texts: [String], prefix: String) -> [RotorEntry] {
        let font = UIFont.preferredFont(forTextStyle: .body)
        return texts.map { text in
            let label = UILabel()
            label.text = "\(prefix) \(text)"
            label.font = font
            label.textColor = .label
            label.numberOfLines = 1

            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = text
            element.accessibilityTraits = .staticText
            return (label, element)
        }
    }

    private func sectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = UIFont.preferredFont(forTextStyle: .caption1).bold()
        label.textColor = .secondaryLabel
        return label
    }

    private func result(for predicate: UIAccessibilityCustomRotorSearchPredicate, entries: [RotorEntry]) -> UIAccessibilityCustomRotorItemResult? {
        guard !entries.isEmpty else { return nil }

        let currentElement = predicate.currentItem.targetElement as? UIAccessibilityElement
        let startIndex: Int

        if
            let currentElement,
            let currentIndex = entries.firstIndex(where: { $0.element === currentElement })
        {
            startIndex = currentIndex
        } else {
            startIndex = predicate.searchDirection == .next ? -1 : entries.count
        }

        let nextIndex = predicate.searchDirection == .next
            ? startIndex + 1
            : startIndex - 1

        guard entries.indices.contains(nextIndex) else { return nil }

        let target = entries[nextIndex].element
        return UIAccessibilityCustomRotorItemResult(targetElement: target, targetRange: nil)
    }

    private func updateAccessibilityFrames(for entries: [RotorEntry]) {
        for entry in entries {
            guard let sourceView = entry.label.superview else { continue }
            let frame = convert(entry.label.frame, from: sourceView)
            entry.element.accessibilityFrameInContainerSpace = frame
        }
    }
}

@available(iOS 16.0, *)
private extension UIFont {
    func bold() -> UIFont {
        return withTraits(.traitBold)
    }

    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits.union(fontDescriptor.symbolicTraits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        AccessibilityFeatureShowcaseView()
    } else {
        Text("Not available")
    }
}
