import AccessibilitySnapshotParser
import UIKit

extension AccessibilitySnapshotView {
    final class OverlayView: UIView {
        init(frame: CGRect, elementShape: AccessibilityMarker.Shape, includedShapes: [AccessibilityMarker.Shape], color: UIColor) {
            super.init(frame: frame)
            addShape(elementShape, color: color)
            includedShapes.forEach { addShape($0, color: color, isIncludedShape: true) }
        }

        private func addShape(_ shape: AccessibilityMarker.Shape, color: UIColor, isIncludedShape: Bool = false) {
            let (path, stroke, fill): (UIBezierPath, UIColor?, UIColor?) = {
                switch shape {
                case let .frame(rect):
                    return (UIBezierPath(rect: rect), nil, color.withAlphaComponent(0.3))
                case let .path(path):
                    return (path, color.withAlphaComponent(0.3), nil)
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
