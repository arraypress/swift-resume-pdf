// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-resume-pdf",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "ResumePDF", targets: ["ResumePDF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/arraypress/swift-text-pdf.git", from: "0.2.0"),
        .package(url: "https://github.com/arraypress/swift-text-docx.git", from: "0.1.0"),
        // The theme — typeface and its bundled fonts, accent, page, density —
        // shared with the Markdown library, so one brand file dresses both.
        .package(url: "https://github.com/arraypress/swift-document-theme.git", from: "0.1.0"),
        // Strict reading: a key a design does not have is refused, by name.
        .package(url: "https://github.com/arraypress/swift-recipe-kit.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "ResumePDF",
            dependencies: [
                .product(name: "TextPDF", package: "swift-text-pdf"),
                .product(name: "TextDocx", package: "swift-text-docx"),
                .product(name: "DocumentTheme", package: "swift-document-theme"),
                .product(name: "RecipeKit", package: "swift-recipe-kit"),
            ]
            // No resources: the designs, letters, cards, presets and schemas
            // are compiled in (Support/*Text.swift); the fonts are
            // DocumentTheme's.
        ),
        .testTarget(name: "ResumePDFTests", dependencies: ["ResumePDF"]),

        // Plain `import`, no @testable. Everything a caller outside the
        // package is meant to be able to reach has to be reachable here, and
        // nothing in the other target can prove that — @testable makes
        // internal declarations visible, so a visibility regression passes
        // every test in it.
        .testTarget(name: "ResumePDFAPITests", dependencies: ["ResumePDF"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
