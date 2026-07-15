// swift-tools-version: 6.2
import PackageDescription

// MermaidKit — native Mermaid diagram parsing, layout, and rendering.
// MermaidLayout is platform-free geometry (parse → layout → scene IR + a
// geometric layout linter). MermaidRender draws with CoreGraphics/CoreText on
// Apple platforms, and with Silica (Cairo/FontConfig) on Linux. No JavaScript,
// no WebView.
//
// The Silica stack is a Linux-only rendering backend: on Apple platforms
// CoreGraphics/CoreText are used and these products are never linked. Pulling
// Silica into the graph is why the toolchain floor is Swift 6.2 (its transitive
// PureSwift/Android dependency requires 6.2, and SwiftPM parses every manifest
// in the graph regardless of platform).
let package = Package(
    name: "MermaidKit",
    platforms: [.macOS(.v14), .iOS(.v17), .visionOS(.v1)],
    products: [
        .library(name: "MermaidLayout", targets: ["MermaidLayout"]),
        .library(name: "MermaidRender", targets: ["MermaidRender"]),
    ],
    dependencies: [
        // Silica and its Cairo backend track `master` (Silica itself depends on
        // Cairo by branch, so a stable version requirement can't be mixed in);
        // Package.resolved pins the exact commits for reproducibility.
        .package(url: "https://github.com/PureSwift/Silica.git", branch: "master"),
        .package(url: "https://github.com/PureSwift/Cairo.git", branch: "master"),
    ],
    targets: [
        .target(name: "MermaidLayout", path: "Sources/MermaidLayout"),
        .target(
            name: "MermaidRender",
            dependencies: [
                "MermaidLayout",
                .product(name: "SilicaCairo", package: "Silica", condition: .when(platforms: [.linux])),
                .product(name: "Cairo", package: "Cairo", condition: .when(platforms: [.linux])),
            ],
            path: "Sources/MermaidRender"),
        .testTarget(name: "MermaidLayoutTests", dependencies: ["MermaidLayout"], path: "Tests/MermaidLayoutTests"),
        .testTarget(name: "MermaidRenderTests", dependencies: ["MermaidRender", "MermaidLayout"], path: "Tests/MermaidRenderTests"),
    ]
)
