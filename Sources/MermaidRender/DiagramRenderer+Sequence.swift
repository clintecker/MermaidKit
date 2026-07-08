#if canImport(AppKit) || canImport(UIKit)
import Foundation
import CoreText
import CoreGraphics
import MermaidLayout

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

extension DiagramRenderer {

    /// Draws the arrow ending for a sequence head style: filled triangle,
    /// cross, open half-arrow, or nothing.
    private static func drawSequenceHead(
        _ head: SequenceDiagram.Message.ArrowHead,
        at tip: CGPoint, from origin: CGPoint,
        stroke: PlatformColor, theme: DiagramTheme, in context: CGContext
    ) {
        switch head {
        case .none:
            return
        case .filled, .both:
            drawArrowhead(at: tip, from: origin, color: stroke, canvas: theme.canvas, in: context)
        case .cross:
            let r: CGFloat = 4.5
            let inset: CGFloat = tip.x >= origin.x ? -3 : 3
            let cx = tip.x + inset
            context.setStrokeColor(resolvedCGColor(stroke))
            context.setLineWidth(1.6)
            context.beginPath()
            context.move(to: CGPoint(x: cx - r, y: tip.y - r))
            context.addLine(to: CGPoint(x: cx + r, y: tip.y + r))
            context.move(to: CGPoint(x: cx - r, y: tip.y + r))
            context.addLine(to: CGPoint(x: cx + r, y: tip.y - r))
            context.strokePath()
        case .open:
            let angle = atan2(tip.y - origin.y, tip.x - origin.x)
            let length: CGFloat = 9
            let spread: CGFloat = 0.5
            context.setStrokeColor(resolvedCGColor(stroke))
            context.setLineWidth(1.4)
            context.beginPath()
            context.move(to: CGPoint(x: tip.x - length * cos(angle - spread),
                                     y: tip.y - length * sin(angle - spread)))
            context.addLine(to: tip)
            context.addLine(to: CGPoint(x: tip.x - length * cos(angle + spread),
                                        y: tip.y - length * sin(angle + spread)))
            context.strokePath()
        }
    }

    static func draw(_ layout: SequenceLayout, theme: DiagramTheme, in context: CGContext) {
        let stroke = theme.ink.withAlphaComponent(0.35)
        let hairline = theme.ink.withAlphaComponent(0.18)

        // Lifelines behind everything.
        for head in layout.heads {
            context.saveGState()
            context.setStrokeColor(resolvedCGColor(hairline))
            context.setLineWidth(1)
            context.setLineDash(phase: 0, lengths: [3, 3])
            context.beginPath()
            context.move(to: CGPoint(x: head.lifelineX, y: head.frame.maxY))
            context.addLine(to: CGPoint(x: head.lifelineX, y: layout.lifelineBottom))
            context.strokePath()
            context.restoreGState()
        }

        for head in layout.heads {
            if head.isActor {
                // Stick figure above the label: head circle, body, arms, legs.
                let cx = head.frame.midX
                let top = head.frame.minY
                context.setStrokeColor(resolvedCGColor(theme.ink.withAlphaComponent(0.75)))
                context.setLineWidth(1.4)
                context.strokeEllipse(in: CGRect(x: cx - 4, y: top, width: 8, height: 8))
                context.beginPath()
                context.move(to: CGPoint(x: cx, y: top + 8))
                context.addLine(to: CGPoint(x: cx, y: top + 17))          // body
                context.move(to: CGPoint(x: cx - 6, y: top + 11))
                context.addLine(to: CGPoint(x: cx + 6, y: top + 11))      // arms
                context.move(to: CGPoint(x: cx, y: top + 17))
                context.addLine(to: CGPoint(x: cx - 5, y: top + 24))      // legs
                context.move(to: CGPoint(x: cx, y: top + 17))
                context.addLine(to: CGPoint(x: cx + 5, y: top + 24))
                context.strokePath()
                drawText(head.label, center: CGPoint(x: cx, y: head.frame.maxY + 7),
                         size: 10.5, weight: .medium, color: theme.ink, in: context)
            } else {
                fillStrokeBox(head.frame, radius: 6, fill: theme.accent.withAlphaComponent(0.06), stroke: stroke, in: context)
                drawText(head.label, center: CGPoint(x: head.frame.midX, y: head.frame.midY),
                         size: 12, weight: .medium, color: theme.ink, in: context)
            }
        }

        // Autonumber badges: a small chip at the sender end of the arrow.
        for arrow in layout.arrows where arrow.number != nil {
            let text = "\(arrow.number!)"
            let size = measure(text, size: 8)
            let sign: CGFloat = arrow.toX >= arrow.fromX ? 1 : -1
            let chip = CGRect(x: arrow.fromX + sign * 4 - (sign < 0 ? size.width + 8 : 0),
                              y: arrow.y - 17,
                              width: size.width + 8, height: 12)
            context.setFillColor(resolvedCGColor(theme.accent.withAlphaComponent(0.85)))
            context.addPath(CGPath(roundedRect: chip, cornerWidth: 5, cornerHeight: 5, transform: nil))
            context.fillPath()
            drawText(text, center: CGPoint(x: chip.midX, y: chip.midY),
                     size: 8, weight: .semibold, color: theme.canvas, in: context)
        }

        // Note boxes: tinted, hairline-bordered, text centered — the classic
        // sequence-note look.
        for note in layout.notes {
            fillStrokeBox(note.frame, radius: 3,
                          fill: theme.categoricalColor(2).withAlphaComponent(0.18),
                          stroke: theme.categoricalColor(2), in: context)
            drawText(note.text, center: CGPoint(x: note.frame.midX, y: note.frame.midY),
                     size: labelSize, color: theme.ink, in: context)
        }

        for arrow in layout.arrows {
            context.saveGState()
            context.setStrokeColor(resolvedCGColor(stroke))
            context.setLineWidth(1)
            if arrow.dashed { context.setLineDash(phase: 0, lengths: [4, 3]) }
            context.beginPath()
            if arrow.isSelfMessage {
                // Loop out, down, and back into the lifeline.
                context.move(to: CGPoint(x: arrow.fromX, y: arrow.y))
                context.addLine(to: CGPoint(x: arrow.toX, y: arrow.y))
                context.addLine(to: CGPoint(x: arrow.toX, y: arrow.y + 12))
                context.addLine(to: CGPoint(x: arrow.fromX, y: arrow.y + 12))
            } else {
                context.move(to: CGPoint(x: arrow.fromX, y: arrow.y))
                context.addLine(to: CGPoint(x: arrow.toX, y: arrow.y))
            }
            context.strokePath()
            context.restoreGState()

            if arrow.isSelfMessage {
                drawSequenceHead(arrow.head,
                    at: CGPoint(x: arrow.fromX, y: arrow.y + 12),
                    from: CGPoint(x: arrow.toX, y: arrow.y + 12),
                    stroke: stroke, theme: theme, in: context)
                if !arrow.text.isEmpty {
                    let size = measure(arrow.text, size: 10.5)
                    drawText(arrow.text,
                             center: CGPoint(x: arrow.toX + 8 + size.width / 2, y: arrow.y + 6),
                             size: 10.5, color: theme.secondaryTextColor, in: context)
                }
            } else {
                drawSequenceHead(arrow.head,
                    at: CGPoint(x: arrow.toX, y: arrow.y),
                    from: CGPoint(x: arrow.fromX, y: arrow.y),
                    stroke: stroke, theme: theme, in: context)
                if arrow.head == .both {
                    drawSequenceHead(.filled,
                        at: CGPoint(x: arrow.fromX, y: arrow.y),
                        from: CGPoint(x: arrow.toX, y: arrow.y),
                        stroke: stroke, theme: theme, in: context)
                }
                if !arrow.text.isEmpty {
                    drawText(arrow.text,
                             center: CGPoint(x: (arrow.fromX + arrow.toX) / 2, y: arrow.y - 10),
                             size: 10.5, color: theme.secondaryTextColor, in: context)
                }
            }
        }
    }
}
#endif
