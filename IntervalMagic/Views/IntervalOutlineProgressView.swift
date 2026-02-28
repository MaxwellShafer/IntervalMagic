import SwiftUI

enum IntervalOutlineShape: String, CaseIterable, Identifiable {
    case square
    case circle
    case triangle
    case star
    case hexagon

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .square: return "Square"
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .star: return "Star"
        case .hexagon: return "Hexagon"
        }
    }
}

struct IntervalOutlineProgressView<Content: View>: View {
    let shape: IntervalOutlineShape
    let progress: Double // 0...1
    let baseColor: Color
    let progressColor: Color
    let lineWidth: CGFloat
    let inset: CGFloat
    let content: () -> Content

    init(shape: IntervalOutlineShape,
         progress: Double,
         baseColor: Color = .white,
         progressColor: Color = .accentColor,
         lineWidth: CGFloat = 4,
         inset: CGFloat = 8,
         @ViewBuilder content: @escaping () -> Content) {
        self.shape = shape
        self.progress = min(max(progress, 0), 1)
        self.baseColor = baseColor
        self.progressColor = progressColor
        self.lineWidth = lineWidth
        self.inset = inset
        self.content = content
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                let rect = CGRect(
                    x: inset + lineWidth / 2,
                    y: inset + lineWidth / 2,
                    width: size.width - 2 * inset - lineWidth,
                    height: size.height - 2 * inset - lineWidth
                )
                let path = pathForShape(in: rect)
                let totalLength = path.length
                let filledLength = totalLength * CGFloat(progress)

                // Base outline
                Path { p in
                    p.addPath(path)
                }
                .stroke(Color.secondary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Progress outline
                Path { p in
                    p.addPath(path.trimmedPath(to: filledLength))
                }
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
            .animation(.linear(duration: 1.0), value: progress)
            .animation(.easeInOut(duration: 0.3), value: progressColor)

            content()
                .padding(inset + lineWidth)
        }
    }

    private func pathForShape(in rect: CGRect) -> Path {
        switch shape {
        case .square:
            var p = Path()
            p.addRoundedRect(in: rect, cornerSize: .zero)
            return p
        case .circle:
            var p = Path()
            p.addEllipse(in: rect)
            return p
        case .triangle:
            let adjustedTriangle = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
            return polygonPath(sides: 3, in: adjustedTriangle, rotation: -.pi / 2)
        case .star:
            let adjustedStar = rect.insetBy(dx: rect.width * 0.14, dy: rect.height * 0.14)
            return starPath(points: 5, in: adjustedStar, rotation: -.pi / 2)
        case .hexagon:
            return polygonPath(sides: 6, in: rect, rotation: 0)
        }
    }

    private func polygonPath(sides: Int, in rect: CGRect, rotation: CGFloat) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<sides {
            let angle = (CGFloat(i) / CGFloat(sides)) * 2 * .pi + rotation
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private func starPath(points: Int, in rect: CGRect, rotation: CGFloat) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.48
        var path = Path()
        let total = points * 2
        for i in 0..<total {
            let isOuter = i % 2 == 0
            let radius = isOuter ? outerRadius : innerRadius
            let angle = (CGFloat(i) / CGFloat(total)) * 2 * .pi + rotation
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Path utilities
private extension Path {
    var length: CGFloat {
        var total: CGFloat = 0
        var last: CGPoint? = nil
        self.forEach { element in
            switch element {
            case .move(let to):
                last = to
            case .line(let to):
                if let l = last {
                    total += hypot(to.x - l.x, to.y - l.y)
                }
                last = to
            case .quadCurve(let to, let control):
                total += approxCurveLength(from: last ?? .zero, to: to, control1: control, control2: nil)
                last = to
            case .curve(let to, let c1, let c2):
                total += approxCurveLength(from: last ?? .zero, to: to, control1: c1, control2: c2)
                last = to
            case .closeSubpath:
                break
            }
        }
        return total
    }

    func trimmedPath(to length: CGFloat) -> Path {
        let total = self.length
        let target = max(0, min(length, total))
        if total == 0 { return self }
        let fraction = target / total
        return self.trimmedPath(from: 0, to: fraction)
    }

    private func approxCurveLength(from start: CGPoint, to end: CGPoint, control1: CGPoint, control2: CGPoint?) -> CGFloat {
        let steps = 20
        var length: CGFloat = 0
        var previous = start
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let point: CGPoint
            if let c2 = control2 {
                point = cubicBezier(t: t, p0: start, p1: control1, p2: c2, p3: end)
            } else {
                point = quadBezier(t: t, p0: start, p1: control1, p2: end)
            }
            length += hypot(point.x - previous.x, point.y - previous.y)
            previous = point
        }
        return length
    }

    private func quadBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x
        let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    private func cubicBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = pow(oneMinusT, 3) * p0.x + 3 * pow(oneMinusT, 2) * t * p1.x + 3 * oneMinusT * t * t * p2.x + pow(t, 3) * p3.x
        let y = pow(oneMinusT, 3) * p0.y + 3 * pow(oneMinusT, 2) * t * p1.y + 3 * oneMinusT * t * t * p2.y + pow(t, 3) * p3.y
        return CGPoint(x: x, y: y)
    }
}
