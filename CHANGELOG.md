# Changelog

## 0.3.1

- Chain straightening after Brandes-Koepf placement, in both the flowchart
  pipeline and the class/ER/state layeredRoutes: BK's balancing step leaves
  single-parent chains a few points off their neighbour's centre (a visible
  jog, with the edge label on the kink). A gap-clamped priority pass
  (Gansner et al. section 4.2, degree-1 case) snaps them straight; where
  parent and child alignment genuinely conflict, one clean alignment wins
  over two half-jogs. Pinned by ChainAlignmentTests at 0.5pt.

## 0.3.0

The gallery becomes the documentation, and the linter learns to read.

- **Self-referential fixtures**: every example diagram is now about
  MermaidKit itself — the class diagram is the real public API, the sankey
  hero is the render pipeline, the gantt/timeline/gitgraph are the actual
  project history, the xychart plots the published benchmark numbers. The
  same 23 files are the gallery, the lint corpus, and the benchmark suite.
- **New linter invariant, `edge-cuts-label` (error)**: an edge traveling
  through bare label text fails CI. `DiagramScene.Label` gained
  `anchorEdge` (an edge label sits on its own route by design) and `backed`
  (an opaque chip interrupts a crossing line; the text stays readable) so
  the check flags only genuine defects. Found and fixed a real one on
  arrival: sankey's outboard labels now draw on canvas chips.
- **gitgraph engine upgrades** (all exposed by real-word fixture labels):
  commit columns space adaptively by measured label width; auto-generated
  ids (`c1`, `merge2`) no longer render as labels; a label whose dot has a
  branch/merge leg below it flips above the rail (or slides aside when a
  tag occupies the top).
- Docs: benchmark table re-measured on the 0.2.0 engine (worst 24.7 ms,
  most types under 12 ms); every claim audited against the code.

Model additions (pre-1.0 reshape per the stability policy):
`GitGraph.Commit.hasExplicitID`, `GitGraphLayout.Commit.label/labelCenter`,
`DiagramScene.Label.anchorEdge/backed` — all defaulted where possible.

## 0.2.0

ELK-inspired layout upgrades ("what can we learn from the Eclipse Layout
Kernel" — the answer, implemented):

- Network-simplex layering (ELK/dot's default) replaces longest-path for
  the layered family: class fixture total edge length -36%, state -32%.
- Edge labels are layout citizens: multi-layer edges reserve a real channel
  (widened median dummy) and draw their label exactly there; adjacent-layer
  labeled edges grow their inter-layer gap. Previously merged label pairs
  render separated.
- Fixed-side ports: architecture honors author-declared edge sides
  (`waf:R --> L:gateway`); Edge.fromSide/toSide are now optional (nil =
  engine picks the facing side).
- Edit stability (ELK's "consider model order"): explicit declaration-order
  tie-breaking in crossing minimization, fully deterministic optimization
  (no Set-iteration order dependence), verified by SceneDelta-based tests —
  re-runs are bit-identical, a same-width label rename moves nothing, and
  appending a leaf node has a bounded blast radius.
- `DiagramSpacing` — the density knob (`.compact`/`.regular`/
  `.comfortable`, or custom gaps), threaded through flowchart/class/ER/
  state/architecture and surfaced on MermaidView/MermaidRenderer; render
  cache keys include it. Preset safety is tested (compact stays
  occlusion-free; presets order canvas area).

## 0.1.1

- Fix iOS build: v0.1.0's trait pinning used a nonexistent
  `UIGraphicsImageRendererFormat.traitCollection` property (the UIKit branch
  had never been compiled). The format is now resolved via `.preferred()`
  under the pinned traits.
- CI now compiles MermaidRender for the iOS Simulator on every push, so the
  UIKit branch can't silently break again.

## Unreleased (pre-0.1)

Initial public release — extracted from the markdown editor it grew inside.

- 23 Mermaid diagram types parsed, laid out, and rendered natively
  (Swift + CoreGraphics, zero dependencies).
- `MermaidView` (SwiftUI), `MermaidRenderer.image`/`.attachmentString`,
  `DiagramTheme`.
- `DiagramScene` geometry IR + `DiagramLayoutLinter` — layout quality
  enforced in CI as geometric invariants.
- Adversarial-input hardening: numeric sanitation at the parser boundary,
  mermaid.js-style input caps (`maxTextSize` 50k, `maxEdges` 500), fuzz-style
  pipeline tests.
- Render benchmarks: every fixture type renders cold in <25 ms on Apple
  silicon (CI-enforced <250 ms).
- Themeable categorical palette: `DiagramTheme(palette:)` re-skins node
  tints/pie slices/sankey bands across all types; render cache now keys on
  the full theme fingerprint (a same-appearance theme change previously
  could serve a stale cached render).
- Second external audit round: fixed two reproduced process crashes
  (gantt `inf`/`nan` duration skipping the sanitizer; packet bit index at
  Int.max overflowing in layout) and two hostile-input hangs (packet
  0..1M-bit ranges, unbounded radar tick loops) — all now clamped at parse
  with adversarial regression tests. Render-layer correctness: iOS trait
  resolution pinned to the theme's appearance (dynamic colors no longer
  bake at ambient traits), theme fingerprint resolved under the same
  pinned appearance and memoized (was ambient-dependent, with a crash
  path on unconvertible colors), cache cost accounts for backing-scale
  bytes, cache hits skip re-parsing, and returned NSImages are copies so
  host mutations can't poison the cache. Async API renamed to
  `renderImage` (a same-name overload made the sync path unreachable in
  async contexts) and now propagates cancellation. Benchmarks force
  rasterization — published numbers were flattered by NSImage's deferred
  drawing; honest worst is ~19 ms (was reported 13.1).
- Swift 6 language mode (swift-tools-version 6.0), zero warnings; async
  `MermaidRenderer.image(source:theme:)` twin renders off the calling
  thread via `sending`.
- `MermaidParser.diagnose(_:)`: human-readable parse failures with 1-based
  line numbers, cap explanations, and did-you-mean header suggestions.
- Performance/robustness audit: A* router's open set is a binary heap
  (architecture fixture 22.4 -> 13.1 ms cold); render cache is bounded
  (64 MB cost limit, NSCache pressure eviction) and wrapped Sendable; both
  targets compile with ZERO warnings under -strict-concurrency=complete.
- DocC documentation catalogs for both targets (Getting Started, Theming,
  Embedding in Text Views, Headless Layout, Scene Geometry and Linting,
  Adding a Diagram Type) + `.spi.yml` for Swift Package Index hosting.
