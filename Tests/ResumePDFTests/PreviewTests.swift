//
//  PreviewTests.swift
//  ResumePDF
//
//  Renders each design to a PDF and a PNG so they can be looked at.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class PreviewTests: XCTestCase {

    private let output = URL(fileURLWithPath: ProcessInfo.processInfo.environment["PREVIEW_DIR"] ?? "/tmp/resume-previews")

    func testRenderEveryDesign() throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        for design in DesignKind.allCases {
            let theme = Theme(typeface: design.intendedTypeface)
            let data = try Resume.sample.render(design: design, theme: theme)
            let name = design.rawValue

            try data.write(to: output.appendingPathComponent("\(name).pdf"))

            let doc = try XCTUnwrap(PDFDocument(data: data), "PDFKit refused \(name)")
            print("\(name): \(data.count) bytes, \(doc.pageCount) page(s)")

            for index in 0..<doc.pageCount {
                let page = try XCTUnwrap(doc.page(at: index))
                try rasterise(page, to: output.appendingPathComponent("\(name)-\(index + 1).png"))
            }
        }
    }

    func testRenderAcademicAndThemes() throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        let cases: [(String, Resume, DesignKind, Theme)] = [
            ("academic", .academicSample, .broadsheet, .classic),
            ("navy-sidebar", .sample, .sidebar, Theme(accent: "#1F3A5F")),
            ("compact-ledger", .sample, .ledger, Theme(density: .compact)),
        ]

        for (name, resume, design, theme) in cases {
            let data = try resume.render(design: design, theme: theme)
            try data.write(to: output.appendingPathComponent("\(name).pdf"))

            let doc = try XCTUnwrap(PDFDocument(data: data))
            print("\(name): \(data.count) bytes, \(doc.pageCount) page(s)")

            for index in 0..<doc.pageCount {
                let page = try XCTUnwrap(doc.page(at: index))
                try rasterise(page, to: output.appendingPathComponent("\(name)-\(index + 1).png"))
            }
        }
    }

    private func rasterise(_ page: PDFPage, to url: URL, scale: CGFloat = 2) throws {
        let bounds = page.bounds(for: .mediaBox)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let image = page.thumbnail(of: size, for: .mediaBox)

        var rect = CGRect(origin: .zero, size: size)
        let raster = try XCTUnwrap(image.cgImage(forProposedRect: &rect, context: nil, hints: nil))
        let bitmap = NSBitmapImageRep(cgImage: raster)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: url)
    }
}
