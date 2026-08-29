//
//  Eclipse.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The whole page dark, and the masthead darker still.
//
//  Nocturne with the light band taken away. Nocturne keeps the page's own
//  colour for the masthead so a name is read the way it is read everywhere
//  else; here nothing on the page is the page's colour, and the masthead is
//  set apart by being a step blacker than the body rather than a step
//  lighter. The accent hairline under it does the same work it does in
//  Nocturne — it makes the split look intended.
//
//  Always dark, whatever the theme says, because that is the design. A dark
//  theme leaves the body as the theme's page and steps the band down from it;
//  a light theme gets both surfaces derived from black. Either way the
//  palettes are derived from the fills, so every shared block — bullets,
//  dates, chips, rules — reads inside them without being told.
//
//  Everything Nocturne says about printing applies twice over.
//

import Foundation
import TextPDF

struct Eclipse: Design {

    var showsPhoto: Bool { true }

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let top = pdf.height() - sheet.theme.density.margin

        let bodyFill = sheet.theme.scheme == .dark
            ? sheet.theme.page
            : sheet.theme.page.darkened(by: 0.88)
        let bandFill = bodyFill.darkened(by: 0.55)
        let body = Sheet.Palette.against(bodyFill, accent: sheet.theme.accentColor)
        let band = Sheet.Palette.against(bandFill, accent: sheet.theme.accentColor)

        var bandHeight = 0.0
        sheet.drawing(on: band) {
            bandHeight = masthead(resume, on: sheet, top: top)
        }
        let bandBottom = pdf.height() - bandHeight

        // Painted behind the content on every page. The band belongs to page
        // one; every page after it is the body's colour edge to edge.
        sheet.background { doc, page, _ in
            doc.rect(x: 0, y: 0, width: doc.width(), height: doc.height(), color: bodyFill)
            if page == 1 {
                doc.rect(x: 0, y: bandBottom, width: doc.width(),
                         height: doc.height() - bandBottom, color: bandFill)
            }
        }

        pdf.rect(x: 0, y: bandBottom - 2.4, width: pdf.width(), height: 2.4, color: body.accent)

        pdf.move(to: bandBottom - 30)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 14
        style.skills = .chips

        sheet.drawing(on: body) {
            for section in resume.populated() {
                sheet.sectionHeading(
                    resume.heading(for: section),
                    style: .plain,
                    color: body.accent
                )
                Blocks.render(section, of: resume, on: sheet, style: style)
                sheet.gap(17)
            }
        }

        sheet.footer(name: resume.profile.name, palette: body)
    }

    /// The band's contents, drawn in whatever palette the caller has put in
    /// force. Returns the band's height.
    private func masthead(_ resume: Resume, on sheet: Sheet, top: Double) -> Double {
        let pdf = sheet.pdf
        let profile = resume.profile

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        var y = top - 41
        if !profile.headline.isEmpty {
            // The role in the accent: the one place on a page this dark
            // where a colour has room to mean something.
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.6,
                       color: sheet.accent, face: sheet.regular)
            y -= 17
        }

        pdf.move(to: y)
        sheet.contactFlow(profile.contactEntries(), size: 8.7)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, size: 8.4)
        }

        // A portrait against the right edge of the band, as in Nocturne.
        let diameter = 74.0
        if sheet.portrait(profile.photo, x: sheet.right - diameter,
                          y: top - diameter + 6, diameter: diameter) {
            pdf.move(to: min(pdf.cursor(), top - diameter - 4))
        }

        return pdf.height() - pdf.cursor() + 14
    }
}
