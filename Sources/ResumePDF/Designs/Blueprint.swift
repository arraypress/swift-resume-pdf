//
//  Blueprint.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A design described rather than written.
//
//  All fourteen built-in designs are the same skeleton:
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
//  Two-column designs are not expressible for the same reason ``Sidebar`` is
//  the one design that blocks: the interesting decision there is what goes in
//  the rail, which is a judgement about a particular document rather than a
//  setting.
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

    // MARK: Reading one

    /// Reads a blueprint from a JSON file.
    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Blueprint.self, from: data)
    }

    /// Writes it back out, formatted to be edited by hand.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    // MARK: What it declares

    /// Its own name, as given.
    public var displayName: String { name.prefix(1).uppercased() + name.dropFirst() }

    /// Always. There is no way to say "two columns" in this format, which is
    /// what makes it safe to hand somebody: a design written as data cannot
    /// produce a document a tracking system reads out of order.
    public var isSingleColumn: Bool { side == nil }

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
            drawRailHead(resume, on: sheet, side: side, x: sideX, width: sideWidth, top: pageTop)
        case .above:
            _ = masthead.draw(resume, on: sheet, x: sheet.left, width: sheet.width)
            top = pdf.cursor()
            pdf.move(to: top)
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
            let scratch = Sheet(theme: sheet.theme, family: sheet.family, labels: sheet.labels)
            scratch.pdf.move(to: sheet.cursor)
            side.heading.draw(resume.heading(for: section), section: section, on: scratch,
                              x: sideX, width: sideWidth, labelWidth: 0, labelAlign: .right)
            Blocks.render(section, of: resume, on: scratch, style: sideStyle)

            guard scratch.pdf.pageCount() <= 1 else {
                moved.append(section)
                continue
            }

            side.heading.draw(resume.heading(for: section), section: section, on: sheet,
                              x: sideX, width: sideWidth, labelWidth: 0, labelAlign: .right)
            Blocks.render(section, of: resume, on: sheet, style: sideStyle)
            sheet.gap(13)
        }

        pdf.move(to: top)
        let mainStyle = entries.style(x: mainX, width: mainWidth)
        var index = 0
        for section in wanted where !side.sections.contains(section) || moved.contains(section) {
            if index > 0 { sheet.gap(sectionGap) }
            heading.draw(resume.heading(for: section), section: section, on: sheet,
                         x: mainX, width: mainWidth, labelWidth: 0, labelAlign: .right)
            Blocks.render(section, of: resume, on: sheet, style: mainStyle)
            index += 1
        }

        if footer { sheet.footer(name: resume.profile.name) }
    }

    /// The masthead a rail carries: a portrait, the name wrapped to the
    /// rail's width, and the contact details one per line under a label.
    private func drawRailHead(
        _ resume: Resume, on sheet: Sheet, side: Side, x: Double, width: Double, top: Double
    ) {
        let pdf = sheet.pdf
        let profile = resume.profile
        pdf.move(to: top)

        if masthead.photo != nil, Sheet.photo(at: profile.photo) != nil {
            sheet.portrait(profile.photo, x: x, y: top - width, diameter: width)
            pdf.move(to: top - width - 16)
        }

        sheet.paragraph(profile.name, x: x, width: width, size: 18.5, face: sheet.semibold)
        if !profile.headline.isEmpty {
            sheet.rigidGap(6)
            sheet.paragraph(profile.headline, x: x, width: width, size: 8.8, color: sheet.muted)
        }
        sheet.gap(16)

        let tint = side.heading.colour.colour(on: sheet)
        let contact = profile.contactEntries()
        if !contact.isEmpty {
            sheet.sectionHeading("Contact", x: x, width: width, style: .plain, color: tint, size: side.heading.size)
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
            sheet.sectionHeading("Details", x: x, width: width, style: .plain, color: tint, size: side.heading.size)
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

// MARK: - The name at the top

extension Blueprint {

    /// The name, the claim, and how to reach them.
    public struct Masthead: Codable, Sendable, Equatable {

        public var align: Alignment
        public var nameSize: Double
        public var uppercase: Bool

        /// Letter spacing for the name, in points. Negative closes it up,
        /// which is what makes a name look set rather than typed.
        public var tracking: Double

        public var headlineSize: Double
        public var headlineColour: Paint
        public var contactSize: Double

        /// A filled band behind the masthead, as Banner and Nocturne have.
        public var panel: Panel?

        /// A round portrait. Only drawn when the profile carries one.
        public var photo: Photo?

        /// A scannable code against the right edge, in points. Zero for none.
        ///
        /// Only drawn where the profile carries one, and the name is measured
        /// against what is left rather than against the page.
        public var qr: Double

        /// A rule under the whole thing.
        public var rule: Rule?

        /// Set the name, headline and contact details in the monospace.
        ///
        /// Contact details are addresses, which is data — so they are also
        /// stacked one per line rather than flowed, because a column of them
        /// is easier to copy from than a paragraph.
        public var monospaced: Bool

        /// Space between the masthead and the first heading.
        public var gapAfter: Double

        /// The weight the name is set in. Regular with tracking is how a
        /// serif masthead reads as considered rather than loud.
        public var nameWeight: Weight

        /// The name's colour. `accent` is the one place a colour can carry a
        /// whole page; on a monochrome theme it falls back to the ink.
        public var nameColour: Paint

        /// The headline in the italic, where the family has one.
        public var headlineItalic: Bool

        /// What sits between the contact details. A mono masthead uses a
        /// pipe whatever this says, because that is what a status line uses.
        public var separator: String

        /// How the contact details are set: flowed under the headline, or as
        /// a ruled row with "Contact" hung in the margin — which wants a
        /// column with a margin to hang it in, and flows without one.
        public var contacts: Contacts

        /// Two panels under the name — the summary on a washed one, the
        /// contact details with their marks on a dark one — in place of the
        /// contact line. The summary is then not drawn as a section.
        public var twin: Bool

        /// The page below the masthead painted this colour, with every
        /// block drawn in a palette derived from it. `inverse` is the page
        /// reversed; `dark` is near-black whatever the theme.
        public var body: Paint?

        /// The masthead's own colour when the body is painted. Nil keeps
        /// the page's, so the head is the one light thing on a dark page.
        public var band: Paint?

        public enum Weight: String, Codable, Sendable, CaseIterable {
            case regular, semibold
        }

        public enum Contacts: String, Codable, Sendable, CaseIterable {
            case flow, labelled
        }

        public init(
            align: Alignment = .left,
            nameSize: Double = 25.5,
            uppercase: Bool = false,
            tracking: Double = -0.4,
            headlineSize: Double = 10.8,
            headlineColour: Paint = .accent,
            contactSize: Double = 8.7,
            panel: Panel? = nil,
            photo: Photo? = nil,
            qr: Double = 0,
            rule: Rule? = Rule(),
            monospaced: Bool = false,
            gapAfter: Double = 19,
            nameWeight: Weight = .semibold,
            nameColour: Paint = .ink,
            headlineItalic: Bool = false,
            separator: String = "·",
            contacts: Contacts = .flow,
            twin: Bool = false,
            body: Paint? = nil,
            band: Paint? = nil
        ) {
            self.align = align
            self.nameSize = nameSize
            self.uppercase = uppercase
            self.tracking = tracking
            self.headlineSize = headlineSize
            self.headlineColour = headlineColour
            self.contactSize = contactSize
            self.panel = panel
            self.photo = photo
            self.qr = qr
            self.rule = rule
            self.monospaced = monospaced
            self.gapAfter = gapAfter
            self.nameWeight = nameWeight
            self.nameColour = nameColour
            self.headlineItalic = headlineItalic
            self.separator = separator
            self.contacts = contacts
            self.twin = twin
            self.body = body
            self.band = band
        }

        /// Draws the masthead and leaves the cursor where the sections start.
        /// - Parameter labelWidth: The margin column's width, for a labelled
        ///   contact row to hang its label in. Zero when there is no margin.
        /// - Returns: The palette the body is to be drawn in, when the
        ///   masthead painted one; nil when the page is the page.
        @discardableResult
        func draw(
            _ resume: Resume, on sheet: Sheet, x: Double, width: Double,
            labelWidth: Double = 0, labelAlign: Alignment = .right
        ) -> Sheet.Palette? {
            guard let body else {
                _ = head(resume, on: sheet, x: x, width: width,
                         labelWidth: labelWidth, labelAlign: labelAlign, banded: false)
                return nil
            }

            // The body is painted behind everything below the band, on every
            // page; the band keeps the page's colour unless told otherwise.
            // Palettes are derived from the fills, so every block reads.
            let pdf = sheet.pdf
            let bodyFill = body.colour(on: sheet)
            let bodyPalette = Sheet.Palette.against(bodyFill, accent: sheet.theme.accentColor)
            let bandFill = band?.colour(on: sheet)
            let bandPalette = bandFill.map { Sheet.Palette.against($0, accent: sheet.theme.accentColor) }

            var bandBottom = 0.0
            sheet.drawing(on: bandPalette) {
                bandBottom = head(resume, on: sheet, x: x, width: width,
                                  labelWidth: labelWidth, labelAlign: labelAlign, banded: true)
            }

            sheet.background { doc, page, _ in
                let height = page == 1 ? bandBottom : doc.height()
                doc.rect(x: 0, y: 0, width: doc.width(), height: height, color: bodyFill)
                if page == 1, let bandFill {
                    doc.rect(x: 0, y: bandBottom, width: doc.width(),
                             height: doc.height() - bandBottom, color: bandFill)
                }
            }

            // A hairline of accent under the band, which is what makes the
            // split look intended rather than like a printing fault.
            pdf.rect(x: 0, y: bandBottom - 2.4, width: pdf.width(), height: 2.4, color: bodyPalette.accent)
            pdf.move(to: bandBottom - 30)
            return bodyPalette
        }

        /// The head itself. Returns the band's bottom when banded, else the
        /// cursor after the gap.
        private func head(
            _ resume: Resume, on sheet: Sheet, x: Double, width: Double,
            labelWidth: Double, labelAlign: Alignment, banded: Bool
        ) -> Double {
            let pdf = sheet.pdf
            let profile = resume.profile
            let carriesPhoto = photo != nil && Sheet.photo(at: profile.photo) != nil

            // A panel is painted first and the type reversed out of it, so the
            // colours below are asked of the panel rather than the page.
            let painted = panel?.draw(on: sheet, hasPhoto: carriesPhoto)
            let panelHeight = painted?.height
            let ink = painted?.palette.ink ?? sheet.ink
            let mutedInk = painted?.palette.muted ?? sheet.muted

            // Inside a panel the name sits about a third of the way down,
            // which leaves room for the contact line under it and keeps the
            // band from reading as an empty stripe with a name at the bottom.
            var top = panelHeight.map { pdf.height() - $0 * 0.30 + nameSize * 0.86 }
                ?? (pdf.height() - sheet.theme.density.margin)

            var textX = x
            var textWidth = width

            // The code takes the right of the masthead. Drawn first, because
            // the name is set to whatever is left rather than to the page.
            let coded = qr > 0 && sheet.code(profile.qr, x: x + width - qr, y: top - qr, size: qr)
            if coded { textWidth -= qr + 20 }

            // The portrait takes its side of the masthead, and the type takes
            // the rest — otherwise a long headline runs under the face.
            if let photo, carriesPhoto {
                let diameter = photo.diameter

                // A right-aligned portrait and a code both claim the right
                // edge, and the code got there first — so the portrait
                // crosses to the left rather than being drawn through it.
                let align = photo.align == .right && coded ? Alignment.left : photo.align

                switch align {
                case .centre:
                    // Centred above the name, the way a centred masthead
                    // carries one — everything under it moves down to make
                    // the room, and the type keeps the whole measure.
                    _ = sheet.portrait(profile.photo, x: x + (width - diameter) / 2,
                                       y: top - diameter + nameSize * 0.4, diameter: diameter)
                    top -= diameter + 14

                case .right:
                    _ = sheet.portrait(profile.photo, x: x + width - diameter,
                                       y: top - diameter + nameSize * 0.4, diameter: diameter)
                    textWidth -= diameter + 18

                case .left:
                    _ = sheet.portrait(profile.photo, x: x,
                                       y: top - diameter + nameSize * 0.4, diameter: diameter)
                    textX += diameter + 18
                    textWidth -= diameter + 18
                }
            }

            let regular = nameWeight == .regular ? sheet.regular : sheet.semibold
            let heavy = monospaced ? (sheet.monoBold ?? sheet.semibold) : regular
            let plain = monospaced ? (sheet.mono ?? sheet.regular) : sheet.regular

            // The accent is only a colour for the name where there is one;
            // on a monochrome theme it is the ink under another name.
            let nameTint = nameColour == .ink || (sheet.theme.isMonochrome && nameColour == .accent)
                ? ink
                : nameColour.colour(on: sheet, fallback: ink)

            let label = uppercase ? profile.name.uppercased() : profile.name
            // Beside a code the name is set to what is left, not to the page.
            let fitted = coded ? pdf.fit(label, into: textWidth, size: nameSize, face: heavy) : label
            pdf.textAt(fitted, x: textX, y: top - nameSize * 0.86, size: nameSize,
                       color: nameTint, align: align.textAlign, boxWidth: textWidth,
                       face: heavy, tracking: tracking)

            // A signature rule: as wide as the name and right under it, the
            // way a name is ruled on printed stationery.
            if let rule, rule.underName {
                let measured = pdf.width(of: fitted, size: nameSize, face: heavy, tracking: tracking)
                let startX: Double
                switch align {
                case .left: startX = textX
                case .centre: startX = textX + (textWidth - measured) / 2
                case .right: startX = textX + textWidth - measured
                }
                pdf.rect(x: startX, y: top - nameSize * 0.86 - nameSize * 0.3,
                         width: measured, height: rule.thickness, color: rule.colour.colour(on: sheet))
            }

            var y = top - nameSize * 0.86 - nameSize * 0.72

            if !profile.headline.isEmpty {
                let tint = sheet.theme.isMonochrome && headlineColour == .accent
                    ? mutedInk
                    : headlineColour.colour(on: sheet, fallback: ink)
                let face = headlineItalic ? (sheet.italic ?? plain) : plain
                pdf.textAt(profile.headline, x: textX, y: y, size: headlineSize,
                           color: tint, align: align.textAlign, boxWidth: textWidth,
                           face: face)
                y -= headlineSize * 1.6
            }

            pdf.move(to: y)

            if twin {
                twinPanels(resume, on: sheet, x: textX, width: textWidth, top: top)
                return pdf.cursor()
            }

            let particulars = profile.particulars().map { "\($0.label): \($0.value)" }
            let between = monospaced ? "|" : separator

            if contacts == .labelled, labelWidth > 0 {
                // A ruled row each, with the word hung in the margin the way
                // the section names are — so the contact details read as the
                // first section rather than as part of the name.
                pdf.move(to: y - 8)
                let entries = profile.contactEntries()
                if !entries.isEmpty {
                    sheet.rule(x: textX, width: textWidth, thickness: 0.6)
                    sheet.gap(11)
                    hang("Contact", on: sheet, labelWidth: labelWidth, align: labelAlign, color: mutedInk)
                    sheet.contactFlow(entries, x: textX, width: textWidth,
                                      size: contactSize, color: mutedInk, separator: between, face: plain)
                }
                if !particulars.isEmpty {
                    sheet.gap(13)
                    sheet.rule(x: textX, width: textWidth, thickness: 0.6)
                    sheet.gap(11)
                    hang("Details", on: sheet, labelWidth: labelWidth, align: labelAlign, color: mutedInk)
                    sheet.contactFlow(particulars, x: textX, width: textWidth,
                                      size: contactSize - 0.3, color: mutedInk, separator: between, face: plain)
                }
            } else {
                // Flowed either way; a mono masthead sets them in mono with a
                // pipe between, the way a status line is printed.
                sheet.contactFlow(profile.contactEntries(), x: textX, width: textWidth,
                                  size: contactSize, color: mutedInk, align: align.textAlign,
                                  separator: between, face: plain)
                if !particulars.isEmpty {
                    sheet.contactFlow(particulars, x: textX, width: textWidth,
                                      size: contactSize - 0.3, color: mutedInk, align: align.textAlign,
                                      separator: between, face: plain)
                }
            }

            // Inside a band the head is done: the caller paints under it.
            if banded { return pdf.cursor() - 14 }

            if let panelHeight {
                pdf.move(to: pdf.height() - panelHeight - 30)
            } else if let rule, !rule.underName {
                sheet.rigidGap(5)
                let span = rule.width > 0 ? rule.width : width
                sheet.rule(x: x, width: span, color: rule.colour.colour(on: sheet),
                           thickness: rule.thickness)
                if rule.double {
                    // A heavy rule and a hairline under it: the pair a
                    // broadsheet's masthead is cut off with.
                    sheet.rigidGap(2.6)
                    sheet.rule(x: x, width: span, color: sheet.hairline, thickness: 0.5)
                }
            }

            sheet.gap(gapAfter)
            return pdf.cursor()
        }

        /// The summary on a washed panel and the contact details on a dark
        /// one, side by side under the name, each entry with its mark.
        private func twinPanels(_ resume: Resume, on sheet: Sheet, x: Double, width: Double, top: Double) {
            let pdf = sheet.pdf
            let entries = Self.marked(resume.profile)
            let panelTop = top - 58
            let gutter = 16.0
            let rightWidth = min(232.0, width * 0.44)
            let leftWidth = width - rightWidth - gutter
            let padding = 15.0

            let summaryHeight = resume.summary.isEmpty ? 0 : pdf.blockHeight(
                resume.summary, size: 9.2, width: leftWidth - padding * 2,
                leading: sheet.leading(9.2), face: sheet.regular
            )
            let contactHeight = Double(entries.count) * 19
            let height = max(summaryHeight, contactHeight) + padding * 2

            let darkFill = sheet.theme.scheme == .dark
                ? sheet.theme.page.lightened(by: 0.12)
                : sheet.accentPanel
            let dark = Sheet.Palette.against(darkFill, accent: sheet.theme.accentColor)

            if !resume.summary.isEmpty {
                pdf.roundedRect(x: x, y: panelTop - height, width: leftWidth,
                                height: height, radius: 8, color: sheet.wash)
                pdf.move(to: panelTop - padding)
                sheet.paragraph(resume.summary, x: x + padding, width: leftWidth - padding * 2, size: 9.2)
            }

            pdf.roundedRect(x: x + leftWidth + gutter, y: panelTop - height,
                            width: rightWidth, height: height, radius: 8, color: darkFill)

            let originX = x + leftWidth + gutter + padding
            for (index, entry) in entries.enumerated() {
                let baseline = panelTop - padding - Double(index) * 19
                sheet.icon(entry.icon, x: originX, y: baseline - 11.5, size: 12, color: dark.accent)
                if entry.url.isEmpty {
                    pdf.textAt(entry.text, x: originX + 18, y: baseline - 9.6, size: 8.8,
                               color: dark.ink, face: sheet.regular)
                } else {
                    pdf.linked(entry.text, url: entry.url, x: originX + 18, y: baseline - 9.6,
                               size: 8.8, color: dark.ink, face: sheet.regular)
                }
            }

            pdf.move(to: panelTop - height)
            sheet.gap(22)
        }

        /// The contact details, each with the mark that says what it is.
        private static func marked(_ profile: Profile) -> [(icon: Icon, text: String, url: String)] {
            profile.contactEntries().map { entry in
                let icon: Icon
                if entry.url.hasPrefix("mailto:") { icon = .email }
                else if entry.url.hasPrefix("tel:") { icon = .phone }
                else if entry.url.isEmpty { icon = .location }
                else { icon = .link }
                return (icon, entry.text, entry.url)
            }
        }

        /// A word in the margin, level with what follows it.
        private func hang(
            _ word: String, on sheet: Sheet, labelWidth: Double, align: Alignment, color: Color
        ) {
            let pdf = sheet.pdf
            let top = pdf.cursor()
            pdf.cell(word, x: sheet.left, boxWidth: labelWidth, size: 8.6,
                     color: color, align: align.textAlign, face: sheet.medium)
            pdf.move(to: top)
        }
    }

    /// One entry per line, linked where it has somewhere to go.
    /// A filled band behind the masthead.
    ///
    /// The type on it is *not* a setting. Reversing white out of a pale accent
    /// is the commonest fault in this shape of design, and it is a fault a
    /// blueprint author cannot see until they render it under somebody else's
    /// accent — so the ink is derived from the fill, the same way the compiled
    /// designs derive it.
    public struct Panel: Codable, Sendable, Equatable {

        public var fill: Paint

        /// How tall, before allowing for a portrait.
        public var height: Double

        /// How far the bottom edge rises at the sides, in points. Zero is a
        /// straight cut; anything larger gives the shallow V the plaqued blueprint has.
        public var dip: Double

        public init(fill: Paint = .accent, height: Double = 172, dip: Double = 26) {
            self.fill = fill
            self.height = height
            self.dip = dip
        }

        /// Paints it and returns how tall it is, and what reads on it.
        func draw(on sheet: Sheet, hasPhoto: Bool) -> (height: Double, palette: Sheet.Palette) {
            let pdf = sheet.pdf
            let panelHeight = hasPhoto ? height + 36 : height
            let top = pdf.height()
            let bottom = top - panelHeight

            // Filled where the colour can carry reversed type, washed where it
            // cannot — asked of the colour rather than assumed.
            let asked = fill.colour(on: sheet)
            let tint = fill == .accent && !(sheet.theme.accentIsDark && !sheet.theme.isMonochrome)
                ? sheet.wash
                : asked

            if dip > 0 {
                pdf.polygon([
                    (x: 0, y: top),
                    (x: pdf.width(), y: top),
                    (x: pdf.width(), y: bottom + dip),
                    (x: pdf.width() / 2, y: bottom),
                    (x: 0, y: bottom + dip),
                ], color: tint)
            } else {
                pdf.rect(x: 0, y: bottom, width: pdf.width(), height: panelHeight, color: tint)
            }

            return (panelHeight, Sheet.Palette.against(tint, accent: sheet.theme.accentColor))
        }
    }

    /// A round portrait in the masthead.
    public struct Photo: Codable, Sendable, Equatable {

        public var diameter: Double
        public var align: Alignment

        public init(diameter: Double = 66, align: Alignment = .right) {
            self.diameter = diameter
            self.align = align
        }
    }

    /// A ruled line.
    public struct Rule: Codable, Sendable, Equatable {

        public var colour: Paint
        public var thickness: Double

        /// A hairline under the rule as well, the way a broadsheet cuts its
        /// masthead off.
        public var double: Bool

        /// How far it runs, in points. Zero is the whole column.
        public var width: Double

        /// Under the name and as wide as it, rather than across the column
        /// under the contact details.
        public var underName: Bool

        public init(
            colour: Paint = .ink, thickness: Double = 0.9,
            double: Bool = false, width: Double = 0, underName: Bool = false
        ) {
            self.colour = colour
            self.thickness = thickness
            self.double = double
            self.width = width
            self.underName = underName
        }
    }
}

// MARK: - The column

extension Blueprint {

    /// Where the text sits, and what is beside it.
    ///
    /// `labelWidth` of zero is a full-width column — the usual case. Anything
    /// larger insets the text and leaves that much room to its left for
    /// section labels, which is how Margin and Timeline are laid
    /// out. It is still one column in reading order.
    public struct Column: Codable, Sendable, Equatable {

        /// What a rail takes when the design did not say.
        static let railWidth = 96.0
        static let railGutter = 16.0

        public var labelWidth: Double
        public var gutter: Double
        public var labelAlign: Alignment

        /// The masthead and the headings start at the page margin, and only
        /// the entries sit past the rail — the shape of a timeline, where
        /// the rail belongs to the entries and not to the page.
        public var headAtMargin: Bool

        /// A hairline across the body above every section.
        public var ruled: Bool

        public init(
            labelWidth: Double = 0, gutter: Double = 0, labelAlign: Alignment = .right,
            headAtMargin: Bool = false, ruled: Bool = false
        ) {
            self.labelWidth = labelWidth
            self.gutter = gutter
            self.labelAlign = labelAlign
            self.headAtMargin = headAtMargin
            self.ruled = ruled
        }
    }
}

// MARK: - A second column

extension Blueprint {

    /// A second column, carrying the sections it names.
    ///
    /// The one thing in this vocabulary a tracking system reads wrong: the
    /// parser extracts the text in order and does not know the column is a
    /// column, so the rail comes out interleaved with the experience — a
    /// phone number in the middle of an employment history. A blueprint
    /// with a side is therefore not ``isSingleColumn``, and `check` reports
    /// it as the blocker it is. It exists for the document a person will
    /// open, and says so.
    public struct Side: Codable, Sendable, Equatable {

        /// The column's width in points, from the page edge when filled.
        public var width: Double
        public var edge: Edge

        /// The sections it carries. The rest go in the main column, as does
        /// any of these that would not fit on page one.
        public var sections: [Section]

        /// A tint behind it, running the page's full height. `rail` is the
        /// theme's accent lightened to a wash. Nil is no tint.
        public var fill: Paint?

        /// A hairline between the columns.
        public var divider: Bool

        /// How far the words sit in from the filled edge.
        public var inset: Double

        /// The space between the columns.
        public var gutter: Double

        /// Where the masthead goes: inside the column, stacked to its width
        /// with the contact details one per line; or above both columns,
        /// set by ``Masthead``.
        public var head: Head

        public var heading: Heading
        public var entries: Entries

        public enum Edge: String, Codable, Sendable, CaseIterable { case left, right }
        public enum Head: String, Codable, Sendable, CaseIterable { case inside, above }

        public init(
            width: Double = 190,
            edge: Edge = .left,
            sections: [Section] = [.skills, .languages, .education, .certifications, .interests],
            fill: Paint? = .rail,
            divider: Bool = false,
            inset: Double = 27,
            gutter: Double = 30,
            head: Head = .inside,
            heading: Heading = Heading(style: .plain, size: 7.4, colour: .accent),
            entries: Entries = Entries(dates: .beneath, roleSize: 9.6, bodySize: 8.7,
                                       detailSize: 8.6, dateSize: 8, entryGap: 10)
        ) {
            self.width = width
            self.edge = edge
            self.sections = sections
            self.fill = fill
            self.divider = divider
            self.inset = inset
            self.gutter = gutter
            self.head = head
            self.heading = heading
            self.entries = entries
        }
    }
}

// MARK: - Headings

extension Blueprint {

    /// How a section announces itself.
    public struct Heading: Codable, Sendable, Equatable {

        public var style: Style
        public var size: Double
        public var colour: Paint

        /// A small mark beside the heading, from the built-in set.
        public var icon: Bool

        public init(
            style: Style = .ruled,
            size: Double = 7.6,
            colour: Paint = .muted,
            icon: Bool = false
        ) {
            self.style = style
            self.size = size
            self.colour = colour
            self.icon = icon
        }

        /// The treatments, which are the ones the built-in designs use.
        public enum Style: String, Codable, Sendable, CaseIterable {

            /// A rule across the column, under the words.
            case ruled

            /// Nothing but the words.
            case plain

            /// A short bar in the accent colour, beside them.
            case accentBar

            /// Centred, with a rule either side.
            case centred

            /// A rounded tab behind them.
            case tab

            /// A highlighter swipe behind them, ending part-way.
            case marker

            /// Hung in the margin beside the text, which needs a `column`
            /// with room for it.
            case margin

            /// A label with a rule running out from it to the right margin.
            /// Set in the monospace, which is the point of it.
            case terminal

            /// The label with a short accent stub under it: the band's echo,
            /// for a page whose one strong horizontal is a masthead band.
            case underlined
        }

        func draw(
            _ title: String, section: Section, on sheet: Sheet,
            x: Double, width: Double, labelWidth: Double, labelAlign: Alignment
        ) {
            let tint = colour.colour(on: sheet)

            switch style {
            case .ruled, .plain, .accentBar, .centred:
                sheet.sectionHeading(title, x: x, width: width,
                                     style: style.builtIn, color: tint, size: size)
                if icon {
                    sheet.icon(Icon.of(section), x: x - size - 8,
                               y: sheet.cursor + size * 2.2, size: size + 3, color: sheet.accent)
                }

            case .tab:
                drawTab(title, section: section, on: sheet, x: x)

            case .marker:
                drawMarker(title, on: sheet, x: x)

            case .margin:
                drawMargin(title, section: section, on: sheet,
                           x: x, labelWidth: labelWidth, labelAlign: labelAlign)

            case .terminal:
                drawTerminal(title, on: sheet, x: x, width: width)

            case .underlined:
                drawUnderlined(title, on: sheet, x: x)
            }
        }

        /// A section label with a short accent underline.
        ///
        /// A stub of ink under the label, not a rule across the column: a
        /// masthead band has already drawn the page's one strong horizontal,
        /// and a second full-width line would compete with it.
        private func drawUnderlined(_ title: String, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()

            // Kept with the first entry of what follows — see `sectionHeading`.
            pdf.breakIfNeeded(sheet.leading(size) + 64)
            let top = pdf.cursor()

            pdf.textAt(label, x: x, y: top - 8, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: size * 0.14)
            pdf.rect(x: x, y: top - 14.6, width: 22, height: 2.2, color: sheet.accent)

            pdf.move(to: top - 16)
            sheet.gap(11)
        }

        /// A prompt, a mono label, and a rule running out from it to the margin.
        private func drawTerminal(_ title: String, on sheet: Sheet, x: Double, width: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()
            let tracking = size * 0.1
            let face = sheet.monoMedium ?? sheet.medium

            pdf.breakIfNeeded(sheet.leading(size) + 62)
            let baseline = pdf.cursor()

            // Drawn, not typed — see `Sheet.prompt`.
            sheet.prompt(x: x, y: baseline - size * 0.62, size: size,
                         color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent)
            let labelX = x + size * 1.3

            pdf.textAt(label, x: labelX, y: baseline - size, size: size,
                       color: colour.colour(on: sheet), face: face, tracking: tracking)

            // The rule starts where the label ends rather than under it, so
            // the two read as one object. Measured with the face that drew it,
            // which is the only reason the gap is right.
            let measured = pdf.width(of: label, size: size, face: face, tracking: tracking)
            let from = labelX + measured + 12
            if from < x + width - 20 {
                pdf.line(from: from, baseline - size * 0.6, to: x + width, baseline - size * 0.6,
                         color: sheet.hairline, thickness: 0.7)
            }

            pdf.move(to: baseline - size * 1.45)
            sheet.gap(11)
        }

        /// A rounded tab, with the mark inside it.
        private func drawTab(_ title: String, section: Section, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let height = size * 2.6
            let badge = height - 1
            let label = title.uppercased()
            let tracking = size * 0.14

            pdf.breakIfNeeded(height + 66)

            let top = pdf.cursor()
            let bottom = top - height
            let textWidth = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)

            // The badge sits inside the tab's rounded end, concentric with it
            // — see Bulletin.
            let textX = x + height + 6
            pdf.roundedRect(x: x, y: bottom, width: textX - x + textWidth + 13,
                            height: height, radius: height / 2, color: sheet.wash)

            if icon {
                // Filled where the accent can carry a reversed mark, outlined
                // where it cannot — the same choice the panel makes, for the
                // same reason.
                let centreX = x + height / 2
                let centreY = bottom + height / 2
                let mark = badge * 0.55
                let filled = sheet.theme.accentIsDark && !sheet.theme.isMonochrome

                if filled {
                    pdf.circle(x: centreX, y: centreY, radius: badge / 2, color: sheet.accent)
                } else {
                    pdf.ring(x: centreX, y: centreY, radius: badge / 2 - 0.5,
                             thickness: 1.1, color: sheet.accent)
                }

                sheet.icon(Icon.of(section), x: centreX - mark / 2, y: centreY - mark / 2,
                           size: mark, color: filled ? sheet.theme.page : sheet.accent)
            }

            pdf.textAt(label, x: textX, y: bottom + height * 0.35, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: tracking)

            pdf.move(to: bottom - 10)
        }

        /// A highlighter swipe across the words, a little past each end.
        private func drawMarker(_ title: String, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()
            let tracking = size * 0.05

            pdf.breakIfNeeded(size * 3 + 52)

            let top = pdf.cursor()
            let measured = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)
            let swipe = sheet.theme.isMonochrome
                ? sheet.theme.wash.darkened(by: 0.06)
                : sheet.accent.lightened(by: 0.62)

            pdf.rect(x: x - 4, y: top - size * 1.12, width: measured + 8,
                     height: size * 1.05, color: swipe)
            pdf.textAt(label, x: x, y: top - size * 0.92, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: tracking)

            pdf.move(to: top - size * 1.9)
        }

        /// The name hung in the margin, level with the text it labels.
        private func drawMargin(
            _ title: String, section: Section, on sheet: Sheet,
            x: Double, labelWidth: Double, labelAlign: Alignment
        ) {
            let pdf = sheet.pdf
            pdf.breakIfNeeded(size * 6)

            let top = pdf.cursor()
            let boxWidth = max(20, labelWidth - (icon ? 20 : 0))

            if icon {
                sheet.icon(Icon.of(section), x: sheet.left + labelWidth - 13,
                           y: top - 12, size: 13, color: sheet.accent)
            }

            pdf.cell(title, x: sheet.left, boxWidth: boxWidth, size: size + 1,
                     color: colour.colour(on: sheet), align: labelAlign.textAlign,
                     face: sheet.medium)

            // The cursor does not move: the label sits beside the entries
            // rather than above them, which is the whole point of hanging it.
            pdf.move(to: top)
        }
    }
}

extension Blueprint.Heading.Style {

    /// The four that map onto the built-in heading treatments.
    var builtIn: HeadingStyle {
        switch self {
        case .plain: return .plain
        case .accentBar: return .accentBar
        case .centred: return .centred
        case .ruled, .tab, .marker, .margin, .terminal, .underlined: return .ruled
        }
    }
}

// MARK: - Entries

extension Blueprint {

    /// How the entries under a heading are set.
    public struct Entries: Codable, Sendable, Equatable {

        public var dates: Dates
        public var roleSize: Double
        public var bodySize: Double
        public var detailSize: Double
        public var dateSize: Double
        public var entryGap: Double
        public var accentRoles: Bool
        public var skills: Skills

        public init(
            dates: Dates = .besideTitle,
            roleSize: Double = 10.4,
            bodySize: Double = 9.4,
            detailSize: Double = 9.2,
            dateSize: Double = 8.5,
            entryGap: Double = 13,
            accentRoles: Bool = false,
            skills: Skills = .list
        ) {
            self.dates = dates
            self.roleSize = roleSize
            self.bodySize = bodySize
            self.detailSize = detailSize
            self.dateSize = dateSize
            self.entryGap = entryGap
            self.accentRoles = accentRoles
            self.skills = skills
        }

        /// Where an entry's dates go.
        public enum Dates: String, Codable, Sendable, CaseIterable {

            /// Against the right edge, on the title's line. Wants a wide column.
            case besideTitle

            /// Under the organisation, which is what a narrow column has room for.
            case beneath
        }

        /// How a skills section is drawn. All four are real words on the page,
        /// so all four survive a parser.
        public enum Skills: String, Codable, Sendable, CaseIterable {
            case list, chips, bars, dots
        }

        func style(x: Double, width: Double) -> Blocks.Style {
            Blocks.Style(
                x: x, width: width,
                dates: dates == .besideTitle ? .besideTitle : .beneath,
                roleSize: roleSize, bodySize: bodySize,
                detailSize: detailSize, dateSize: dateSize,
                entryGap: entryGap, accentRoles: accentRoles,
                skills: skills.blocks
            )
        }
    }
}

extension Blueprint.Entries.Skills {

    var blocks: Blocks.SkillStyle {
        switch self {
        case .list: return .list
        case .chips: return .chips
        case .bars: return .bars
        case .dots: return .dots
        }
    }
}

// MARK: - What is drawn behind

extension Blueprint {

    /// Shading behind the text.
    ///
    /// Recorded while the page is laid out and painted in the background pass,
    /// because the height of a band is not known until the words that sit on
    /// it have been placed.
    public enum Ornament: String, Codable, Sendable, CaseIterable {

        case none

        /// Every other section on a tinted band.
        case bands

        /// The whole section on one rounded panel.
        case cards

        /// Every entry on a panel of its own. Suits several short roles;
        /// unkind to one long one.
        case entryCards

        /// Dates hung in a rail down the left, with a tick out to each entry.
        ///
        /// Sections that are not lists of dated things fall through to the
        /// ordinary treatment rather than being given an empty rail.
        case rail

        /// A bar of accent down the left of every section — the column
        /// inset by the bar's width, which is the column's `labelWidth`.
        case tabs

        static let cardPadding = 13.0

        /// Whether the entries sit inside something and need room from its edge.
        var insets: Bool { self == .cards || self == .entryCards }

        func prepare(on sheet: Sheet) -> Shading? {
            guard self != .none, self != .rail, self != .tabs else { return nil }

            let shading = Shading()
            let tint = sheet.wash
            let rounded = insets

            // A card gets a hairline edge — a larger panel under an inset
            // one, because the writer has no stroked rounded rectangle.
            // Without it the wash reads as page smudge rather than as an
            // object with a boundary. A band stays edgeless: it runs the
            // full bleed, and a boundary is exactly what it does not want.
            let edge = sheet.theme.scheme == .dark
                ? tint.lightened(by: 0.18)
                : Color.grey(225)

            sheet.background { doc, page, _ in
                for rect in shading.rects(onPage: page) {
                    if rounded {
                        doc.roundedRect(x: rect.x, y: rect.bottom, width: rect.width,
                                        height: rect.top - rect.bottom, radius: 7, color: edge)
                        doc.roundedRect(x: rect.x + 0.8, y: rect.bottom + 0.8,
                                        width: rect.width - 1.6,
                                        height: rect.top - rect.bottom - 1.6,
                                        radius: 6.2, color: tint)
                    } else {
                        doc.rect(x: 0, y: rect.bottom, width: doc.width(),
                                 height: rect.top - rect.bottom, color: tint)
                    }
                }
            }
            return shading
        }

        /// Runs `body`, recording what it covered so it can be painted under.
        func wrap(
            index: Int, on sheet: Sheet, shading: Shading?,
            x: Double, width: Double, _ body: () -> Void
        ) {
            guard let shading, self != .none, self == .cards || index.isMultiple(of: 2) else {
                body()
                return
            }

            let pdf = sheet.pdf
            let page = pdf.pageCount()
            // From the cursor down, with the words inset — a panel that
            // reached up into the heading's gap touched the label above it.
            let top = pdf.cursor()
            pdf.gap(13)

            // Drawn with a palette derived from the shading, so a chip's own
            // wash steps away from the wash it sits on rather than vanishing
            // into it.
            sheet.drawing(on: .against(sheet.wash, accent: sheet.theme.accentColor)) {
                body()
            }

            // Only shaded when the section stayed on one page: a rectangle
            // whose corners are on different sheets of paper is not a shape.
            guard pdf.pageCount() == page else { return }
            shading.add(page: page, x: x, width: width, top: top, bottom: pdf.cursor() - 4)
        }
    }

    /// Rectangles recorded during layout, drawn afterwards.
    public final class Shading: @unchecked Sendable {

        struct Rect {
            let page: Int
            let x: Double
            let width: Double
            let top: Double
            let bottom: Double
        }

        private var recorded: [Rect] = []

        func add(page: Int, x: Double, width: Double, top: Double, bottom: Double) {
            guard top > bottom else { return }
            recorded.append(Rect(page: page, x: x, width: width, top: top, bottom: bottom))
        }

        func rects(onPage page: Int) -> [Rect] {
            recorded.filter { $0.page == page }
        }
    }
}

// MARK: - Colours

extension Blueprint {

    /// A colour, named or given.
    ///
    /// The named ones follow the theme, so a blueprint that says `accent`
    /// works under every accent somebody sets rather than pinning one.
    public struct Paint: Codable, Sendable, Equatable, RawRepresentable,
                         ExpressibleByStringLiteral {

        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }

        public static let ink = Paint(rawValue: "ink")
        public static let muted = Paint(rawValue: "muted")
        public static let accent = Paint(rawValue: "accent")
        public static let hairline = Paint(rawValue: "hairline")
        public static let wash = Paint(rawValue: "wash")
        public static let page = Paint(rawValue: "page")

        /// The accent lightened to a wash, for a rail down the page.
        public static let rail = Paint(rawValue: "rail")

        /// The page reversed: near-black on a light theme, near-white on a
        /// dark one.
        public static let inverse = Paint(rawValue: "inverse")

        /// Near-black whatever the theme; `darkest` a step below it.
        public static let dark = Paint(rawValue: "dark")
        public static let darkest = Paint(rawValue: "darkest")

        public static let named: [Paint] = [.ink, .muted, .accent, .hairline, .wash, .page, .rail, .inverse, .dark, .darkest]

        func colour(on sheet: Sheet, fallback: Color? = nil) -> Color {
            switch rawValue {
            case "ink": return sheet.ink
            case "muted": return sheet.muted
            case "accent": return sheet.accent
            case "hairline": return sheet.hairline
            case "wash": return sheet.wash
            case "page": return sheet.page
            case "rail": return sheet.theme.railTint
            case "inverse": return sheet.theme.inverse
            case "dark": return sheet.theme.dark
            case "darkest": return sheet.theme.dark.darkened(by: 0.55)
            default:
                // A hex value, or a name nobody defined — in which case the
                // theme's own ink is a better answer than black.
                return rawValue.hasPrefix("#") ? .hex(rawValue) : (fallback ?? sheet.ink)
            }
        }

        /// Whether this is a name the renderer knows or a colour it can read.
        public var isValid: Bool {
            Paint.named.contains(self) || (rawValue.hasPrefix("#") && rawValue.count == 7)
        }
    }

    /// Theme colours a design overrides for its own identity.
    public struct PaletteOverride: Codable, Sendable, Equatable {

        public var page: Paint?
        public var ink: Paint?
        public var muted: Paint?
        public var hairline: Paint?
        public var wash: Paint?
        public var accent: Paint?

        public init(
            page: Paint? = nil, ink: Paint? = nil, muted: Paint? = nil,
            hairline: Paint? = nil, wash: Paint? = nil, accent: Paint? = nil
        ) {
            self.page = page
            self.ink = ink
            self.muted = muted
            self.hairline = hairline
            self.wash = wash
            self.accent = accent
        }

        func resolved(on sheet: Sheet) -> Sheet.Palette {
            Sheet.Palette(
                page: page?.colour(on: sheet) ?? sheet.page,
                ink: ink?.colour(on: sheet) ?? sheet.ink,
                muted: muted?.colour(on: sheet) ?? sheet.muted,
                hairline: hairline?.colour(on: sheet) ?? sheet.hairline,
                wash: wash?.colour(on: sheet) ?? sheet.wash,
                accent: accent?.colour(on: sheet) ?? sheet.accent
            )
        }
    }

    /// Where something sits in its column.
    public enum Alignment: String, Codable, Sendable, CaseIterable {
        case left, centre, right

        var textAlign: Align {
            switch self {
            case .left: return .left
            case .centre: return .center
            case .right: return .right
            }
        }
    }
}

// MARK: - Starting points

extension Blueprint {

    /// The built-ins, as blueprints.
    ///
    /// Not the compiled designs themselves — those keep their bespoke touches
    /// and are not going to be rewritten as data to prove a point. These are
    /// close relatives, and they exist to be starting points: nobody writes a
    /// design from an empty file, and "ledger with a marker heading and chips"
    /// is how one actually gets made.
    /// The designs that ship with the package, read from the JSON files in
    /// its resources — because a design is a JSON file, and the Swift here
    /// only names it. The first fourteen are the designs; the last four are
    /// starting points only.
    public static let starting: [Blueprint] = bundledNames.map { bundled($0) }

    static let bundledNames = [
        "ledger", "broadsheet", "timeline", "sidebar", "margin", "nocturne", "eclipse",
        "bulletin", "marker", "slate", "card", "terminal", "banner", "gazette",
        "plain", "register", "plaqued", "carded",
    ]

    /// One column, a rule under each heading, a code beside the name where
    /// there is one. Restraint is the design.
    public static let ledger = bundled("ledger")

    /// Serif, centred masthead: the name in light tracked capitals, the
    /// headline in the italic, a heavy rule and a hairline under the head.
    /// Academic and formal.
    public static let broadsheet = bundled("broadsheet")

    /// Dates in a rail down the left, with a tick out to each entry. The head
    /// and the headings sit at the margin; only the entries are past the
    /// rail, so the employment history is the shape of the page.
    public static let timeline = bundled("timeline")

    /// A tinted rail carrying contact, skills and languages, with the
    /// experience beside it. The best-looking of the set and the one a
    /// tracking system reads wrong — `check` says so.
    public static let sidebar = bundled("sidebar")

    /// Section names hung in the left margin, a hairline above every
    /// section, and the contact details as the first ruled row. Book
    /// typography, and the calmest page here.
    public static let margin = bundled("margin")

    /// A light band at the top and the rest of the page reversed out.
    /// Striking on a screen, expensive on somebody's office printer.
    public static let nocturne = bundled("nocturne")

    /// Nocturne with the light band taken away: the whole page dark, the
    /// masthead a step darker still. The darkest page here.
    public static let eclipse = bundled("eclipse")

    /// Headings as rounded tabs, each with a mark, and room for a portrait.
    /// Navigable at a glance, which suits a long CV.
    public static let bulletin = bundled("bulletin")

    /// Headings struck through with a highlighter, a name ruled like a
    /// signature. The least formal of them.
    public static let marker = bundled("marker")

    /// Two panels across the head — summary on one, contact on the other —
    /// and a coloured tab beside every section.
    public static let slate = bundled("slate")

    /// Every entry on a panel of its own — a section that is a list of
    /// entries gets one each, the rest get one around the block. Suits
    /// several short roles; unkind to one long one.
    public static let card = bundled("card")

    /// A prompt before every heading, monospaced labels and dates,
    /// proportional prose, and a code beside the name where there is one.
    /// Technical without being a costume.
    public static let terminal = bundled("terminal")

    /// A near-black band across the head with the name reversed out of it,
    /// the role in the accent and the portrait inside the band; a light page
    /// under it. The modern product-company résumé.
    public static let banner = bundled("banner")

    /// The serif two-column: centred masthead, the argument in a wide
    /// column and the credentials in a narrow one behind a hairline. The
    /// academic and executive look, and the other one a parser reads wrong.
    public static let gazette = bundled("gazette")

    /// Centred name, ruled headings, no ornament, and a scale that gets a
    /// first job onto one page. The shape every careers service hands out,
    /// set properly: the one to start from when the posting says one page.
    public static let plain = bundled("plain")

    /// Alternating tinted bands, labels hung in the margin.
    public static let register = bundled("register")

    /// A coloured panel across the top, dipped, with a portrait.
    public static let plaqued = bundled("plaqued")

    /// Every section on its own rounded panel.
    public static let carded = bundled("carded")

    /// A design from the package's resources.
    ///
    /// The files are part of the package, so one that is missing or will
    /// not read is a build fault rather than a condition to handle — and
    /// there is a test that reads every one of them.
    static func bundled(_ name: String) -> Blueprint {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Designs") else {
            preconditionFailure("The bundled design \(name).json is not in the package")
        }
        do {
            return try Blueprint(contentsOf: url)
        } catch {
            preconditionFailure("The bundled design \(name).json does not read: \(error)")
        }
    }
}

// MARK: - Reading a partial one

//  A design is written by hand — that is the entire point of the format — so
//  the same rule applies here as to a résumé: name what you want changed, and
//  leave the rest out. Swift's synthesised decoder would demand all thirty-odd
//  keys to say "ledger, but with a marker heading".

extension Blueprint {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.value(.name, or: "custom"),
            masthead: try container.value(.masthead, or: Masthead()),
            column: try container.value(.column, or: Column()),
            heading: try container.value(.heading, or: Heading()),
            entries: try container.value(.entries, or: Entries()),
            ornament: try container.value(.ornament, or: .none),
            sectionGap: try container.value(.sectionGap, or: 17),
            footer: try container.value(.footer, or: true),
            skip: try container.value(.skip, or: []),
            palette: try container.maybe(.palette),
            typeface: try container.value(.typeface, or: .sans),
            sections: try container.value(.sections, or: [:]),
            side: try container.maybe(.side)
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, masthead, column, heading, entries
        case ornament, sectionGap, footer, skip, palette, typeface, sections, side
    }
}

extension Blueprint.Masthead {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Masthead()
        self.init(
            align: try container.value(.align, or: defaults.align),
            nameSize: try container.value(.nameSize, or: defaults.nameSize),
            uppercase: try container.value(.uppercase, or: defaults.uppercase),
            tracking: try container.value(.tracking, or: defaults.tracking),
            headlineSize: try container.value(.headlineSize, or: defaults.headlineSize),
            headlineColour: try container.value(.headlineColour, or: defaults.headlineColour),
            contactSize: try container.value(.contactSize, or: defaults.contactSize),
            panel: try container.maybe(.panel),
            photo: try container.maybe(.photo),
            qr: try container.value(.qr, or: defaults.qr),
            // A rule is on by default, so leaving the key out keeps it and
            // "rule": null is how you say you do not want one.
            rule: container.contains(.rule) ? try container.maybe(.rule) : defaults.rule,
            monospaced: try container.value(.monospaced, or: defaults.monospaced),
            gapAfter: try container.value(.gapAfter, or: defaults.gapAfter),
            nameWeight: try container.value(.nameWeight, or: defaults.nameWeight),
            nameColour: try container.value(.nameColour, or: defaults.nameColour),
            headlineItalic: try container.value(.headlineItalic, or: defaults.headlineItalic),
            separator: try container.value(.separator, or: defaults.separator),
            contacts: try container.value(.contacts, or: defaults.contacts),
            twin: try container.value(.twin, or: defaults.twin),
            body: try container.maybe(.body),
            band: try container.maybe(.band)
        )
    }

    /// Written out with `rule` always present, null included.
    ///
    /// The synthesised encoder omits a nil optional, and this decoder reads an
    /// absent `rule` as "as it comes" — so a design that deliberately has no
    /// rule came back with one. Absent and refused have to stay different in
    /// both directions or the format does not round-trip.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(align, forKey: .align)
        try container.encode(nameSize, forKey: .nameSize)
        try container.encode(uppercase, forKey: .uppercase)
        try container.encode(tracking, forKey: .tracking)
        try container.encode(headlineSize, forKey: .headlineSize)
        try container.encode(headlineColour, forKey: .headlineColour)
        try container.encode(contactSize, forKey: .contactSize)
        try container.encodeIfPresent(panel, forKey: .panel)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encode(qr, forKey: .qr)
        try container.encode(rule, forKey: .rule)
        try container.encode(monospaced, forKey: .monospaced)
        try container.encode(gapAfter, forKey: .gapAfter)
        try container.encode(nameWeight, forKey: .nameWeight)
        try container.encode(nameColour, forKey: .nameColour)
        try container.encode(headlineItalic, forKey: .headlineItalic)
        try container.encode(separator, forKey: .separator)
        try container.encode(contacts, forKey: .contacts)
        try container.encode(twin, forKey: .twin)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(band, forKey: .band)
    }

    enum CodingKeys: String, CodingKey {
        case align, nameSize, uppercase, tracking, headlineSize
        case headlineColour, contactSize, panel, photo, qr, rule, monospaced, gapAfter
        case nameWeight, nameColour, headlineItalic, separator, contacts, twin, body, band
    }
}

extension Blueprint.Panel {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Panel()
        self.init(
            fill: try container.value(.fill, or: defaults.fill),
            height: try container.value(.height, or: defaults.height),
            dip: try container.value(.dip, or: defaults.dip)
        )
    }

    enum CodingKeys: String, CodingKey { case fill, height, dip }
}

extension Blueprint.Photo {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Photo()
        self.init(
            diameter: try container.value(.diameter, or: defaults.diameter),
            align: try container.value(.align, or: defaults.align)
        )
    }

    enum CodingKeys: String, CodingKey { case diameter, align }
}

extension Blueprint.Rule {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Rule()
        self.init(
            colour: try container.value(.colour, or: defaults.colour),
            thickness: try container.value(.thickness, or: defaults.thickness),
            double: try container.value(.double, or: defaults.double),
            width: try container.value(.width, or: defaults.width),
            underName: try container.value(.underName, or: defaults.underName)
        )
    }

    enum CodingKeys: String, CodingKey { case colour, thickness, double, width, underName }
}

extension Blueprint.Column {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Column()
        self.init(
            labelWidth: try container.value(.labelWidth, or: defaults.labelWidth),
            gutter: try container.value(.gutter, or: defaults.gutter),
            labelAlign: try container.value(.labelAlign, or: defaults.labelAlign),
            headAtMargin: try container.value(.headAtMargin, or: defaults.headAtMargin),
            ruled: try container.value(.ruled, or: defaults.ruled)
        )
    }

    enum CodingKeys: String, CodingKey { case labelWidth, gutter, labelAlign, headAtMargin, ruled }
}

extension Blueprint.Side {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Side()
        self.init(
            width: try container.value(.width, or: defaults.width),
            edge: try container.value(.edge, or: defaults.edge),
            sections: try container.value(.sections, or: defaults.sections),
            // A fill is on by default, so leaving the key out keeps it and
            // "fill": null is how you say you do not want one.
            fill: container.contains(.fill) ? try container.maybe(.fill) : defaults.fill,
            divider: try container.value(.divider, or: defaults.divider),
            inset: try container.value(.inset, or: defaults.inset),
            gutter: try container.value(.gutter, or: defaults.gutter),
            head: try container.value(.head, or: defaults.head),
            heading: try container.value(.heading, or: defaults.heading),
            entries: try container.value(.entries, or: defaults.entries)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(edge, forKey: .edge)
        try container.encode(sections, forKey: .sections)
        try container.encode(fill, forKey: .fill)
        try container.encode(divider, forKey: .divider)
        try container.encode(inset, forKey: .inset)
        try container.encode(gutter, forKey: .gutter)
        try container.encode(head, forKey: .head)
        try container.encode(heading, forKey: .heading)
        try container.encode(entries, forKey: .entries)
    }

    enum CodingKeys: String, CodingKey {
        case width, edge, sections, fill, divider, inset, gutter, head, heading, entries
    }
}

// MARK: - The colours the paints name

extension Theme {

    /// The accent lightened to a wash — or the wash itself on a monochrome
    /// theme, where there is no accent to lighten.
    var railTint: Color {
        guard !isMonochrome else { return wash }
        return scheme == .dark
            ? accentColor.darkened(by: 0.72).lightened(by: 0.06)
            : accentColor.lightened(by: 0.93)
    }

    /// The page reversed.
    var inverse: Color {
        scheme == .dark ? page.lightened(by: 0.93) : page.darkened(by: 0.9)
    }

    /// Near-black whatever the theme: a dark theme's page as it is, a light
    /// theme's taken most of the way to black.
    var dark: Color {
        scheme == .dark ? page : page.darkened(by: 0.88)
    }
}

extension Sheet {

    /// A panel dark enough to reverse type out of: the accent taken down,
    /// or a plain dark grey where the theme has no accent.
    var accentPanel: Color {
        guard !theme.isMonochrome else { return .grey(46) }
        return theme.accentColor.darkened(by: theme.accentIsDark ? 0.15 : 0.62)
    }
}

extension Blueprint.Heading {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Heading()
        self.init(
            style: try container.value(.style, or: defaults.style),
            size: try container.value(.size, or: defaults.size),
            colour: try container.value(.colour, or: defaults.colour),
            icon: try container.value(.icon, or: defaults.icon)
        )
    }

    enum CodingKeys: String, CodingKey { case style, size, colour, icon }
}

extension Blueprint.Entries {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Entries()
        self.init(
            dates: try container.value(.dates, or: defaults.dates),
            roleSize: try container.value(.roleSize, or: defaults.roleSize),
            bodySize: try container.value(.bodySize, or: defaults.bodySize),
            detailSize: try container.value(.detailSize, or: defaults.detailSize),
            dateSize: try container.value(.dateSize, or: defaults.dateSize),
            entryGap: try container.value(.entryGap, or: defaults.entryGap),
            accentRoles: try container.value(.accentRoles, or: defaults.accentRoles),
            skills: try container.value(.skills, or: defaults.skills)
        )
    }

    enum CodingKeys: String, CodingKey {
        case dates, roleSize, bodySize, detailSize, dateSize, entryGap, accentRoles, skills
    }
}

extension Blueprint.PaletteOverride {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            page: try container.maybe(.page),
            ink: try container.maybe(.ink),
            muted: try container.maybe(.muted),
            hairline: try container.maybe(.hairline),
            wash: try container.maybe(.wash),
            accent: try container.maybe(.accent)
        )
    }

    enum CodingKeys: String, CodingKey { case page, ink, muted, hairline, wash, accent }
}

// MARK: - Naming what there is

extension Decoder {

    /// Decodes a named choice, saying what the choices are when it is not one.
    ///
    /// "There is no heading style called 'tabbed'" and a list beats "Cannot
    /// initialize Style from invalid String value tabbed", which tells
    /// somebody editing a JSON file nothing they did not already know.
    func choice<T: RawRepresentable & CaseIterable>(
        _ type: T.Type, called what: String
    ) throws -> T where T.RawValue == String {
        let raw = try singleValueContainer().decode(String.self)

        guard let value = T(rawValue: raw) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "There is no \(what) called \"\(raw)\" — one of: "
                    + T.allCases.map(\.rawValue).joined(separator: ", ")
            ))
        }
        return value
    }
}

extension Blueprint.Heading.Style {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "heading style") }
}

extension Blueprint.Entries.Dates {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "date placement") }
}

extension Blueprint.Entries.Skills {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "skill style") }
}

extension Blueprint.Ornament {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "ornament") }
}

extension Blueprint.Alignment {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "alignment") }
}

extension Blueprint.Face {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "typeface") }
}

// MARK: - One section, set differently

extension Blueprint {

    /// What a single section does differently from the rest.
    ///
    /// Every field is optional and every absent one means "as the design has
    /// it" — not "as the default has it". That distinction is the whole point:
    /// a design that sets 11pt roles and then says `{"skills": "chips"}` for
    /// one section must keep its 11pt roles there, and a patch made of
    /// defaults would quietly undo them.
    public struct SectionOverride: Codable, Sendable, Equatable {

        public var heading: HeadingPatch?
        public var entries: EntriesPatch?

        /// Space after this section, where it wants more or less air than the
        /// rest — a skills list rarely needs the same gap as an employment
        /// history.
        public var sectionGap: Double?

        public init(
            heading: HeadingPatch? = nil,
            entries: EntriesPatch? = nil,
            sectionGap: Double? = nil
        ) {
            self.heading = heading
            self.entries = entries
            self.sectionGap = sectionGap
        }
    }

    /// A heading, changed in part.
    public struct HeadingPatch: Codable, Sendable, Equatable {

        public var style: Heading.Style?
        public var size: Double?
        public var colour: Paint?
        public var icon: Bool?

        public init(
            style: Heading.Style? = nil, size: Double? = nil,
            colour: Paint? = nil, icon: Bool? = nil
        ) {
            self.style = style
            self.size = size
            self.colour = colour
            self.icon = icon
        }

        func applied(to heading: Heading) -> Heading {
            Heading(
                style: style ?? heading.style,
                size: size ?? heading.size,
                colour: colour ?? heading.colour,
                icon: icon ?? heading.icon
            )
        }
    }

    /// Entry settings, changed in part.
    public struct EntriesPatch: Codable, Sendable, Equatable {

        public var dates: Entries.Dates?
        public var roleSize: Double?
        public var bodySize: Double?
        public var detailSize: Double?
        public var dateSize: Double?
        public var entryGap: Double?
        public var accentRoles: Bool?
        public var skills: Entries.Skills?

        public init(
            dates: Entries.Dates? = nil, roleSize: Double? = nil, bodySize: Double? = nil,
            detailSize: Double? = nil, dateSize: Double? = nil, entryGap: Double? = nil,
            accentRoles: Bool? = nil, skills: Entries.Skills? = nil
        ) {
            self.dates = dates
            self.roleSize = roleSize
            self.bodySize = bodySize
            self.detailSize = detailSize
            self.dateSize = dateSize
            self.entryGap = entryGap
            self.accentRoles = accentRoles
            self.skills = skills
        }

        func applied(to entries: Entries) -> Entries {
            Entries(
                dates: dates ?? entries.dates,
                roleSize: roleSize ?? entries.roleSize,
                bodySize: bodySize ?? entries.bodySize,
                detailSize: detailSize ?? entries.detailSize,
                dateSize: dateSize ?? entries.dateSize,
                entryGap: entryGap ?? entries.entryGap,
                accentRoles: accentRoles ?? entries.accentRoles,
                skills: skills ?? entries.skills
            )
        }
    }
}
