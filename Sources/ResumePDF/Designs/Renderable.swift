//
//  Renderable.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a résumé and a letter do the same way once they are laid out.
//
//  The two documents differ in the design that arranges them and in what
//  can be wrong with them. They do not differ in what happens next: the
//  bytes are written to a file, or the finished page is rendered, counted
//  and read for what it shows, and the findings sorted into a report. That
//  walk was written twice and had started to drift, so it is here once —
//  the way ``Outlined`` carries the flat formats.
//

import Foundation
import TextPDF

/// A document that is laid out under a design: a résumé, or a letter.
public protocol Renderable {

    /// The kind of design that lays it out — ``Design`` for a résumé,
    /// ``LetterLayout`` for a letter.
    associatedtype Layout

    /// Lays the document out on a prepared sheet.
    func document(design: Layout, theme: Theme) throws -> Document

    /// The finished bytes.
    func render(design: Layout, theme: Theme) throws -> Data

    /// What is wrong with the document itself, as distinct from its page:
    /// the checks that read the model and the design's declarations.
    /// - Parameter pages: How many it ran to, which the checks on length read.
    func findings(design: Layout, pages: Int, region: Region) -> [Finding]
}

extension Renderable {

    /// Renders the document under a design of your own and writes it,
    /// returning the byte count.
    @discardableResult
    public func save(to url: URL, design: Layout, theme: Theme = .plain) throws -> Int {
        let data = try render(design: design, theme: theme)
        try data.write(to: url, options: .atomic)
        return data.count
    }

    /// Renders the document and reports what is wrong with it: what the
    /// document's own checks find, then what the finished page shows.
    ///
    /// Rendering is part of the check rather than beside it, because the
    /// most useful facts — how many pages it runs to, and whether a run of
    /// text fell back to a font the reader supplies — are properties of the
    /// finished document.
    /// - Parameter name: What the design is called, for the report. The
    ///   layout is whatever this document takes, and a report wants a word.
    /// - Parameter coverage: How much of a posting is on the page, where
    ///   there was one to match against.
    func report(
        design: Layout, named name: String, theme: Theme, region: Region, coverage: Coverage? = nil
    ) throws -> Report {
        let document = try document(design: design, theme: theme)
        _ = document.render()
        let pages = document.pageCount()

        var findings = findings(design: design, pages: pages, region: region)
        findings += ATS.substitutions(in: document)
        if let coverage { findings += ATS.coverage(coverage) }

        return Report(
            findings: findings.sorted { $0.severity < $1.severity },
            pages: pages,
            design: name,
            region: region,
            coverage: coverage
        )
    }
}

// MARK: - The two documents

extension Resume: Renderable {
    public typealias Layout = any Design
}

extension CoverLetter: Renderable {
    public typealias Layout = any LetterLayout
}
