//
//  BlueprintMasthead.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The name at the top, and what it is set on: a panel, a portrait, a code,
//  a rule, twin panels, a painted body.

import Foundation
import TextPDF

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

            let plain = monospaced ? (sheet.mono ?? sheet.regular) : sheet.regular

            // Beside a code the name is set to what is left, not to the page.
            let y = sheet.nameplate(
                plate(profile, on: sheet, ink: ink, muted: mutedInk, fitted: coded),
                x: textX, top: top, width: textWidth
            )
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
                    hang(resume.labels.contact, on: sheet, labelWidth: labelWidth, align: labelAlign, color: mutedInk)
                    sheet.contactFlow(entries, x: textX, width: textWidth,
                                      size: contactSize, color: mutedInk, separator: between, face: plain)
                }
                if !particulars.isEmpty {
                    sheet.gap(13)
                    sheet.rule(x: textX, width: textWidth, thickness: 0.6)
                    sheet.gap(11)
                    hang(resume.labels.details, on: sheet, labelWidth: labelWidth, align: labelAlign, color: mutedInk)
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

        /// The name and the claim as ``Sheet/nameplate(_:x:top:width:boxWidth:)``
        /// sets them, from this masthead's choices. Built here once, because
        /// the head draws it and so does a side whose name sits over the
        /// main column — and two copies of the name's tint rule drift.
        /// - Parameters:
        ///   - ink: The ink of whatever the name is set on — the page's, or a
        ///     panel's.
        ///   - fitted: Set to what is left of the measure rather than run past it.
        func plate(_ profile: Profile, on sheet: Sheet, ink: Color, muted: Color, fitted: Bool) -> Sheet.Nameplate {
            let regular = nameWeight == .regular ? sheet.regular : sheet.semibold
            let heavy = monospaced ? (sheet.monoBold ?? sheet.semibold) : regular
            let plain = monospaced ? (sheet.mono ?? sheet.regular) : sheet.regular

            // The accent is only a colour for the name where there is one;
            // on a monochrome theme it is the ink under another name.
            let nameTint = nameColour == .ink || (sheet.theme.isMonochrome && nameColour == .accent)
                ? ink
                : nameColour.colour(on: sheet, fallback: ink)

            return Sheet.Nameplate(
                name: profile.name, size: nameSize, face: heavy, colour: nameTint,
                tracking: tracking, uppercase: uppercase,
                fitted: fitted, rule: rule,
                headline: profile.headline, headlineSize: headlineSize,
                headlineFace: headlineItalic ? (sheet.italic ?? plain) : plain,
                headlineColour: sheet.headlineTint(headlineColour, ink: ink, muted: muted),
                headlineFitted: false,
                align: align, metrics: .resume
            )
        }

        /// The summary on a washed panel and the contact details on a dark
        /// one, side by side under the name, each entry with its mark.
        private func twinPanels(_ resume: Resume, on sheet: Sheet, x: Double, width: Double, top: Double) {
            let pdf = sheet.pdf
            let entries = resume.profile.markedContacts()
            let panelTop = top - 58
            let gutter = 16.0
            let rightWidth = min(232.0, width * 0.44)
            let leftWidth = width - rightWidth - gutter
            let padding = Sheet.panelPadding

            let summaryHeight = resume.summary.isEmpty ? 0 : pdf.blockHeight(
                resume.summary, size: 9.2, width: leftWidth - padding * 2,
                leading: sheet.leading(9.2), face: sheet.regular
            )
            let contactHeight = Double(entries.count) * Sheet.contactRow
            let height = max(summaryHeight, contactHeight) + padding * 2

            let darkFill = sheet.theme.scheme == .dark
                ? sheet.theme.page.lightened(by: 0.12)
                : sheet.accentPanel

            if !resume.summary.isEmpty {
                pdf.roundedRect(x: x, y: panelTop - height, width: leftWidth,
                                height: height, radius: 8, color: sheet.wash)
                pdf.move(to: panelTop - padding)
                sheet.paragraph(resume.summary, x: x + padding, width: leftWidth - padding * 2, size: 9.2)
            }

            sheet.contactPanel(entries, x: x + leftWidth + gutter, top: panelTop, width: rightWidth,
                               height: height, radius: 8, fill: darkFill, size: 8.8)
            sheet.gap(22)
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

// MARK: - What every head shares

extension Sheet {

    /// The name at the top of a document and the claim under it — set the
    /// same way on a résumé and on a letter. The size, the face and the
    /// measure are the design's; the fitting, the tinting and the spacing
    /// are not, and are drawn once by ``Sheet/nameplate(_:x:top:width:boxWidth:)``.
    struct Nameplate {

        var name: String
        var size: Double
        var face: EmbeddedFont?
        var colour: Color
        var tracking: Double
        var uppercase: Bool

        /// Set to what is left of the measure rather than run past it.
        var fitted: Bool

        /// A signature rule — as wide as the name and right under it, the
        /// way a name is ruled on printed stationery — where the design
        /// asks for one there.
        var rule: Blueprint.Rule?

        var headline: String
        var headlineSize: Double
        var headlineFace: EmbeddedFont?
        var headlineColour: Color
        var headlineFitted: Bool

        var align: Blueprint.Alignment
        var metrics: Metrics

        /// The proportions of the head, in multiples of the type size: how
        /// far the name's baseline sits under the top, how far the headline
        /// sits under that, and how much room it leaves after itself. A
        /// résumé's 25-point name and a letter's 22-point one are not set
        /// to the same proportions, and the difference is deliberate.
        struct Metrics {
            var baseline: Double
            var headline: Double
            var after: Double

            static let resume = Metrics(baseline: 0.86, headline: 0.72, after: 1.6)
            static let letter = Metrics(baseline: 0.88, headline: 0.74, after: 1.55)
        }
    }

    /// Draws the nameplate from `top`, across `width` from `x`.
    /// - Parameter boxWidth: The box the type is aligned within, where it
    ///   is not the measure it is fitted to.
    /// - Returns: Where the cursor is left — under the headline, or under
    ///   the name where there is none.
    func nameplate(_ plate: Nameplate, x: Double, top: Double, width: Double, boxWidth: Double? = nil) -> Double {
        let box = boxWidth ?? width
        let label = plate.uppercase ? plate.name.uppercased() : plate.name
        let fitted = plate.fitted ? pdf.fit(label, into: width, size: plate.size, face: plate.face) : label
        let baseline = top - plate.size * plate.metrics.baseline

        pdf.textAt(fitted, x: x, y: baseline, size: plate.size, color: plate.colour,
                   align: plate.align.textAlign, boxWidth: box, face: plate.face, tracking: plate.tracking)

        if let rule = plate.rule, rule.underName {
            let measured = pdf.width(of: fitted, size: plate.size, face: plate.face, tracking: plate.tracking)
            let startX: Double
            switch plate.align {
            case .left: startX = x
            case .centre: startX = x + (box - measured) / 2
            case .right: startX = x + box - measured
            }
            pdf.rect(x: startX, y: baseline - plate.size * 0.3, width: measured,
                     height: rule.thickness, color: rule.colour.colour(on: self))
        }

        var y = baseline - plate.size * plate.metrics.headline
        if !plate.headline.isEmpty {
            let headline = plate.headlineFitted
                ? pdf.fit(plate.headline, into: width, size: plate.headlineSize, face: plate.headlineFace)
                : plate.headline
            pdf.textAt(headline, x: x, y: y, size: plate.headlineSize, color: plate.headlineColour,
                       align: plate.align.textAlign, boxWidth: box, face: plate.headlineFace)
            y -= plate.headlineSize * plate.metrics.after
        }
        return y
    }

    /// The headline's colour: the paint the design asks for — unless that
    /// is the accent on a monochrome theme, where the accent is only the
    /// ink under another name and the headline would read as a second line
    /// of the name. Then the muted ink, which is what such a theme has.
    func headlineTint(_ paint: Blueprint.Paint, ink: Color, muted: Color) -> Color {
        theme.isMonochrome && paint == .accent ? muted : paint.colour(on: self, fallback: ink)
    }

    /// A contact panel's row height, and the space inside its edge.
    static let contactRow = 19.0
    static let panelPadding = 15.0

    /// The contact details in a filled panel, each with its mark: the
    /// rectangle, then a row per entry — or two columns of them — with the
    /// mark at the left of each and the text linked where it has somewhere
    /// to go. The ink and the mark's colour are asked of the fill, so the
    /// panel reads whatever the theme is. Leaves the cursor at its foot.
    func contactPanel(
        _ entries: [(icon: Icon, text: String, url: String)],
        x: Double, top: Double, width: Double, height: Double, columns: Int = 1,
        radius: Double, fill: Color, size: Double
    ) {
        let palette = Palette.against(fill, accent: theme.accentColor)
        pdf.roundedRect(x: x, y: top - height, width: width, height: height, radius: radius, color: fill)

        let columnWidth = (width - Self.panelPadding * 2) / Double(columns)
        for (index, entry) in entries.enumerated() {
            let originX = x + Self.panelPadding + Double(index % columns) * columnWidth
            let baseline = top - Self.panelPadding - Double(index / columns) * Self.contactRow

            icon(entry.icon, x: originX, y: baseline - 11.5, size: 12, color: palette.accent)
            if entry.url.isEmpty {
                pdf.textAt(entry.text, x: originX + 18, y: baseline - 9.6, size: size,
                           color: palette.ink, face: regular)
            } else {
                pdf.linked(entry.text, url: entry.url, x: originX + 18, y: baseline - 9.6,
                           size: size, color: palette.ink, face: regular)
            }
        }

        pdf.move(to: top - height)
    }
}
