//
//  Design.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Which arrangement the document takes.
//
//  Four, because they are genuinely different documents rather than one
//  document with the colours changed — and because the good-looking ones and
//  the machine-readable ones are not the same set. A design declares which it
//  is, and ``ATS`` reports it, so the choice is made with the trade-off in
//  view rather than discovered after an application disappears.
//

import Foundation
import TextPDF

/// One of the built-in arrangements.
public enum DesignKind: String, Sendable, CaseIterable, Codable {

    /// Single column, ruled sections, set in the sans. The one to send when
    /// nothing is known about what will read it.
    case ledger

    /// Single column set in the serif, with a centred masthead. Reads as
    /// considered rather than current — academia, law, medicine, and senior
    /// roles where looking current is not the point.
    case broadsheet

    /// A date rail down the left with entries hung off a hairline. The
    /// employment history is the shape of the page, which suits a clean
    /// progression and flatters nothing else.
    case timeline

    /// A tinted rail carrying contact, skills and languages, with the
    /// experience beside it. The best-looking of the set and the only one
    /// that will not survive an applicant tracking system.
    case sidebar

    /// Section names hung in the left margin, content in one column beside
    /// them. Book typography, and the calmest page here.
    case margin

    /// A light band at the top and the rest of the page reversed out.
    /// Striking on a screen, expensive on somebody's office printer.
    case nocturne

    /// A coloured panel across the top with the name reversed out of it.
    case plaque

    /// Section headings as tabs with a mark beside each. Navigable at a
    /// glance, which suits a long CV.
    case bulletin

    /// Alternate sections on a tinted band, labels in the margin.
    case register

    /// Headings struck through with a highlighter. The least formal of them.
    case marker

    /// Two panels across the head — summary on one, contact on the other —
    /// and a coloured tab beside every section.
    case slate

    /// A very large name, very small labels, and a great deal of nothing.
    /// The most confident page here, and the first to run over.
    case swiss

    /// Every entry on a panel of its own. Suits several short roles; unkind
    /// to one long one.
    case card

    /// Monospace for the data — dates, labels, technologies — and
    /// proportional type for the prose. Technical without being a costume.
    case terminal

    public var displayName: String {
        switch self {
        case .ledger: return "Ledger"
        case .broadsheet: return "Broadsheet"
        case .timeline: return "Timeline"
        case .sidebar: return "Sidebar"
        case .margin: return "Margin"
        case .nocturne: return "Nocturne"
        case .plaque: return "Plaque"
        case .bulletin: return "Bulletin"
        case .register: return "Register"
        case .marker: return "Marker"
        case .slate: return "Slate"
        case .swiss: return "Swiss"
        case .card: return "Card"
        case .terminal: return "Terminal"
        }
    }

    /// What the design is for, in one line.
    public var summary: String {
        switch self {
        case .ledger: return "Single column, ruled sections. Safe anywhere."
        case .broadsheet: return "Serif, centred masthead. Academic and formal."
        case .timeline: return "A date rail down the left edge."
        case .sidebar: return "Two columns with a tinted rail. Not machine-readable."
        case .margin: return "Section names hung in the left margin."
        case .nocturne: return "Light masthead, reversed body."
        case .plaque: return "A coloured panel across the top."
        case .bulletin: return "Headings as tabs, each with a mark."
        case .register: return "Alternating tinted bands."
        case .marker: return "Highlighter headings. Informal."
        case .slate: return "Twin panels and section tabs."
        case .swiss: return "An oversized name and a lot of air."
        case .card: return "Every entry on its own panel."
        case .terminal: return "Monospaced labels and dates, proportional prose."
        }
    }

    /// Whether the text of the page runs in one column.
    ///
    /// The single fact that decides whether a résumé survives being parsed.
    /// An applicant tracking system extracts the text and reads it in order;
    /// where two columns sit side by side, a line of the left one is followed
    /// by a line of the right, and an employment history comes out
    /// interleaved with a skills list. Nobody reads the result — it is
    /// scored, and it scores badly.
    public var isSingleColumn: Bool { design.isSingleColumn }

    /// The typeface the design was drawn for.
    ///
    /// A theme may override it. Broadsheet in a grotesque is a different
    /// document and not an improvement, but it is the caller's page.
    public var intendedTypeface: Typeface {
        self == .broadsheet ? .sourceSerif : .inter
    }

    /// Whether the design has somewhere to put a photograph.
    ///
    /// Reported rather than silently ignored: a résumé that carries a portrait
    /// and renders without one should say which design dropped it.
    /// Asked of the design itself, so the declaration cannot drift from the
    /// thing that draws — which it did: these were two lists, and the checks
    /// read the wrong one the moment a design was reached by any other route.
    public var showsPhoto: Bool { design.showsPhoto }

    /// Whether this design draws a scannable code.
    public var showsCode: Bool { design.showsCode }

    /// The thing that draws.
    ///
    /// Public so a caller can reach a built-in design through the same
    /// ``Design`` interface a design of their own uses — which is what lets a
    /// tool treat "one of the fourteen" and "a blueprint from a file" as the
    /// same kind of thing.
    public var design: any Design {
        switch self {
        case .ledger: return Ledger()
        case .broadsheet: return Broadsheet()
        case .timeline: return Timeline()
        case .sidebar: return Sidebar()
        case .margin: return Margin()
        case .nocturne: return Nocturne()
        case .plaque: return Plaque()
        case .bulletin: return Bulletin()
        case .register: return Register()
        case .marker: return Marker()
        case .slate: return Slate()
        case .swiss: return Swiss()
        case .card: return Card()
        case .terminal: return Terminal()
        }
    }
}

/// An arrangement of a résumé on a page.
///
/// Beyond drawing, a design declares three things about itself, because the
/// checks read declarations as well as the finished page. They have defaults —
/// a design of your own is assumed to be a readable single column that draws
/// no photograph, which is what one written with ``Blocks`` will be — so
/// `render` remains the only requirement.
public protocol Design: Sendable {

    /// Lays the document out on a prepared sheet.
    func render(_ resume: Resume, on sheet: Sheet)

    /// What this design is called, in a report or a listing.
    var displayName: String { get }

    /// Whether the text runs in one column in reading order.
    ///
    /// A tracking system extracts text in order and does not know a rail is a
    /// separate column, so declaring `false` is what makes ``ATS`` block the
    /// document rather than let somebody send it into a form.
    var isSingleColumn: Bool { get }

    /// Whether the design has somewhere to put a photograph.
    ///
    /// Read by the checks, so a résumé carrying a portrait that this design
    /// will not draw is reported rather than silently dropped.
    var showsPhoto: Bool { get }

    /// Whether the design has somewhere to put a scannable code.
    ///
    /// Same contract as the photograph: a code that is set and not drawn is
    /// reported, because it was meant.
    var showsCode: Bool { get }
}

extension Design {

    public var displayName: String { String(describing: type(of: self)) }
    public var isSingleColumn: Bool { true }
    public var showsPhoto: Bool { false }
    public var showsCode: Bool { false }
}

// MARK: - Rendering

extension Resume {

    /// Lays the résumé out, ready to render or save.
    ///
    /// The typeface is loaded here rather than cached, because an embedded
    /// font accumulates the glyphs it is asked to draw in order to subset
    /// itself — so one shared between two documents carries the first one's
    /// characters into the second one's file.
    public func document(design: DesignKind = .ledger, theme: Theme = .plain) throws -> Document {
        try document(design: design.design, theme: theme)
    }

    /// The same, laid out by a design of your own.
    ///
    /// ```swift
    /// struct Broadside: Design {
    ///     func render(_ resume: Resume, on sheet: Sheet) {
    ///         sheet.line(resume.profile.name, size: 30, face: sheet.semibold)
    ///         for section in resume.populated() {
    ///             sheet.sectionHeading(resume.heading(for: section))
    ///             Blocks.render(section, of: resume, on: sheet,
    ///                           style: .init(x: sheet.left, width: sheet.width))
    ///         }
    ///     }
    /// }
    ///
    /// try resume.save(to: url, design: Broadside())
    /// ```
    ///
    /// ``Blocks`` renders any section the same way the built-in designs do, so
    /// a design of your own is a masthead and a loop unless you want it to be
    /// more. Everything below that — ``Sheet``'s type, palette, rhythm and
    /// components — is the same furniture the fourteen are built from.
    public func document(design: any Design, theme: Theme = .plain) throws -> Document {
        let family = try Typography.family(theme.typeface)
        let sheet = Sheet(theme: theme, family: family, labels: labels)
        sheet.pdf.language = labels.language
        design.render(self, on: sheet)
        return sheet.pdf
    }

    /// The finished bytes, from a design of your own.
    public func render(
        design: any Design, theme: Theme = .plain, archival: Bool = false, password: String = ""
    ) throws -> Data {
        try document(design: design, theme: theme)
            .render(metadata: metadata(design: .ledger),
                    standard: archival ? .pdfA3b : .none, password: password)
    }

    /// Renders a design of your own and writes it, returning the byte count.
    @discardableResult
    public func save(to url: URL, design: any Design, theme: Theme = .plain) throws -> Int {
        let data = try render(design: design, theme: theme)
        try data.write(to: url, options: .atomic)
        return data.count
    }

    /// The loosest setting that fits the résumé into `pages`.
    ///
    /// The complaint every résumé tool gets is that the document runs four
    /// lines onto a second page, and the usual answer — drop the type to 8pt —
    /// makes it look desperate. Tightening the leading and the gaps between
    /// blocks buys most of the same room and costs far less legibility, so
    /// that is what this tries, in order, and it stops at the first setting
    /// that works.
    ///
    /// Returns the theme it settled on, `nil` when even the tightest will not
    /// fit. That is a content problem and not a formatting one: something has
    /// to come off the page, and choosing what is not a decision a layout
    /// engine should be making on somebody's behalf.
    public func fitted(
        to pages: Int = 1,
        design: DesignKind = .ledger,
        theme: Theme = .plain
    ) throws -> Theme? {
        try fitted(to: pages, design: design.design, theme: theme)
    }

    /// The same, for a design of your own.
    public func fitted(
        to pages: Int = 1,
        design: any Design,
        theme: Theme = .plain
    ) throws -> Theme? {
        for density in [Density.relaxed, .normal, .compact] {
            let candidate = Theme(
                typeface: theme.typeface, accent: theme.accent, pageSize: theme.pageSize,
                density: density, scheme: theme.scheme, tint: theme.tint,
                justified: theme.justified
            )
            if try document(design: design, theme: candidate).pageCount() <= pages {
                return candidate
            }
        }
        return nil
    }

    /// The finished PDF bytes.
    ///
    /// - Parameter archival: Write as PDF/A-3, which some academic and
    ///   government applications ask for by name. Free here: the typefaces
    ///   travel with the document already, which is the requirement most
    ///   documents fail.
    public func render(
        design: DesignKind = .ledger, theme: Theme = .plain,
        archival: Bool = false, password: String = ""
    ) throws -> Data {
        try document(design: design, theme: theme)
            .render(metadata: metadata(design: design),
                    standard: archival ? .pdfA3b : .none, password: password)
    }

    /// Renders and writes to a file, returning the byte count.
    @discardableResult
    public func save(
        to url: URL, design: DesignKind = .ledger, theme: Theme = .plain
    ) throws -> Int {
        let data = try render(design: design, theme: theme)
        try data.write(to: url, options: .atomic)
        return data.count
    }

    /// Document properties.
    ///
    /// The title is what a browser tab and a recruiter's file list will show,
    /// so it carries the name — an attachment called "Document1" is a small
    /// own goal, and the default title is whatever the writer put there.
    func metadata(design: DesignKind) -> [String: String] {
        var fields = [
            "Title": profile.name.isEmpty ? "Résumé" : "\(profile.name) — \(profile.headline.isEmpty ? "CV" : profile.headline)",
            "Author": profile.name,
            "Creator": "ResumePDF",
        ]
        // Keywords are read by some tracking systems, and skills are the terms
        // being matched against.
        let terms = skills.flatMap(\.names)
        if !terms.isEmpty { fields["Keywords"] = terms.joined(separator: ", ") }
        fields["Subject"] = design.displayName
        return fields
    }
}
