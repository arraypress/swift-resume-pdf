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

    /// A mono label with a rule running out from it to the margin.
    private func heading(_ title: String, on sheet: Sheet) {
        let pdf = sheet.pdf
        let size = 8.2
        let label = title.uppercased()
        let tracking = size * 0.1

        pdf.breakIfNeeded(sheet.leading(size) + 48)
        let baseline = pdf.cursor()

        pdf.textAt(label, x: sheet.left, y: baseline - 8, size: size,
                   color: sheet.ink, face: sheet.monoMedium, tracking: tracking)

        // The rule starts where the label ends rather than under it, so the
        // two read as one object. Measured with the mono face, which is the
        // only reason the gap is right.
        let measured = pdf.width(of: label, size: size, face: sheet.monoMedium, tracking: tracking)
        let from = sheet.left + measured + 12
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

        let code = 58.0
        sheet.code(profile.qr, x: sheet.right - code, y: top - code, size: code)

        pdf.textAt(profile.name, x: sheet.left, y: top - 21, size: 23,
                   color: sheet.ink, face: sheet.monoBold, tracking: -0.9)

        var y = top - 41
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.4,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.mono)
            y -= 18
        }

        // Contact details are addresses, which is data — so mono, and set one
        // per line rather than flowed, because a column of them is easier to
        // copy from than a paragraph.
        pdf.move(to: y - 2)
        for entry in profile.contactEntries() {
            let baseline = pdf.cursor() - 8.4
            if entry.url.isEmpty {
                pdf.textAt(entry.text, x: sheet.left, y: baseline, size: 8.6,
                           color: sheet.muted, face: sheet.mono)
            } else {
                pdf.linked(entry.text, url: entry.url, x: sheet.left, y: baseline,
                           size: 8.6, color: sheet.muted, face: sheet.mono)
            }
            pdf.move(to: pdf.cursor() - 13)
        }

        let particulars = profile.particulars()
        for item in particulars {
            pdf.textAt("\(item.label): \(item.value)", x: sheet.left, y: pdf.cursor() - 8.2,
                       size: 8.4, color: sheet.muted, face: sheet.mono)
            pdf.move(to: pdf.cursor() - 12.5)
        }

        sheet.rigidGap(6)
        sheet.rule(color: sheet.ink, thickness: 1)
        sheet.gap(18)
    }
}
