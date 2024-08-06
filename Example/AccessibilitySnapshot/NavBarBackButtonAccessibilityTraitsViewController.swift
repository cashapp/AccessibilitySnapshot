//
//  Copyright 2024 Square Inc.
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

final class NavBarBackButtonAccessibilityTraitsViewController: AccessibilityViewController {

    // MARK: - Public Properties
    
    init(titles: [String?] = [nil, nil]) {
        self.titles = titles
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var titles: [String?]

    // MARK: - Private Properties

    private var rootView: View {
        return view as! View
    }

    // MARK: - UIViewController

    override func loadView() {
        view = View(titles: titles)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

// MARK: -

extension NavBarBackButtonAccessibilityTraitsViewController {
    
    final class Child: UIViewController {
        
        init(_ title: String? = nil) {
            super.init(nibName: nil, bundle: nil)
            self.title = title
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        let label = UILabel()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.hidesBackButton = false
            
            label.text = "Back Button Accessibility Traits - "
            label.text?.append(hasTitle ? "With Titles" : "Without Titles" )
            view.addSubview(label)
        }
        private var hasTitle: Bool {
             self.title != nil
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            label.sizeToFit()
            let x = (view.bounds.width / 2) - (label.frame.size.width / 2)
            let y = (view.bounds.height / 2) - (label.frame.size.height / 2)
            label.frame = CGRect(origin: CGPoint(x: x, y: y), size: label.frame.size)
        }
    }
}

extension NavBarBackButtonAccessibilityTraitsViewController {


    final class View: UIView {

        // MARK: - Life Cycle

        init(titles: [String?]) {
            self.titles = titles
            super.init(frame: .zero)
            addSubview(navView)
            navController.viewControllers = titles.map { Child($0) }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Public Properties
        var titles: [String?]
        
        let navController = UINavigationController()
        var navView: UIView {
            navController.view
        }

        

        // MARK: - Private Properties

        // MARK: - UIView

        override func layoutSubviews() {
            super.layoutSubviews()
            navView.frame = bounds
        }
        

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
        horizontallySpreadSubviews(tabs, margin: 0)
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
            leftLabel.capInsetsAlignmentProxy.align(withSuperview: .leftCenter, inset: 4)

            rightLabel.sizeToFit()
            rightLabel.capInsetsAlignmentProxy.align(withSuperview: .rightCenter, inset: 4)

            middleLabel.sizeToFit()
            middleLabel.capInsetsAlignmentProxy.align(withSuperview: .center)
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

        horizontallySpreadSubviews(itemLabels, margin: 0)

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
