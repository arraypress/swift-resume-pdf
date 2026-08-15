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
        .package(url: "https://github.com/arraypress/swift-text-pdf.git", from: "1.8.0"),
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
