#if canImport(AppKit) || canImport(UIKit)
import Foundation
import CoreGraphics
import MermaidLayout
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

extension DiagramRenderer {
    /// Renders a diagram as single-page vector PDF data — the same layout and
    /// draw code as the raster path (via `renderPlan`), into a `CGPDFContext`
    /// instead of a bitmap, so exports and print stay crisp at any zoom.
    ///
    /// One-shot (no cache): exports are rare compared to view renders, and
    /// PDF data is cheap to regenerate relative to holding it hot. Returns
    /// nil for unparseable sources, exactly like the raster APIs.
    static func pdfData(source: String, theme: DiagramTheme,
                        spacing: DiagramSpacing = .regular) -> Data? {
        guard let diagram = MermaidParser.parse(source) else { return nil }
        let plan = captionedPlan(renderPlan(for: diagram, theme: theme, spacing: spacing),
                                 source: source, diagram: diagram, theme: theme)
        guard let (canvasSize, originX, originY) =
                paddedCanvas(size: plan.size, edgePolylines: plan.edgePolylines) else { return nil }

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else { return nil }
        var mediaBox = CGRect(origin: .zero, size: canvasSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        context.beginPDFPage(nil)
        // Fill the page with the theme canvas (the raster path gets this from
        // the attachment's background; a PDF page starts transparent).
        context.setFillColor(resolvedCGColor(theme.canvas))
        context.fill(mediaBox)
        // The draw code (drawText's textMatrix included) assumes a flipped,
        // top-left-origin CTM — the raster paths get that from
        // NSImage(flipped:)/UIGraphicsImageRenderer. A PDF context is y-up,
        // so flip it ourselves before the shared translation.
        context.translateBy(x: 0, y: canvasSize.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: originX, y: originY)

        // Pin appearance resolution exactly like the raster paths, so dynamic
        // platform colors resolve to the theme's variant, not the ambient one.
        #if canImport(AppKit)
        if let appearance = NSAppearance(named: theme.prefersDark ? .darkAqua : .aqua) {
            appearance.performAsCurrentDrawingAppearance { plan.draw(context) }
        } else {
            plan.draw(context)
        }
        #else
        let traits = UITraitCollection(userInterfaceStyle: theme.prefersDark ? .dark : .light)
        traits.performAsCurrent { plan.draw(context) }
        #endif

        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
}
#endif
