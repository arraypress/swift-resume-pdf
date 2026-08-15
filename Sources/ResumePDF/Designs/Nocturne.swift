//
//  Nocturne.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A light band at the top, and the rest of the page inverted.
//
//  The one design here that is mostly about colour, and the reason it is a
//  design rather than a theme: the split is a layout decision. The masthead
//  keeps the page's own colour so a name and an email address are read the way
//  they are read everywhere else, and everything below it reverses — which
//  makes the band a masthead rather than merely the first inch of the page.
//
//  Single column, deliberately. The references this comes from are two-column
//  and therefore unparseable, and a dark two-column document is a dark version
//  of ``Sidebar`` rather than anything new. Keeping it to one column means the
//  striking option is not automatically the unsendable one.
//
//  ## Printing
//
//  A page of reversed type uses a great deal of toner, and a recruiter's
//  office printer will make a worse job of it than a screen does. That is a
//  real cost of this design and not a reason to avoid it — but it is why the
//  default is not this.
//

import Foundation
import TextPDF

struct Nocturne: Design {

    var showsPhoto: Bool { true }

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let top = pdf.height() - sheet.theme.density.margin

        // The body is the page inverted. A dark theme therefore gives a dark
        // masthead over a light body, which is the same idea upside down and
        // still reads as one decision.
        let bodyFill = sheet.theme.scheme == .dark
            ? sheet.theme.page.lightened(by: 0.93)
            : sheet.theme.page.darkened(by: 0.9)
        let body = Sheet.Palette.against(bodyFill, accent: sheet.theme.accentColor)

        let bandHeight = masthead(resume, on: sheet, top: top)
        let bandBottom = pdf.height() - bandHeight

        // Painted behind the content on every page, and on pages after the
        // first it covers the whole sheet — the masthead belongs to page one.
        sheet.background { doc, page, _ in
            let height = page == 1 ? bandBottom : doc.height()
            doc.rect(x: 0, y: 0, width: doc.width(), height: height, color: bodyFill)
        }

        // A hairline of accent under the band, which is what makes the split
        // look intended rather than like a printing fault.
        pdf.rect(x: 0, y: bandBottom - 2.4, width: pdf.width(), height: 2.4, color: sheet.accent)

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

        footer(resume.profile.name, on: sheet, palette: body)
    }

    /// The light band. Returns its height.
    private func masthead(_ resume: Resume, on sheet: Sheet, top: Double) -> Double {
        let pdf = sheet.pdf
        let profile = resume.profile

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        var y = top - 41
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.6,
                       color: sheet.muted, face: sheet.regular)
            y -= 17
        }

        pdf.move(to: y)
        sheet.contactFlow(profile.contactEntries(), size: 8.7)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, size: 8.4)
        }

        // A portrait sits against the right edge of the band, where it does
        // not push the name around.
        let diameter = 74.0
        if sheet.portrait(profile.photo, x: sheet.right - diameter,
                          y: top - diameter + 6, diameter: diameter) {
            pdf.move(to: min(pdf.cursor(), top - diameter - 4))
        }

        return pdf.height() - pdf.cursor() + 14
    }

    private func footer(_ name: String, on sheet: Sheet, palette: Sheet.Palette) {
        let tint = palette.muted
        let rule = palette.hairline

        sheet.pdf.onEachPage { doc, page, total in
            guard total > 1 else { return }
            doc.line(from: doc.left(), 46, to: doc.right(), 46, color: rule, thickness: 0.5)
            doc.textAt(name, x: doc.left(), y: 34, size: 7.6, color: tint)
            doc.textAt("\(page) / \(total)", x: doc.left(), y: 34, size: 7.6,
                       color: tint, align: .right, boxWidth: doc.contentWidth())
        }
    }
}
