import XCTest
#if canImport(CoreGraphics)
import CoreGraphics
#else
import Foundation
#endif
@testable import MermaidLayout

/// Issue #1 — a flowchart cycle back-edge must route to a real, attached path.
///
/// The reporter proposed "every edge's polyline endpoints must coincide with
/// its node anchors" as a *linter* invariant. Empirically it doesn't
/// generalize: sequence arrows land on lifelines, ishikawa bones on the spine,
/// gitgraph/wardley/treeview edges on non-node geometry — so a scene-level
/// check flags clean fixtures. It IS a valid invariant for the node-graph
/// families (flowchart/state), where every edge connects two boxes, so it is
/// pinned here as a scoped test rather than a global linter rule.
final class BackEdgeReproTests: XCTestCase {
    private let measure: DiagramTextMeasurer = { t, s in
        CGSize(width: CGFloat(max(t.count, 1)) * s * 0.6, height: s + 4)
    }

    /// Distance from `p` to the nearest point of rect `r` (0 inside/on border).
    private func exteriorDistance(_ p: CGPoint, _ r: CGRect) -> CGFloat {
        hypot(max(r.minX - p.x, 0, p.x - r.maxX), max(r.minY - p.y, 0, p.y - r.maxY))
    }

    /// The reported repro (with `B` kept a diamond, the mermaid-faithful bare
    /// back-reference): every edge — including the `D -->|who| B` back-edge —
    /// must have both polyline endpoints land on a node border.
    func testBackEdgeEndpointsAttachToNodes() throws {
        try assertEveryEdgeAttaches("""
        flowchart LR
            A[Start] --> B{Decision}
            B -->|yes| C[Ship it]
            B -->|nah| D[Bite It]
            D -->|who| B
        """)
    }

    /// A two-node tight cycle: the back-edge is the whole reverse connection.
    func testTightCycleBackEdgeAttaches() throws {
        try assertEveryEdgeAttaches("""
        flowchart TD
            A[One] --> B[Two]
            B --> A
        """)
    }

    private func assertEveryEdgeAttaches(_ src: String) throws {
        guard case .flowchart(let chart) = MermaidParser.parse(src) else { return XCTFail() }
        let scene = DiagramScene.lower(.flowchart(chart), measure: measure)
        let boxes = scene.nodes.filter { !$0.isContainer }
        XCTAssertFalse(scene.edges.isEmpty, "no edges laid out")
        for (i, edge) in scene.edges.enumerated() {
            guard let first = edge.polyline.first, let last = edge.polyline.last else {
                return XCTFail("edge #\(i) has no polyline")
            }
            for (which, p) in [("start", first), ("end", last)] {
                let onABox = boxes.contains { exteriorDistance(p, $0.frame) <= 6 }
                XCTAssertTrue(onABox,
                    "edge #\(i) \(which) (\(Int(p.x)),\(Int(p.y))) reaches no node — dangling")
            }
        }
    }
}
