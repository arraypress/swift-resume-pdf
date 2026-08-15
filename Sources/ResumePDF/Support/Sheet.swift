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

    var ink: Color { theme.ink }
    var muted: Color { theme.muted }
    var accent: Color { theme.accentColor }
    var hairline: Color { theme.hairline }

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
        let items = group.items.joined(separator: ", ")
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
