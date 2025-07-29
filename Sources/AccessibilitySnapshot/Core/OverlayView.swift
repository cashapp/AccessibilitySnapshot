import UIKit
#if SWIFT_PACKAGE
import AccessibilitySnapshotParser
#endif


internal extension AccessibilitySnapshotView {
    
    final class OverlayView: UIView {
        
        init(elementShape: AccessibilityMarker.Shape, lesserIncludedShapes: [AccessibilityMarker.Shape], frame: CGRect, color: UIColor) {
            super .init(frame: frame)
            addShape(elementShape, color: color)
            lesserIncludedShapes.forEach({ addShape($0, color: color, isLesserShape: true) })
        }
        
        private func addShape(_ shape: AccessibilityMarker.Shape, color: UIColor, isLesserShape: Bool =  false) {
                        
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
            
            if isLesserShape {
                overlayLayer.lineWidth = 2
                overlayLayer.lineDashPattern = [2, 2] as [NSNumber]
            }
            
            layer.addSublayer(overlayLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
