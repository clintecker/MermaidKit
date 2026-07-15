// Linux golden-image (reference-image) regression test.
//
// The geometry linter and the draw-vs-scene conformance ratchet catch
// STRUCTURAL defects (overlaps, uncovered text, edges through boxes) but are
// blind to APPEARANCE drift — a text baseline that shifts a few pixels, a wrong
// color, a corner radius that changes, a glyph that lands off-centre. This test
// is the pixel-level backstop for exactly that class: it re-renders every
// fixture and compares against a committed reference image, failing on drift.
//
// Why only on Linux: golden-image tests are flaky when rendering isn't
// reproducible, which is why the repo judges APPLE output by geometry, not
// pixels (CoreText + the SF system font + subpixel AA shift across macOS/Xcode
// versions). The Linux Silica/Cairo/FreeType stack with a pinned font
// (fonts-dejavu-core) in a pinned container is deterministic, so pixel goldens
// are trustworthy here. The CI container is digest-pinned (see ci.yml), which
// freezes the toolchain and base OS; the Cairo/FreeType/DejaVu libraries are
// apt-installed (stable, but not frozen by the digest), and the small tolerance
// below absorbs the sub-pixel AA jitter a patch-level bump might introduce.
//
// Comparison is pixel-level with a small per-channel tolerance (decoded through
// Cairo), so a libcairo/zlib PNG-encoder change alone never trips it — only an
// actual rasterization change does. The references are ARCHITECTURE- and
// ENVIRONMENT-specific (FreeType/Cairo AA depends on the CPU + library build),
// so they must be produced by the SAME environment that verifies them: the
// Linux CI runner. Regenerate after an intentional visual change by running the
// "Regenerate goldens" GitHub Actions workflow (it renders on the runner and
// commits the images back); reviewing the resulting diff is the review. Locally
// on matching hardware `UPDATE_GOLDENS=1 scripts/test-linux.sh` works for
// iteration, but only CI-produced goldens are authoritative.
//
// REQUIRES `SWIFT_DETERMINISTIC_HASHING=1` (set for the Linux test run in
// ci.yml and scripts/test-linux.sh). Swift randomizes the Set/Dictionary hash
// seed per process; a few layouts iterate hashed collections in a way that
// still reaches geometry, so the same source renders a hair differently across
// process launches (this test caught it — StabilityTests only checks
// within-process determinism). A fixed seed makes rendering reproducible so the
// goldens are stable. The residual cross-process layout nondeterminism is a
// separate, minor quality issue worth a follow-up — see the note in
// docs/notes/linux-rendering-via-silica.md.
#if canImport(SilicaCairo) && !canImport(AppKit) && !canImport(UIKit)
import XCTest
import Foundation
import Cairo
@testable import MermaidRender
@testable import MermaidLayout

final class LinuxGoldenTests: XCTestCase {
    /// A per-channel (0–255) delta at or below this is treated as identical —
    /// absorbs sub-unit anti-aliasing jitter without hiding real changes.
    private let channelThreshold = 8
    /// Fail when more than this fraction of pixels exceed the threshold. A real
    /// regression (shifted text, wrong fill) moves far more than 0.1%; patch-
    /// level AA noise moves far less.
    private let maxDiffFraction = 0.001

    func testFixturesMatchGoldens() throws {
        let testDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let repoRoot = testDir.deletingLastPathComponent().deletingLastPathComponent()
        let fixturesDir = repoRoot.appendingPathComponent("Fixtures/diagrams")
        let goldenDir = testDir.appendingPathComponent("__golden__")
        let update = ProcessInfo.processInfo.environment["UPDATE_GOLDENS"] == "1"

        let files = try FileManager.default.contentsOfDirectory(atPath: fixturesDir.path)
            .filter { $0.hasSuffix(".mmd") }.sorted()
        try XCTSkipIf(files.isEmpty, "fixtures not found")
        if update { try? FileManager.default.createDirectory(at: goldenDir, withIntermediateDirectories: true) }

        let theme = DiagramTheme(prefersDark: false)
        let failureDir = repoRoot.appendingPathComponent(".golden-failures")
        var failures: [String] = []

        for file in files {
            let name = (file as NSString).deletingPathExtension
            let src = try String(contentsOf: fixturesDir.appendingPathComponent(file), encoding: .utf8)
            guard let image = MermaidRenderer.image(source: src, theme: theme),
                  let fresh = image.pngData() else {
                failures.append("\(name): render/encode failed"); continue
            }
            let goldenURL = goldenDir.appendingPathComponent("\(name).png")

            if update {
                try fresh.write(to: goldenURL)
                continue
            }
            guard let golden = try? Data(contentsOf: goldenURL) else {
                failures.append("\(name): no golden — run UPDATE_GOLDENS=1"); continue
            }
            guard let a = decode(fresh), let b = decode(golden) else {
                failures.append("\(name): PNG decode failed"); continue
            }
            guard a.width == b.width, a.height == b.height else {
                dumpActual(fresh, name, into: failureDir)
                failures.append("\(name): size \(a.width)x\(a.height) vs golden \(b.width)x\(b.height)")
                continue
            }
            let (differing, total) = compare(a, b, threshold: channelThreshold)
            let fraction = Double(differing) / Double(max(total, 1))
            if fraction > maxDiffFraction {
                dumpActual(fresh, name, into: failureDir)
                failures.append(String(format: "%@: %d/%d px differ (%.3f%% > %.3f%%)",
                                       name, differing, total, fraction * 100, maxDiffFraction * 100))
            }
        }

        if update { throw XCTSkip("regenerated \(files.count) goldens in \(goldenDir.path)") }
        XCTAssertTrue(failures.isEmpty,
                      "golden mismatches (actual images in .golden-failures/):\n  "
                        + failures.joined(separator: "\n  "))
    }

    // MARK: - Pixel comparison (ARGB32, decoded through Cairo)

    private struct Bitmap { let width, height, stride: Int; let bytes: Data }

    private func decode(_ png: Data) -> Bitmap? {
        guard let surface = try? Cairo.Surface.Image(png: png), let data = surface.data else { return nil }
        return Bitmap(width: surface.width, height: surface.height, stride: surface.stride, bytes: data)
    }

    /// Count pixels whose maximum per-channel delta exceeds `threshold`.
    private func compare(_ a: Bitmap, _ b: Bitmap, threshold: Int) -> (differing: Int, total: Int) {
        var differing = 0
        a.bytes.withUnsafeBytes { ap in
            b.bytes.withUnsafeBytes { bp in
                let A = ap.bindMemory(to: UInt8.self), B = bp.bindMemory(to: UInt8.self)
                for y in 0..<a.height {
                    let rowA = y * a.stride, rowB = y * b.stride
                    for x in 0..<a.width {
                        let iA = rowA + x * 4, iB = rowB + x * 4
                        var delta = 0
                        for c in 0..<4 { delta = max(delta, abs(Int(A[iA + c]) - Int(B[iB + c]))) }
                        if delta > threshold { differing += 1 }
                    }
                }
            }
        }
        return (differing, a.width * a.height)
    }

    private func dumpActual(_ png: Data, _ name: String, into dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? png.write(to: dir.appendingPathComponent("\(name).actual.png"))
    }
}
#endif
