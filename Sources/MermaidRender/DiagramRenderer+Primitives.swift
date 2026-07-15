#if canImport(AppKit) || canImport(UIKit) || canImport(SilicaCairo)
import Foundation
import MermaidLayout

#if canImport(AppKit)
import CoreGraphics
import CoreText
import AppKit
#elseif canImport(UIKit)
import CoreGraphics
import CoreText
import UIKit
#endif

extension DiagramRenderer {

    #if canImport(AppKit) || canImport(UIKit)
    static func font(_ size: CGFloat, weight: PlatformFont.Weight = .regular) -> CTFont {
        PlatformFont.systemFont(ofSize: size, weight: weight) as CTFont
    }
    #endif

    static func measure(_ text: String, size: CGFloat, weight: PlatformFont.Weight = .regular) -> CGSize {
        #if canImport(AppKit) || canImport(UIKit)
        let attributed = NSAttributedString(string: text, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font(size, weight: weight),
        ])
        let line = CTLineCreateWithAttributedString(attributed)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        return CGSize(width: width, height: ascent + descent)
        #else
        // Linux: measure with Silica's FontConfig-resolved font metrics.
        // `descent` is negative below the baseline, so height = ascent − descent
        // is the full em span (matching the ascent+descent Apple returns).
        guard let f = linuxFont(weight) else {
            return CGSize(width: CGFloat(text.count) * size * 0.6, height: size + 4)
        }
        return CGSize(width: f.singleLineWidth(text: text, fontSize: size),
                      height: (f.ascent - f.descent) * size)
        #endif
    }

    /// Draws text centered on `center` in a flipped (y-down) context.
    #if DEBUG
    /// Test-only: receives every text rect drawText paints, in layout
    /// coordinates (the CTM applies canvas translation after the fact).
    /// The draw-vs-scene conformance test uses it to prove that everything
    /// the renderer draws is visible to the geometry linter.
    nonisolated(unsafe) static var textCaptureHook: ((String, CGRect) -> Void)?
    /// Suspends capture inside rotated CTMs, where the argument-space rect
    /// would be meaningless.
    nonisolated(unsafe) static var textCaptureSuspended = false
    #endif

    static func drawText(
        _ text: String,
        center: CGPoint,
        size: CGFloat,
        weight: PlatformFont.Weight = .regular,
        color: PlatformColor,
        in context: CGContext
    ) {
        guard !text.isEmpty else { return }
        #if DEBUG
        if let hook = textCaptureHook, !textCaptureSuspended {
            let measured = measure(text, size: size, weight: weight)
            hook(text, CGRect(x: center.x - measured.width / 2,
                              y: center.y - measured.height / 2,
                              width: measured.width, height: measured.height))
        }
        #endif
        #if canImport(AppKit) || canImport(UIKit)
        let attributed = NSAttributedString(string: text, attributes: [
            kCTFontAttributeName as NSAttributedString.Key: font(size, weight: weight),
            kCTForegroundColorFromContextAttributeName as NSAttributedString.Key: true,
        ])
        let line = CTLineCreateWithAttributedString(attributed)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))

        context.saveGState()
        context.setFillColor(resolvedCGColor(color))
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        context.textPosition = CGPoint(
            x: center.x - width / 2,
            y: center.y + (ascent - descent) / 2
        )
        CTLineDraw(line, context)
        context.restoreGState()
        #else
        // Linux: draw with Silica. `show(text:)` treats textMatrix.ty as the
        // text top (it adds ascent·fontSize in a flipped context), so we place
        // the top at center.y − height/2 to vertically center on `center`, and
        // tx at center.x − width/2 to horizontally center.
        guard let f = linuxFont(weight) else { return }
        let width = f.singleLineWidth(text: text, fontSize: size)
        let textH = (f.ascent - f.descent) * size
        context.saveGState()
        context.setFillColor(resolvedCGColor(color))
        context.setFont(f)
        context.fontSize = size
        context.textMatrix = CGAffineTransform(a: 1, b: 0, c: 0, d: 1,
                                               tx: center.x - width / 2,
                                               ty: center.y - textH / 2)
        context.show(text: text)
        context.restoreGState()
        #endif
    }

    /// The true bounding box of everything a box/flowchart diagram draws: the
    /// layout's own `size` (boxes + clamped labels) unioned with every edge
    /// point inflated by the maximum endpoint-marker reach. Markers point
    /// inward along the edge (already inside the point-to-point span) and only
    /// spread a few points perpendicular, so a uniform inflate captures them
    /// without having to know each marker's exact geometry.
    static func contentBounds(size: CGSize, edges: [[CGPoint]]) -> CGRect {
        var box = CGRect(origin: .zero, size: size)
        // Widest perpendicular marker spread across all types: the ER crow's
        // foot / zero-circle and the UML triangle sit within this of the line.
        // Must cover the largest end-marker overhang: arrowheads reach 8.5pt
        // along the edge, ER crow's feet ~18pt along (toward the box, already
        // inside bounds) with ~6pt perpendicular spread. 10pt covers every
        // marker's off-edge spread with margin.
        let markerReach: CGFloat = 10
        for points in edges {
            for p in points {
                box = box.union(CGRect(x: p.x - markerReach, y: p.y - markerReach,
                                       width: markerReach * 2, height: markerReach * 2))
            }
        }
        return box
    }

    /// The standard centred diagram title — one implementation for the nine
    /// chart types that draw one (12.5pt semibold ink, centred at y = 14).
    static func drawDiagramTitle(_ title: String?, width: CGFloat, theme: DiagramTheme, in context: CGContext) {
        guard let title, !title.isEmpty else { return }
        drawText(title, center: CGPoint(x: width / 2, y: 14),
                 size: 12.5, weight: .semibold, color: theme.ink, in: context)
    }

    /// Draws text rotated 90° (reading bottom-to-top) centered on `center`,
    /// for vertical y-axis labels.
    static func drawTextRotated(
        _ text: String, center: CGPoint, size: CGFloat,
        weight: PlatformFont.Weight = .regular, color: PlatformColor, in context: CGContext
    ) {
        guard !text.isEmpty else { return }
        #if DEBUG
        textCaptureSuspended = true
        defer { textCaptureSuspended = false }
        #endif
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -.pi / 2)
        drawText(text, center: .zero, size: size, weight: weight, color: color, in: context)
        context.restoreGState()
    }

    static func drawTextLeft(
        _ text: String, at origin: CGPoint, size: CGFloat,
        weight: PlatformFont.Weight = .regular, color: PlatformColor, in context: CGContext
    ) {
        let measured = measure(text, size: size, weight: weight)
        drawText(text, center: CGPoint(x: origin.x + measured.width / 2, y: origin.y),
                 size: size, weight: weight, color: color, in: context)
    }
}
#endif
