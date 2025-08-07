import Paralayout
import UIKit

final class AccessibilityCustomRotorsViewController: AccessibilityViewController {

    // MARK: - UIViewController

    override func loadView() {
        view = View(
            views: [
                CharacterView(frame: .zero ),
                PrimesView(frame: .zero),
                UUIDView(frame: .zero)
            ]
        )
    }

}

// MARK: -

private extension AccessibilityCustomRotorsViewController {

    final class View: UIView {

        // MARK: - Life Cycle

        init(views: [UIView], frame: CGRect = .zero) {
            self.views = views

            super.init(frame: frame)

            views.forEach(addSubview)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Properties

        private let views: [UIView]

        // MARK: - UIView

        override func layoutSubviews() {
            views.forEach {
                $0.bounds.size = .init(width: bounds.width / 2, height: 200)
                $0.sizeToFit()
            }
            
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
    
    final class PrimesView : UILabel {
        let twoDigitPrimes: [NSString] = [
            "11", "13", "17", "19", "23", "29", "31", "37", "41", "43", "47",
            "53", "59", "61", "67", "71", "73", "79", "83", "89", "97"
            ].map {$0.accessibilityLabel = "\($0)"; return $0 as NSString }
        
        func nextIndex(_ predicate: UIAccessibilityCustomRotorSearchPredicate) -> Int? {
            guard let current = predicate.currentItem.targetElement as? NSString,
                  let index = self.twoDigitPrimes.firstIndex(of: current) else { return 0 }
            let nextIndex = predicate.searchDirection == .next ? index + 1 : index - 1
            guard nextIndex >= 0, nextIndex < self.twoDigitPrimes.count else { return nil }
            return nextIndex
        }
        
        lazy private var rotor: UIAccessibilityCustomRotor = UIAccessibilityCustomRotor(name: "Two Digit Primes") { predicate in
            guard let nextIndex = self.nextIndex(predicate) else { return nil }
            let string = self.twoDigitPrimes[nextIndex]
            return .init(targetElement: string, targetRange: nil)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            numberOfLines = 0
            text = "This one gets truncated."
            backgroundColor = .gray
        }
        
        override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
            set { }
            get { return [rotor] }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    final class UUIDView: UILabel {
        private var storage = [NSString]()
        
        lazy private var rotor: UIAccessibilityCustomRotor = UIAccessibilityCustomRotor(name: "Random Strings") { predicate in
            guard predicate.searchDirection == .next else { return nil }
            let string = String(UUID().uuidString.split(separator: "-").first ?? "") as NSString
            string.accessibilityLabel = string as String
            self.storage.append(string)
            return .init(targetElement: string, targetRange: nil)
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            numberOfLines = 0
            text = "This one goes forever."
            backgroundColor = .gray
        }
        
        override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
            set { }
            get { return [rotor] }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    final class CharacterView: UIView {
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
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            textView.sizeThatFits(size)
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
