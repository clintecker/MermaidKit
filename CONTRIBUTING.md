# Contributing to MermaidKit

## The lay of the land

One diagram type = three small, independent pieces:

- `Sources/MermaidLayout/MermaidParser+<Type>.swift` — text → model
- `Sources/MermaidLayout/DiagramLayout<Type>.swift` — model → geometry
  (frames/polylines; text metrics come in through `DiagramTextMeasurer`)
- `Sources/MermaidRender/DiagramRenderer+<Type>.swift` — geometry → drawing
  (one `CGContext` seam: CoreGraphics on Apple, Silica/Cairo on Linux)

Plus a lowering (`DiagramScene+<Type>.swift`) that hands the geometry to the
layout linter.

## Ground rules

- `swift test` and `swift test --package-path MermaidKit` must stay green.
- **Layout changes are judged by geometry.** Every type's dense fixture in
  `Fixtures/diagrams/` must lint clean (`LayoutLintTests`); iterate on one
  type with `MERMAIDKIT_LINT_TYPE=<type> swift test --filter testLintSingleType`.
  The linter is necessary, not sufficient — also render your fixture and
  *look at it*.
- **The parser never crashes.** New numeric fields go through
  `MermaidParser.finiteDouble`; new syntax must tolerate garbage (see
  `AdversarialInputTests` — add cases for anything you touch).
- Performance: `RenderBenchmarks` fails if any fixture renders cold in
  >250 ms.
- `MermaidLayout` stays zero-dependency and platform-free (`Foundation` +
  `CoreGraphics` geometry only, `canImport`-guarded — it must keep building on
  swift-corelibs-foundation). `MermaidRender` is CoreGraphics on Apple and
  links Silica only on Linux, and only when the `LinuxRaster` package trait is
  enabled (default OFF, so `from:`-pinned consumers get a Silica-free graph);
  don't add other dependencies.
- Regenerate README images with `scripts/gen-gallery.sh` when a fix changes
  how a fixture renders.

## Developing on Linux

`MermaidRender` draws on Linux via Silica (Cairo/FontConfig) — the same layout
and per-type draw code as Apple. The Silica backend is behind the `LinuxRaster`
package trait (default OFF, so Apple/`from:`-pinned consumers never fetch the
Silica graph), so Linux builds opt in with `swift build --traits LinuxRaster`.
To build and test the whole package the way CI does, in a `swift:6.2`
container:

    scripts/test-linux.sh   # requires Docker; enables LinuxRaster

Check a per-type renderer change on both backends: `swift test` on Apple and
`scripts/test-linux.sh` for Linux (its `LinuxRenderTests` render every fixture).
The porting approach is written up in
`docs/notes/linux-rendering-via-silica.md`. The toolchain floor is Swift 6.2 /
Xcode 26 — package traits (and Silica's graph, when enabled) require it.

`LinuxGoldenTests` compares every Linux render against a committed reference
image in `Tests/MermaidRenderTests/__golden__/` — the pixel-level backstop for
appearance drift the geometry linter can't see. The references are
environment-specific (FreeType/Cairo anti-aliasing depends on the runner's CPU +
library build), so they're generated *by CI, on the runner*: after a change that
*intentionally* alters how a fixture renders, run the **Regenerate goldens**
GitHub Actions workflow (Actions ▸ Regenerate goldens ▸ Run workflow) — it
renders on the CI runner and commits the images back, and reviewing that commit
is the review. `UPDATE_GOLDENS=1 scripts/test-linux.sh` regenerates locally for
iteration on matching hardware, but only CI-produced goldens pass CI.

## API stability stance

The wide public surface — every model and layout struct — is deliberate:
headless geometry is a feature, not leakage. The deal that keeps it from
becoming a semver trap:

- Pre-1.0, minor versions may reshape model/layout fields (they follow the
  diagrams' needs); the *entry points* (`MermaidParser.parse`/`diagnose`,
  `DiagramLayoutEngine.layout`, `DiagramScene.lower`, `DiagramLayoutLinter`,
  `MermaidRenderer`, `MermaidView`, `DiagramTheme`) stay stable.
- Post-1.0, model/field changes are semver-major.

## Most-wanted

- Syntax-coverage gaps in existing types (bring the diagram that broke).
- An SVG backend over `DiagramScene` / the layout structs — resolution-
  independent vector output (the Silica/Cairo backend already covers native
  Linux rendering; SVG is the remaining portable-output gap).
- Lower OS floors, with CI to prove them.
