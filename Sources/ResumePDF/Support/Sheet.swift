//
//  Sheet.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The furniture the designs share.
//
//  Kept in one place because these are the parts that make a page look set
//  rather than typed: the rhythm between blocks, the hanging indent on a
//  bullet, the tracking on a small heading. Four copies of them drift apart
//  one fix at a time, and the drift shows — a résumé whose sections are
//  spaced two points differently from one another reads as careless before
//  anybody has read a word of it.
//

import Foundation
import TextPDF

/// A page being laid out, with the theme and typeface already on it.
final class Sheet {

    let pdf: Document
    let theme: Theme
    let family: FontFamily
    let labels: Labels

    /// Layers drawn behind the content, in the order they were added.
    private var backgrounds: [(Document, Int, Int) -> Void] = []

    init(theme: Theme, family: FontFamily, labels: Labels) {
        self.theme = theme
        self.family = family
        self.labels = labels

        pdf = Document(
            size: theme.pageSize,
            orientation: .portrait,
            margin: theme.density.margin,
            fontSize: 9.4,
            leading: 13 * theme.density.leading
        )
        pdf.family = family

        // The page colour goes down before anything a design adds, so a rail
        // or a band sits on top of it rather than under it.
        if theme.paintsPage {
            let fill = theme.page
            background { doc, _, _ in
                doc.rect(x: 0, y: 0, width: doc.width(), height: doc.height(), color: fill)
            }
        }
    }

    /// Adds a layer behind the page's content.
    ///
    /// Composed rather than assigned. `Document` holds one background
    /// callback, so a design registering its own panel would otherwise
    /// silently replace the page colour underneath it — and the fault would
    /// look like the theme being ignored rather than like two things fighting
    /// over one slot.
    func background(_ draw: @escaping (Document, Int, Int) -> Void) {
        backgrounds.append(draw)
        let layers = backgrounds
        pdf.behindEachPage { doc, page, total in
            for layer in layers { layer(doc, page, total) }
        }
    }

    // MARK: Type

    func face(_ weight: FontFamily.Weight, italic: Bool = false) -> EmbeddedFont? {
        family.face(weight, italic: italic)
    }

    var regular: EmbeddedFont? { face(.regular) }
    var medium: EmbeddedFont? { face(.medium) }
    var semibold: EmbeddedFont? { face(.semibold) }
    var bold: EmbeddedFont? { face(.bold) }
    var italic: EmbeddedFont? { face(.regular, italic: true) }

    /// Set while drawing over something that is not the page colour.
    private var override: Palette?

    var ink: Color { override?.ink ?? theme.ink }
    var muted: Color { override?.muted ?? theme.muted }
    var accent: Color { override?.accent ?? theme.accentColor }
    var hairline: Color { override?.hairline ?? theme.hairline }
    var wash: Color { override?.wash ?? theme.wash }
    var page: Color { override?.page ?? theme.page }

    /// A palette, for a region of the page that is not the page's colour.
    struct Palette {
        var page: Color
        var ink: Color
        var muted: Color
        var hairline: Color
        var wash: Color
        var accent: Color

        /// Derived from a background, so a design says what it is drawing on
        /// and gets a palette that reads against it.
        ///
        /// This is what lets one design invert a band and keep every shared
        /// block — bullets, dates, rules — legible inside it, without any of
        /// them being told that anything unusual is happening.
        static func against(_ background: Color, accent: Color) -> Palette {
            let dark = background.luminance < 0.5

            // An accent picked for the page can vanish against a band that is
            // the opposite colour, so it is lifted the same way the theme
            // lifts it — the band is just a smaller page.
            var readable = accent
            if abs(accent.luminance - background.luminance) < 0.28 {
                readable = dark ? accent.lightened(by: 0.6) : accent.darkened(by: 0.4)
            }

            return Palette(
                page: background,
                ink: dark ? .grey(236) : .grey(26),
                muted: dark ? .grey(158) : .grey(120),
                hairline: dark ? background.lightened(by: 0.24) : background.darkened(by: 0.14),
                wash: dark ? background.lightened(by: 0.09) : background.darkened(by: 0.045),
                accent: readable
            )
        }
    }

    /// Runs `body` with a different palette in force.
    func drawing(on palette: Palette?, _ body: () -> Void) {
        let previous = override
        override = palette
        body()
        override = previous
    }

    // MARK: Geometry

    var left: Double { pdf.left() }
    var right: Double { pdf.right() }
    var width: Double { pdf.contentWidth() }
    var cursor: Double { pdf.cursor() }

    /// Vertical space scaled by the theme's density.
    ///
    /// Everything between blocks goes through here, so tightening a page is
    /// one number rather than forty.
    func gap(_ points: Double) {
        pdf.gap(points * theme.density.sectionGap)
    }

    /// A fixed gap, for space inside a block where the rhythm must not move.
    func rigidGap(_ points: Double) {
        pdf.gap(points)
    }

    /// Line height for body text at a size.
    func leading(_ size: Double) -> Double {
        size * 1.42 * theme.density.leading
    }

    // MARK: Elements

    /// A section heading.
    ///
    /// Tracked, because uppercase set at seven points with no letter-spacing
    /// closes up into a grey bar. The spacing is what makes it read as a
    /// label rather than a squashed word.
    func sectionHeading(
        _ title: String,
        x: Double? = nil,
        width columnWidth: Double? = nil,
        style: HeadingStyle = .ruled,
        color: Color? = nil,
        size: Double = 7.6
    ) {
        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let label = title.uppercased()
        let tint = color ?? muted

        pdf.breakIfNeeded(leading(size) + 46)

        switch style {
        case .accentBar:
            // A short stub of accent to the left of the label. Carries colour
            // without tinting any text, which keeps the page readable if the
            // accent is pale or the printer is monochrome.
            let baseline = pdf.cursor()
            pdf.rect(x: originX, y: baseline - 7.5, width: 13, height: 2.4, color: accent)
            pdf.textAt(label, x: originX + 20, y: baseline - 9, size: size,
                       color: tint, face: semibold, tracking: size * 0.14)
            pdf.move(to: baseline - 9)

        case .ruled:
            let baseline = pdf.cursor()
            pdf.textAt(label, x: originX, y: baseline - 8, size: size,
                       color: tint, face: semibold, tracking: size * 0.14)
            pdf.move(to: baseline - 13)
            pdf.line(from: originX, pdf.cursor(), to: originX + boxWidth, pdf.cursor(),
                     color: hairline, thickness: 0.6)

        case .plain:
            let baseline = pdf.cursor()
            pdf.textAt(label, x: originX, y: baseline - 8, size: size,
                       color: tint, face: semibold, tracking: size * 0.14)
            pdf.move(to: baseline - 9)

        case .centred:
            let baseline = pdf.cursor()
            pdf.textAt(label, x: originX, y: baseline - 8, size: size,
                       color: tint, align: .center, boxWidth: boxWidth,
                       face: semibold, tracking: size * 0.14)
            pdf.move(to: baseline - 13)
            // A rule broken either side of the label, drawn as two segments
            // with the label's measured width left out of the middle.
            let measured = pdf.width(of: label, size: size, face: semibold, tracking: size * 0.14)
            let inset = (boxWidth - measured) / 2 - 10
            if inset > 20 {
                pdf.line(from: originX, pdf.cursor() + 5, to: originX + inset, pdf.cursor() + 5,
                         color: hairline, thickness: 0.6)
                pdf.line(from: originX + boxWidth - inset, pdf.cursor() + 5,
                         to: originX + boxWidth, pdf.cursor() + 5, color: hairline, thickness: 0.6)
            }
        }
        gap(12)
    }

    /// A line of text, advancing the cursor by its own height.
    @discardableResult
    func line(
        _ text: String,
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 9.4,
        face: EmbeddedFont? = nil,
        color: Color? = nil,
        align: Align = .left,
        tracking: Double = 0,
        advance: Bool = true
    ) -> Double {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return 0 }

        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let top = pdf.cursor()

        pdf.cell(text, x: originX, boxWidth: boxWidth, size: size,
                 color: color ?? ink, align: align, face: face ?? regular, tracking: tracking)

        let height = leading(size)
        if advance { pdf.move(to: top - height) }
        return height
    }

    /// Wrapped body text.
    @discardableResult
    func paragraph(
        _ text: String,
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 9.4,
        face: EmbeddedFont? = nil,
        color: Color? = nil
    ) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let step = leading(size)
        let resolved = face ?? regular

        // Measured and broken before anything is drawn: `block` does not page
        // break on its own, so a paragraph starting four lines from the
        // bottom would run off the page rather than onto the next one.
        let height = pdf.blockHeight(trimmed, size: size, width: boxWidth, leading: step, face: resolved)
        pdf.breakIfNeeded(height)

        return pdf.block(trimmed, x: originX, width: boxWidth, size: size,
                         color: color ?? ink, leading: step, face: resolved)
    }

    /// A list with a hanging indent, so wrapped lines line up under the text
    /// rather than under the bullet.
    func bullets(
        _ items: [String],
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 9.4,
        glyph: String = "•"
    ) {
        guard !items.isEmpty else { return }

        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let indent = size * 1.25
        let step = leading(size)

        for item in items {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let height = pdf.blockHeight(
                trimmed, size: size, width: boxWidth - indent, leading: step, face: regular
            )
            // Kept whole where it will fit on the next page. A bullet split
            // across a page break reads as two separate claims.
            pdf.breakIfNeeded(min(height, step * 3))

            let top = pdf.cursor()
            pdf.cell(glyph, x: originX, boxWidth: indent, size: size, color: muted, face: regular)
            pdf.move(to: top)
            pdf.block(trimmed, x: originX + indent, width: boxWidth - indent,
                      size: size, color: ink, leading: step, face: regular)
            rigidGap(size * 0.22)
        }
    }

    /// Comma-separated terms under a label — "Languages   Swift, Go, Rust".
    func skillRow(
        _ group: SkillGroup,
        x: Double? = nil,
        width columnWidth: Double? = nil,
        labelWidth: Double,
        size: Double = 9.2
    ) {
        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let items = group.names.joined(separator: ", ")
        let step = leading(size)

        let height = pdf.blockHeight(
            items, size: size, width: boxWidth - labelWidth, leading: step, face: regular
        )
        pdf.breakIfNeeded(height)

        let top = pdf.cursor()
        pdf.cell(group.name, x: originX, boxWidth: labelWidth - 8, size: size,
                 color: muted, face: medium)
        pdf.move(to: top)
        pdf.block(items, x: originX + labelWidth, width: boxWidth - labelWidth,
                  size: size, color: ink, leading: step, face: regular)
        rigidGap(size * 0.3)
    }

    /// Contact details flowed across a width, wrapping onto further lines.
    ///
    /// Flowed rather than joined and wrapped as one string, so a break never
    /// falls inside an email address or between a separator and the thing it
    /// separates. A phone number split across two lines is not a phone number.
    @discardableResult
    func contactFlow(
        _ items: [String],
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 8.6,
        color: Color? = nil,
        align: Align = .left,
        separator: String = "·"
    ) -> Double {
        let entries = items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !entries.isEmpty else { return 0 }

        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let joiner = "  \(separator)  "
        let joinerWidth = pdf.width(of: joiner, size: size, face: regular)

        var rows: [String] = []
        var row = ""
        var rowWidth = 0.0

        for entry in entries {
            let entryWidth = pdf.width(of: entry, size: size, face: regular)
            let needed = row.isEmpty ? entryWidth : rowWidth + joinerWidth + entryWidth

            if !row.isEmpty, needed > boxWidth {
                rows.append(row)
                row = entry
                rowWidth = entryWidth
            } else {
                row = row.isEmpty ? entry : row + joiner + entry
                rowWidth = needed
            }
        }
        if !row.isEmpty { rows.append(row) }

        let step = size * 1.5
        for text in rows {
            pdf.cell(text, x: originX, boxWidth: boxWidth, size: size,
                     color: color ?? muted, align: align, face: regular)
            pdf.move(to: pdf.cursor() - step)
        }
        return Double(rows.count) * step
    }

    /// Two runs on one baseline, the second in a quieter style — "Stripe ·
    /// London", where only the employer is emphasised.
    func qualified(
        _ lead: String,
        _ trailing: String,
        x: Double? = nil,
        size: Double = 9.4,
        leadFace: EmbeddedFont? = nil,
        leadColor: Color? = nil,
        separator: String = "  ·  "
    ) {
        let originX = x ?? left
        let top = pdf.cursor()
        let head = lead.trimmingCharacters(in: .whitespaces)
        let tail = trailing.trimmingCharacters(in: .whitespaces)

        var cursorX = originX
        if !head.isEmpty {
            pdf.cell(head, x: cursorX, boxWidth: width, size: size,
                     color: leadColor ?? ink, face: leadFace ?? medium)
            cursorX += pdf.width(of: head, size: size, face: leadFace ?? medium)
        }
        if !tail.isEmpty {
            let prefix = head.isEmpty ? "" : separator
            pdf.cell(prefix + tail, x: cursorX, boxWidth: width - (cursorX - originX),
                     size: size, color: muted, face: regular)
        }
        pdf.move(to: top - leading(size))
    }

    // MARK: Components

    /// Keyword tags, flowed across a width and wrapping.
    ///
    /// The one decorative treatment on a résumé that costs nothing: a chip is
    /// a real word a parser reads as a keyword, unlike a bar or a dial, which
    /// are pictures of a number nobody can check.
    @discardableResult
    func chips(
        _ items: [String],
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 8.4,
        filled: Bool = true
    ) -> Double {
        let entries = items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !entries.isEmpty else { return 0 }

        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let padding = size * 0.72
        let height = size * 1.95
        let spacing = size * 0.42
        let top = cursor

        // Broken into rows before anything is drawn, so each row can be
        // page-broken on its own. Flowing straight onto the page with a
        // running y instead is how a list of skills ends up printed over the
        // footer — the cursor never moves, so nothing ever checks the margin.
        var rows: [[(text: String, width: Double)]] = []
        var row: [(text: String, width: Double)] = []
        var used = 0.0

        for entry in entries {
            let chipWidth = pdf.width(of: entry, size: size, face: regular) + padding * 2
            if !row.isEmpty, used + chipWidth > boxWidth {
                rows.append(row)
                row = []
                used = 0
            }
            row.append((entry, chipWidth))
            used += chipWidth + spacing
        }
        if !row.isEmpty { rows.append(row) }

        for line in rows {
            pdf.breakIfNeeded(height + spacing)
            let baseline = cursor - height
            var cursorX = originX

            for chip in line {
                if filled {
                    pdf.roundedRect(x: cursorX, y: baseline, width: chip.width,
                                    height: height, radius: height / 2, color: wash)
                } else {
                    pdf.roundedRect(x: cursorX, y: baseline, width: chip.width,
                                    height: height, radius: height / 2, color: page)
                    pdf.line(from: cursorX, baseline, to: cursorX + chip.width, baseline,
                             color: hairline, thickness: 0.6)
                }

                pdf.textAt(
                    chip.text, x: cursorX + padding,
                    y: baseline + (height - size * 0.72) / 2,
                    size: size, color: ink, face: regular
                )
                cursorX += chip.width + spacing
            }
            pdf.move(to: baseline - spacing)
        }

        pdf.gap(size * 0.3)
        return top - cursor
    }

    /// A row of filled and empty dots.
    ///
    /// Five of them, because a scale with more points than a reader can
    /// distinguish is a scale pretending to a precision it does not have.
    func dots(_ fraction: Double, x: Double, y dotY: Double, size: Double = 4, count: Int = 5) {
        let filled = Int((min(max(fraction, 0), 1) * Double(count)).rounded())
        let spacing = size * 2.6

        for index in 0..<count {
            let centre = x + Double(index) * spacing + size / 2
            if index < filled {
                pdf.circle(x: centre, y: dotY, radius: size / 2, color: accent)
            } else {
                pdf.ring(x: centre, y: dotY, radius: size / 2 - 0.35, thickness: 0.7, color: hairline)
            }
        }
    }

    /// A dial — a ring with an arc over it and the figure inside.
    func dial(
        _ fraction: Double,
        x: Double, y dialY: Double,
        radius: Double,
        caption: String = ""
    ) {
        let value = min(max(fraction, 0), 1)
        let thickness = max(2.2, radius * 0.17)

        pdf.ring(x: x, y: dialY, radius: radius, thickness: thickness, color: hairline)
        if value > 0.001 {
            pdf.arc(x: x, y: dialY, radius: radius, from: 0, to: 360 * value,
                    thickness: thickness, color: accent)
        }

        let figure = "\(Int((value * 100).rounded()))"
        let size = radius * 0.72
        pdf.textAt(figure, x: x - radius, y: dialY - size * 0.36, size: size,
                   color: ink, align: .center, boxWidth: radius * 2, face: medium)

        guard !caption.isEmpty else { return }
        pdf.textAt(caption, x: x - radius * 1.5, y: dialY - radius - 11, size: 7.6,
                   color: muted, align: .center, boxWidth: radius * 3, face: regular)
    }

    /// A labelled bar.
    func gauge(
        _ label: String,
        _ fraction: Double,
        x: Double,
        width columnWidth: Double,
        labelWidth: Double,
        size: Double = 8.6
    ) {
        let top = cursor
        pdf.cell(label, x: x, boxWidth: labelWidth - 8, size: size, color: ink, face: regular)

        let barWidth = columnWidth - labelWidth
        if barWidth > 20 {
            pdf.meter(
                x: x + labelWidth, y: top - size * 1.05,
                width: barWidth, height: max(3.4, size * 0.42),
                fraction: fraction, color: accent, track: wash
            )
        }
        pdf.move(to: top - leading(size))
    }

    /// A portrait, clipped to a circle.
    ///
    /// Silently absent when there is no photograph or it cannot be read: a
    /// résumé that refuses to render because a JPEG moved is worse than one
    /// with a gap where a face was, and ``ATS`` reports the reason.
    @discardableResult
    func portrait(_ path: String, x: Double, y photoY: Double, diameter: Double) -> Bool {
        guard let picture = Sheet.photo(at: path) else { return false }
        pdf.circularImage(picture, x: x, y: photoY, diameter: diameter)
        return true
    }

    /// Loads a portrait, or nothing.
    static func photo(at path: String) -> EmbeddedImage? {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let expanded = (trimmed as NSString).expandingTildeInPath
        return try? EmbeddedImage.load(URL(fileURLWithPath: expanded))
    }

    /// A wrapped block whose opening phrase is set in a heavier weight.
    ///
    /// The two runs are laid end to end, not drawn over one another. Printing
    /// the whole thing in one weight and re-stamping the lead-in on top is the
    /// obvious shortcut and it only works if the two faces are the same width,
    /// which is the one thing a bold and a regular are guaranteed not to be —
    /// the result is a double-struck smear.
    ///
    /// So the lead is measured, the first line of the detail is filled with
    /// whatever fits beside it, and the remainder wraps at full width.
    func runOn(
        _ lead: String,
        _ detail: String,
        x: Double? = nil,
        width columnWidth: Double? = nil,
        size: Double = 9.4,
        leadFace: EmbeddedFont? = nil,
        color: Color? = nil
    ) {
        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        let heavy = leadFace ?? semibold
        let tint = color ?? ink
        let step = leading(size)

        let trimmedLead = lead.trimmingCharacters(in: .whitespaces)
        guard !trimmedLead.isEmpty else {
            paragraph(detail, x: originX, width: boxWidth, size: size, color: tint)
            return
        }

        let leadWidth = pdf.width(of: trimmedLead + " ", size: size, face: heavy)
        var words = detail.split(whereSeparator: { $0 == " " }).map(String.init)

        var opening = ""
        while let word = words.first {
            let candidate = opening.isEmpty ? word : opening + " " + word
            guard leadWidth + pdf.width(of: candidate, size: size, face: regular) <= boxWidth else { break }
            opening = candidate
            words.removeFirst()
        }

        pdf.breakIfNeeded(step * 2)
        let top = cursor

        pdf.cell(trimmedLead, x: originX, boxWidth: boxWidth, size: size, color: tint, face: heavy)
        if !opening.isEmpty {
            pdf.cell(opening, x: originX + leadWidth, boxWidth: boxWidth - leadWidth,
                     size: size, color: tint, face: regular)
        }
        pdf.move(to: top - step)

        let remainder = words.joined(separator: " ")
        guard !remainder.isEmpty else { return }
        pdf.block(remainder, x: originX, width: boxWidth, size: size,
                  color: tint, leading: step, face: regular)
    }

    /// A rule across a column.
    func rule(x: Double? = nil, width columnWidth: Double? = nil, color: Color? = nil, thickness: Double = 0.6) {
        let originX = x ?? left
        let boxWidth = columnWidth ?? width
        pdf.line(from: originX, pdf.cursor(), to: originX + boxWidth, pdf.cursor(),
                 color: color ?? hairline, thickness: thickness)
    }

    /// The running foot, from the second page on.
    ///
    /// Only from the second: a page number on a one-page document says the
    /// document was produced by something that could not tell. The name goes
    /// with it because printed pages get separated, and page two of a résumé
    /// with no name on it belongs to nobody.
    func footer(name: String) {
        let tint = muted
        let rule = hairline

        pdf.onEachPage { doc, page, total in
            guard total > 1 else { return }

            doc.line(from: doc.left(), 46, to: doc.right(), 46, color: rule, thickness: 0.5)
            doc.textAt(name, x: doc.left(), y: 34, size: 7.6, color: tint)
            doc.textAt("\(page) / \(total)", x: doc.left(), y: 34, size: 7.6,
                       color: tint, align: .right, boxWidth: doc.contentWidth())
        }
    }
}

// MARK: - Heading style

/// How a section heading is set.
enum HeadingStyle {

    /// Label, then a hairline across the column.
    case ruled

    /// Label alone.
    case plain

    /// A short accent stub, then the label.
    case accentBar

    /// Centred, with the rule broken either side of it.
    case centred
}
