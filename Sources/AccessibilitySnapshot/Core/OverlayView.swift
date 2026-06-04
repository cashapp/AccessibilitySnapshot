import AccessibilitySnapshotParser
import UIKit

extension AccessibilitySnapshotView {
    final class OverlayView: UIView {
        init(frame: CGRect, elementShape: AccessibilityShape, includedShapes: [AccessibilityShape], fillColor: UIColor, strokeColor: UIColor) {
            super.init(frame: frame)
            addShape(elementShape, fillColor: fillColor, strokeColor: strokeColor)
            includedShapes.forEach { addShape($0, fillColor: fillColor, strokeColor: strokeColor, isIncludedShape: true) }
        }

        private func addShape(_ shape: AccessibilityShape, fillColor: UIColor, strokeColor: UIColor, isIncludedShape: Bool = false) {
            let (path, stroke, fill): (UIBezierPath, UIColor?, UIColor?) = {
                switch shape {
                case let .frame(rect):
                    return (UIBezierPath(rect: rect.cgRect), nil, fillColor)
                case let .path(path):
                    let bezier = UIBezierPath()
                    for element in path {
                        element.apply(to: bezier)
                    }
                    return (bezier, strokeColor, nil)
                }
            }()

            let overlayLayer = CAShapeLayer()
            overlayLayer.lineWidth = 4
            overlayLayer.strokeColor = stroke?.cgColor
            overlayLayer.fillColor = fill?.cgColor
            overlayLayer.path = path.cgPath

            if isIncludedShape {
                overlayLayer.lineWidth = 2
                overlayLayer.lineDashPattern = [2, 2] as [NSNumber]
            }

            layer.addSublayer(overlayLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
