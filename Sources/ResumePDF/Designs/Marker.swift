//
//  Marker.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Section headings struck through with a highlighter.
//
//  A block of colour behind part of the word, as though somebody went over the
//  page with a marker pen. It is the least formal design here and the one with
//  the most personality, which makes it right for a studio and wrong for a
//  bank.
//
//  The block covers roughly the first two-thirds of the label rather than all
//  of it, because a pen does not stop neatly and a rectangle that does looks
//  like a table cell. That ragged end is the whole effect.
//

import Foundation
import TextPDF

struct Marker: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 15
        style.skills = .bars

        for section in resume.populated() {
            highlighted(resume.heading(for: section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(18)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// The heading, with a swipe of colour behind its first two-thirds.
    private func highlighted(_ title: String, on sheet: Sheet) {
        let pdf = sheet.pdf
        let size = 12.0
        let label = title.uppercased()
        let tracking = size * 0.05

        pdf.breakIfNeeded(size * 3 + 52)
        let top = pdf.cursor()
        let measured = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)

        // Pale enough to read black type through. A highlighter that hides the
        // word it marks is a redaction.
        let swipe = sheet.theme.isMonochrome
            ? sheet.theme.wash.darkened(by: 0.06)
            : sheet.accent.lightened(by: 0.62)

        pdf.rect(x: sheet.left - 3, y: top - size * 1.12,
                 width: measured * 0.66 + 6, height: size * 1.05, color: swipe)

        pdf.textAt(label, x: sheet.left, y: top - size * 0.92, size: size,
                   color: sheet.ink, face: sheet.semibold, tracking: tracking)

        pdf.move(to: top - size * 1.5)
        sheet.gap(11)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 24, size: 28,
                   color: sheet.ink, align: .center, boxWidth: sheet.width,
                   face: sheet.semibold, tracking: -0.5)

        // A short rule under the name, in the accent, as a signature would be.
        let measured = pdf.width(of: profile.name, size: 28, face: sheet.semibold, tracking: -0.5)
        pdf.rect(x: sheet.left + (sheet.width - measured) / 2, y: top - 32,
                 width: measured, height: 2.6, color: sheet.accent)

        var y = top - 52
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.8,
                       color: sheet.muted, align: .center, boxWidth: sheet.width,
                       face: sheet.regular)
            y -= 18
        }

        pdf.move(to: y)
        sheet.contactFlow(profile.contactEntries(),
                          size: 8.7, align: .center, separator: "▪")

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              size: 8.4, align: .center)
        }
        sheet.gap(14)
    }
}
