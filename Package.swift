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
        .package(url: "https://github.com/arraypress/swift-text-pdf.git", from: "0.1.0"),
        .package(url: "https://github.com/arraypress/swift-text-docx.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "ResumePDF",
            dependencies: [
                .product(name: "TextPDF", package: "swift-text-pdf"),
                .product(name: "TextDocx", package: "swift-text-docx"),
            ],
            resources: [
                .copy("Resources/Fonts"),
                // The designs themselves. A design is a JSON file; the Swift
                // only names it.
                .copy("Resources/Designs"),
                .copy("Resources/Letters"),
            ]
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
