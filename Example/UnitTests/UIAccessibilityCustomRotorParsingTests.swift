import Foundation
import UIKit
import XCTest

@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser

final class UIAccessibilityCustomRotorParsingTests: XCTestCase {
    func test_zeroLimitPreservesRotorNameWithoutCollectingResults() {
        var searchCount = 0
        let rotor = UIAccessibilityCustomRotor(name: "Errors") { _ in
            searchCount += 1
            return .init(targetElement: "error" as NSString, targetRange: nil)
        }

        let marker = AccessibilityElement.CustomRotor(
            from: rotor,
            accessibilityLanguage: nil,
            root: UIView(),
            resultLimit: 0
        )

        guard let marker else {
            return XCTFail("Expected custom rotor marker")
        }
        XCTAssertEqual(marker.name, "Errors")
        XCTAssertEqual(marker.results, [])
        XCTAssertEqual(marker.limit, .none)
        XCTAssertEqual(searchCount, 0)
    }

    func test_negativeLimitPreservesRotorNameWithoutCollectingResults() {
        var searchCount = 0
        let rotor = UIAccessibilityCustomRotor(name: "Errors") { _ in
            searchCount += 1
            return .init(targetElement: "error" as NSString, targetRange: nil)
        }

        let marker = AccessibilityElement.CustomRotor(
            from: rotor,
            accessibilityLanguage: nil,
            root: UIView(),
            resultLimit: -1
        )

        guard let marker else {
            return XCTFail("Expected custom rotor marker")
        }
        XCTAssertEqual(marker.name, "Errors")
        XCTAssertEqual(marker.results, [])
        XCTAssertEqual(marker.limit, .none)
        XCTAssertEqual(searchCount, 0)
    }

    func test_capturePreservesNonsequentialRepeatedResults() throws {
        let root = UIView()
        var targets = ["A", "B", "C", "D", "E"].map { label in
            let target = UIAccessibilityElement(accessibilityContainer: root)
            target.accessibilityLabel = label
            target.accessibilityFrame = .zero
            return target
        }
        targets.insert(targets[0], at: 3)
        var nextIndex = 0
        let rotor = UIAccessibilityCustomRotor(name: "Matches") { predicate in
            if predicate.searchDirection == .previous {
                guard predicate.currentItem.targetElement == nil else { return nil }
                return .init(targetElement: targets[0], targetRange: nil)
            }
            guard nextIndex < targets.count else { return nil }
            defer { nextIndex += 1 }
            return .init(targetElement: targets[nextIndex], targetRange: nil)
        }
        let captured = try XCTUnwrap(CapturedRotor(from: rotor, accessibilityLanguage: nil, root: root, resultLimit: 6))

        XCTAssertEqual(captured.rotor(), .init(
            name: "Matches",
            results: ["A", "B", "C", "A", "D", "E"].map {
                .init(elementDescription: $0, shape: .frame(.zero))
            },
            limit: .none
        ))
    }

    func test_capturePreservesTargetValuesBeforeDerivingContext() throws {
        let root = UIView()
        let target = UIAccessibilityElement(accessibilityContainer: root)
        let frame = CGRect(x: 10, y: 20, width: 30, height: 40)
        target.accessibilityLabel = "Amount"
        target.accessibilityValue = "10"
        target.accessibilityTraits = [.button, .selected]
        target.accessibilityLanguage = "de-DE"
        target.accessibilityFrame = frame
        var searchCount = 0
        let rotor = UIAccessibilityCustomRotor(name: "Matches") { predicate in
            searchCount += 1
            guard predicate.currentItem.targetElement == nil else { return nil }
            return .init(targetElement: target, targetRange: nil)
        }
        let captured = try XCTUnwrap(CapturedRotor(from: rotor, accessibilityLanguage: "en-US", root: root, resultLimit: 10))
        let searchCountAfterCapture = searchCount

        rotor.name = "Changed rotor"
        target.accessibilityLabel = "Changed"
        target.accessibilityValue = "99"
        target.accessibilityTraits = []
        target.accessibilityLanguage = "en-US"
        target.accessibilityFrame = .zero

        let shape = AccessibilityShape.frame(AccessibilityRect(frame))
        XCTAssertEqual([
            captured.rotor(),
            captured.rotor(context: .tab(index: 2, count: 3)),
        ], [
            .init(name: "Matches", results: [.init(elementDescription: "Auswahl: Amount: 10. Taste.", shape: shape)]),
            .init(name: "Matches", results: [.init(elementDescription: "Auswahl: Amount: 10. Tabulator. 2 von 3.", shape: shape)]),
        ])
        XCTAssertEqual(searchCount, searchCountAfterCapture)
    }

    func test_capturePreservesAuthoredHintForContextSpeech() throws {
        let root = UIView()
        let target = UIAccessibilityElement(accessibilityContainer: root)
        target.accessibilityHint = "Choose amount."
        target.accessibilityTraits = .adjustable
        target.accessibilityLanguage = "en-US"
        target.accessibilityFrame = .zero
        let rotor = UIAccessibilityCustomRotor(name: "Amounts") { predicate in
            guard predicate.currentItem.targetElement == nil else { return nil }
            return .init(targetElement: target, targetRange: nil)
        }
        let captured = try XCTUnwrap(CapturedRotor(from: rotor, accessibilityLanguage: nil, root: root, resultLimit: 10))

        target.accessibilityHint = "Changed hint."
        target.accessibilityLabel = "Changed label"
        target.accessibilityTraits = []

        XCTAssertEqual(captured.rotor(context: .listEnd), .init(name: "Amounts", results: [
            .init(elementDescription: "Choose amount. Adjustable. List End.", shape: .frame(.zero)),
        ]))
    }

    func test_parserCapturesPlainObjectRotorTargetWithoutIdentifier() throws {
        let owner = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        owner.isAccessibilityElement = true
        owner.accessibilityLabel = "Owner"
        let target = NSObject()
        let targetFrame = CGRect(x: 10, y: 20, width: 30, height: 40)
        target.accessibilityLabel = "Match"
        target.accessibilityLanguage = "en"
        target.accessibilityFrame = targetFrame
        owner.accessibilityCustomRotors = [UIAccessibilityCustomRotor(name: "Matches") { predicate in
            guard predicate.currentItem.targetElement == nil else { return nil }
            return .init(targetElement: target, targetRange: nil)
        }]

        let element = try XCTUnwrap(AccessibilityHierarchyParser().parseAccessibilityHierarchy(in: owner).flattenToElements().first)
        XCTAssertNil(element.identifier)
        XCTAssertEqual(element.customRotors, [.init(name: "Matches", results: [
            .init(elementDescription: "Match", shape: .frame(AccessibilityRect(targetFrame))),
        ])])
    }

    func test_capturePreservesTextRangeBeforeDerivingContext() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let target = UITextField(frame: root.bounds)
        root.addSubview(target)
        target.text = "one two three"
        target.accessibilityLanguage = "en-US"
        let start = try XCTUnwrap(target.position(from: target.beginningOfDocument, offset: 4))
        let end = try XCTUnwrap(target.position(from: target.beginningOfDocument, offset: 7))
        let range = try XCTUnwrap(target.textRange(from: start, to: end))
        let rotor = UIAccessibilityCustomRotor(name: "Words") { predicate in
            guard predicate.currentItem.targetElement == nil else { return nil }
            return .init(targetElement: target, targetRange: range)
        }
        let captured = try XCTUnwrap(CapturedRotor(from: rotor, accessibilityLanguage: nil, root: root, resultLimit: 10))
        let shape = try XCTUnwrap(captured.rotor().results.first).shape

        target.text = "changed text"
        target.accessibilityLabel = "Changed label"
        target.accessibilityFrame = .zero

        XCTAssertEqual(captured.rotor(context: .tab(index: 2, count: 3)), .init(name: "Words", results: [
            .init(elementDescription: "two", rangeDescription: "[4..<7]", shape: shape),
        ]))
    }

    func test_collectResults() {
        let strings: [NSString] = ["one", "two", "three", "four", "five"]

        let basicRotor = UIAccessibilityCustomRotor(name: "basic") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current)
            {
                guard index > 0 || predicate.searchDirection == .next else { return nil }
                guard index < (strings.count - 1) || predicate.searchDirection == .previous else { return nil }

                return .init(targetElement: strings[index + (predicate.searchDirection == .next ? 1 : -1)], targetRange: nil)
            }
            return UIAccessibilityCustomRotorItemResult(targetElement: strings.first!, targetRange: nil)
        }

        let next = basicRotor.iterateResults(direction: .next, limit: 10).results
        XCTAssertEqual(next.map { $0.targetElement as! NSString }, strings)

        let prev = basicRotor.iterateResults(direction: .previous, limit: 10).results
        XCTAssertEqual(prev.count, 1)
        XCTAssertEqual(prev.first!.targetElement as! NSString, strings.first!)

        let limited = basicRotor.iterateResults(direction: .next, limit: 2).results
        XCTAssertEqual(limited.map { $0.targetElement as! NSString }, Array(strings.prefix(2)))

        let notLimited = basicRotor.iterateResults(direction: .next, limit: 1000).results
        XCTAssertEqual(notLimited.map { $0.targetElement as! NSString }, strings)

        // this rotor has elements in both directions.
        let startInTheMiddle = UIAccessibilityCustomRotor(name: "middle") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current)
            {
                guard index > 0, index < (strings.count - 1) else { return nil }
                return .init(targetElement: strings[index + (predicate.searchDirection == .next ? 1 : -1)], targetRange: nil)
            }
            // return the middle element first
            return UIAccessibilityCustomRotorItemResult(targetElement: strings[2], targetRange: nil)
        }

        let middle = startInTheMiddle.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(middle.map { $0.targetElement as! NSString }, strings)

        // This rotor starts at the back of the array if you pass previous with no current item in the predicate.
        let reversed = UIAccessibilityCustomRotor(name: "reversed") { predicate in
            let array = predicate.searchDirection == .next ? strings : strings.reversed()

            if let current = predicate.currentItem.targetElement as? NSString,
               let index = array.firstIndex(of: current)
            {
                guard index >= 0, index < (array.count - 1) else { return nil }
                return .init(targetElement: array[index + 1], targetRange: nil)
            }
            return UIAccessibilityCustomRotorItemResult(targetElement: array.first!, targetRange: nil)
        }

        let all = reversed.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(all.map { $0.targetElement as! NSString }, strings)

        // This rotor loops over the array indefinitely
        let loopingRotor = UIAccessibilityCustomRotor(name: "looping") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current)
            {
                var newIndex = index + (predicate.searchDirection == .next ? 1 : -1)

                if newIndex <= -1 { newIndex = strings.count - 1 }
                else if newIndex >= strings.count { newIndex = 0 }

                return .init(targetElement: strings[newIndex], targetRange: nil)
            }
            return UIAccessibilityCustomRotorItemResult(targetElement: predicate.searchDirection == .next ? strings.first! : strings.last!, targetRange: nil)
        }
        let looping = loopingRotor.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(looping.map { $0.targetElement as! NSString }, strings)
    }

    func test_limits() {
        var storage = [NSString]()
        let rotor = UIAccessibilityCustomRotor(name: "test") { _ in
            let uuid = UUID().uuidString as NSString
            uuid.accessibilityLabel = uuid as String
            storage.append(uuid)
            return .init(targetElement: uuid, targetRange: nil)
        }

        XCTAssertEqual(rotor.iterateResults(direction: .next, limit: 10).results.count, 10)
        XCTAssertEqual(rotor.iterateResults(direction: .previous, limit: 10).results.count, 10)

        XCTAssertEqual(rotor.collectAllResults(nextLimit: 10, previousLimit: 10).results.count, 20)
    }
}
