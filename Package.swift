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
        // Local while the family support this needs is unreleased. Switch to
        // the version URL once swift-text-pdf is tagged.
        .package(path: "../swift-text-pdf"),
    ],
    targets: [
        .target(
            name: "ResumePDF",
            dependencies: [
                .product(name: "TextPDF", package: "swift-text-pdf"),
            ],
            resources: [
                .copy("Resources/Fonts"),
            ]
        ),
        .testTarget(name: "ResumePDFTests", dependencies: ["ResumePDF"]),
    ]
)
