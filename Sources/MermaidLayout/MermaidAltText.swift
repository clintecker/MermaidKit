import Foundation

/// Accessibility descriptions for diagrams — a concise, deterministic
/// sentence or two per type, generated from the TYPED models (which carry
/// the semantics; the geometry scene only knows frames). Hosts get this
/// automatically: `MermaidView` sets it as the accessibility label and
/// `attachmentString` attaches it to the embedded image.
///
/// Style rules: lead with the diagram type, give the honest scale (counts),
/// then the leading content by name so a listener learns what the diagram is
/// ABOUT, not just its shape. Long lists truncate with a count of the rest.
public enum MermaidAltText {

    /// A description of the parsed diagram, suitable for VoiceOver.
    public static func describe(_ diagram: MermaidDiagram) -> String {
        switch diagram {
        case .flowchart(let d):
            let names = list(d.nodes.map(\.label))
            return "Flowchart with \(count(d.nodes.count, "node")) and " +
                "\(count(d.edges.count, "connection")): \(names)."
        case .sequence(let d):
            return "Sequence diagram: \(count(d.messages.count, "message")) between " +
                "\(list(d.participants.map(\.label)))."
        case .pie(let d):
            let total = d.slices.reduce(0) { $0 + $1.value }
            let slices = d.slices.prefix(4).map { slice -> String in
                let share = total > 0 ? Int((slice.value / total * 100).rounded()) : 0
                return "\(slice.label) \(share) percent"
            }
            return "Pie chart\(titled(d.title)) with \(count(d.slices.count, "slice")): " +
                "\(slices.joined(separator: ", "))\(d.slices.count > 4 ? ", and \(d.slices.count - 4) more" : "")."
        case .classDiagram(let d):
            return "Class diagram with \(count(d.classes.count, "class")) and " +
                "\(count(d.relations.count, "relation")): \(list(d.classes.map(\.name)))."
        case .er(let d):
            return "Entity-relationship diagram with \(count(d.entities.count, "entity", "entities")) and " +
                "\(count(d.relations.count, "relation")): \(list(d.entities.map(\.name)))."
        case .state(let d):
            return "State diagram with \(count(d.nodes.count, "state")) and " +
                "\(count(d.edges.count, "transition")): \(list(d.nodes.map(\.label).filter { !$0.isEmpty }))."
        case .gantt(let d):
            return "Gantt chart\(titled(d.title)) with \(count(d.tasks.count, "task")) across " +
                "\(count(d.sections.count, "section")): \(list(d.sections))."
        case .timeline(let d):
            return "Timeline\(titled(d.title)) with \(count(d.periods.count, "period"))" +
                (d.sections.isEmpty ? "" : " across sections \(list(d.sections))") + "."
        case .mindmap(let d):
            return "Mind map rooted at \(quote(d.root.label)) with " +
                "\(count(d.root.children.count, "main branch")): \(list(d.root.children.map(\.label)))."
        case .journey(let d):
            return "User journey\(titled(d.title)) with \(count(d.tasks.count, "step")) across " +
                "\(count(d.sections.count, "section")): \(list(d.sections))."
        case .quadrant(let d):
            return "Quadrant chart\(titled(d.title)) plotting \(count(d.points.count, "item")): " +
                "\(list(d.points.map(\.label)))."
        case .packet(let d):
            return "Packet diagram\(titled(d.title)) with \(count(d.fields.count, "field")): " +
                "\(list(d.fields.map(\.label)))."
        case .xychart(let d):
            return "XY chart\(titled(d.title)) with \(count(d.series.count, "series", "series")) over " +
                "\(count(d.categories.count, "category", "categories"))."
        case .kanban(let d):
            let cards = d.columns.reduce(0) { $0 + $1.cards.count }
            return "Kanban board with \(count(cards, "card")) across " +
                "\(count(d.columns.count, "column")): \(list(d.columns.map(\.title)))."
        case .radar(let d):
            return "Radar chart\(titled(d.title)) with \(count(d.curves.count, "curve")) over " +
                "\(count(d.axes.count, "axis", "axes")): \(list(d.axes.map(\.label)))."
        case .treemap(let d):
            return "Treemap rooted at \(quote(d.root.label)) with " +
                "\(count(d.root.children.count, "top-level group")): \(list(d.root.children.map(\.label)))."
        case .gitGraph(let d):
            return "Git graph with \(count(d.commits.count, "commit")) on " +
                "\(count(d.branches.count, "branch", "branches")): \(list(d.branches))."
        case .sankey(let d):
            return "Sankey diagram with \(count(d.nodes.count, "node")) and " +
                "\(count(d.links.count, "flow")): \(list(d.nodes))."
        case .requirement(let d):
            return "Requirement diagram with \(count(d.requirements.count, "requirement")), " +
                "\(count(d.elements.count, "element")), and \(count(d.relations.count, "relation"))."
        case .zenuml(let d):
            return "ZenUML sequence diagram: \(count(d.messages.count, "message")) between " +
                "\(list(d.participants.map(\.name)))."
        case .c4(let d):
            return "C4 diagram with \(count(d.elements.count, "element")) and " +
                "\(count(d.relations.count, "relationship")): \(list(d.elements.map(\.label)))."
        case .architecture(let d):
            return "Architecture diagram with \(count(d.services.count, "service")) in " +
                "\(count(d.groups.count, "group")): \(list(d.groups.map(\.label)))."
        case .block(let d):
            return "Block diagram with \(count(d.blocks.count, "block")): " +
                "\(list(d.blocks.map(\.label)))."
        }
    }

    /// Parses and describes in one call; nil when the source doesn't parse
    /// (hosts fall back to their own description of the raw source).
    public static func describe(source: String) -> String? {
        MermaidParser.parse(source).map(describe)
    }

    // MARK: - Phrasing helpers

    private static func count(_ n: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(n) \(n == 1 ? singular : (plural ?? singular + "s"))"
    }

    private static func titled(_ title: String?) -> String {
        guard let title, !title.isEmpty else { return "" }
        return " titled \(quote(title))"
    }

    private static func quote(_ s: String) -> String { "“\(s)”" }

    /// First few names, then "and N more" — enough to know what the diagram
    /// is about without reading a phone book.
    private static func list(_ items: [String], limit: Int = 6) -> String {
        let cleaned = items.filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return "unnamed" }
        if cleaned.count <= limit { return cleaned.joined(separator: ", ") }
        return cleaned.prefix(limit).joined(separator: ", ") +
            ", and \(cleaned.count - limit) more"
    }
}
