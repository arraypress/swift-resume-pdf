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
        sheet.contactFlow(profile.contactEntries(), x: bodyX, width: bodyWidth, size: 9)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              x: bodyX, width: bodyWidth, size: 8.6)
        }
    }
}
