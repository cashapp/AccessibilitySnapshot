import AccessibilitySnapshotModel
import CoreGraphics
import UIKit

// MARK: - Geometry Bridging

public extension AccessibilityPoint {
    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

public extension AccessibilitySize {
    init(_ size: CGSize) {
        self.init(width: Double(size.width), height: Double(size.height))
    }

    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}

public extension AccessibilityRect {
    init(_ rect: CGRect) {
        self.init(
            origin: AccessibilityPoint(rect.origin),
            size: AccessibilitySize(rect.size)
        )
    }

    var cgRect: CGRect {
        CGRect(origin: origin.cgPoint, size: size.cgSize)
    }
}

// MARK: - Path Bridging

public extension AccessibilityPathElement {
    func apply(to path: UIBezierPath) {
        switch self {
        case let .move(to):
            path.move(to: to.cgPoint)
        case let .line(to):
            path.addLine(to: to.cgPoint)
        case let .quadCurve(to, control):
            path.addQuadCurve(to: to.cgPoint, controlPoint: control.cgPoint)
        case let .curve(to, control1, control2):
            path.addCurve(to: to.cgPoint, controlPoint1: control1.cgPoint, controlPoint2: control2.cgPoint)
        case .closeSubpath:
            path.close()
        }
    }

    static func elements(from cgPath: CGPath) -> [AccessibilityPathElement] {
        var elements: [AccessibilityPathElement] = []
        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint:
                elements.append(.move(to: AccessibilityPoint(element.points[0])))
            case .addLineToPoint:
                elements.append(.line(to: AccessibilityPoint(element.points[0])))
            case .addQuadCurveToPoint:
                elements.append(.quadCurve(
                    to: AccessibilityPoint(element.points[1]),
                    control: AccessibilityPoint(element.points[0])
                ))
            case .addCurveToPoint:
                elements.append(.curve(
                    to: AccessibilityPoint(element.points[2]),
                    control1: AccessibilityPoint(element.points[0]),
                    control2: AccessibilityPoint(element.points[1])
                ))
            case .closeSubpath:
                elements.append(.closeSubpath)
            @unknown default:
                break
            }
        }
        return elements
    }
}

public extension AccessibilityShape {
    var bezierPath: UIBezierPath {
        switch self {
        case let .frame(rect):
            return UIBezierPath(rect: rect.cgRect)
        case let .path(pathElements):
            let bezier = UIBezierPath()
            for element in pathElements {
                element.apply(to: bezier)
            }
            return bezier
        }
    }
}

// MARK: - Trait Bridging

public extension AccessibilityTraits {
    init(_ uiTraits: UIAccessibilityTraits) {
        self.init(rawValue: uiTraits.rawValue)
    }

    var uiAccessibilityTraits: UIAccessibilityTraits {
        UIAccessibilityTraits(rawValue: rawValue)
    }
}

// MARK: - Rotor Limit Bridging

public extension AccessibilityRotorResultLimit {
    init(_ limit: UIAccessibilityCustomRotor.CollectedRotorResults.Limit) {
        switch limit {
        case .none:
            self = .none
        case let .underMaxCount(count):
            self = .underMaxCount(count)
        case .greaterThanMaxCount:
            self = .greaterThanMaxCount
        }
    }
}
