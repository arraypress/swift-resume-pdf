//
//  Bulletin.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Section headings as tabs, each with a mark beside it.
//
//  The heading becomes an object rather than a line of type, which makes the
//  page navigable at a glance — useful for a long CV, and the reason software
//  documentation has looked like this for twenty years.
//
//  The icons are decoration and nothing more. The heading underneath one is
//  still the same word a parser matches on, so the mark costs nothing; this is
//  the only ornament in the set that is genuinely free.
//

import Foundation
import TextPDF

struct Bulletin: Design {

    var showsPhoto: Bool { true }

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        var style = Blocks.Style(x: sheet.left, width: sheet.width)
        style.entryGap = 14
        style.skills = .chips

        for section in resume.populated() {
            tab(resume.heading(for: section), icon: Icon.of(section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(16)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// A rounded tab with a circled mark at its left.
    private func tab(_ title: String, icon: Icon, on sheet: Sheet) {
        let pdf = sheet.pdf
        let height = 21.0
        let badge = 20.0

        pdf.breakIfNeeded(height + 66)
        let top = pdf.cursor()
        let bottom = top - height

        // The tab is measured to the words, so it frames them rather than the
        // column. The badge sits inside the tab's rounded end, concentric with
        // it: one that began at the badge's centre showed its own edge through
        // the ring.
        let size = 8.2
        let label = title.uppercased()
        let tracking = size * 0.14
        let textWidth = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)
        let centreX = sheet.left + height / 2
        let centreY = bottom + height / 2
        let textX = sheet.left + height + 6

        pdf.roundedRect(
            x: sheet.left, y: bottom,
            width: textX - sheet.left + textWidth + 13, height: height,
            radius: height / 2, color: sheet.wash
        )

        let filled = sheet.theme.accentIsDark && !sheet.theme.isMonochrome
        if filled {
            pdf.circle(x: centreX, y: centreY, radius: badge / 2, color: sheet.accent)
        } else {
            pdf.ring(x: centreX, y: centreY, radius: badge / 2 - 0.5,
                     thickness: 1.1, color: sheet.accent)
        }

        sheet.icon(
            icon,
            x: centreX - 5.5, y: centreY - 5.5, size: 11,
            color: filled ? sheet.theme.page : sheet.accent
        )

        pdf.textAt(label, x: textX, y: bottom + (height - size * 0.72) / 2,
                   size: size, color: sheet.ink, face: sheet.semibold, tracking: tracking)

        pdf.move(to: bottom)
        sheet.gap(12)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        let diameter = 78.0
        let hasPhoto = Sheet.photo(at: profile.photo) != nil
        if hasPhoto {
            sheet.portrait(profile.photo, x: sheet.right - diameter, y: top - diameter + 4,
                           diameter: diameter)
        }

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        var y = top - 42
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 11,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
            y -= 18
        }

        pdf.move(to: y - 2)
        let width = hasPhoto ? sheet.width - diameter - 20 : sheet.width
        sheet.contactFlow(profile.contactEntries(),
                          width: width, size: 8.7)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              width: width, size: 8.4)
        }

        if hasPhoto { pdf.move(to: min(pdf.cursor(), top - diameter - 6)) }
        sheet.gap(16)
    }
}
