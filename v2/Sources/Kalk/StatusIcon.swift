import AppKit

/// The menubar icon: four tiles with + − × =, drawn as a template image so it's sharp at any
/// scale and adapts to light and dark menu bars.
enum StatusIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: true) { _ in
            let tile: CGFloat = 7
            let tiles = [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 8.5, y: 0.5), CGPoint(x: 0.5, y: 8.5), CGPoint(x: 8.5, y: 8.5)]
            NSColor.black.setFill()
            for origin in tiles {
                NSBezierPath(roundedRect: NSRect(origin: origin, size: NSSize(width: tile, height: tile)), xRadius: 1.6, yRadius: 1.6).fill()
            }

            // Punch the symbols out of the tiles.
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            let glyphs = NSBezierPath()
            glyphs.lineWidth = 1.2
            glyphs.lineCapStyle = .round
            func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) {
                glyphs.move(to: NSPoint(x: x1, y: y1))
                glyphs.line(to: NSPoint(x: x2, y: y2))
            }
            line(2.2, 4, 5.8, 4); line(4, 2.2, 4, 5.8)                    // +
            line(10.2, 4, 13.8, 4)                                          // −
            line(2.6, 10.6, 5.4, 13.4); line(5.4, 10.6, 2.6, 13.4)        // ×
            line(10.2, 10.9, 13.8, 10.9); line(10.2, 13.1, 13.8, 13.1)    // =
            glyphs.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Kalk"
        return image
    }
}
