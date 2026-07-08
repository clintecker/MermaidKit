# Changelog

## 0.8.0

Sequence lifecycle and typography — the remaining Tier-1 items, validated
against websequencediagrams.com's classic feature set (all in mermaid
syntax; no extensions):

- `create participant/actor X` places the head at its creation row;
  `destroy X` ends the lifeline with the classic cross (open activation
  bars die with it).
- `<br/>` (and `<br>`) line breaks in messages and notes: rows grow,
  note boxes size to their widest line, message labels stack above the
  arrow, and column sizing measures lines rather than raw strings.
- Typed participants — `participant DB@{ "type": "database" }` — render
  head glyphs for database, queue, collections, boundary, control, and
  entity (websequencediagrams' participant types, absorbed by mermaid
  v11).

## 0.7.0

Sequence diagrams reach structural mermaid-parity for everyday syntax —
the sequence-primitives research memo's Tier 1, shipped:

- `box [color] Label ... end` participant groupings render as full-height
  background bands (color tokens recognized and dropped; our theme
  palette supplies the tint), heads dropping to give the band label
  headroom; `end` disambiguates correctly between boxes and fragments.

- Sequence diagrams: combined fragments render — `loop`/`alt`+`else`/
  `opt`/`par`+`and`/`critical`+`option`/`break` frames with kind tabs,
  guard labels, and dividers, arbitrarily nested (tolerant stack machine;
  a missing `end` closes at end-of-diagram), plus `rect` background
  bands. The layout's flat row list became a typed row stream (the
  sequence-primitives research memo's design), which variable-height rows
  and future activation bars build on. Frames lower to the scene as
  containers.
- Sequence activation bars render: `->>+`/`->>-` shorthand and explicit
  `activate`/`deactivate` statements produce execution bars on lifelines,
  nested activations stacking with rightward depth offsets; unclosed bars
  run to the lifeline bottom. Bars lower into the scene as slim nodes.
- Sequence arrows carry their identity: all mermaid arrow tokens map to
  true head styles (none/filled/cross/open/both, including v11's
  `<<->>`); `autonumber start step off` variants render as badge chips.
- Sequence `Note right of / left of / over` boxes render (author content
  that previously vanished); `actor` participants draw as stick figures.
- README/fixture: the sequence self-portrait now exercises an actor, a
  note, and an alt/else fragment.

## 0.6.0

The parser honesty sprint: syntax that used to be silently dropped — or
worse, corrupted into confident phantom content — now parses to what the
author wrote. Every fix is pinned by a regression test using the exact
previously-broken form (ParserHonestyTests).

Fabrication/corruption fixes:
- sequence: `->>+`/`->>-` activation shorthand no longer mints phantom
  `+Name`/`-Name` lifelines (the docs' first example was affected); the
  `participant P as an actor guy` alias no longer loses text to a global
  "actor " strip.
- gantt: directive lines containing colons (`axisFormat %H:%M`,
  `todayMarker`, `click ... href`) no longer become phantom task bars;
  `until` no longer becomes a task id; `y/M/s/ms` duration units parse.
- radar: positional `{1, 2, 3}` values (the docs' primary form) no longer
  render every curve flat at the minimum; multiple `axis` lines append;
  the ceiling grows to the data when `max` is unset.
- packet: `+N` is a field WIDTH after the previous field, not an absolute
  single bit — relative layouts were confidently wrong before.
- treemap: `:::styleClass` no longer destroys leaf values; `classDef`
  lines are no longer literal tree nodes.
- zenuml: comments and assignment targets no longer fabricate
  participants.
- C4: `RelIndex(i, from, to, ...)` no longer shifts the index into `from`.
- gitGraph: `cherry-pick` appears on the timeline instead of vanishing.

New flowchart syntax (was silently erased whole-line before):
- chained edges `A --> B --> C`; `&` fan-out (`A & B --> C & D`, label-safe);
  inline `-- text -->` labels; min-length links (`---->`); bidirectional
  `<-->` (new `backArrow` on Edge, drawn at both ends); `--o`/`--x` heads
  (drawn as plain arrows — honest degradation); edge IDs (`e1@-->`);
  `:::class` suffixes.

Cross-cutting: YAML front-matter (`---title/config---`) is stripped, so
every config-bearing doc example now native-renders. Fixtures exercise the
new syntax with graph-identical rewrites, so the lint corpus proves it.

## 0.5.0

Full mermaid.js type parity: **all 30 documented diagram types render.**

Seven new types, each full-stack (parser + layout + renderer + scene
lowering + linter coverage + alt-text + PDF + gallery self-portrait):

- `treeView-beta` — indentation hierarchy with folder/file glyphs; accepts
  pasted `tree` output (box-drawing normalizes to indents).
- `venn-beta` — 1-3 sets, area-proportional radii, overlap labels pushed
  into their region's private lens.
- `cynefin-beta` — the fixed 2x2 + confusion disk; transitions run in the
  outer corridor past the item stacks.
- `wardley-beta` — author-coordinate scatter with evolution bands, links,
  dashed evolve arrows, inertia bars, collision-staggered labels.
- `ishikawa-beta` — classic fishbone: spine, alternating 60-degree ribs,
  horizontal twigs (upstream's minimal documented grammar).
- `eventmodeling` — strict time-by-lane grid with typed color-coded
  frames and elbow connectors.
- `swimlane-beta` — flowchart semantics under lane constraints: global
  columns from network-simplex layering, authored lane bands, cross-lane
  orthogonal edges.

Linter refinements the new types forced: T-junctions no longer count as
edge crossings (strict-orientation test), and `mark-escapes-plot` applies
only to a sole bounding container (lanes/composites are not plots).

Benchmarks re-measured across all 30 (worst: sankey 35.8 ms rasterized —
its fixture grew and its labels gained chips; still 7x under the CI cap).

## 0.4.1

- Fix the iOS build under Swift 6.1: `UIImage.accessibilityLabel` is
  `@MainActor` in the iOS SDK, so the attachment path now sets it only
  when already on the main thread (the real text-view embedding case);
  `MermaidView`'s own accessibility label covers the view path regardless.
  Local Swift 6.2 accepted the unguarded mutation — CI's 6.1 correctly
  rejected it, and the CI step now preserves compiler diagnostics on
  failure instead of swallowing them with `tail`.

## 0.4.0

Three capabilities from the IR-compilation design review (docs/website has
the memo's conclusions; SVG/ASCII backends are deliberately deferred until
there's a concrete consumer):

- **Vector PDF export** — `MermaidRenderer.pdfData(source:theme:spacing:)`:
  the same layout and draw code as the raster path, into a `CGPDFContext`.
  Crisp at any zoom; the export/print path. All 23 fixture types verified.
- **Accessibility alt-text** — every diagram describes itself.
  `MermaidView` exposes a full content description to VoiceOver
  ("Flowchart with 12 nodes and 14 connections: ..."), `attachmentString`
  sets it on the embedded image, `MermaidRenderer.altText(source:)` and
  the platform-free `MermaidAltText.describe(_:)` expose it directly.
- **`DiagramColor`** — platform-free sRGB color values in MermaidLayout,
  and `DiagramTheme.resolved`: every theme color as `DiagramColor`,
  resolved once under the theme's pinned appearance (the fingerprint now
  derives from the same pass). The color groundwork for future
  non-CoreGraphics backends, fully additive.
- Internals: the per-type render dispatch is factored into `renderPlan` +
  `paddedCanvas`, shared by raster and PDF — new types reach every output
  format at once.

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
