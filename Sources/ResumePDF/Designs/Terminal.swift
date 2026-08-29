//
//  Terminal.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Monospace for the data, proportional type for the prose.
//
//  The mixture is the design, and it is not decoration. Dates, versions,
//  ratios and technology names are read by comparing them down a column, and
//  a monospaced face makes that possible — "Mar 2022" and "Sep 2016" line up
//  digit under digit. Sentences are read along a line, and monospaced prose at
//  nine points is markedly harder work than the same words proportionally set.
//
//  So the labels, the dates and the skills are mono, and everything somebody
//  has to actually read is not. Setting the whole page in a monospace is the
//  obvious version of this idea and the wrong one — it looks like a terminal,
//  which is the joke, and then it has to be read.
//
//  The identity has to come from the chrome, then. Every heading is preceded
//  by a prompt — drawn as two strokes, not typed, so the words a parser
//  matches on are still the words — and the contact details run along one
//  mono line, the way a shell prints a status line, rather than down the
//  page one address at a time.
//

import Foundation
import TextPDF

struct Terminal: Design {

    var showsCode: Bool { true }

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 15
        style.skills = .list

        for section in resume.populated() {
            heading(resume.heading(for: section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(17)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// A prompt, a mono label, and a rule running out from it to the margin.
    private func heading(_ title: String, on sheet: Sheet) {
        let pdf = sheet.pdf
        let size = 8.2
        let label = title.uppercased()
        let tracking = size * 0.1

        pdf.breakIfNeeded(sheet.leading(size) + 62)
        let baseline = pdf.cursor()

        // The prompt sits on the label's x-height centre, in the accent where
        // there is one — the one place colour belongs on this page.
        sheet.prompt(x: sheet.left, y: baseline - 5, size: size,
                     color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent)
        let labelX = sheet.left + size * 1.3

        pdf.textAt(label, x: labelX, y: baseline - 8, size: size,
                   color: sheet.ink, face: sheet.monoMedium, tracking: tracking)

        // The rule starts where the label ends rather than under it, so the
        // two read as one object. Measured with the mono face, which is the
        // only reason the gap is right.
        let measured = pdf.width(of: label, size: size, face: sheet.monoMedium, tracking: tracking)
        let from = labelX + measured + 12
        if from < sheet.right - 20 {
            pdf.line(from: from, baseline - 5, to: sheet.right, baseline - 5,
                     color: sheet.hairline, thickness: 0.7)
        }

        pdf.move(to: baseline - 12)
        sheet.gap(11)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        // Drawn first so the width it takes is known: a name set without
        // regard for it ran straight through the code and left it unreadable.
        let code = 58.0
        let coded = sheet.code(profile.qr, x: sheet.right - code, y: top - code, size: code)
        let measure = coded ? sheet.width - code - 20 : sheet.width

        pdf.textAt(pdf.fit(profile.name, into: measure, size: 23, face: sheet.monoBold),
                   x: sheet.left, y: top - 21, size: 23,
                   color: sheet.ink, face: sheet.monoBold, tracking: -0.9)

        var y = top - 41
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.4,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.mono)
            y -= 18
        }

        // Contact details are addresses, which is data — so mono. Flowed
        // along one line like a status line, and kept clear of the code: a
        // column of five addresses cost a quarter of the masthead and said
        // nothing a line does not.
        pdf.move(to: y - 2)
        sheet.contactFlow(profile.contactEntries(), width: measure,
                          size: 8.6, separator: "|", face: sheet.mono)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, width: measure,
                              size: 8.4, separator: "|", face: sheet.mono)
        }

        sheet.rigidGap(6)
        sheet.rule(color: sheet.ink, thickness: 1)
        sheet.gap(18)
    }
}
