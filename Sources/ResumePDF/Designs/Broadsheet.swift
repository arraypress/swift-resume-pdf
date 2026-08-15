//
//  Broadsheet.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A centred masthead and a serif, for documents that should not look new.
//
//  Academia, law, medicine, the civil service, and senior roles anywhere:
//  places where a résumé that looks like a product landing page reads as a
//  misjudgement of the room. The serif is doing the work — the arrangement is
//  otherwise as plain as Ledger, and just as parseable.
//
//  Names are set in small capitals rather than at a larger size. A CV whose
//  owner has forty years of publications does not need its author's name in
//  thirty-point type, and setting it that way looks like it is compensating.
//

import Foundation
import TextPDF

struct Broadsheet: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.roleSize = 10.6
        style.bodySize = 9.7
        style.detailSize = 9.5
        style.entryGap = 14

        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .centred, size: 8)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(18)
        }

        sheet.footer(name: resume.profile.name)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        // Letter-spaced capitals, which is what a serif masthead wants. Set
        // solid, the capitals of a transitional face close up; opened out
        // they read as deliberate.
        pdf.textAt(profile.name.uppercased(), x: sheet.left, y: top - 20, size: 19,
                   color: sheet.ink, align: .center, boxWidth: sheet.width,
                   face: sheet.regular, tracking: 2.2)

        var y = top - 38
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.6,
                       color: sheet.muted, align: .center, boxWidth: sheet.width,
                       face: sheet.italic)
            y -= 17
        }

        pdf.move(to: y)
        sheet.contactFlow(
            profile.contactEntries(),
            size: 8.8, align: .center
        )

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(
                particulars.map { "\($0.label): \($0.value)" },
                size: 8.5, align: .center
            )
        }

        sheet.rigidGap(6)
        sheet.rule(color: sheet.ink, thickness: 0.7)
        sheet.rigidGap(2.6)
        // A second, lighter rule. The pair is a broadsheet's signature and
        // costs two points of vertical space.
        sheet.rule(color: sheet.hairline, thickness: 0.5)
        sheet.gap(20)
    }
}
