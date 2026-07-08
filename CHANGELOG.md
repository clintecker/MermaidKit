# Changelog

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

Initial extraction from [Quoin](https://github.com/clintecker/quoin).

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
