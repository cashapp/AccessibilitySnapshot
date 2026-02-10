import UIKit

// MARK: - Rotor Extensions

extension UIAccessibilityCustomRotor {
    var isKnownRotorType: Bool {
        switch systemRotorType {
        case .none, .link, .visitedLink, .heading, .headingLevel1, .headingLevel2, .headingLevel3, .headingLevel4, .headingLevel5, .headingLevel6, .boldText, .italicText, .underlineText, .misspelledWord, .image, .textField, .table, .list, .landmark:
            return true
        @unknown default:
            return false
        }
    }

    func displayName(locale: String? = nil) -> String {
        guard name.isEmpty else {
            return name
        }

        switch systemRotorType {
        case .none:
            return "None".localized(
                key: "rotor.none.description",
                comment: "Description for a rotor with no type",
                locale: locale
            )
        case .link:
            return "Links".localized(
                key: "rotor.link.description",
                comment: "Description for the 'links' rotor",
                locale: locale
            )
        case .visitedLink:
            return "Visited Links".localized(
                key: "rotor.visited_link.description",
                comment: "Description for the 'visited links' rotor",
                locale: locale
            )
        case .heading:
            return "Headings".localized(
                key: "rotor.heading.description",
                comment: "Description for the 'headings' rotor",
                locale: locale
            )
        case .headingLevel1:
            return "Heading 1".localized(
                key: "rotor.heading_level1.description",
                comment: "Description for the 'heading level 1' rotor",
                locale: locale
            )
        case .headingLevel2:
            return "Heading 2".localized(
                key: "rotor.heading_level2.description",
                comment: "Description for the 'heading level 2' rotor",
                locale: locale
            )
        case .headingLevel3:
            return "Heading 3".localized(
                key: "rotor.heading_level3.description",
                comment: "Description for the 'heading level 3' rotor",
                locale: locale
            )
        case .headingLevel4:
            return "Heading 4".localized(
                key: "rotor.heading_level4.description",
                comment: "Description for the 'heading level 4' rotor",
                locale: locale
            )
        case .headingLevel5:
            return "Heading 5".localized(
                key: "rotor.heading_level5.description",
                comment: "Description for the 'heading level 5' rotor",
                locale: locale
            )
        case .headingLevel6:
            return "Heading 6".localized(
                key: "rotor.heading_level6.description",
                comment: "Description for the 'heading level 6' rotor",
                locale: locale
            )
        case .boldText:
            return "Bold Text".localized(
                key: "rotor.bold_text.description",
                comment: "Description for the 'bold text' rotor",
                locale: locale
            )
        case .italicText:
            return "Italic Text".localized(
                key: "rotor.italic_text.description",
                comment: "Description for the 'italic text' rotor",
                locale: locale
            )
        case .underlineText:
            return "Underlined Text".localized(
                key: "rotor.underline_text.description",
                comment: "Description for the 'underlined text' rotor",
                locale: locale
            )
        case .misspelledWord:
            return "Misspelled Words".localized(
                key: "rotor.misspelled_word.description",
                comment: "Description for the 'misspelled words' rotor",
                locale: locale
            )
        case .image:
            return "Images".localized(
                key: "rotor.image.description",
                comment: "Description for the 'images' rotor",
                locale: locale
            )
        case .textField:
            return "Text Fields".localized(
                key: "rotor.text_field.description",
                comment: "Description for the 'text fields' rotor",
                locale: locale
            )
        case .table:
            return "Tables".localized(
                key: "rotor.table.description",
                comment: "Description for the 'tables' rotor",
                locale: locale
            )
        case .list:
            return "Lists".localized(
                key: "rotor.list.description",
                comment: "Description for the 'lists' rotor",
                locale: locale
            )
        case .landmark:
            return "Landmarks".localized(
                key: "rotor.landmark.description",
                comment: "Description for the 'landmarks' rotor",
                locale: locale
            )
        @unknown default:
            return String(format:
                "Unknown Rotor Type, Raw value: %lld".localized(
                    key: "rotor.unknown.description_format",
                    comment: "Format for description of an unknown rotor type; param0: the raw value",
                    locale: locale
                ),
                systemRotorType.rawValue)
        }
    }

    public struct CollectedRotorResults: Equatable {
        // Maximum number of results to count before stopping enumeration.
        // When this limit is reached, we stop counting and report "99+ More Results"
        public static let maximumCount: Int = 99

        public enum Limit: Equatable, Codable {
            case none
            case underMaxCount(Int)
            case greaterThanMaxCount

            func combine(_ other: Limit) -> Limit {
                switch (self, other) {
                case (.none, .none):
                    return .none
                case (_, .greaterThanMaxCount), (.greaterThanMaxCount, _):
                    return .greaterThanMaxCount
                case let (.underMaxCount(count), .none), let (.none, .underMaxCount(count)):
                    return .underMaxCount(count)
                case let (.underMaxCount(a), .underMaxCount(b)):
                    if a + b <= maximumCount {
                        return .underMaxCount(a + b)
                    }
                    return .greaterThanMaxCount
                }
            }
        }

        public let results: [UIAccessibilityCustomRotorItemResult]
        public let limit: Limit

        init(results: [UIAccessibilityCustomRotorItemResult], limit: Limit = .none) {
            self.results = results
            self.limit = limit
        }
    }

    // Collects rotor results in both directions to capture all accessible items.
    // Some rotors only provide results in one direction, so we check both.
    // Intelligently merges results, removing duplicates and handling edge cases.
    func collectAllResults(nextLimit: Int, previousLimit: Int) -> CollectedRotorResults {
        let forwards = iterateResults(direction: .next, limit: nextLimit)
        let backwards = iterateResults(direction: .previous, limit: nextLimit)

        // Its common that backwards and forwards contain the same elements with differing orders.

        let forwardsSet = resultSet(forwards.results)
        let backwardsSet = resultSet(backwards.results)

        if forwardsSet == backwardsSet { return forwards }
        if forwardsSet.isSuperset(of: backwardsSet) { return forwards }
        if backwardsSet.isSuperset(of: forwardsSet) { return backwards }

        // When starting iteration without a currentItem, both directions often return
        // the same first element. Drop one copy before merging to avoid duplicates.
        // Example: forward=[A,B,C], backward=[A,D,E] -> result=[E,D,A,B,C] not [E,D,A,A,B,C]
        if forwards.results.first?.compare(backwards.results.first) ?? false {
            let results = backwards.results.dropFirst().reversed() + forwards.results
            return .init(results: results, limit: backwards.limit.combine(forwards.limit))
        }

        let results = (backwards.results.reversed() + forwards.results).removingDuplicates()
        return .init(results: results, limit: backwards.limit.combine(forwards.limit))
    }

    func iterateResults(direction: UIAccessibilityCustomRotor.Direction, limit: Int) -> CollectedRotorResults {
        var results: [UIAccessibilityCustomRotorItemResult] = []
        let predicate = UIAccessibilityCustomRotorSearchPredicate()
        var loopDetection: [Int] = []

        predicate.searchDirection = direction

        while results.count < limit {
            guard let result = itemSearchBlock(predicate), !result.compare(predicate.currentItem) else { break }

            if let hashable = _hashableRotorResult(result),
               resultSet(results).contains(hashable)
            {
                loopDetection.append(results.count)
            }
            // Loop detection: Track when we encounter duplicate results.
            // If we see 3 duplicates in a row (sequential indices), we're in an infinite loop.
            // Example: [A,B,C,D,E,C,D,E,C,D,E] - indices [5,7,9] are sequential, stop at index 5.
            // Non-sequential duplicates are OK (e.g., A->B->C->A->D->E->F is not a loop).
            if loopDetection.count >= 3 {
                if loopDetection.isSequential() {
                    break
                }
                // indices are not sequential, this is not a loop.
                else {
                    loopDetection = []
                }
            }

            results.append(result)
            predicate.currentItem = result
        }

        // Reset the results array to end at the first duplicated element
        if !loopDetection.isEmpty, loopDetection.isSequential(), loopDetection.last == results.count {
            results = Array(results.prefix(upTo: loopDetection.first!))
        }

        if let last = results.last {
            predicate.currentItem = last
        }

        let limited = results.count <= limit ? countAdditionalResults(predicate) : .none
        return .init(results: results, limit: limited)
    }

    private func countAdditionalResults(_ predicate: UIAccessibilityCustomRotorSearchPredicate, maxCount: Int = CollectedRotorResults.maximumCount) -> CollectedRotorResults.Limit {
        // We have a ton of elements, more than we can display in a snapshot. lets get a count of how many there are up to our max count.
        var count = 0
        var result: UIAccessibilityCustomRotorItemResult?
        while count < maxCount, let next = itemSearchBlock(predicate) {
            if next.targetElement == nil || (next.targetElement as? NSObject)?.isEqual(result?.targetElement as? NSObject) ?? false {
                break
            }
            result = next
            count += 1
            predicate.currentItem = next
        }
        if count == 0 {
            // this is unlikely
            return .none
        }
        if count >= maxCount {
            return .greaterThanMaxCount
        }
        return .underMaxCount(count)
    }

    // Helper for duplicate detection in rotor results.
    // NSObject uses identity equality (===), but we need value equality
    // to detect when a rotor returns the same logical item multiple times.
    private struct _hashableRotorResult: Hashable {
        var element: NSObject
        var range: UITextRange?
        init?(_ result: UIAccessibilityCustomRotorItemResult) {
            guard let element = result.targetElement as? NSObject else { return nil }
            self.element = element
            range = result.targetRange
        }
    }

    private func resultSet(_ results: [UIAccessibilityCustomRotorItemResult]) -> Set<_hashableRotorResult> {
        Set(results.compactMap { _hashableRotorResult($0) })
    }
}

private extension UIAccessibilityCustomRotorItemResult {
    func compare(_ other: UIAccessibilityCustomRotorItemResult?) -> Bool {
        guard let other else { return false }

        // 'any NSObjectProtocol' cannot be used as a type conforming to protocol 'Equatable' because 'Equatable' has static requirements
        let target = targetElement as? NSObject
        let otherTarget = other.targetElement as? NSObject
        return target == otherTarget && targetRange == other.targetRange
    }
}

extension Array where Element: UIAccessibilityCustomRotorItemResult {
    func compareWith(_ other: [Element]) -> Bool {
        guard count == other.count else { return false }
        return zip(self, other).allSatisfy { $0.compare($1) }
    }

    func removingDuplicates() -> [Element] {
        reduce(into: []) { array, element in
            if !array.contains(where: { $0.compare(element) }) {
                array.append(element)
            }
        }
    }
}

extension Array where Element == Int {
    func isSequential() -> Bool {
        guard count > 1 else { return true }
        return zip(self, dropFirst()).allSatisfy { $1 == $0 + 1 }
    }
}
