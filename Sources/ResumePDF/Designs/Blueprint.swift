//
//  Blueprint.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A design described rather than written.
//
//  All twenty-four built-in designs are the same skeleton:
//
//      masthead
//      for each populated section:
//          heading
//          the entries
//          a gap
//      footer
//
//  What separates Ledger from Marker from Bulletin is not the structure but
//  a bounded set of choices about it — where the name sits and how big, what a
//  heading looks like, whether the sections sit in a full-width column or an
//  inset one with labels hung in the margin, whether anything is drawn behind
//  the text. That is a vocabulary, and a vocabulary can be data.
//
//  So a Blueprint is a design as JSON. It renders through the same components
//  the compiled designs are built from, which is what keeps it honest: a
//  blueprint cannot draw anything a design written in Swift could not, and
//  every check that reads the finished page reads a blueprint's page the same
//  way.
//
//  ## What it deliberately cannot do
//
//  There is no layout language here — no boxes, no coordinates, no expressions.
//  A general one would let somebody build a résumé that overlaps itself, and
//  the failure mode of a bad layout language is a document that renders
//  looking wrong rather than an error that says what is wrong. Composition of
//  known-good parts fails differently: every combination of these choices
//  produces a page that reads.
//
//  A second column is the one exception, and it is not hidden: a ``Side``
//  names the sections it carries, and a blueprint that has one is reported
//  by `check` as the blocker it is, because a parser reads two columns
//  interleaved. What goes in the rail is a judgement about a particular
//  document, so the designs that ship with one each make a different call.
//

import Foundation
import TextPDF

/// A design written as data.
///
/// ```swift
/// let blueprint = try Blueprint(contentsOf: url)
/// try resume.save(to: out, design: blueprint)
/// ```
///
/// Or start from one of the built-ins and change what you want:
///
/// ```swift
/// var mine = Blueprint.ledger
/// mine.heading.style = .marker
/// mine.entries.skills = .chips
/// ```
public struct Blueprint: Design, Codable, Sendable, Equatable {

    /// What this design is called, as `designs` would list it.
    public var name: String

    public var masthead: Masthead
    public var column: Column
    public var heading: Heading
    public var entries: Entries

    /// What is drawn behind the text, if anything.
    public var ornament: Ornament

    /// The space after one section's entries and before the next heading.
    public var sectionGap: Double

    /// The running foot, from the second page on.
    public var footer: Bool

    /// Sections this design draws somewhere of its own, or not at all.
    ///
    /// A design that prints the summary in its masthead puts `summary` here,
    /// or it appears twice — which is a mistake that reads as carelessness
    /// rather than as a bug.
    public var skip: [Section]

    /// Colours that override the theme's, for a design whose identity is one.
    public var palette: PaletteOverride?

    /// The family this design was drawn for.
    ///
    /// A suggestion, not a lock: a theme that names a typeface wins, because
    /// it is the caller's page. But a design whose identity is a serif gets
    /// to say so — under a theme with no preference, `broadsheet` written as
    /// data comes out in its serif rather than in the grotesque, which would
    /// be a different document.
    public var typeface: Face

    /// Settings for one section that differ from the rest.
    ///
    /// Because "chips for skills, plain lists everywhere else" is a real
    /// design decision and the built-ins make it — and a format where the
    /// only way to say it is to give up and write Swift is a format that
    /// stops one step short.
    public var sections: [Section: SectionOverride]

    /// A second column, carrying the sections it names. The one thing in
    /// this vocabulary a tracking system reads wrong — see ``Side``.
    public var side: Side?

    public init(
        name: String,
        masthead: Masthead = Masthead(),
        column: Column = Column(),
        heading: Heading = Heading(),
        entries: Entries = Entries(),
        ornament: Ornament = .none,
        sectionGap: Double = 17,
        footer: Bool = true,
        skip: [Section] = [],
        palette: PaletteOverride? = nil,
        typeface: Face = .sans,
        sections: [Section: SectionOverride] = [:],
        side: Side? = nil
    ) {
        self.name = name
        self.masthead = masthead
        self.column = column
        self.heading = heading
        self.entries = entries
        self.ornament = ornament
        self.sectionGap = sectionGap
        self.footer = footer
        self.skip = skip
        self.palette = palette
        self.typeface = typeface
        self.sections = sections
        self.side = side
    }

    /// The families a blueprint can ask for, by name.
    public enum Face: String, Codable, Sendable, CaseIterable {

        /// Inter. The default, and right for almost everything.
        case sans

        /// Source Serif 4 — academia, law, and anywhere looking current is
        /// not the point.
        case serif

        // There is no whole-document monospace here on purpose. Nine-point
        // monospaced prose is markedly harder work to read along a line, and
        // `terminal` — the design that looks like this idea — sets its
        // labels and masthead in mono and its sentences in Inter. That is
        // `monospaced` on the masthead and the heading, below.

        public var typeface: Typeface {
            switch self {
            case .sans: return .inter
            case .serif: return .sourceSerif
            }
        }
    }

    // MARK: What it declares

    /// Its own name, capitalised.
    public var displayName: String { name.capitalised }

    /// Always. There is no way to say "two columns" in this format, which is
    /// what makes it safe to hand somebody: a design written as data cannot
    /// produce a document a tracking system reads out of order.
    public var isSingleColumn: Bool { side == nil }

    /// The same design in one column, for anything that goes through a form.
    ///
    /// The side is folded into the main flow: its sections take their place
    /// in the résumé's own order, under the same headings, in the same
    /// palette, under the same masthead — so the document keeps its look
    /// and loses only the thing a parser reads wrong. Measured with PDFKit,
    /// a two-column page hands a pair of side-by-side headings back as one
    /// line; the folded page hands the sections back in order. A design
    /// with no side is already this, and comes back unchanged.
    public var singleColumn: Blueprint {
        var folded = self
        folded.side = nil
        return folded
    }

    /// Whether the masthead was told to place a portrait.
    public var showsPhoto: Bool { masthead.photo != nil }

    /// Whether the masthead was given room for a code.
    public var showsCode: Bool { masthead.qr > 0 }

    /// The family the blueprint names for itself, honoured wherever the
    /// theme states no preference.
    public var intendedTypeface: Typeface? { typeface.typeface }

    // MARK: Rendering

    public func render(_ resume: Resume, on sheet: Sheet) {
        sheet.drawing(on: palette?.resolved(on: sheet)) {
            draw(resume, on: sheet)
        }
    }

    private func draw(_ resume: Resume, on sheet: Sheet) {
        if let side {
            drawWithSide(side, resume, on: sheet)
            return
        }

        let rail = ornament == .rail
        let labelWidth = rail && column.labelWidth == 0 ? Column.railWidth : column.labelWidth
        let gutter = rail && column.gutter == 0 ? Column.railGutter : column.gutter

        let bodyX = sheet.left + labelWidth + gutter
        let bodyWidth = sheet.width - labelWidth - gutter

        // Where the head and the headings sit: past the margin like the
        // entries, or at the page's edge with only the entries inset.
        let headX = column.headAtMargin ? sheet.left : bodyX
        let headWidth = column.headAtMargin ? sheet.width : bodyWidth

        // A masthead that paints the body hands back the palette the body is
        // to be drawn in; the rest of the page is set inside it.
        let body = masthead.draw(resume, on: sheet, x: headX, width: headWidth,
                                 labelWidth: labelWidth, labelAlign: column.labelAlign)

        let shading = ornament.prepare(on: sheet)
        // Twin panels carry the summary in the masthead, so it is not a section.
        let drawn = resume.populated().filter { !skip.contains($0) && !(masthead.twin && $0 == .summary) }

        sheet.drawing(on: body) {
        for (index, section) in drawn.enumerated() {
            let local = sections[section]
            let sectionHeading = local?.heading?.applied(to: heading) ?? heading
            let sectionEntries = local?.entries?.applied(to: entries) ?? entries

            var style = sectionEntries.style(x: bodyX, width: bodyWidth)
            if ornament.insets {
                // Inset from the panel's edge, so the words are not against it.
                style.x = bodyX + Ornament.cardPadding
                style.width = bodyWidth - Ornament.cardPadding * 2
            }
            // A rail draws the dates itself. Left to the blocks as well they
            // would be printed twice, which is the more visible mistake.
            if rail { style.dates = DatePlacement.external }

            if index > 0 { sheet.gap(local?.sectionGap ?? sectionGap) }

            // A section drawn as one piece takes its heading with it to the
            // next page, rather than leaving the heading behind.
            if let whole = Blocks.wholeHeight(of: section, in: resume, style: style, on: sheet) {
                sheet.pdf.breakIfNeeded(whole + sheet.leading(sectionHeading.size) * 3)
            }

            if column.ruled {
                // Kept with what follows: a rule alone at the foot of a page
                // underlines nothing.
                sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 4)
                sheet.rule(x: bodyX, width: bodyWidth, thickness: 0.6)
                sheet.gap(11)
            }

            sectionHeading.draw(
                resume.heading(for: section),
                section: section,
                on: sheet,
                x: headX, width: headWidth,
                labelWidth: labelWidth,
                labelAlign: column.labelAlign
            )

            draw(section, of: resume, on: sheet, style: style, index: index,
                 shading: shading, bodyX: bodyX, bodyWidth: bodyWidth, labelWidth: labelWidth)
        }
        }

        if footer { sheet.footer(name: resume.profile.name, palette: body) }
    }

    // MARK: A second column

    /// The page in two columns: the side carrying the sections it names, the
    /// main column the rest — and any side section that would not fit on
    /// page one, because a rail lives on page one and the pages after it
    /// carry the main column alone.
    private func drawWithSide(_ side: Side, _ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let margin = sheet.theme.density.margin
        let pageWidth = pdf.width()
        let filled = side.fill != nil

        // Where the two columns sit. A filled rail runs from the page edge
        // and its words are inset from it; an unfilled column sits inside
        // the margins like everything else.
        let sideX: Double, sideWidth: Double, mainX: Double, mainWidth: Double
        switch (side.edge, filled) {
        case (.left, true):
            sideX = side.inset; sideWidth = side.width - side.inset * 2
            mainX = side.width + side.gutter; mainWidth = pageWidth - mainX - margin
        case (.right, true):
            sideX = pageWidth - side.width + side.inset; sideWidth = side.width - side.inset * 2
            mainX = sheet.left; mainWidth = pageWidth - side.width - side.gutter - sheet.left
        case (.left, false):
            sideX = sheet.left; sideWidth = side.width
            mainX = sheet.left + side.width + side.gutter; mainWidth = sheet.width - side.width - side.gutter
        case (.right, false):
            sideX = sheet.right - side.width; sideWidth = side.width
            mainX = sheet.left; mainWidth = sheet.width - side.width - side.gutter
        }

        // A filled rail runs the page's full height. A dark one hands back
        // the palette its words are drawn in, so the head and the sections
        // on it read under every theme — see ``Side/palette(on:)``.
        let railPalette = side.palette(on: sheet)
        if let fill = side.fill {
            let tint = fill.colour(on: sheet)
            let railX = side.edge == .left ? 0 : pageWidth - side.width
            let railWidth = side.width
            sheet.background { doc, _, _ in
                doc.rect(x: railX, y: 0, width: railWidth, height: doc.height(), color: tint)
            }
        }

        let pageTop = pdf.height() - margin
        let top: Double
        switch side.head {
        case .inside:
            top = pageTop
            sheet.drawing(on: railPalette) {
                drawRailHead(resume, on: sheet, side: side, x: sideX, width: sideWidth,
                             top: pageTop, named: true)
            }
        case .above:
            _ = masthead.draw(resume, on: sheet, x: sheet.left, width: sheet.width)
            top = pdf.cursor()
            pdf.move(to: top)
        case .main:
            // The name and the claim over the main column, where they are
            // read first; the portrait and the contact details at the head
            // of the side, which is what a rail is for.
            let y = sheet.nameplate(
                masthead.plate(resume.profile, on: sheet, ink: sheet.ink, muted: sheet.muted, fitted: false),
                x: mainX, top: pageTop, width: mainWidth
            )
            pdf.move(to: y)
            sheet.gap(masthead.gapAfter)
            top = pdf.cursor()
            pdf.move(to: pageTop)
            sheet.drawing(on: railPalette) {
                drawRailHead(resume, on: sheet, side: side, x: sideX, width: sideWidth,
                             top: pageTop, named: false)
            }
        }

        if side.divider {
            let x = side.edge == .left ? mainX - side.gutter / 2 : sideX - side.gutter / 2
            pdf.line(from: x, top, to: x, margin, color: sheet.hairline, thickness: 0.6)
        }

        // The side's sections, each measured on a scratch sheet first: one
        // that would run past page one is moved to the main column rather
        // than continued down a rail that is not there on page two.
        var moved: [Section] = []
        let sideStyle = side.entries.style(x: sideX, width: sideWidth)
        let wanted = resume.populated().filter { !skip.contains($0) }

        for section in wanted where side.sections.contains(section) {
            // The heading and the entries, on whichever sheet: measured on
            // the scratch one first, then drawn on the real one.
            func place(on target: Sheet) {
                if let whole = Blocks.wholeHeight(of: section, in: resume, style: sideStyle, on: target) {
                    target.pdf.breakIfNeeded(whole + target.leading(side.heading.size) * 3)
                }
                side.heading.draw(resume.heading(for: section), section: section, on: target,
                                  x: sideX, width: sideWidth, labelWidth: 0, labelAlign: .right)
                Blocks.render(section, of: resume, on: target, style: sideStyle)
            }

            let scratch = Sheet(theme: sheet.theme, family: sheet.family, labels: sheet.labels)
            scratch.pdf.move(to: sheet.cursor)
            place(on: scratch)

            guard scratch.pdf.pageCount() <= 1 else {
                moved.append(section)
                continue
            }

            sheet.drawing(on: railPalette) { place(on: sheet) }
            sheet.gap(13)
        }

        pdf.move(to: top)
        let mainStyle = entries.style(x: mainX, width: mainWidth)
        var index = 0
        for section in wanted where !side.sections.contains(section) || moved.contains(section) {
            if index > 0 { sheet.gap(sectionGap) }
            if let whole = Blocks.wholeHeight(of: section, in: resume, style: mainStyle, on: sheet) {
                sheet.pdf.breakIfNeeded(whole + sheet.leading(heading.size) * 3)
            }
            heading.draw(resume.heading(for: section), section: section, on: sheet,
                         x: mainX, width: mainWidth, labelWidth: 0, labelAlign: .right)
            Blocks.render(section, of: resume, on: sheet, style: mainStyle)
            index += 1
        }

        // A filled rail runs down every page, so the foot keeps to the main
        // column rather than printing its page number on the rail.
        if footer {
            sheet.footer(name: resume.profile.name,
                         x: filled ? mainX : nil, width: filled ? mainWidth : nil)
        }
    }

    /// The masthead a rail carries: a portrait, the name wrapped to the
    /// rail's width, and the contact details one per line under a label.
    /// - Parameter named: Whether the name and the claim are set here. A
    ///   split head sets them over the main column and leaves the rail the
    ///   portrait and the contact details.
    private func drawRailHead(
        _ resume: Resume, on sheet: Sheet, side: Side, x: Double, width: Double, top: Double,
        named: Bool
    ) {
        let pdf = sheet.pdf
        let profile = resume.profile
        pdf.move(to: top)

        if masthead.photo != nil, Sheet.photo(at: profile.photo) != nil {
            sheet.portrait(profile.photo, x: x, y: top - width, diameter: width)
            pdf.move(to: top - width - 16)
        }

        if named {
            sheet.paragraph(profile.name, x: x, width: width, size: 18.5, face: sheet.semibold)
            if !profile.headline.isEmpty {
                sheet.rigidGap(6)
                sheet.paragraph(profile.headline, x: x, width: width, size: 8.8, color: sheet.muted)
            }
            sheet.gap(16)
        }

        let tint = side.heading.colour.colour(on: sheet)
        let contact = profile.contactEntries()
        if !contact.isEmpty {
            sheet.sectionHeading(resume.labels.contact, x: x, width: width, style: .plain, color: tint, size: side.heading.size)
            for entry in contact {
                let lineTop = sheet.cursor
                sheet.paragraph(entry.text, x: x, width: width, size: 8.6, color: sheet.ink)
                if !entry.url.isEmpty {
                    pdf.link(entry.url, x: x, y: sheet.cursor, width: width, height: lineTop - sheet.cursor)
                }
                sheet.rigidGap(2)
            }
            sheet.gap(13)
        }

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.sectionHeading(resume.labels.details, x: x, width: width, style: .plain, color: tint, size: side.heading.size)
            for item in particulars {
                sheet.line(item.label, x: x, width: width, size: 7.8, face: sheet.regular, color: sheet.muted)
                sheet.paragraph(item.value, x: x, width: width, size: 8.6)
                sheet.rigidGap(3)
            }
            sheet.gap(13)
        }
    }

    /// One section's entries, however this design treats them.
    private func draw(
        _ section: Section, of resume: Resume, on sheet: Sheet, style: Blocks.Style,
        index: Int, shading: Shading?, bodyX: Double, bodyWidth: Double, labelWidth: Double
    ) {
        switch ornament {
        case .entryCards:
            // A panel around each entry rather than around the section. The
            // gap after one has to clear both panels' padding, or the
            // rectangles overlap and three entries read as one long box.
            let padding = Ornament.cardPadding
            for entry in Blocks.entriesOrWhole(of: section, in: resume) {
                let page = sheet.pdf.pageCount()
                let top = sheet.cursor
                sheet.pdf.gap(padding + 2)

                sheet.drawing(on: .against(sheet.wash, accent: sheet.theme.accentColor)) {
                    entry.draw(sheet, style)
                }

                if sheet.pdf.pageCount() == page {
                    shading?.add(page: page, x: bodyX, width: bodyWidth,
                                 top: top, bottom: sheet.cursor - padding + 4)
                }
                // The next panel starts at the cursor: clear this one's bottom
                // padding with daylight to spare, or neighbouring cards touch
                // and a drawn edge turns them into one long smear of boxes.
                sheet.gap(15)
            }

        case .rail:
            guard let entries = Blocks.entries(of: section, in: resume),
                  entries.contains(where: { !$0.dates.isEmpty })
            else {
                // A skills list given a rail is a hundred points of white down
                // the left of it.
                Blocks.render(section, of: resume, on: sheet, style: style)
                return
            }

            for (position, entry) in entries.enumerated() {
                if position > 0 { sheet.gap(style.entryGap) }
                Blocks.railed(entry, on: sheet, style: style, labels: resume.labels,
                              railX: sheet.left, railWidth: labelWidth,
                              gutter: bodyX - sheet.left - labelWidth)
            }

        case .tabs:
            // The bar runs from just above the entries to just below them,
            // and only when the section stayed on one page: a bar whose ends
            // are on different sheets of paper is not a bar.
            let pdf = sheet.pdf
            let page = pdf.pageCount()
            let top = pdf.cursor() + 16
            Blocks.render(section, of: resume, on: sheet, style: style)
            if pdf.pageCount() == page {
                pdf.rect(x: sheet.left, y: pdf.cursor() + 4, width: labelWidth,
                         height: top - pdf.cursor() - 4, color: sheet.accent)
            }

        case .none, .bands, .cards:
            ornament.wrap(index: index, on: sheet, shading: shading,
                          x: sheet.left, width: sheet.width) {
                Blocks.render(section, of: resume, on: sheet, style: style)
            }
        }
    }

}
