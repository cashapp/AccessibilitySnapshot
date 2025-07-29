//
//  Copyright 2020 Square Inc.
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

final class AccessibilityCustomRotorsViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View(
            views: [
                .init(frame: .zero ),
            ]
        )
    }

}

// MARK: -

private extension AccessibilityCustomRotorsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        init(views: [CustomRotorView], frame: CGRect = .zero) {
            self.views = views

            super.init(frame: frame)

            views.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let views: [CustomRotorView]

        // MARK: - UIView

        override func layoutSubviews() {
            views.forEach { $0.bounds.size = .init(width: bounds.width / 2, height: 200) }

            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

            var distributionSpecifiers: [ViewDistributionSpecifying] = [ statusBarHeight.fixed, 1.flexible ]
            for subview in views {
                distributionSpecifiers.append(subview)
                distributionSpecifiers.append(1.flexible)
            }
            applyVerticalSubviewDistribution(distributionSpecifiers)
        }
    }
}

// MARK: -

private extension AccessibilityCustomRotorsViewController {
    
    final class CustomRotorView: UIView {
        // MARK: - Life Cycle
        
        private let textView: UITextView
        
        override init(frame: CGRect) {
            textView = .init(frame: frame)
            super.init(frame:frame)
            isAccessibilityElement = true
            
            let councilText = "The council of Elrond was attended by: Elrond, Erestor, Gandalf the Grey, Aragorn, Frodo Baggins, Bilbo Baggins, Boromir of Gondor, Glóin of the Lonely Mountain, Gimli (son of Glóin), Legolas of the Woodland Realm, Glorfindel, and Galdor of the Havens."
            
            accessibilityLabel = councilText
            
            textView.text = councilText
            textView.isEditable = false
            textView.backgroundColor = .gray
            addSubview(textView)
            
        }
        
        override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
            set {}
            get { [ UIAccessibilityCustomRotor(name: "Elves") { [weak self] predicate in
                        guard let self else { return nil }
                        return self.rangeArraySearch(self.elves, for: predicate)
                    },
                    UIAccessibilityCustomRotor(name: "Dwarves") { [weak self] predicate in
                        guard let self else { return nil }
                        return self.rangeArraySearch(self.dwarves, for: predicate)
                    },
                    UIAccessibilityCustomRotor(name: "Hobbits") { [weak self] predicate in
                        guard let self else { return nil }
                        return self.rangeArraySearch(self.hobbits, for: predicate)
                    },
                    UIAccessibilityCustomRotor(name: "Men") { [weak self] predicate in
                        guard let self else { return nil }
                        return self.rangeArraySearch(self.men, for: predicate)
                    },
                    UIAccessibilityCustomRotor(name: "Ents") { _ in return nil } ] }
        }

        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            textView.frame = bounds
        }
        
        // MARK: - UIAccessibility
        
        lazy var elves = ["Elrond", "Erestor", "Legolas of the Woodland Realm", "Glorfindel", "Galdor of the Havens"].compactMap { textRange(of: $0, in: textView) }
        lazy var dwarves = ["Glóin of the Lonely Mountain", "Gimli (son of Glóin)" ].compactMap { textRange(of: $0, in: textView) }
        lazy var hobbits = ["Frodo Baggins", "Bilbo Baggins" ].compactMap { textRange(of: $0, in: textView) }
        lazy var men = ["Aragorn", "Boromir of Gondor" ].compactMap { textRange(of: $0, in: textView) }

        private func rangeArraySearch(_ inArray: [UITextRange], for predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
                let array = predicate.searchDirection == .next ? inArray : inArray.reversed()
                if let currentRange = predicate.currentItem.targetRange,
                   let index = array.firstIndex(of: currentRange) {
                    guard index >= 0, index < (array.count - 1 ) else { return nil }
                    return .init(targetElement: textView, targetRange: array[index + 1])
                }
            return UIAccessibilityCustomRotorItemResult(targetElement: textView, targetRange: array.first)
        }
            
        // MARK: - Internal
        private func textRange(of substring: String, in textView: UITextView) -> UITextRange? {
            guard let range = textView.text.range(of: substring) else {
                return nil
            }
            
            let nsRange = NSRange(range, in: textView.text)
            
            guard
                let start = textView.position(from: textView.beginningOfDocument, offset: nsRange.location),
                let end = textView.position(from: start, offset: nsRange.length)
            else {
                return nil
            }
            
            return textView.textRange(from: start, to: end)
        }
    }
}
