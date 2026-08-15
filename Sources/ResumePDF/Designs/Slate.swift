//
//  Slate.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Two panels across the head, and a coloured tab beside every entry.
//
//  The summary sits in a pale panel on the left and the contact details in a
//  dark one on the right, which does two things at once: it gets the whole of
//  the top of the page working, and it puts the details a recruiter needs to
//  act on into the one block their eye is drawn to.
//
//  The tabs down the left edge are the other half. They are the shortest
//  possible version of a timeline — the eye counts four jobs before reading
//  any of them — and they cost one rectangle each.
//

import Foundation
import TextPDF

struct Slate: Design {

    private let tabWidth = 4.0
    private let tabGutter = 14.0

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        masthead(resume, on: sheet)

        let bodyX = sheet.left + tabWidth + tabGutter
        var style = Blocks.Style(x: bodyX, width: sheet.width - tabWidth - tabGutter)
        style.entryGap = 15
        style.skills = .chips

        // The summary is the left-hand panel in this design, so it must not
        // also appear as a section — the masthead is not a preview of the
        // page, it is part of it.
        for section in resume.populated() where section != .summary {
            sheet.sectionHeading(
                resume.heading(for: section),
                x: bodyX, width: style.width,
                style: .plain,
                color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent,
                size: 8.4
            )

            // A tab beside the whole section, recorded as it is drawn and only
            // where it stayed on one page — a rectangle whose ends are on
            // different sheets of paper is not a shape.
            let page = pdf.pageCount()
            let top = pdf.cursor() + 16

            Blocks.render(section, of: resume, on: sheet, style: style)

            if pdf.pageCount() == page {
                pdf.rect(x: sheet.left, y: pdf.cursor() + 4, width: tabWidth,
                         height: top - pdf.cursor() - 4, color: sheet.accent)
            }
            sheet.gap(16)
        }

        sheet.footer(name: resume.profile.name)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: top - 42, size: 11,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
        }

        let entries = contactEntries(profile)
        let panelTop = top - 58
        let gutter = 16.0
        let rightWidth = min(232.0, sheet.width * 0.44)
        let leftWidth = sheet.width - rightWidth - gutter
        let padding = 15.0

        // The panels are as tall as the taller of the two, so their bases line
        // up. Two panels of different heights read as a mistake rather than as
        // a composition.
        let summaryHeight = resume.summary.isEmpty ? 0 : pdf.blockHeight(
            resume.summary, size: 9.2, width: leftWidth - padding * 2,
            leading: sheet.leading(9.2), face: sheet.regular
        )
        let contactHeight = Double(entries.count) * 19
        let height = max(summaryHeight, contactHeight) + padding * 2

        let darkFill = sheet.theme.scheme == .dark
            ? sheet.theme.page.lightened(by: 0.12)
            : sheet.accentPanel
        let dark = Sheet.Palette.against(darkFill, accent: sheet.theme.accentColor)

        if !resume.summary.isEmpty {
            pdf.roundedRect(x: sheet.left, y: panelTop - height, width: leftWidth,
                            height: height, radius: 8, color: sheet.wash)
            pdf.move(to: panelTop - padding)
            sheet.paragraph(resume.summary, x: sheet.left + padding,
                            width: leftWidth - padding * 2, size: 9.2)
        }

        pdf.roundedRect(x: sheet.left + leftWidth + gutter, y: panelTop - height,
                        width: rightWidth, height: height, radius: 8, color: darkFill)

        let originX = sheet.left + leftWidth + gutter + padding
        for (index, entry) in entries.enumerated() {
            let baseline = panelTop - padding - Double(index) * 19

            sheet.icon(entry.icon, x: originX, y: baseline - 11.5, size: 12, color: dark.accent)
            if entry.url.isEmpty {
                pdf.textAt(entry.text, x: originX + 18, y: baseline - 9.6, size: 8.8,
                           color: dark.ink, face: sheet.regular)
            } else {
                pdf.linked(entry.text, url: entry.url, x: originX + 18, y: baseline - 9.6,
                           size: 8.8, color: dark.ink, face: sheet.regular)
            }
        }

        pdf.move(to: panelTop - height)
        sheet.gap(22)
    }

    private func contactEntries(_ profile: Profile) -> [(icon: Icon, text: String, url: String)] {
        var entries: [(Icon, String, String)] = []
        for entry in profile.contactEntries() {
            let icon: Icon
            if entry.url.hasPrefix("mailto:") { icon = .email }
            else if entry.url.hasPrefix("tel:") { icon = .phone }
            else if entry.url.isEmpty { icon = .location }
            else { icon = .link }
            entries.append((icon, entry.text, entry.url))
        }
        return entries.map { (icon: $0.0, text: $0.1, url: $0.2) }
    }
}

extension Sheet {

    /// A fill dark enough to reverse type out of, whatever the accent is.
    ///
    /// A design that needs a dark panel cannot simply use the accent: half the
    /// accents anybody picks are pale, and white text on a pale one is a panel
    /// nobody can read. A near-neutral carrying a trace of the accent keeps
    /// the theme visible and the contrast certain.
    var accentPanel: Color {
        guard !theme.isMonochrome else { return .grey(46) }
        return theme.accentColor.darkened(by: theme.accentIsDark ? 0.15 : 0.62)
    }
}
