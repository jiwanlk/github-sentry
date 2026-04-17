import Cocoa

enum GitHubIcon {
    /// Creates a GitHub Octomark template image suitable for the macOS menu bar.
    /// Rendered at 18x18 points (36x36 pixels for Retina).
    static func menuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { rect in
            let path = GitHubIcon.octocatPath(in: rect.insetBy(dx: 1, dy: 1))
            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    /// The GitHub Octocat mark as an NSBezierPath, scaled to fit the given rect.
    /// Based on the official GitHub mark SVG (viewBox 0 0 16 16).
    private static func octocatPath(in rect: NSRect) -> NSBezierPath {
        let sx = rect.width / 16.0
        let sy = rect.height / 16.0
        let ox = rect.origin.x
        let oy = rect.origin.y

        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(x: ox + x * sx, y: oy + y * sy)
        }

        let path = NSBezierPath()

        // Main circle/body - GitHub Octocat mark path
        path.move(to: p(8, 0))
        path.curve(to: p(0, 8), controlPoint1: p(3.58, 0), controlPoint2: p(0, 3.58))
        path.curve(to: p(5.47, 15.59), controlPoint1: p(0, 11.54), controlPoint2: p(2.29, 14.53))
        path.curve(to: p(5.87, 15.59), controlPoint1: p(5.57, 15.52), controlPoint2: p(5.87, 15.42))
        // Approximate: 0-.19-.01-.82-.01-1.49
        path.curve(to: p(6.02, 15.21), controlPoint1: p(5.87, 15.59), controlPoint2: p(5.87, 15.4))
        path.curve(to: p(5.86, 13.72), controlPoint1: p(6.02, 15.21), controlPoint2: p(5.86, 14.39))
        // -2.01.37-2.53-.49-2.69-.94
        path.curve(to: p(3.85, 13.35), controlPoint1: p(5.86, 13.72), controlPoint2: p(3.85, 14.09))
        path.curve(to: p(3.17, 12.41), controlPoint1: p(3.85, 13.35), controlPoint2: p(3.33, 12.78))
        // -.09-.23-.48-.94-.82-1.13
        path.curve(to: p(3.08, 12.18), controlPoint1: p(3.17, 12.41), controlPoint2: p(3.08, 12.18))
        path.curve(to: p(2.35, 11.28), controlPoint1: p(3.08, 12.18), controlPoint2: p(2.69, 11.47))
        // -.28-.15-.68-.52-.01-.53
        path.curve(to: p(2.07, 11.13), controlPoint1: p(2.35, 11.28), controlPoint2: p(2.07, 11.13))
        path.curve(to: p(2.34, 10.75), controlPoint1: p(2.07, 11.13), controlPoint2: p(1.67, 10.76))
        // .63-.01 1.08.58 1.23.82
        path.curve(to: p(2.97, 10.74), controlPoint1: p(2.34, 10.75), controlPoint2: p(2.97, 10.74))
        path.curve(to: p(3.57, 11.32), controlPoint1: p(2.97, 10.74), controlPoint2: p(3.42, 11.32))
        path.curve(to: p(4.2, 11.56), controlPoint1: p(3.57, 11.32), controlPoint2: p(3.8, 11.56))

        path.removeAllPoints()

        // Use a simpler, more accurate approach with the actual SVG path
        return octocatSimplified(in: rect)
    }

    private static func octocatSimplified(in rect: NSRect) -> NSBezierPath {
        // GitHub Octocat mark - simplified for 16x16 menu bar rendering
        let sx = rect.width / 16.0
        let sy = rect.height / 16.0
        let ox = rect.origin.x
        let oy = rect.origin.y

        // Use CGPath with the SVG data for accuracy, then convert
        let cgPath = CGMutablePath()

        func s(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: ox + x * sx, y: oy + y * sy)
        }

        // M8 0
        cgPath.move(to: s(8, 0))
        // C3.58 0 0 3.58 0 8
        cgPath.addCurve(to: s(0, 8), control1: s(3.58, 0), control2: s(0, 3.58))
        // c0 3.54 2.29 6.53 5.47 7.59
        cgPath.addCurve(to: s(5.47, 15.59), control1: s(0, 11.54), control2: s(2.29, 14.53))
        // .4.07.55-.17.55-.38
        cgPath.addCurve(to: s(6.02, 15.21), control1: s(5.87, 15.66), control2: s(6.02, 15.42))
        // 0-.19-.01-.82-.01-1.49
        cgPath.addCurve(to: s(6.01, 13.72), control1: s(6.02, 15.02), control2: s(6.01, 14.39))
        // -2.01.37-2.53-.49-2.69-.94
        cgPath.addCurve(to: s(3.32, 12.78), control1: s(4.00, 14.09), control2: s(3.48, 13.23))
        // -.09-.23-.48-.94-.82-1.13
        cgPath.addCurve(to: s(2.50, 11.65), control1: s(3.23, 12.55), control2: s(2.84, 11.84))
        // -.28-.15-.68-.52-.01-.53
        cgPath.addCurve(to: s(2.49, 11.12), control1: s(2.22, 11.50), control2: s(1.82, 10.60))
        // .63-.01 1.08.58 1.23.82
        cgPath.addCurve(to: s(3.72, 11.94), control1: s(3.12, 11.11), control2: s(3.57, 11.70))
        // .72 1.21 1.87.87 2.33.66
        cgPath.addCurve(to: s(6.05, 12.60), control1: s(4.44, 13.15), control2: s(5.59, 12.81))
        // .07-.52.28-.87.51-1.07
        cgPath.addCurve(to: s(6.56, 11.53), control1: s(6.12, 12.08), control2: s(6.33, 11.73))
        // -1.78-.2-3.64-.89-3.64-3.95
        cgPath.addCurve(to: s(2.92, 7.58), control1: s(4.78, 11.33), control2: s(2.92, 10.64))
        // 0-.87.31-1.59.82-2.15
        cgPath.addCurve(to: s(3.74, 5.43), control1: s(2.92, 6.71), control2: s(3.23, 5.99))
        // -.08-.2-.36-1.02.08-2.12
        cgPath.addCurve(to: s(3.82, 3.31), control1: s(3.66, 5.23), control2: s(3.38, 4.41))
        // 0 0 .67-.21 2.2.82
        cgPath.addLine(to: s(3.82, 3.31))
        cgPath.addCurve(to: s(6.02, 4.13), control1: s(3.82, 3.31), control2: s(4.49, 3.10))
        // .64-.18 1.32-.27 2-.27
        cgPath.addCurve(to: s(8.02, 3.86), control1: s(6.66, 3.95), control2: s(7.34, 3.86))
        // .68 0 1.36.09 2 .27
        cgPath.addCurve(to: s(10.02, 4.13), control1: s(8.70, 3.86), control2: s(9.38, 3.95))
        // 1.53-1.04 2.2-.82 2.2-.82
        cgPath.addCurve(to: s(12.22, 3.31), control1: s(11.55, 3.09), control2: s(12.22, 3.31))
        // .44 1.1.16 1.92.08 2.12
        cgPath.addCurve(to: s(12.30, 5.43), control1: s(12.66, 4.41), control2: s(12.38, 5.23))
        // .51.56.82 1.27.82 2.15
        cgPath.addCurve(to: s(13.12, 7.58), control1: s(12.81, 5.99), control2: s(13.12, 6.70))
        // 0 3.07-1.87 3.75-3.65 3.95
        cgPath.addCurve(to: s(9.47, 11.53), control1: s(13.12, 10.65), control2: s(11.25, 11.33))
        // .29.25.54.73.54 1.48
        cgPath.addCurve(to: s(10.01, 13.01), control1: s(9.76, 11.78), control2: s(10.01, 12.26))
        // 0 1.07-.01 1.93-.01 2.2
        cgPath.addCurve(to: s(10.00, 15.21), control1: s(10.01, 14.08), control2: s(10.00, 14.94))
        // 0 .21.15.46.55.38
        cgPath.addCurve(to: s(10.55, 15.59), control1: s(10.00, 15.42), control2: s(10.15, 15.67))
        // A8.013 8.013 0 0016 8
        cgPath.addCurve(to: s(16, 8), control1: s(13.71, 14.53), control2: s(16, 11.54))
        // c0-4.42-3.58-8-8-8
        cgPath.addCurve(to: s(8, 0), control1: s(16, 3.58), control2: s(12.42, 0))
        cgPath.closeSubpath()

        return NSBezierPath(cgPath: cgPath)
    }
}

private extension CGMutablePath {
    func addCurve(to end: CGPoint, controlPoint1 cp1: CGPoint, controlPoint2 cp2: CGPoint) {
        addCurve(to: end, control1: cp1, control2: cp2)
    }
}

private extension NSBezierPath {
    convenience init(cgPath: CGPath) {
        self.init()
        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points = element.points
            switch element.type {
            case .moveToPoint:
                self.move(to: points[0])
            case .addLineToPoint:
                self.line(to: points[0])
            case .addCurveToPoint:
                self.curve(to: points[2], controlPoint1: points[0], controlPoint2: points[1])
            case .addQuadCurveToPoint:
                // Approximate with line
                self.line(to: points[1])
            case .closeSubpath:
                self.close()
            @unknown default:
                break
            }
        }
    }
}
