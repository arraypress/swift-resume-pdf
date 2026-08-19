//
//  Banner.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A dark band across the head, and a light page under it.
//
//  The archetype the modern product company settled on: the identity lives
//  in a near-black masthead — name reversed out, the role in the accent, the
//  contact line inside the band — and everything below it is set with the
//  family's usual restraint. The band is the whole design; spending any more
//  colour under it would be saying the same thing twice.
//
//  Not ``Nocturne``, deliberately. Nocturne is a light masthead over a dark
//  page — the page is the statement, and it costs a recruiter's toner to
//  print. This is a dark band over a light page: the statement is one stripe,
//  and the rest prints like any other résumé.
//

import Foundation
import TextPDF

struct Banner: Design {

    var showsPhoto: Bool { true }

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let band = masthead(resume, on: sheet)

        pdf.move(to: pdf.height() - band - 28)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 14
        style.skills = .chips

        for section in resume.populated() {
            heading(resume.heading(for: section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(16)
        }

        sheet.footer(name: resume.profile.name)
    }

    // MARK: The band

    /// The dark band, with everything the head carries inside it.
    /// Returns its height.
    private func masthead(_ resume: Resume, on sheet: Sheet) -> Double {
        let pdf = sheet.pdf
        let profile = resume.profile
        let height = 150.0
        let top = pdf.height()

        // The band is the page inverted, the same trick Nocturne plays on
        // the body — so a dark theme gets a light band over its dark page,
        // and either way the head is the thing that is not the page.
        let fill = sheet.theme.scheme == .dark
            ? sheet.theme.page.lightened(by: 0.93)
            : sheet.theme.page.darkened(by: 0.9)
        let palette = Sheet.Palette.against(fill, accent: sheet.theme.accentColor)

        pdf.rect(x: 0, y: top - height, width: pdf.width(), height: height, color: fill)

        // A portrait sits inside the band against the right edge, vertically
        // centred, where it reads as part of the identity rather than as a
        // sticker on the page.
        let diameter = 84.0
        let hasPhoto = Sheet.photo(at: profile.photo) != nil
        if hasPhoto {
            sheet.portrait(profile.photo, x: sheet.right - diameter,
                           y: top - (height + diameter) / 2, diameter: diameter)
        }
        let textWidth = hasPhoto ? sheet.width - diameter - 22 : sheet.width

        sheet.drawing(on: palette) {
            pdf.textAt(profile.name, x: sheet.left, y: top - 56, size: 27,
                       color: palette.ink, face: sheet.semibold, tracking: -0.4)

            var y = top - 79.0
            if !profile.headline.isEmpty {
                pdf.textAt(profile.headline, x: sheet.left, y: y, size: 11.2,
                           color: palette.accent, face: sheet.regular)
                y -= 20
            }

            pdf.move(to: y + 3)
            sheet.contactFlow(profile.contactEntries(), width: textWidth,
                              size: 8.7, color: palette.muted)

            let particulars = profile.particulars()
            if !particulars.isEmpty {
                sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                                  width: textWidth, size: 8.4, color: palette.muted)
            }
        }
        return height
    }

    // MARK: Headings

    /// A section label with a short accent underline.
    ///
    /// The underline is the band's echo: a stub of ink under the label, not
    /// a rule across the column — the band already drew the page's one
    /// strong horizontal, and a second full-width line would compete with it.
    private func heading(_ title: String, on sheet: Sheet) {
        let pdf = sheet.pdf
        let size = 7.8
        let label = title.uppercased()

        // Kept with the first entry of what follows — see `sectionHeading`.
        pdf.breakIfNeeded(sheet.leading(size) + 64)
        let top = pdf.cursor()

        pdf.textAt(label, x: sheet.left, y: top - 8, size: size,
                   color: sheet.ink, face: sheet.semibold, tracking: size * 0.14)
        pdf.rect(x: sheet.left, y: top - 14.6, width: 22, height: 2.2, color: sheet.accent)

        pdf.move(to: top - 16)
        sheet.gap(11)
    }
}
