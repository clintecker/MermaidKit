import XCTest
@testable import MermaidLayout

/// The honesty sprint's contract: syntax that used to be silently dropped or
/// — worse — corrupted into confident phantom content now parses to what the
/// author wrote. Each test uses the exact form that failed before.
final class ParserHonestyTests: XCTestCase {

    func testFrontMatterIsStripped() throws {
        let d = MermaidParser.parse("---\ntitle: Hello\nconfig:\n  theme: base\n---\nflowchart TD\n  A --> B")
        guard case .flowchart(let chart)? = d else { return XCTFail("front-matter killed the parse") }
        XCTAssertEqual(chart.edges.count, 1)
    }

    // MARK: flowchart

    private func flow(_ body: String) throws -> Flowchart {
        guard case .flowchart(let c)? = MermaidParser.parse("flowchart TD\n" + body) else {
            throw XCTSkip("parse failed: \(body)")
        }
        return c
    }

    func testChainedEdges() throws {
        let c = try flow("A --> B --> C")
        XCTAssertEqual(c.edges.count, 2, "chain must yield both edges")
        XCTAssertEqual(c.nodes.count, 3)
    }

    func testAmpersandFanOut() throws {
        let c = try flow("A & B --> C & D")
        XCTAssertEqual(c.edges.count, 4, "2x2 fan-out")
        XCTAssertEqual(c.nodes.map(\.id).sorted(), ["A", "B", "C", "D"])
    }

    func testAmpersandInsideLabelIsNotASplit() throws {
        let c = try flow("A[Tom & Jerry] --> B")
        XCTAssertEqual(c.edges.count, 1)
        XCTAssertEqual(c.nodes.first(where: { $0.id == "A" })?.label, "Tom & Jerry")
    }

    func testInlineEdgeLabel() throws {
        let c = try flow("A-- hello -->B")
        XCTAssertEqual(c.edges.first?.label, "hello")
    }

    func testMinLengthLinksNormalize() throws {
        let c = try flow("A ----> B")
        XCTAssertEqual(c.edges.count, 1)
        XCTAssertEqual(c.edges.first?.hasArrow, true)
    }

    func testBidirectionalArrow() throws {
        let c = try flow("A <--> B")
        XCTAssertEqual(c.edges.first?.backArrow, true)
        XCTAssertEqual(c.nodes.map(\.id).sorted(), ["A", "B"], "no phantom 'A<' node")
    }

    func testCircleAndCrossHeadsDoNotMintPhantomNodes() throws {
        let c = try flow("A --o B\nC --x D")
        XCTAssertEqual(c.nodes.map(\.id).sorted(), ["A", "B", "C", "D"],
                       "'oB'/'xD' phantoms must not exist")
        XCTAssertEqual(c.edges.count, 2)
    }

    func testStyleClassSuffixTolerated() throws {
        let c = try flow("A:::hot --> B[Cool]:::cold")
        XCTAssertEqual(c.edges.count, 1)
        XCTAssertEqual(c.nodes.first(where: { $0.id == "B" })?.label, "Cool")
    }

    func testEdgeIDDropped() throws {
        let c = try flow("A e1@--> B")
        XCTAssertEqual(c.edges.count, 1, "edge id must not kill the line")
    }

    // MARK: sequence

    private func seq(_ body: String) throws -> SequenceDiagram {
        guard case .sequence(let s)? = MermaidParser.parse("sequenceDiagram\n" + body) else {
            throw XCTSkip("parse failed")
        }
        return s
    }

    func testActivationShorthandMintsNoPhantomLifelines() throws {
        let s = try seq("Alice->>+John: Hello\nJohn->>-Alice: Hi")
        XCTAssertEqual(s.participants.map(\.id).sorted(), ["Alice", "John"],
                       "the docs' first example: no '+John'/'-John' lifelines")
        XCTAssertEqual(s.messages.count, 2)
    }

    func testCrossAndAsyncArrowsParse() throws {
        let s = try seq("A-x B: dies\nC-) D: async\nE--) F: dashed async")
        XCTAssertEqual(s.messages.count, 3, "message text must survive head-style degradation")
        XCTAssertEqual(s.messages[0].text, "dies")
    }

    func testAutonumberStampsMessages() throws {
        let s = try seq("autonumber\nA->>B: first\nB->>A: second")
        XCTAssertEqual(s.messages[0].text, "1. first")
        XCTAssertEqual(s.messages[1].text, "2. second")
    }

    func testActorAliasKeepsItsLabel() throws {
        let s = try seq("participant P as an actor guy\nP->>P: hi")
        XCTAssertEqual(s.participants.first?.label, "an actor guy",
                       "global 'actor ' strip once corrupted this label")
    }

    // MARK: gantt

    func testColonDirectivesAreNotPhantomTasks() throws {
        guard case .gantt(let g)? = MermaidParser.parse("""
        gantt
            dateFormat YYYY-MM-DD
            axisFormat %H:%M
            todayMarker stroke-width:5px,opacity:0.5
            tickInterval 1week
            click t1 href "https://example.com"
            section S
            Real task : t1, 2026-01-01, 3d
        """) else { return XCTFail() }
        XCTAssertEqual(g.tasks.count, 1, "directives with colons must not become bars")
        XCTAssertEqual(g.tasks.first?.label, "Real task")
    }

    func testLongDurationUnits() throws {
        guard case .gantt(let g)? = MermaidParser.parse("""
        gantt
            section S
            Year : t1, 2026-01-01, 1y
        """) else { return XCTFail() }
        XCTAssertEqual(g.tasks.first?.length ?? 0, 365, accuracy: 0.1)
    }

    // MARK: radar

    func testRadarPositionalValues() throws {
        guard case .radar(let r)? = MermaidParser.parse("""
        radar-beta
            axis a["A"], b["B"], c["C"]
            curve x["X"]{10, 20, 30}
        """) else { return XCTFail() }
        XCTAssertEqual(r.curves.first?.values, [10, 20, 30],
                       "the docs' primary form once rendered flat at min")
    }

    func testRadarMultipleAxisLinesAppend() throws {
        guard case .radar(let r)? = MermaidParser.parse("""
        radar-beta
            axis a["A"], b["B"]
            axis c["C"]
            curve x{1, 2, 3}
        """) else { return XCTFail() }
        XCTAssertEqual(r.axes.count, 3, "second axis line once replaced the first")
    }

    // MARK: packet

    func testPacketRelativeWidths() throws {
        guard case .packet(let p)? = MermaidParser.parse("""
        packet-beta
            0-15: "Source"
            +16: "Destination"
            +8: "Flags"
        """) else { return XCTFail() }
        XCTAssertEqual(p.fields[1].startBit, 16)
        XCTAssertEqual(p.fields[1].endBit, 31, "+16 is a WIDTH after the previous field")
        XCTAssertEqual(p.fields[2].startBit, 32)
        XCTAssertEqual(p.fields[2].endBit, 39)
    }

    // MARK: treemap

    func testTreemapStyleClassKeepsValue() throws {
        guard case .treemap(let t)? = MermaidParser.parse("""
        treemap-beta
            "Products"
                "Phones": 50:::urgent
                "Laptops": 30
            classDef urgent fill:#f00
        """) else { return XCTFail() }
        let products = t.root.label == "Products" ? t.root : t.root.children[0]
        let phones = products.children.first(where: { $0.label == "Phones" })
        XCTAssertEqual(phones?.value ?? 0, 50, accuracy: 0.1, ":::class once destroyed the value")
        XCTAssertNil(findNode(products, labelContains: "classDef"), "CSS is not a tree node")
    }

    private func findNode(_ node: TreemapNode, labelContains text: String) -> TreemapNode? {
        if node.label.contains(text) { return node }
        for child in node.children {
            if let found = findNode(child, labelContains: text) { return found }
        }
        return nil
    }

    // MARK: zenuml

    func testZenUMLFabricatesNothing() throws {
        guard case .zenuml(let z)? = MermaidParser.parse("""
        zenuml
            // this is a comment
            result = Service.fetch()
        """) else { return XCTFail() }
        XCTAssertFalse(z.participants.contains(where: { $0.name.contains("//") }),
                       "comments are not participants")
        XCTAssertFalse(z.participants.contains(where: { $0.name == "result" }),
                       "assignment targets are not participants")
    }

    // MARK: c4

    func testC4RelIndexDoesNotShiftArguments() throws {
        guard case .c4(let c)? = MermaidParser.parse("""
        C4Context
            Person(a, "A")
            System(b, "B")
            RelIndex(1, a, b, "uses")
        """) else { return XCTFail() }
        XCTAssertEqual(c.relations.first?.from, "a", "the index arg once became 'from'")
        XCTAssertEqual(c.relations.first?.label, "uses")
    }

    // MARK: gitGraph

    func testCherryPickAppearsOnTheTimeline() throws {
        guard case .gitGraph(let g)? = MermaidParser.parse("""
        gitGraph
            commit id: "one"
            branch dev
            commit id: "two"
            checkout main
            cherry-pick id: "two"
        """) else { return XCTFail() }
        XCTAssertTrue(g.commits.contains(where: { $0.id.contains("cherry-pick") && $0.branch == "main" }),
                      "cherry-pick once vanished from the timeline")
    }
}

extension ParserHonestyTests {
    func testNotesSurviveAndInterleave() throws {
        guard case .sequence(let s)? = MermaidParser.parse("""
        sequenceDiagram
            A->>B: first
            Note over A,B: between the two
            B->>A: second
            Note right of A: at the end
        """) else { return XCTFail() }
        XCTAssertEqual(s.notes.count, 2, "note text is author content; it must survive")
        XCTAssertEqual(s.notes[0].afterMessage, 1)
        XCTAssertEqual(s.notes[1].afterMessage, 2)
        XCTAssertEqual(s.notes[0].text, "between the two")

        let measure: DiagramTextMeasurer = { t, size in
            CGSize(width: CGFloat(max(t.count, 1)) * size * 0.6, height: size + 4)
        }
        let layout = DiagramLayoutEngine.layout(s, measure: measure)
        XCTAssertEqual(layout.notes.count, 2)
        // The over-note's row sits strictly between the two message rows.
        XCTAssertGreaterThan(layout.notes[0].frame.minY, layout.arrows[0].y)
        XCTAssertLessThan(layout.notes[0].frame.maxY, layout.arrows[1].y + 1)
    }

    func testActorDeclarationsFlagTheParticipant() throws {
        guard case .sequence(let s)? = MermaidParser.parse("""
        sequenceDiagram
            actor Alice
            participant Bob
            Alice->>Bob: hi
        """) else { return XCTFail() }
        XCTAssertEqual(s.participants.first(where: { $0.id == "Alice" })?.isActor, true)
        XCTAssertEqual(s.participants.first(where: { $0.id == "Bob" })?.isActor, false)
    }
}
