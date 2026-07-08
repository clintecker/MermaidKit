# MermaidKit website — context package for the design session

Everything a design/build session needs to create the GitHub Pages site.
Written 2026-07-08 against MermaidKit v0.2.0.

## What MermaidKit is (the one-paragraph truth)

MermaidKit renders [Mermaid](https://mermaid.js.org) diagrams natively on
Apple platforms — pure Swift + CoreGraphics, no JavaScript, no WebView,
zero dependencies. 23 diagram types, a SwiftUI drop-in view, images and
attributed-string attachments, themeable with one value. Extracted from a
native markdown editor, which consumes it from GitHub like any other app.
MIT.

- Repo: https://github.com/clintecker/MermaidKit
- Latest release: v0.2.0 ("ELK-grade layout": network-simplex layering,
  label-space reservation, fixed-side ports, DiagramSpacing density presets,
  edit stability — see CHANGELOG)
- Swift Package Index (once submitted): https://swiftpackageindex.com/clintecker/MermaidKit
- Author: Clint Ecker (clintecker on GitHub)

## Hosting mechanics (decide with Clint, defaults suggested)

- **GitHub Pages, `/docs` folder on `main`** is the path of least
  resistance: this directory already holds the images the site needs, so
  the site can reference `images/...` relatively. Enable in repo Settings →
  Pages → "Deploy from a branch" → `main` / `/docs`.
- Site URL will be `https://clintecker.github.io/MermaidKit/`.
- Static HTML/CSS is plenty — no build step, no framework, nothing to rot.
  If a generator is used anyway, it must emit into `docs/`.
- `docs/` currently contains: `GALLERY.md`, `images/` (see asset inventory),
  and this brief in `website/`. An `index.html` at `docs/index.html` becomes
  the homepage. NOTE: GitHub Pages will serve the whole `docs/` folder;
  that's fine (the images are the point), but be aware GALLERY.md won't
  auto-render as HTML on Pages — the site should have its own gallery page.

## Asset inventory (all paths relative to `docs/`)

- `images/hero-light.png`, `images/hero-dark.png` — the energy-flow sankey,
  2200×~1180, palette-quantized (~50–65KB each). Current hero image.
- `images/types/<name>.png` + `images/types/<name>-dark.png` — one image
  per diagram type, rendered by MermaidKit itself from the dense fixtures.
  23 types × 2 appearances, max 2000px wide, quantized. The `<name>`s:
  architecture, block, c4, class, er, flowchart, gantt, gitgraph, journey,
  kanban, mindmap, packet, pie, quadrant, radar, requirement, sankey,
  sequence, state, timeline, treemap, xychart, zenuml.
- Regeneration: `scripts/gen-gallery.sh` (runs the render harness + ImageMagick
  quantization). Never hand-edit these; they're build artifacts.
- No logo exists. If the site wants one, that's a new design task (keep it
  simple; the diagrams are the visual identity).

## Numbers and facts the site may cite (all verified; do not embellish)

- 23 diagram types; header list in README's support matrix.
- Zero dependencies. Swift 6 language mode, zero concurrency warnings.
- Platforms: macOS 14+, iOS 17+, visionOS 1+. Xcode 16+ to build.
- Performance (Apple silicon, cold, **rasterization included**): worst
  fixture ~25ms (architecture), most types 2–12ms, cached thereafter.
- Layout engine credentials (site-worthy): network-simplex layer assignment
  (ELK/Graphviz-dot's default strategy), label-space reservation during
  layout, author-declared ports honored, `.compact`/`.regular`/
  `.comfortable` density presets, and edit stability verified by scene-diff
  tests (same-width rename moves nothing). Per-type performance table in
  README; CI enforces <250ms.
- Robustness: fuzz-style adversarial suite in CI; numeric sanitation at the
  parser boundary; input caps mirroring mermaid.js (50k chars; 500 edges
  for flowcharts). `MermaidParser.diagnose()` explains failures with line
  numbers and did-you-mean suggestions.
- The differentiator worth a whole page/section: **the geometry linter**.
  Every diagram lowers to a Codable scene IR (boxes, edge polylines,
  labels); a linter checks invariants of good layout (no edge through a
  box, no overlapping nodes, nothing off-canvas, no series escaping its
  plot). Layout regressions fail CI as geometry ("edge #3 passes through
  node 'Customer' (165pt inside)"), not pixel diffs. No other Mermaid
  renderer does this.

## Code snippets (copy exactly; these compile)

SwiftUI:
```swift
import MermaidRender

MermaidView("""
flowchart TD
    A[Start] --> B{Choice}
    B -->|yes| C[Do it]
    B -->|no| D[Skip]
""")
```

Image:
```swift
let image = MermaidRenderer.image(
    source: "sequenceDiagram\n  Alice->>Bob: Hello",
    theme: DiagramTheme(prefersDark: false)
)
```

Install:
```swift
.package(url: "https://github.com/clintecker/MermaidKit.git", from: "0.2.0")
```

## Voice and honesty rules (non-negotiable, hard-won)

The project's public materials are deliberately anti-hype and were audited
line-by-line against the code. The site must keep that register:

- No superlatives ("blazingly", "the best"), no emoji sections, no vague
  "production-ready" claims. Numbers over adjectives.
- State limitations plainly, near the claims they qualify: core syntax per
  type (not a full mermaid.js port); styling directives ignored-not-fatal;
  Apple-only rendering (SVG backend is the most-wanted contribution);
  output is native-looking, not a pixel-clone of mermaid.js.
- Comparison honesty: BeautifulMermaid (lukilabs) is the closest neighbor —
  they have SVG/ASCII output and lower OS floors; MermaidKit has ~4× the
  type coverage, zero deps, and the linter. Both MIT. Say it that way.
- Any performance claim must match the README table exactly.

## Suggested information architecture (a starting point, not a mandate)

1. **Hero** — the pitch line + the sankey hero image (theme-aware) + the
   SwiftUI snippet + install line. "No JavaScript. No WebView. No
   dependencies." is the honest hook.
2. **Gallery** — the 23 per-type images (this is the killer section; the
   site exists to show these). Light/dark aware via `<picture>`.
3. **How it's verified** — the geometry-linter story. This is the section
   that earns engineers' respect.
4. **Get started** — install + the three API entry points + theming.
5. **Footer** — GitHub, release, license.

Single page is fine. Fast, static, readable on a phone. The diagrams carry
the visual identity — the design should stay quiet around them (they're
colorful; the chrome shouldn't compete).

## Things the site must NOT do

- Don't claim SVG output, Linux support, or full mermaid.js syntax parity.
- Don't ship analytics/trackers (the library's privacy story is "no
  network"; the site should live up to it).
- Don't invent a benchmark comparison against mermaid.js/WKWebView — we
  never measured one; the table is MermaidKit-only cold-render times.

## Open questions for Clint

- Domain: default `clintecker.github.io/MermaidKit` or a custom domain?
- Logo/wordmark: want one, or type-only?
- Should the site lead with launch-announcement framing or stay evergreen?
