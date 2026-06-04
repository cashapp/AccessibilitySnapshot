import AccessibilitySnapshotModel
import UIKit

// MARK: - CustomRotor UIKit Init

extension AccessibilityElement.CustomRotor {
    init?(from rotor: UIAccessibilityCustomRotor, parentElement: NSObject, root: UIView, context: AccessibilityHierarchyParser.Context? = nil, resultLimit: Int) {
        guard rotor.isKnownRotorType else { return nil }

        let name = rotor.displayName(locale: parentElement.accessibilityLanguage)

        // A nonpositive result limit means the rotor should be preserved as metadata only:
        // keep its name but don't invoke the search block or collect any results.
        guard resultLimit > 0 else {
            self.init(name: name, resultMarkers: [], limit: .none)
            return
        }

        let collected = rotor.collectAllResults(nextLimit: resultLimit, previousLimit: resultLimit)
        let markers: [ResultMarker] = collected.results.compactMap { result in
            guard let element = result.targetElement as? NSObject else { return nil }
            var description = element.accessibilityDescription(context: context).description
            var shape: AccessibilityShape? = AccessibilityHierarchyParser.accessibilityShape(for: element, in: root)

            if let range = result.targetRange,
               let input = element as? UITextInput
            {
                if let path = input.accessibilityPath(for: range) {
                    let converted = root.convert(path, from: input as? UIView)
                    shape = .path(AccessibilityPathElement.elements(from: converted.cgPath))
                }
                if let substring = input.text(in: range) {
                    description = substring
                }
                return ResultMarker(elementDescription: description, rangeDescription: range.formatted(in: input), shape: shape)
            }
            return ResultMarker(elementDescription: description, rangeDescription: nil, shape: shape)
        }
        self.init(
            name: name,
            resultMarkers: markers,
            limit: AccessibilityRotorResultLimit(collected.limit)
        )
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
