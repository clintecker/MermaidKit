#if canImport(AppKit)
import XCTest
import CoreGraphics
@testable import MermaidRender
import MermaidLayout

/// End-to-end timings (parse → layout → render to image) for every fixture.
/// Guards the "renders in interactive time" claim; run with BENCH_TABLE=1 to
/// print the markdown table the README's numbers come from.
final class RenderBenchmarks: XCTestCase {

    private var fixturesDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/diagrams")
    }

    /// Every dense fixture must render cold in under 250ms — an order of
    /// magnitude inside "feels instant", and the fixtures are deliberately
    /// dense (real-world diagrams are smaller).
    func testColdRenderStaysInteractive() throws {
        let theme = DiagramTheme(prefersDark: false)
        let files = try FileManager.default.contentsOfDirectory(at: fixturesDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "mmd" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        XCTAssertGreaterThanOrEqual(files.count, 20)

        var rows: [(String, Double, Double)] = []
        // ROUND-ROBIN sampling: measure every type once per round instead of
        // three consecutive samples per type. Sequential per-type sampling
        // biased late-alphabet types (sankey, sequence) with the heat and
        // cache pressure built up by the twenty types before them — observed
        // as a 2x swing (23 ms isolated vs 45 ms in-suite) on the same
        // fixture. Rounds spread that contention evenly, and best-of-rounds
        // recovers the true cold cost.
        let sources: [(name: String, source: String)] = try files.map {
            ($0.deletingPathExtension().lastPathComponent,
             try String(contentsOf: $0, encoding: .utf8))
        }
        var parseBestByName: [String: Double] = [:]
        var totalBestByName: [String: Double] = [:]
        for run in 0..<3 {
            for entry in sources {
                // A run-unique comment busts the render cache so every
                // measurement is a true cold parse+layout+render.
                let src = entry.source + "\n%% bench-\(entry.name)-\(run)"
                var t0 = CFAbsoluteTimeGetCurrent()
                let parsed = MermaidParser.parse(src)
                let parseMS = (CFAbsoluteTimeGetCurrent() - t0) * 1000
                XCTAssertNotNil(parsed, entry.name)

                t0 = CFAbsoluteTimeGetCurrent()
                let image = MermaidRenderer.image(source: src, theme: theme)
                // Force rasterization: a handler-backed NSImage defers drawing
                // until first use, so timing image() alone would flatter the
                // numbers by excluding the actual CoreGraphics work.
                let rasterized = image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
                let totalMS = (CFAbsoluteTimeGetCurrent() - t0) * 1000
                XCTAssertNotNil(image, entry.name)
                XCTAssertNotNil(rasterized, entry.name)
                parseBestByName[entry.name] = min(parseBestByName[entry.name] ?? .infinity, parseMS)
                totalBestByName[entry.name] = min(totalBestByName[entry.name] ?? .infinity, totalMS)
            }
        }
        for entry in sources {
            let parseBest = parseBestByName[entry.name] ?? 0
            let totalBest = totalBestByName[entry.name] ?? 0
            let name = entry.name
            rows.append((name, parseBest, totalBest))
            XCTAssertLessThan(totalBest, 250, "\(name): cold render must stay interactive")
        }

        if ProcessInfo.processInfo.environment["BENCH_TABLE"] != nil {
            print("BENCH | Diagram | Parse | Parse + layout + render |")
            print("BENCH |---|---:|---:|")
            for (name, parse, total) in rows {
                print(String(format: "BENCH | %@ | %.2f ms | %.2f ms |", name, parse, total))
            }
            let worst = rows.map(\.2).max() ?? 0
            print(String(format: "BENCH worst: %.1f ms", worst))
        }
    }
}
#endif
