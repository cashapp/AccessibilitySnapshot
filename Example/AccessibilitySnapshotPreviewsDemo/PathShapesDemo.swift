import SwiftUI
import AccessibilitySnapshotPreviews
import UIKit

struct PathShapesDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                DemoSection(title: "Path Shapes", description: "Testing badge placement on various accessibility paths") {
                    VStack(spacing: 64) {
                        // Row 1: Simple shapes
                        HStack(spacing: 48) {
                            CircleShapeView()
                            OvalShapeView()
                            DiamondShapeView()
                        }

                        // Row 2: L shapes in all orientations
                        HStack(spacing: 48) {
                            LShapeBottomRight()
                            LShapeBottomLeft()
                            LShapeTopLeft()
                            LShapeTopRight()
                        }

                        // Row 3: Complex shapes
                        HStack(spacing: 48) {
                            StarShapeView()
                            CrescentShapeView()
                        }

                        // Row 4: Extreme cases
                        HStack(spacing: 48) {
                            ThinRectView()
                            TriangleShapeView()
                            CrossShapeView()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Path Shapes")
    }
}

// MARK: - Shape Views with Custom Accessibility Paths

struct CircleShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        view.shapePath = UIBezierPath(ovalIn: view.bounds)
        view.shapeColor = .systemBlue
        view.accessibilityLabel = "Circle"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct OvalShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        view.shapePath = UIBezierPath(ovalIn: view.bounds)
        view.shapeColor = .systemGreen
        view.accessibilityLabel = "Oval"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct DiamondShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: w, y: h / 2))
        path.addLine(to: CGPoint(x: w / 2, y: h))
        path.addLine(to: CGPoint(x: 0, y: h / 2))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemPurple
        view.accessibilityLabel = "Diamond"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

// L shape with corner at bottom-right (└)
struct LShapeBottomRight: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 40))
        path.addLine(to: CGPoint(x: 60, y: 40))
        path.addLine(to: CGPoint(x: 60, y: 60))
        path.addLine(to: CGPoint(x: 0, y: 60))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemOrange
        view.accessibilityLabel = "L Bottom Right"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

// L shape with corner at bottom-left (┘)
struct LShapeBottomLeft: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 40, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 60))
        path.addLine(to: CGPoint(x: 0, y: 60))
        path.addLine(to: CGPoint(x: 0, y: 40))
        path.addLine(to: CGPoint(x: 40, y: 40))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemBrown
        view.accessibilityLabel = "L Bottom Left"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

// L shape with corner at top-left (┐)
struct LShapeTopLeft: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 60))
        path.addLine(to: CGPoint(x: 0, y: 60))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemMint
        view.accessibilityLabel = "L Top Left"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

// L shape with corner at top-right (┌)
struct LShapeTopRight: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 0))
        path.addLine(to: CGPoint(x: 60, y: 60))
        path.addLine(to: CGPoint(x: 40, y: 60))
        path.addLine(to: CGPoint(x: 40, y: 20))
        path.addLine(to: CGPoint(x: 0, y: 20))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemCyan
        view.accessibilityLabel = "L Top Right"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct StarShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        view.shapePath = starPath(in: view.bounds, points: 5, innerRadius: 12, outerRadius: 30)
        view.shapeColor = .systemYellow
        view.accessibilityLabel = "Star"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}

    private func starPath(in rect: CGRect, points: Int, innerRadius: CGFloat, outerRadius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angleIncrement = .pi / CGFloat(points)

        for i in 0 ..< points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(i) * angleIncrement - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }
}

struct CrescentShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 50, height: 60))
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height

        // Outer arc (full moon)
        path.addArc(
            withCenter: CGPoint(x: w / 2, y: h / 2),
            radius: h / 2,
            startAngle: -.pi / 2,
            endAngle: .pi / 2,
            clockwise: true
        )

        // Inner arc (bite out of moon) - creates crescent
        path.addArc(
            withCenter: CGPoint(x: w / 2 + 10, y: h / 2),
            radius: h / 2 - 5,
            startAngle: .pi / 2,
            endAngle: -.pi / 2,
            clockwise: false
        )

        path.close()
        view.shapePath = path
        view.shapeColor = .systemIndigo
        view.accessibilityLabel = "Crescent"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct ThinRectView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        view.shapePath = UIBezierPath(rect: view.bounds)
        view.shapeColor = .systemRed
        view.accessibilityLabel = "Thin Rectangle"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct TriangleShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 52))
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.close()
        view.shapePath = path
        view.shapeColor = .systemTeal
        view.accessibilityLabel = "Triangle"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

struct CrossShapeView: UIViewRepresentable {
    func makeUIView(context: Context) -> PathShapeUIView {
        let view = PathShapeUIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height
        let t: CGFloat = 20 // thickness

        // Horizontal bar
        path.move(to: CGPoint(x: 0, y: (h - t) / 2))
        path.addLine(to: CGPoint(x: (w - t) / 2, y: (h - t) / 2))
        path.addLine(to: CGPoint(x: (w - t) / 2, y: 0))
        path.addLine(to: CGPoint(x: (w + t) / 2, y: 0))
        path.addLine(to: CGPoint(x: (w + t) / 2, y: (h - t) / 2))
        path.addLine(to: CGPoint(x: w, y: (h - t) / 2))
        path.addLine(to: CGPoint(x: w, y: (h + t) / 2))
        path.addLine(to: CGPoint(x: (w + t) / 2, y: (h + t) / 2))
        path.addLine(to: CGPoint(x: (w + t) / 2, y: h))
        path.addLine(to: CGPoint(x: (w - t) / 2, y: h))
        path.addLine(to: CGPoint(x: (w - t) / 2, y: (h + t) / 2))
        path.addLine(to: CGPoint(x: 0, y: (h + t) / 2))
        path.close()

        view.shapePath = path
        view.shapeColor = .systemPink
        view.accessibilityLabel = "Cross"
        return view
    }

    func updateUIView(_ uiView: PathShapeUIView, context: Context) {}
}

// MARK: - UIView with Custom Accessibility Path

class PathShapeUIView: UIView {
    var shapePath: UIBezierPath? {
        didSet {
            setNeedsDisplay()
            // Set accessibility path in screen coordinates
            if shapePath != nil {
                isAccessibilityElement = true
            }
        }
    }

    var shapeColor: UIColor = .systemBlue {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let path = shapePath else { return }
        shapeColor.withAlphaComponent(0.3).setFill()
        shapeColor.setStroke()
        path.lineWidth = 2
        path.fill()
        path.stroke()
    }

    override var accessibilityPath: UIBezierPath? {
        get {
            guard let path = shapePath else { return nil }
            // Convert to screen coordinates
            let screenPath = path.copy() as! UIBezierPath
            let screenOrigin = convert(CGPoint.zero, to: nil)
            screenPath.apply(CGAffineTransform(translationX: screenOrigin.x, y: screenOrigin.y))
            return screenPath
        }
        set {}
    }

    override var intrinsicContentSize: CGSize {
        return bounds.size
    }
}

#Preview {
    NavigationStack {
        PathShapesDemo()
    }
}
