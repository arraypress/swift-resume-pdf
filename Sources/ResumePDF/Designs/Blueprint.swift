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
//  What separates Ledger from Register from Bulletin is not the structure but
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
        palette: PaletteOverride? = nil
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
    public var displayName: String { name }

    /// Always. There is no way to say "two columns" in this format, which is
    /// what makes it safe to hand somebody: a design written as data cannot
    /// produce a document a tracking system reads out of order.
    public var isSingleColumn: Bool { true }

    /// Whether the masthead was told to place a portrait.
    public var showsPhoto: Bool { masthead.photo != nil }

    // MARK: Rendering

    public func render(_ resume: Resume, on sheet: Sheet) {
        sheet.drawing(on: palette?.resolved(on: sheet)) {
            draw(resume, on: sheet)
        }
    }

    private func draw(_ resume: Resume, on sheet: Sheet) {
        let bodyX = sheet.left + column.labelWidth + column.gutter
        let bodyWidth = sheet.width - column.labelWidth - column.gutter

        masthead.draw(resume, on: sheet, x: bodyX, width: bodyWidth)

        var style = entries.style(x: bodyX, width: bodyWidth)
        if ornament == .cards {
            // Inset from the panel's edge. The entry gap is left alone: a
            // panel here holds a whole section, so its entries still need the
            // air between them that any other design gives them.
            style.x = bodyX + Ornament.cardPadding
            style.width = bodyWidth - Ornament.cardPadding * 2
        }

        let shading = ornament.prepare(on: sheet)
        let sections = resume.populated().filter { !skip.contains($0) }

        for (index, section) in sections.enumerated() {
            if index > 0 { sheet.gap(sectionGap) }

            heading.draw(
                resume.heading(for: section),
                section: section,
                on: sheet,
                x: bodyX, width: bodyWidth,
                labelWidth: column.labelWidth,
                labelAlign: column.labelAlign
            )

            ornament.wrap(index: index, on: sheet, shading: shading,
                          x: sheet.left, width: sheet.width) {
                Blocks.render(section, of: resume, on: sheet, style: style)
            }
        }

        if footer { sheet.footer(name: resume.profile.name) }
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

        /// A filled band behind the masthead, as Plaque and Nocturne have.
        public var panel: Panel?

        /// A round portrait. Only drawn when the profile carries one.
        public var photo: Photo?

        /// A rule under the whole thing.
        public var rule: Rule?

        /// Space between the masthead and the first heading.
        public var gapAfter: Double

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
            rule: Rule? = Rule(),
            gapAfter: Double = 19
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
            self.rule = rule
            self.gapAfter = gapAfter
        }

        func draw(_ resume: Resume, on sheet: Sheet, x: Double, width: Double) {
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
            let top = panelHeight.map { pdf.height() - $0 * 0.30 + nameSize * 0.86 }
                ?? (pdf.height() - sheet.theme.density.margin)

            var textX = x
            var textWidth = width

            // The portrait takes its side of the masthead, and the type takes
            // the rest — otherwise a long headline runs under the face.
            if let photo, carriesPhoto {
                let diameter = photo.diameter
                let photoX = photo.align == .right ? x + width - diameter : x
                _ = sheet.portrait(profile.photo, x: photoX,
                                   y: top - diameter + nameSize * 0.4, diameter: diameter)

                if photo.align == .right {
                    textWidth -= diameter + 18
                } else {
                    textX += diameter + 18
                    textWidth -= diameter + 18
                }
            }

            let label = uppercase ? profile.name.uppercased() : profile.name
            pdf.textAt(label, x: textX, y: top - nameSize * 0.86, size: nameSize,
                       color: ink, align: align.textAlign, boxWidth: textWidth,
                       face: sheet.semibold, tracking: tracking)

            var y = top - nameSize * 0.86 - nameSize * 0.72

            if !profile.headline.isEmpty {
                let tint = sheet.theme.isMonochrome && headlineColour == .accent
                    ? mutedInk
                    : headlineColour.colour(on: sheet, fallback: ink)
                pdf.textAt(profile.headline, x: textX, y: y, size: headlineSize,
                           color: tint, align: align.textAlign, boxWidth: textWidth,
                           face: sheet.regular)
                y -= headlineSize * 1.6
            }

            pdf.move(to: y)
            sheet.contactFlow(profile.contactEntries(), x: textX, width: textWidth,
                              size: contactSize, color: mutedInk, align: align.textAlign)

            // Regional particulars, where they have been set at all.
            let particulars = profile.particulars()
            if !particulars.isEmpty {
                sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                                  x: textX, width: textWidth, size: contactSize - 0.3,
                                  color: mutedInk, align: align.textAlign)
            }

            if let panelHeight {
                pdf.move(to: pdf.height() - panelHeight - 30)
            } else if let rule {
                sheet.rigidGap(5)
                sheet.rule(x: x, width: width, color: rule.colour.colour(on: sheet),
                           thickness: rule.thickness)
            }

            sheet.gap(gapAfter)
        }
    }

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
        /// straight cut; anything larger gives the shallow V that Plaque has.
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

        public init(colour: Paint = .ink, thickness: Double = 0.9) {
            self.colour = colour
            self.thickness = thickness
        }
    }
}

// MARK: - The column

extension Blueprint {

    /// Where the text sits, and what is beside it.
    ///
    /// `labelWidth` of zero is a full-width column — the usual case. Anything
    /// larger insets the text and leaves that much room to its left for
    /// section labels, which is how Margin, Register and Timeline are laid
    /// out. It is still one column in reading order.
    public struct Column: Codable, Sendable, Equatable {

        public var labelWidth: Double
        public var gutter: Double
        public var labelAlign: Alignment

        public init(labelWidth: Double = 0, gutter: Double = 0, labelAlign: Alignment = .right) {
            self.labelWidth = labelWidth
            self.gutter = gutter
            self.labelAlign = labelAlign
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
            }
        }

        /// A rounded tab, with the mark inside it.
        private func drawTab(_ title: String, section: Section, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let height = size * 2.6
            let badge = height - 1
            let label = title.uppercased()
            let tracking = size * 0.14

            pdf.breakIfNeeded(height + 54)

            let top = pdf.cursor()
            let bottom = top - height
            let textWidth = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)

            pdf.roundedRect(x: x + badge / 2, y: bottom, width: textWidth + badge + 26,
                            height: height, radius: height / 2, color: sheet.wash)

            if icon {
                // Filled where the accent can carry a reversed mark, outlined
                // where it cannot — the same choice the panel makes, for the
                // same reason.
                let centreX = x + badge / 2
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

            pdf.textAt(label, x: x + badge + 8, y: bottom + height * 0.35, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: tracking)

            pdf.move(to: bottom - 10)
        }

        /// A highlighter swipe, ending part-way through the words.
        private func drawMarker(_ title: String, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()
            let tracking = size * 0.05

            pdf.breakIfNeeded(size * 3 + 44)

            let top = pdf.cursor()
            let measured = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)
            let swipe = sheet.theme.isMonochrome
                ? sheet.theme.wash.darkened(by: 0.06)
                : sheet.accent.lightened(by: 0.62)

            pdf.rect(x: x - 3, y: top - size * 1.12, width: measured * 0.66 + 6,
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
        case .ruled, .tab, .marker, .margin: return .ruled
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

        /// Each section's entries on their own rounded panel.
        case cards

        static let cardPadding = 13.0

        func prepare(on sheet: Sheet) -> Shading? {
            guard self != .none else { return nil }

            let shading = Shading()
            let tint = sheet.wash
            let rounded = self == .cards

            sheet.background { doc, page, _ in
                for rect in shading.rects(onPage: page) {
                    if rounded {
                        doc.roundedRect(x: rect.x, y: rect.bottom, width: rect.width,
                                        height: rect.top - rect.bottom, radius: 7, color: tint)
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
            let top = pdf.cursor() + 13

            body()

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

        public static let named: [Paint] = [.ink, .muted, .accent, .hairline, .wash, .page]

        func colour(on sheet: Sheet, fallback: Color? = nil) -> Color {
            switch rawValue {
            case "ink": return sheet.ink
            case "muted": return sheet.muted
            case "accent": return sheet.accent
            case "hairline": return sheet.hairline
            case "wash": return sheet.wash
            case "page": return sheet.page
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
    public static let starting: [Blueprint] = [
        .ledger, .broadsheet, .register, .marginal, .marked, .tabbed, .plaqued, .carded,
    ]

    /// One column, a rule under each heading. Restraint is the design.
    public static let ledger = Blueprint(name: "ledger")

    /// Serif, centred masthead. Academic and formal.
    public static let broadsheet = Blueprint(
        name: "broadsheet",
        masthead: Masthead(align: .centre, nameSize: 24, uppercase: true, tracking: 1.6,
                           headlineSize: 10.4, headlineColour: .muted),
        heading: Heading(style: .centred, size: 7.4)
    )

    /// Alternating tinted bands, labels hung in the margin.
    public static let register = Blueprint(
        name: "register",
        masthead: Masthead(align: .centre, nameSize: 24, tracking: -0.3, rule: nil, gapAfter: 8),
        column: Column(labelWidth: 96, gutter: 20),
        heading: Heading(style: .margin, size: 8.6, icon: true),
        entries: Entries(entryGap: 14),
        ornament: .bands,
        sectionGap: 15
    )

    /// Section names hung in the left margin, and nothing else.
    public static let marginal = Blueprint(
        name: "marginal",
        masthead: Masthead(nameSize: 24),
        column: Column(labelWidth: 104, gutter: 18),
        heading: Heading(style: .margin, size: 8.6),
        entries: Entries(dates: .beneath, entryGap: 14),
        sectionGap: 16
    )

    /// Highlighter headings. Informal.
    public static let marked = Blueprint(
        name: "marked",
        heading: Heading(style: .marker, size: 12, colour: .ink),
        entries: Entries(entryGap: 15, skills: .bars),
        sectionGap: 18
    )

    /// Headings as rounded tabs, each with a mark.
    public static let tabbed = Blueprint(
        name: "tabbed",
        masthead: Masthead(nameSize: 24, rule: nil),
        heading: Heading(style: .tab, size: 8.2, colour: .ink, icon: true),
        entries: Entries(entryGap: 14, skills: .chips),
        sectionGap: 16
    )

    /// A coloured panel across the top.
    public static let plaqued = Blueprint(
        name: "plaqued",
        masthead: Masthead(nameSize: 27, panel: Panel(), photo: Photo(), rule: nil, gapAfter: 10),
        heading: Heading(style: .accentBar, colour: .accent),
        entries: Entries(entryGap: 14, skills: .chips),
        sectionGap: 16
    )

    /// Every section on its own rounded panel.
    public static let carded = Blueprint(
        name: "carded",
        masthead: Masthead(nameSize: 25, rule: nil),
        heading: Heading(style: .plain, size: 8.2, colour: .accent),
        entries: Entries(entryGap: 12, skills: .chips),
        ornament: .cards,
        sectionGap: 14
    )
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
            palette: try container.maybe(.palette)
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, masthead, column, heading, entries
        case ornament, sectionGap, footer, skip, palette
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
            // A rule is on by default, so leaving the key out keeps it and
            // "rule": null is how you say you do not want one.
            rule: container.contains(.rule) ? try container.maybe(.rule) : defaults.rule,
            gapAfter: try container.value(.gapAfter, or: defaults.gapAfter)
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
        try container.encode(rule, forKey: .rule)
        try container.encode(gapAfter, forKey: .gapAfter)
    }

    enum CodingKeys: String, CodingKey {
        case align, nameSize, uppercase, tracking, headlineSize
        case headlineColour, contactSize, panel, photo, rule, gapAfter
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
            thickness: try container.value(.thickness, or: defaults.thickness)
        )
    }

    enum CodingKeys: String, CodingKey { case colour, thickness }
}

extension Blueprint.Column {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Column()
        self.init(
            labelWidth: try container.value(.labelWidth, or: defaults.labelWidth),
            gutter: try container.value(.gutter, or: defaults.gutter),
            labelAlign: try container.value(.labelAlign, or: defaults.labelAlign)
        )
    }

    enum CodingKeys: String, CodingKey { case labelWidth, gutter, labelAlign }
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
