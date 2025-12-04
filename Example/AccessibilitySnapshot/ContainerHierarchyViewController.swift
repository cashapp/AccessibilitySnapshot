//
//  Copyright 2019 Square Inc.
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

import Paralayout
import UIKit

/// Demonstrates container hierarchy behaviors validated through VoiceOver testing:
/// - Only `.semanticGroup` labels are announced by VoiceOver
/// - Only `.tabBar` trait matters on containers
/// - Other container types (list, landmark, dataTable) affect rotor navigation only
final class ContainerHierarchyViewController: AccessibilityViewController {

    override func loadView() {
        view = View()
    }

}

// MARK: -

private extension ContainerHierarchyViewController {

    final class View: UIView {

        private let containers: [UIView] = [
            // Semantic group WITH label - label IS announced by VoiceOver
            ContainerDemoView(
                title: ".semanticGroup (with label)",
                items: ["Semantic Item 1", "Semantic Item 2"],
                containerType: .semanticGroup,
                accessibilityLabel: "Semantic Label"
            ),

            ContainerDemoView(
                title: ".semanticGroup (with label and value)",
                items: ["Semantic Item 1", "Semantic Item 2"],
                containerType: .semanticGroup,
                accessibilityLabel: "Semantic Label",
                accessibilityValue: "And a value"
            ),

            // Semantic group WITHOUT label/value - container detected but no announcement
            ContainerDemoView(
                title: ".semanticGroup (no label/value set)",
                items: ["Semantic Item 1", "Semantic Item 2"],
                containerType: .semanticGroup
            ),

            // List container - label/value NOT announced, but affects rotor navigation
            ContainerDemoView(
                title: ".list (label/value are not announced)",
                items: ["List Item 1", "List Item 2"],
                containerType: .list,
                accessibilityLabel: "List Container"
            ),

            // Landmark container - label/value NOT announced, but affects rotor navigation
            ContainerDemoView(
                title: ".landmark (label/value are not announced)",
                items: ["Landmark Item 1", "Landmark Item 2"],
                containerType: .landmark,
                accessibilityLabel: "Landmark Container"
            ),

            // Container type .none with label/value - not detected as container
            ContainerDemoView(
                title: ".none (label/value are not announced)",
                items: ["None Item 1", "None Item 2"],
                containerType: .none,
                accessibilityLabel: "Ignored Label"
            ),

            // Container with .tabBar trait - only trait that matters on containers
            TabBarDemoView(),

            // Nested containers to test hierarchy
            NestedContainersDemoView(),
        ]

        override init(frame: CGRect) {
            super.init(frame: frame)
            containers.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var specs: [ViewDistributionSpecifying] = [statusBarHeight.fixed, 1.flexible]

            for container in containers {
                container.bounds.size = container.sizeThatFits(CGSize(width: bounds.width - 32, height: .greatestFiniteMagnitude))
                specs.append(container)
                specs.append(8.fixed)
            }

            specs.append(1.flexible)
            applyVerticalSubviewDistribution(specs)

            for container in containers {
                container.frame.origin.x = 16
            }
        }
    }
}

// MARK: - Reusable Container Demo View

/// Wrapper view containing a title label and the actual container
private final class ContainerDemoView: UIView {

    init(
        title: String,
        items: [String],
        containerType: UIAccessibilityContainerType,
        accessibilityLabel: String? = nil,
        accessibilityValue: String? = nil
    ) {
        self.titleLabel = UILabel()
        self.containerView = ContainerView(
            items: items,
            containerType: containerType,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue
        )

        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.isAccessibilityElement = false
        addSubview(titleLabel)

        addSubview(containerView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let titleLabel: UILabel
    private let containerView: ContainerView

    override func layoutSubviews() {
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: 0, y: 0)

        let containerSize = containerView.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        containerView.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY + 4,
            width: bounds.width,
            height: containerSize.height
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleHeight = titleLabel.sizeThatFits(size).height
        let containerHeight = containerView.sizeThatFits(size).height
        return CGSize(width: size.width, height: titleHeight + 4 + containerHeight)
    }

    /// The actual container view with accessibility container type
    private final class ContainerView: UIView {

        init(
            items: [String],
            containerType: UIAccessibilityContainerType,
            accessibilityLabel: String?,
            accessibilityValue: String? = nil
        ) {
            self.containerType = containerType
            self.itemLabels = items.map { text in
                let label = UILabel()
                label.text = text
                return label
            }

            super.init(frame: .zero)

            layer.borderColor = UIColor.separator.cgColor
            layer.borderWidth = 1

            itemLabels.forEach(addSubview)

            self.accessibilityLabel = accessibilityLabel
            self.accessibilityValue = accessibilityValue
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private let containerType: UIAccessibilityContainerType
        private let itemLabels: [UILabel]

        override func layoutSubviews() {
            var y: CGFloat = 8
            for label in itemLabels {
                label.sizeToFit()
                label.frame.origin = CGPoint(x: 8, y: y)
                y = label.frame.maxY + 4
            }
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var height: CGFloat = 8
            for label in itemLabels {
                height += label.sizeThatFits(size).height + 4
            }
            return CGSize(width: size.width, height: height + 4)
        }

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get { containerType }
            set { }
        }
    }
}

// MARK: - Tab Bar Demo View

/// Wrapper view containing a title label and the actual tab bar container
private final class TabBarDemoView: UIView {

    private let titleLabel = UILabel()
    private let containerView: TabBarContainerView

    override init(frame: CGRect) {
        containerView = TabBarContainerView()

        super.init(frame: frame)

        titleLabel.text = "Container with .tabBar trait"
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.isAccessibilityElement = false
        addSubview(titleLabel)

        addSubview(containerView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: 0, y: 0)

        containerView.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY + 4,
            width: bounds.width,
            height: 52
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: titleLabel.sizeThatFits(size).height + 4 + 52)
    }

    /// The actual tab bar container view
    private final class TabBarContainerView: UIView {

        private let tabs: [UIButton]

        override init(frame: CGRect) {
            tabs = ["Home", "Search", "Profile"].map { title in
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                return button
            }
            tabs[0].accessibilityTraits.insert(.selected)

            super.init(frame: frame)

            layer.borderColor = UIColor.separator.cgColor
            layer.borderWidth = 1

            tabs.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            let tabWidth = bounds.width / CGFloat(tabs.count)
            for (index, tab) in tabs.enumerated() {
                tab.frame = CGRect(x: CGFloat(index) * tabWidth, y: 4, width: tabWidth, height: 44)
            }
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            get { super.accessibilityTraits.union(.tabBar) }
            set { super.accessibilityTraits = newValue }
        }
    }
}

// MARK: - Nested Containers Demo View

/// Wrapper view containing a title label and nested containers
private final class NestedContainersDemoView: UIView {

    private let titleLabel = UILabel()
    private let outerContainer: OuterContainerView

    override init(frame: CGRect) {
        // Build inner container (has label, so will be detected)
        let innerContainer = InnerContainerView()

        // Build outer container to include inner container
        outerContainer = OuterContainerView(innerContainer: innerContainer)

        super.init(frame: frame)

        titleLabel.text = "Nested Containers"
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.isAccessibilityElement = false
        addSubview(titleLabel)

        addSubview(outerContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: 0, y: 0)

        outerContainer.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY + 4,
            width: bounds.width,
            height: outerContainer.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude)).height
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleHeight = titleLabel.sizeThatFits(size).height
        let containerHeight = outerContainer.sizeThatFits(size).height
        return CGSize(width: size.width, height: titleHeight + 4 + containerHeight)
    }

    /// Outer container wraps an item + inner container
    private final class OuterContainerView: UIView {

        private let outerItem = UILabel()
        private let innerContainer: UIView

        init(innerContainer: UIView) {
            self.innerContainer = innerContainer
            super.init(frame: .zero)

            layer.borderColor = UIColor.separator.cgColor
            layer.borderWidth = 1
            accessibilityLabel = "Outer Container"
            accessibilityContainerType = .semanticGroup
            outerItem.text = "Outer Item"
            addSubview(outerItem)
            addSubview(innerContainer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            outerItem.sizeToFit()
            outerItem.frame.origin = CGPoint(x: 8, y: 8)

            let containerWidth = bounds.width - 16
            innerContainer.frame = CGRect(
                x: 8,
                y: outerItem.frame.maxY + 8,
                width: containerWidth,
                height: innerContainer.sizeThatFits(CGSize(width: containerWidth, height: .greatestFiniteMagnitude)).height
            )
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var height: CGFloat = 8 + outerItem.sizeThatFits(size).height + 8
            height += innerContainer.sizeThatFits(CGSize(width: size.width - 16, height: .greatestFiniteMagnitude)).height + 8
            return CGSize(width: size.width, height: height)
        }

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get { .semanticGroup }
            set { }
        }
    }

    /// Inner container with label (will be detected as semantic group)
    private final class InnerContainerView: UIView {

        private let itemLabels: [UILabel]

        override init(frame: CGRect) {
            itemLabels = ["Inner Item 1", "Inner Item 2"].map { text in
                let label = UILabel()
                label.text = text
                return label
            }

            super.init(frame: frame)

            layer.borderColor = UIColor.separator.cgColor
            layer.borderWidth = 1

            itemLabels.forEach(addSubview)

            accessibilityLabel = "Inner Container"
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            var y: CGFloat = 8
            for label in itemLabels {
                label.sizeToFit()
                label.frame.origin = CGPoint(x: 8, y: y)
                y = label.frame.maxY + 4
            }
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var height: CGFloat = 8
            for label in itemLabels {
                height += label.sizeThatFits(size).height + 4
            }
            return CGSize(width: size.width, height: height + 4)
        }

        override var accessibilityContainerType: UIAccessibilityContainerType {
            get { .semanticGroup }
            set { }
        }
    }
}
