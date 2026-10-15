@_spi(Parsing) import AccessibilitySnapshotModel
import UIKit

// MARK: - CustomRotor UIKit Init

extension AccessibilityElement.CustomRotor {
    init?(from rotor: UIAccessibilityCustomRotor, accessibilityLanguage: String?, root: UIView, context: AccessibilityHierarchyParser.Context? = nil, resultLimit: Int) {
        guard let captured = CapturedRotor(from: rotor, accessibilityLanguage: accessibilityLanguage, root: root, resultLimit: resultLimit) else { return nil }
        self = captured.rotor(context: context)
    }
}

struct CapturedRotor {
    private struct Result {
        let element: AccessibilityElement
        let substring: String?
        let rangeDescription: String?
        let shape: AccessibilityShape

        init?(from result: UIAccessibilityCustomRotorItemResult, root: UIView) {
            guard let object = result.targetElement as? NSObject else { return nil }
            element = AccessibilityHierarchyParser.captureElement(for: object, in: root)
            var shape = element.shape
            if let range = result.targetRange,
               let input = object as? UITextInput
            {
                if let path = input.accessibilityPath(for: range), path.hasFiniteBounds {
                    let converted = root.convert(path, from: input as? UIView)
                    shape = .path(AccessibilityPathElement.elements(from: converted.cgPath))
                }
                substring = input.text(in: range)
                rangeDescription = range.formatted(in: input)
            } else {
                substring = nil
                rangeDescription = nil
            }
            self.shape = shape
        }

        func result(context: AccessibilityHierarchyParser.Context?) -> AccessibilityElement.CustomRotor.Result {
            var element = element
            element.addContext(context)
            return .init(elementDescription: substring ?? element.description, rangeDescription: rangeDescription, shape: shape)
        }
    }

    private let name: String
    private let results: [Result]
    private let limit: AccessibilityRotorResultLimit

    init?(from rotor: UIAccessibilityCustomRotor, accessibilityLanguage: String?, root: UIView, resultLimit: Int) {
        guard rotor.isKnownRotorType else { return nil }
        name = rotor.displayName(locale: accessibilityLanguage)

        // A nonpositive result limit preserves the name without invoking the search block.
        guard resultLimit > 0 else {
            results = []
            limit = .none
            return
        }

        let collected = rotor.collectAllResults(nextLimit: resultLimit, previousLimit: resultLimit)
        results = collected.results.compactMap { Result(from: $0, root: root) }
        limit = AccessibilityRotorResultLimit(collected.limit)
    }

    func rotor(context: AccessibilityHierarchyParser.Context? = nil) -> AccessibilityElement.CustomRotor {
        .init(name: name, results: results.map { $0.result(context: context) }, limit: limit)
    }
}

// MARK: - CustomContent UIKit Init

extension AccessibilityElement.CustomContent {
    @available(iOS 14.0, *)
    init(from content: AXCustomContent) {
        self.init(
            label: content.label,
            value: content.value,
            isImportant: content.importance == .high
        )
    }
}
