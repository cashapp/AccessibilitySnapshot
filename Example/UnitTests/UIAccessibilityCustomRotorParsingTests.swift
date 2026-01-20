import Foundation
import UIKit
import XCTest

#if SWIFT_PACKAGE
@testable import AccessibilitySnapshotCore
@testable import AccessibilitySnapshotParser
#else
@testable import AccessibilitySnapshot
#endif

final class UIAccessibilityCustomRotorParsingTests : XCTestCase {
    
    func test_collectResults() {
        let strings : [NSString] = ["one", "two", "three", "four", "five"]
        
        let basicRotor = UIAccessibilityCustomRotor(name: "basic") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current) {
                
                guard index > 0 || predicate.searchDirection == .next else { return nil }
                guard index < (strings.count - 1 )  || predicate.searchDirection == .previous else { return nil }
                
                return .init(targetElement: strings[index + (predicate.searchDirection == .next ? 1 : -1)], targetRange: nil)
                
            }
            return UIAccessibilityCustomRotorItemResult(targetElement: strings.first!, targetRange: nil)
        }
        
        let next = basicRotor.iterateResults(direction: .next, limit: 10).results
        XCTAssertEqual(next.map({ $0.targetElement as! NSString}), strings)
        
        let prev =  basicRotor.iterateResults(direction: .previous, limit: 10).results
        XCTAssertEqual(prev.count, 1)
        XCTAssertEqual(prev.first!.targetElement as! NSString, strings.first!)

        
        let limited = basicRotor.iterateResults(direction: .next, limit: 2).results
        XCTAssertEqual(limited.map({ $0.targetElement as! NSString}), Array(strings.prefix(2)))
        
        let notLimited = basicRotor.iterateResults(direction:.next, limit: 1000).results
        XCTAssertEqual(notLimited.map({ $0.targetElement as! NSString}), strings)

        // this rotor has elements in both directions.
        let startInTheMiddle = UIAccessibilityCustomRotor(name: "middle") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current) {
                
                guard index > 0, index < (strings.count - 1 ) else { return nil }
                return .init(targetElement: strings[index + (predicate.searchDirection == .next ? 1 : -1)], targetRange: nil)
                
            }
            // return the middle element first
            return UIAccessibilityCustomRotorItemResult(targetElement: strings[2], targetRange: nil)
        }
        
        let middle = startInTheMiddle.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(middle.map({ $0.targetElement as! NSString}), strings)
        
        // This rotor starts at the back of the array if you pass previous with no current item in the predicate.
        let reversed = UIAccessibilityCustomRotor(name: "reversed") { predicate in
            let array = predicate.searchDirection == .next ? strings : strings.reversed()

            if let current = predicate.currentItem.targetElement as? NSString,
               let index = array.firstIndex(of: current) {
                guard index >= 0, index < (array.count - 1 ) else { return nil }
                return .init(targetElement: array[index + 1], targetRange: nil)
            }
            return UIAccessibilityCustomRotorItemResult(targetElement: array.first!, targetRange: nil)
        }
        
        let all = reversed.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(all.map({ $0.targetElement as! NSString}), strings)
        
        // This rotor loops over the array indefinitely
        let loopingRotor = UIAccessibilityCustomRotor(name: "looping") { predicate in
            if let current = predicate.currentItem.targetElement as? NSString,
               let index = strings.firstIndex(of: current) {
                
                var newIndex = index + (predicate.searchDirection == .next ? 1 : -1)
                
                if newIndex <= -1  { newIndex = strings.count - 1 }
                else if newIndex >= strings.count { newIndex = 0 }
                
                return .init(targetElement: strings[newIndex], targetRange: nil)
                
            }
            return UIAccessibilityCustomRotorItemResult(targetElement:  predicate.searchDirection == .next ? strings.first! : strings.last!, targetRange: nil)
        }
        let looping = loopingRotor.collectAllResults(nextLimit: 10, previousLimit: 10).results
        XCTAssertEqual(looping.map({ $0.targetElement as! NSString}), strings)
        
        
        
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
