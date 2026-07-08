import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Laid-out Wardley map: the plot frame with evolution bands, positioned
/// component dots, dependency links, evolve arrows, and collision-staggered
/// labels.
public struct WardleyLayout: Sendable {
    public struct Node: Sendable {
        public let name: String
        public let center: CGPoint
        public let isAnchor: Bool
        public let inertia: Bool
        public let decorator: String?
        /// Label frame, staggered clear of neighboring labels.
        public let labelFrame: CGRect
    }
    public struct Link: Sendable {
        public let from: CGPoint
        public let to: CGPoint
        public let isFlow: Bool
    }
    public struct Evolve: Sendable {
        public let from: CGPoint
        public let to: CGPoint
    }
    public struct Note: Sendable {
        public let text: String
        public let center: CGPoint
    }
    public let size: CGSize
    public let title: String?
    public let plotFrame: CGRect
    /// Evolution band boundaries (x positions inside the plot) and names.
    public let bands: [(x: CGFloat, name: String)]
    public let nodes: [Node]
    public let links: [Link]
    public let evolves: [Evolve]
    public let notes: [Note]
}

extension DiagramLayoutEngine {
    /// Lays out a Wardley map. No graph layout: coordinates are the author's
    /// (x = evolution, y = 1 − visibility). The engine's work is axis chrome,
    /// evolve targets, and label collision staggering.
    public static func layout(_ map: WardleyMap, measure: DiagramTextMeasurer) -> WardleyLayout {
        let margin: CGFloat = 14
        let axisGutter: CGFloat = 24
        let titleHeight: CGFloat = map.title == nil ? 0 : 26
        let plotW: CGFloat = 560
        let plotH: CGFloat = 400
        let plot = CGRect(x: margin + axisGutter, y: margin + titleHeight,
                          width: plotW, height: plotH)

        func point(visibility: Double, evolution: Double) -> CGPoint {
            CGPoint(x: plot.minX + CGFloat(evolution) * plot.width,
                    y: plot.minY + CGFloat(1 - visibility) * plot.height)
        }

        let bands: [(x: CGFloat, name: String)] = [
            (plot.minX, "Genesis"),
            (plot.minX + plot.width * 0.25, "Custom Built"),
            (plot.minX + plot.width * 0.50, "Product (+rental)"),
            (plot.minX + plot.width * 0.75, "Commodity (+utility)"),
        ]

        // Labels default to the dot's upper right; when two label frames
        // collide, the later (lower-priority) one flips below its dot.
        var placed: [CGRect] = []
        var nodes: [WardleyLayout.Node] = []
        for component in map.components {
            let center = point(visibility: component.visibility, evolution: component.evolution)
            let size = measure(component.name, labelFontSize)
            var frame = CGRect(x: center.x + 7, y: center.y - size.height - 4,
                               width: size.width, height: size.height)
            if placed.contains(where: { $0.intersects(frame.insetBy(dx: -2, dy: -2)) }) {
                frame.origin.y = center.y + 6   // flip below
            }
            if placed.contains(where: { $0.intersects(frame.insetBy(dx: -2, dy: -2)) }) {
                frame.origin.x = center.x - size.width - 7   // then left
                frame.origin.y = center.y - size.height - 4
            }
            // Keep labels inside the canvas.
            frame.origin.x = min(max(frame.origin.x, 1), plot.maxX + margin - size.width)
            placed.append(frame)
            nodes.append(.init(name: component.name, center: center,
                               isAnchor: component.isAnchor, inertia: component.inertia,
                               decorator: component.decorator?.rawValue,
                               labelFrame: frame))
        }

        func nodeCenter(_ name: String) -> CGPoint? {
            nodes.first(where: { $0.name == name })?.center
        }
        let links: [WardleyLayout.Link] = map.links.compactMap { link in
            guard let a = nodeCenter(link.from), let b = nodeCenter(link.to) else { return nil }
            return .init(from: a, to: b, isFlow: link.isFlow)
        }
        let evolves: [WardleyLayout.Evolve] = map.evolves.compactMap { evolve in
            guard let node = nodes.first(where: { $0.name == evolve.name }) else { return nil }
            let target = CGPoint(x: plot.minX + CGFloat(evolve.target) * plot.width,
                                 y: node.center.y)
            return .init(from: node.center, to: target)
        }
        let notes: [WardleyLayout.Note] = map.notes.map { note in
            var center = point(visibility: note.visibility, evolution: note.evolution)
            // Clamp so the measured text stays on canvas (author coordinates
            // near 0/1 would otherwise push half the note off the edge).
            let half = measure(note.text, labelFontSize).width / 2
            center.x = min(max(center.x, half + 2), plot.maxX + margin - half - 2)
            return .init(text: note.text, center: center)
        }

        return WardleyLayout(
            size: CGSize(width: plot.maxX + margin, height: plot.maxY + margin + 20),
            title: map.title, plotFrame: plot, bands: bands,
            nodes: nodes, links: links, evolves: evolves, notes: notes)
    }
}
