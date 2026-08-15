//
//  Swiss.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A very large name, very small labels, and a great deal of nothing.
//
//  The most modern-looking design here and the one with the least in it. Every
//  other design earns its distinctiveness by adding something — a panel, a
//  rail, a mark. This one earns it by taking things away and then setting what
//  is left with more care: one hairline, one type size for labels, and a name
//  large enough to be the only ornament on the page.
//
//  It costs vertical space, which is the trade. On a career that fits, it is
//  the most confident page in the set; on one that does not, it is the first
//  design to run over and the wrong choice.
//

import Foundation
import TextPDF

struct Swiss: Design {

    var showsCode: Bool { true }

    /// The label column, which is narrow because the labels are tiny.
    private let labelWidth = 76.0
    private let gutter = 26.0

    func render(_ resume: Resume, on sheet: Sheet) {
        let bodyX = sheet.left + labelWidth + gutter
        let bodyWidth = sheet.width - labelWidth - gutter

        masthead(resume, on: sheet, bodyX: bodyX, bodyWidth: bodyWidth)

        var style = Blocks.Style(x: bodyX, width: bodyWidth)
        style.roleSize = 11
        style.bodySize = 9.5
        style.detailSize = 9.4
        style.entryGap = 20

        for (index, section) in resume.populated().enumerated() {
            sheet.gap(index == 0 ? 6 : 24)
            sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 4)

            // The label sits at the top of the block, set very small and
            // tracked wide. At this size it reads as a marginal note, which is
            // what it is — the content is the page.
            sheet.pdf.cell(
                resume.heading(for: section).uppercased(),
                x: sheet.left, boxWidth: labelWidth, size: 6.8,
                color: sheet.muted, face: sheet.medium, tracking: 1.0
            )
            Blocks.render(section, of: resume, on: sheet, style: style)
        }

        sheet.footer(name: resume.profile.name)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet, bodyX: Double, bodyWidth: Double) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        // Set to the full width of the page and as large as that allows, down
        // to a floor. A name is the one thing on a résumé that is allowed to
        // be big, and sizing it to the measure rather than to a constant means
        // a short name fills the line and a long one still fits.
        let size = min(52.0, max(30.0, sheet.width * 62 / max(1, Double(profile.name.count)) / 3.4))

        // The name keeps the whole measure. This design is an oversized name
        // and a lot of air; taking sixty points off it for a code would make
        // a long name shrink or truncate, and a truncated name is the one
        // thing on a résumé that cannot be allowed.
        pdf.textAt(profile.name, x: sheet.left, y: top - size * 0.82, size: size,
                   color: sheet.ink, face: sheet.semibold, tracking: -size * 0.028)

        var y = top - size * 0.82 - 24
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 12,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
            y -= 26
        }

        pdf.move(to: y)
        pdf.line(from: sheet.left, pdf.cursor(), to: sheet.right, pdf.cursor(),
                 color: sheet.ink, thickness: 1)
        sheet.gap(16)

        pdf.cell("CONTACT", x: sheet.left, boxWidth: labelWidth, size: 6.8,
                 color: sheet.muted, face: sheet.medium, tracking: 1.0)

        // Level with the contact details rather than beside the name: this is
        // where the page is empty, and where somebody looking for how to
        // reach you is already looking.
        let code = 62.0
        let band = pdf.cursor()
        let coded = sheet.code(profile.qr, x: sheet.right - code,
                               y: band - code + 10, size: code)
        let measure = coded ? bodyWidth - code - 18 : bodyWidth

        sheet.contactFlow(profile.contactEntries(), x: bodyX, width: measure, size: 9)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              x: bodyX, width: measure, size: 8.6)
        }

        // The code is taller than the two lines beside it, so the next section
        // starts below whichever ran longer. Without this the summary is drawn
        // straight through it.
        if coded { pdf.move(to: min(pdf.cursor(), band - code + 2)) }
    }
}
