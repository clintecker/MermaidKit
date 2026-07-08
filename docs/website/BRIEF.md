# MermaidKit brochure site — design brief

Context package for a design session building the GitHub Pages site.
Written against MermaidKit v0.8.0. Every fact here was verified against the
code; cite them as written and don't embellish.

- Repo: https://github.com/clintecker/MermaidKit
- Latest release: v0.8.0 (all 30 mermaid.js diagram types; sequence
  diagrams at full structural mermaid-parity)
- Site will live at: https://clintecker.github.io/MermaidKit/
  (GitHub Pages, served from the `docs/` folder on `main` — the finished
  site is an `index.html` placed in `docs/`, referencing images relatively
  as `images/...`)

## The one-paragraph truth

MermaidKit renders [Mermaid](https://mermaid.js.org) diagrams natively on
Apple platforms — pure Swift and CoreGraphics, no JavaScript, no WebView,
zero dependencies. 30 diagram types, a one-line SwiftUI view, images and
attributed-string attachments, themed with a single value. MIT.

## The three story pillars (build the site around these)

### 1. Novel: the diagrams check themselves

No other Mermaid renderer does this. Every diagram lowers to a
machine-readable geometry scene (boxes, edge routes, labels), and a
**geometry linter** checks invariants of good layout: no edge through a
box, no line slicing through label text, no overlapping nodes, nothing off
canvas, no series escaping its plot. Layout regressions fail CI as named
geometric facts — "edge #3 passes through node 'DiagramScene' (165pt
inside)" — not as pixel diffs or human eyeballing.

Second novel thing, and the site can say it with a straight face because
the images prove it: **every example is the project documenting itself.**
The class diagram is MermaidKit's real public API. The sankey hero is the
render pipeline. The gitgraph is the actual release history. The xychart
plots the real benchmark numbers. The same 30 files are the gallery, the
lint corpus, and the benchmark suite — the examples cannot drift from what
the engine does.

Layout quality is engineered, not eyeballed: network-simplex layer
assignment (the same strategy Graphviz dot defaults to), labels that
reserve real space during layout, and edit stability verified by
scene-diff tests — rename a label and nothing else moves. Diagrams don't
teleport while you edit.

### 2. Developer experience: one line to a diagram

```swift
import MermaidRender

MermaidView("""
flowchart TD
    A[Start] --> B{Choice}
    B -->|yes| C[Do it]
    B -->|no| D[Skip]
""")
```

That's the whole integration. It follows light/dark automatically, sizes
to the diagram, and caches renders. The rest of the API keeps the same
shape:

- `MermaidRenderer.image(source:theme:spacing:)` — one call, one image.
  Sync and fast enough to call in a SwiftUI `body` (worst dense fixture
  ~25 ms cold **including rasterization**, most types under 12 ms, cached
  thereafter); `renderImage(...)` is the async sibling with cancellation.
- `MermaidRenderer.attachmentString(...)` — a diagram as an
  `NSAttributedString` attachment for text views.
- `DiagramTheme` — six colors plus a categorical palette re-skins all 30
  types at once. `DiagramSpacing` — `.compact`/`.regular`/`.comfortable`
  density presets, or exact gaps.
- When parsing fails, `MermaidParser.diagnose()` explains why, with line
  numbers and did-you-mean suggestions for typo'd headers.
- Headless mode: the parse → layout → scene pipeline is platform-free, so
  tools can get pure geometry without rendering a pixel.

Install:
```swift
.package(url: "https://github.com/clintecker/MermaidKit.git", from: "0.8.0")
```

### 3. Adaptable: built to meet people where they are

- **Nothing breaks the host app.** Unknown dialects degrade to readable
  monospaced source. Styling directives it doesn't support (`%%{init:}%%`,
  `classDef`, `style`, `click`) are ignored, not fatal — the diagram still
  renders. Hostile input (garbage, 100k-char labels, NaN/Infinity) is
  contained by an adversarial test suite in CI.
- **Author intent is honored.** Declare which side an architecture edge
  leaves from (`waf:R --> L:gateway`) and the router obeys. Pick a density
  preset and every layout adapts. Override one palette and every chart
  re-skins.
- **Feedback becomes engineering, fast.** The project's pattern, visible
  in its own gitgraph: a person spots a flaw ("that label overlaps its
  line"), the engine gets fixed for everyone, and the flaw's whole class
  becomes a permanent CI check so it can't return. Three gitgraph layout
  upgrades and a new linter invariant shipped this way in one day.
- **Honest support matrix.** All 30 types parse their core syntax; the
  README says plainly what works, what's ignored, and what's a gap worth
  filing. The site should keep that plainness — it's a feature.
- Platforms: macOS 14+, iOS 17+, visionOS 1+ (Swift 6, Xcode 16+ to
  build). Lower floors and an SVG backend are the top of the roadmap —
  the project wants more people to be able to use it.

## Asset inventory

All images are rendered by MermaidKit itself and regenerate from source —
never hand-edit. Each exists in light and dark; serve both via `<picture>`
with `prefers-color-scheme`.

**Hero** (the render pipeline as a sankey, ~2200px wide):
- https://raw.githubusercontent.com/clintecker/MermaidKit/v0.8.0/docs/images/hero-light.png
- https://raw.githubusercontent.com/clintecker/MermaidKit/v0.8.0/docs/images/hero-dark.png

**Per-type gallery** (30 types × 2 appearances, max 2000px wide). Pattern:
`https://raw.githubusercontent.com/clintecker/MermaidKit/v0.8.0/docs/images/types/<name>.png`
(append `-dark` before `.png` for dark). Names and what each self-portrait
shows:

| name | subject |
|---|---|
| architecture | the module map with author-declared edge sides |
| block | the render pipeline as blocks |
| c4 | a host app embedding MermaidKit |
| class | **the real public API** — strong gallery opener |
| er | the scene IR's data model |
| flowchart | the render decision flow, fallbacks included |
| gantt | the actual 1.0 release program |
| gitgraph | the real branch/tag history (the release history) |
| journey | a developer's first week adopting the library |
| kanban | the live roadmap board |
| mindmap | the feature map |
| packet | TCP header (the canonical example for this type) |
| pie | source lines by component |
| quadrant | roadmap candidates, effort vs impact |
| radar | quality dimensions by release |
| requirement | real quality requirements traced to their verifying tests |
| sankey | sources flowing through the pipeline (same family as hero) |
| sequence | MermaidView's render flow: actor, typed database head, box band, activation bar, note, alt/else fragment |
| state | a source's lifecycle with the light/dark raster fork |
| timeline | project history |
| treemap | the source tree by lines |
| xychart | the published benchmark numbers with the 25 ms budget line |
| zenuml | the diagnose-and-fix flow |
| treeview | this repo's own source tree with inline notes |
| venn | gallery = lint corpus = benchmarks ("the 30 fixtures") |
| cynefin | layout strategies sorted by problem class |
| wardley | the component landscape with evolve arrows toward SVG |
| ishikawa | "diagram renders wrong" root-cause fishbone |
| eventmodeling | the render pipeline as an event model |
| swimlane | parse-to-display flow across module lanes |

In the deployed site these same files are referenced relatively:
`images/hero-light.png`, `images/types/<name>.png`, etc.

## Numbers the site may cite (verified)

- 30 diagram types, zero dependencies, zero JavaScript, no WebView.
- Worst dense fixture ~25 ms (sankey) cold render including rasterization; most
  types 2–12 ms; results cached. CI fails any type over 250 ms.
- Every fixture lint-checked in CI against the geometric invariants above.
- Adversarial input suite; input caps mirror mermaid.js (50k chars, 500
  flowchart edges); numeric sanitation at the parser boundary.
- Swift 6 language mode, zero concurrency warnings. MIT.

## Voice (non-negotiable)

- Anti-hype. No superlatives, no "production-ready", no emoji section
  headers. Numbers over adjectives; the diagrams do the impressing.
- State limitations plainly, near the claims they qualify: core syntax per
  type (not a full mermaid.js port); styling directives ignored-not-fatal;
  Apple platforms only today (SVG backend is the most-wanted
  contribution).
- No comparisons with other tools or benchmark claims against them —
  describe what MermaidKit is, not what others aren't.
- Performance claims must match the README table exactly.

## Suggested shape (starting point, not a mandate)

1. **Hero** — pitch line, the sankey hero (theme-aware), the SwiftUI
   snippet, the install line. "No JavaScript. No WebView. No
   dependencies." is the honest hook.
2. **Gallery** — the 30 self-portraits. This is the killer section; lead
   with class (the API drawing itself).
3. **It checks its own work** — the geometry-linter story, told simply:
   a lint report line next to the diagram it protects.
4. **One line to a diagram** — the DX pillar: snippet, theme, spacing,
   diagnose.
5. **Built to adapt** — the pillar-3 story, ending with the roadmap
   invitations (SVG backend, lower floors).
6. **Footer** — GitHub, release, MIT.

Single page, static HTML/CSS, fast on a phone. The diagrams carry the
visual identity — keep the chrome quiet around them. **No analytics or
trackers** (the library's privacy story is "no network"; the site lives up
to it). Don't claim SVG output, Linux support, or full mermaid.js parity.

## Open questions for Clint

- Custom domain, or default `clintecker.github.io/MermaidKit`?
- Logo/wordmark, or type-only?
