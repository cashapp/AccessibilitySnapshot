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

final class TabBarViewController: AccessibilityViewController {

    // MARK: - Private Properties

    private let tabBar: UITabBar = .init()

    private let tabBarWithBadging: UITabBar = .init()

    private let tabBarTraitView: TabBarTraitView = .init()

    private let tabBarTraitContainerView: TabBarTraitContainerView = .init()

    private var tabBarViews: [UIView] {
        return [
            tabBar,
            tabBarWithBadging,
            tabBarTraitView,
            tabBarTraitContainerView,
        ]
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let standardItem = UITabBarItem(title: "Item A", image: nil, selectedImage: nil)

        let selectedItem = UITabBarItem(title: "Item B", image: nil, selectedImage: nil)

        let disabledItem = UITabBarItem(title: "Item C", image: nil, selectedImage: nil)
        disabledItem.isEnabled = false

        let untitledItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)

        let overriddenItem = UITabBarItem(title: "Item E", image: nil, selectedImage: nil)
        overriddenItem.accessibilityLabel = "Label"
        overriddenItem.accessibilityValue = "Value"
        overriddenItem.accessibilityHint = "Hint"

        let overriddenUntitledItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        overriddenUntitledItem.accessibilityLabel = "Label"
        overriddenUntitledItem.accessibilityValue = "Value"
        overriddenUntitledItem.accessibilityHint = "Hint"

        tabBar.items = [standardItem, selectedItem, disabledItem, untitledItem, overriddenItem, overriddenUntitledItem]
        tabBar.selectedItem = selectedItem

        let emptyBadgedItem = UITabBarItem(title: "Item A", image: nil, selectedImage: nil)
        emptyBadgedItem.badgeValue = ""

        let numberBadgedItem = UITabBarItem(title: "Item B", image: nil, selectedImage: nil)
        numberBadgedItem.badgeValue = "3"

        let textBadgedItem = UITabBarItem(title: "Item C", image: nil, selectedImage: nil)
        textBadgedItem.badgeValue = "A"

        let overriddenBadgedItem = UITabBarItem(title: "Item D", image: nil, selectedImage: nil)
        overriddenBadgedItem.badgeValue = "3"
        overriddenBadgedItem.accessibilityValue = "Value"

        tabBarWithBadging.items = [emptyBadgedItem, numberBadgedItem, textBadgedItem, overriddenBadgedItem]

        tabBarViews.forEach(view.addSubview)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tabBarViews.forEach { $0.frame.size = $0.sizeThatFits(view.bounds.size) }

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
        for subview in tabBarViews {
            distributionSpecifiers.append(subview)
            distributionSpecifiers.append(1.flexible)
        }
        view.applySubviewDistribution(distributionSpecifiers)
    }

}

// MARK: -

private final class TabBarTraitView: UIView {

    // MARK: - Private

    private enum Metrics {
        static let height: CGFloat = 40
    }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        let standardTab = UIButton()
        standardTab.setTitle("A", for: .normal)
        standardTab.setTitleColor(.black, for: .normal)
        standardTab.accessibilityLabel = "Item A"

        let selectedTab = UIButton()
        selectedTab.setTitle("B", for: .normal)
        selectedTab.setTitleColor(.black, for: .normal)
        selectedTab.isSelected = true
        selectedTab.accessibilityLabel = "Item B"

        let disabledTab = UIButton()
        disabledTab.setTitle("C", for: .normal)
        disabledTab.setTitleColor(.lightGray, for: .disabled)
        disabledTab.isEnabled = false
        disabledTab.accessibilityLabel = "Item C"

        let untitledTab = UIButton()

        let nestedTab = MultiElementButton(isContainer: false)

        let nestedContainerTab = MultiElementButton(isContainer: true)

        let nonAccessibileTab = UIButton()
        nonAccessibileTab.setTitle("G", for: .normal)
        nonAccessibileTab.setTitleColor(.black, for: .normal)
        nonAccessibileTab.isAccessibilityElement = false
        nonAccessibileTab.titleLabel?.isAccessibilityElement = false

        let allTheTraitsTab = UIButton()
        allTheTraitsTab.setTitle("H", for: .normal)
        allTheTraitsTab.setTitleColor(.black, for: .normal)
        allTheTraitsTab.accessibilityTraits.insert(.notEnabled)
        allTheTraitsTab.accessibilityTraits.insert(.header)
        allTheTraitsTab.accessibilityTraits.insert(.link)
        allTheTraitsTab.accessibilityTraits.insert(.adjustable)
        allTheTraitsTab.accessibilityTraits.insert(.image)
        allTheTraitsTab.accessibilityTraits.insert(.searchField)

        self.tabs = [standardTab, selectedTab, disabledTab, untitledTab, nestedTab, nestedContainerTab, nonAccessibileTab, allTheTraitsTab]

        super.init(frame: frame)

        tabs.shuffled().forEach(addSubview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let tabs: [UIView]

    // MARK: - UIView

    override func layoutSubviews() {
        tabs.forEach { $0.frame.size.height = bounds.height }
        spreadOutSubviews(tabs, margin: 0)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: Metrics.height)
    }

    // MARK: - UIAccessibility

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return super.accessibilityTraits.union(.tabBar)
        }
        set {
            super.accessibilityTraits = newValue
        }
    }

    // MARK: - Private Types

    private final class MultiElementButton: UIButton {

        // MARK: - Life Cycle

        init(isContainer: Bool) {
            super.init(frame: .zero)

            middleLabel.text = "2"
            addSubview(middleLabel)

            rightLabel.text = "3"
            outerLabelContainer.addSubview(rightLabel)

            leftLabel.text = "1"
            outerLabelContainer.addSubview(leftLabel)
            addSubview(outerLabelContainer)

            isAccessibilityElement = false

            if isContainer {
                accessibilityElements = [middleLabel, leftLabel, rightLabel]
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let leftLabel: UILabel = .init()

        private let middleLabel: UILabel = .init()

        private let rightLabel: UILabel = .init()

        private let outerLabelContainer: UIView = .init()

        // MARK: - UIView

        override func layoutSubviews() {
            outerLabelContainer.frame = bounds

            leftLabel.sizeToFit()
            leftLabel.alignToSuperview(.leftCenter, inset: 4)

            rightLabel.sizeToFit()
            rightLabel.alignToSuperview(.rightCenter, inset: 4)

            middleLabel.sizeToFit()
            middleLabel.alignToSuperview(.center)
        }

    }

}

// MARK: -

private final class TabBarTraitContainerView: UIView {

    // MARK: - Private

    private enum Metrics {
        static let height: CGFloat = 40
    }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        // There is one more label than there are elements, to test that the tab count comes from the number of
        // elements, not the number of subviews.
        self.itemLabels = (0..<5).map { index in
            let label = UILabel()
            label.text = "\(["A","B","C","D","E","-"][index])"
            label.textAlignment = .center
            return label
        }

        super.init(frame: frame)

        let standardElement = UIAccessibilityElement(accessibilityContainer: self)
        standardElement.accessibilityLabel = "Item A"

        let selectedElement = UIAccessibilityElement(accessibilityContainer: self)
        selectedElement.accessibilityLabel = "Item B"
        selectedElement.accessibilityTraits.insert(.selected)

        let disabledElement = UIAccessibilityElement(accessibilityContainer: self)
        disabledElement.accessibilityLabel = "Item C"
        disabledElement.accessibilityTraits.insert(.notEnabled)

        let untitledElement = UIAccessibilityElement(accessibilityContainer: self)

        let allTheTraitsElement = UIAccessibilityElement(accessibilityContainer: self)
        allTheTraitsElement.accessibilityLabel = "Item E"
        allTheTraitsElement.accessibilityTraits.insert(.notEnabled)
        allTheTraitsElement.accessibilityTraits.insert(.header)
        allTheTraitsElement.accessibilityTraits.insert(.link)
        allTheTraitsElement.accessibilityTraits.insert(.adjustable)
        allTheTraitsElement.accessibilityTraits.insert(.image)
        allTheTraitsElement.accessibilityTraits.insert(.searchField)

        accessibilityElements = [standardElement, selectedElement, disabledElement, untitledElement, allTheTraitsElement]

        itemLabels.shuffled().forEach(addSubview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let itemLabels: [UILabel]

    // MARK: - UIView

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: Metrics.height)
    }

    override func layoutSubviews() {
        itemLabels.forEach { $0.frame.size.height = bounds.height }

        spreadOutSubviews(itemLabels, margin: 0)

        for (label, element) in zip(itemLabels, accessibilityElements as! [UIAccessibilityElement]) {
            element.accessibilityFrameInContainerSpace = label.frame
        }
    }

    // MARK: - UIAccessibility

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return super.accessibilityTraits.union(.tabBar)
        }
        set {
            super.accessibilityTraits = newValue
        }
    }

}
