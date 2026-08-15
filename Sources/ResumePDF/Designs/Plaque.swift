//
//  Plaque.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A coloured panel across the top, with the name reversed out of it.
//
//  The most common way a résumé template announces itself, and the one most
//  often done badly: a band of colour is only a masthead if what sits on it
//  can be read. The panel takes the accent, the type on it is chosen against
//  the panel rather than against the page, and where the accent is too pale to
//  reverse out of, the panel is outlined instead of filled.
//
//  The lower edge is a shallow chevron rather than a straight line. It costs
//  nothing, it stops the band reading as a printing error, and it is what the
//  eye follows down into the first section.
//

import Foundation
import TextPDF

struct Plaque: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let panel = masthead(resume, on: sheet)

        pdf.move(to: pdf.height() - panel - 30)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 14
        style.skills = .chips

        for section in resume.populated() {
            sheet.sectionHeading(
                resume.heading(for: section),
                style: .accentBar,
                color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent
            )
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(16)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// The panel. Returns its height.
    private func masthead(_ resume: Resume, on sheet: Sheet) -> Double {
        let pdf = sheet.pdf
        let profile = resume.profile
        let hasPhoto = Sheet.photo(at: profile.photo) != nil

        let height = hasPhoto ? 208.0 : 172.0
        let dip = 26.0
        let top = pdf.height()
        let bottom = top - height

        // Filled where the accent can carry reversed type, outlined where it
        // cannot. A pale accent with white text on it is a masthead nobody can
        // read, and it is the commonest fault in this shape of design.
        let reversed = sheet.theme.accentIsDark && !sheet.theme.isMonochrome
        let fill = reversed ? sheet.accent : sheet.wash
        let palette = Sheet.Palette.against(fill, accent: sheet.theme.accentColor)

        pdf.polygon([
            (x: 0, y: top),
            (x: pdf.width(), y: top),
            (x: pdf.width(), y: bottom + dip),
            (x: pdf.width() / 2, y: bottom),
            (x: 0, y: bottom + dip),
        ], color: fill)

        sheet.drawing(on: palette) {
            let inset = sheet.theme.density.margin
            let textWidth = hasPhoto ? pdf.width() - inset * 2 - 130 : pdf.width() - inset * 2

            pdf.textAt(profile.name, x: inset, y: top - 52, size: 27,
                       color: palette.ink, face: sheet.semibold, tracking: -0.4)

            if !profile.headline.isEmpty {
                pdf.textAt(profile.headline, x: inset, y: top - 74, size: 11.4,
                           color: palette.accent, face: sheet.regular)
            }

            pdf.move(to: top - 96)
            contactGrid(
                profile, on: sheet, x: inset, width: textWidth,
                columns: hasPhoto ? 1 : 2, color: palette.ink, icons: palette.accent
            )

            if hasPhoto {
                let diameter = 104.0
                sheet.portrait(profile.photo,
                               x: pdf.width() - inset - diameter,
                               y: top - 62 - diameter,
                               diameter: diameter)
            }
        }
        return height
    }

    /// Contact details as icon-and-value rows, in one or two columns.
    private func contactGrid(
        _ profile: Profile, on sheet: Sheet,
        x: Double, width: Double, columns: Int, color: Color, icons: Color
    ) {
        let entries: [(Icon, String)] = [
            (.email, profile.email),
            (.phone, profile.phone),
            (.location, profile.location),
        ].filter { !$0.1.trimmingCharacters(in: .whitespaces).isEmpty }
            + profile.links.map { (Icon.link, $0.label) }

        guard !entries.isEmpty else { return }

        let pdf = sheet.pdf
        let columnWidth = width / Double(columns)
        let size = 8.8
        let step = 17.0
        let top = pdf.cursor()

        for (index, entry) in entries.enumerated() {
            let column = index % columns
            let row = index / columns
            let originX = x + Double(column) * columnWidth
            let baseline = top - Double(row) * step

            sheet.icon(entry.0, x: originX, y: baseline - 10.5, size: 11.5, color: icons)
            pdf.textAt(entry.1, x: originX + 17, y: baseline - 8.6, size: size,
                       color: color, face: sheet.regular)
        }

        let rows = (entries.count + columns - 1) / columns
        pdf.move(to: top - Double(rows) * step)
    }
}
