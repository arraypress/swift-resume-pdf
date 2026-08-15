//
//  Ledger.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  One column, ruled sections, set in the sans.
//
//  The default, and the one to send when nothing is known about what will
//  read it. Everything runs in a single column in reading order, so a parser
//  gets the document in the order a person would; nothing lives in a header
//  or a footer where a parser would not look for it at all.
//
//  Restraint is the design. A name set large and confidently, a rule under
//  each section, and otherwise nothing that draws attention to the formatting
//  instead of the content.
//

import Foundation
import TextPDF

struct Ledger: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        let style = Blocks.Style(x: sheet.left, width: sheet.width)

        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .ruled)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(17)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// The name, the claim, and how to reach them.
    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        // Slightly tight tracking. Inter is drawn for text sizes, and at
        // display sizes its default spacing reads loose — closing it up is
        // what makes a name look set rather than typed.
        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25.5,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        var y = top - 40
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.8,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
            y -= 18
        }

        pdf.move(to: y)
        sheet.contactFlow(
            profile.contactLine() + profile.links.map(\.label),
            size: 8.7
        )

        // Regional particulars, where they have been set at all. A Lebenslauf
        // carries them; nothing else should, and nothing else will, because
        // they are empty unless somebody filled them in.
        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, size: 8.4)
        }

        sheet.rigidGap(5)
        sheet.rule(color: sheet.ink, thickness: 0.9)
        sheet.gap(19)
    }
}
