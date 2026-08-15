//
//  Timeline.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Dates in a rail down the left, entries hung off it.
//
//  The employment history becomes the shape of the page. That flatters a
//  clean progression and is unkind to anything else — three years in one
//  place and then four jobs in two are visible before a word is read, which
//  is either exactly what somebody wants or exactly what they do not.
//
//  Still one column as far as a parser is concerned. The rail is narrow and
//  its content is drawn immediately before the entry it belongs to, so the
//  text comes out in the order a person would read it rather than as two
//  interleaved streams. That is the difference between this and ``Sidebar``.
//

import Foundation
import TextPDF

struct Timeline: Design {

    /// Wide enough for "September 2019 – March 2022" at the rail's size, and
    /// no wider: every point here comes off the column that carries the
    /// actual content.
    private let railWidth = 96.0
    private let gutter = 16.0

    func render(_ resume: Resume, on sheet: Sheet) {
        masthead(resume, on: sheet)

        let bodyX = sheet.left + railWidth + gutter
        let bodyWidth = sheet.width - railWidth - gutter

        var style = Blocks.Style(x: bodyX, width: bodyWidth)
        // Drawn in the rail by this design, so the blocks must not set them
        // again — the duplicate is more visible than the omission.
        style.dates = .external
        style.entryGap = 15

        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .accentBar)

            if let railed = railedEntries(section, of: resume) {
                render(railed, on: sheet, style: style, bodyX: bodyX, labels: resume.labels)
            } else {
                Blocks.render(section, of: resume, on: sheet, style: style)
            }
            sheet.gap(17)
        }

        sheet.footer(name: resume.profile.name)
    }

    // MARK: The rail

    /// A section's entries as date-and-body pairs, where it has any.
    ///
    /// Sections without dates — skills, interests — fall through to the
    /// ordinary renderer rather than being given an empty rail, which would
    /// leave a hundred points of white down the left of a skills list.
    private func railedEntries(_ section: Section, of resume: Resume) -> [(dates: DateRange, draw: (Sheet, Blocks.Style) -> Void)]? {
        let labels = resume.labels

        switch section {
        case .experience, .volunteering:
            let items = section == .experience ? resume.experience : resume.volunteering
            return items.map { item in
                (item.dates, { sheet, style in
                    Blocks.position(item, on: sheet, style: style, labels: labels)
                })
            }

        case .education:
            return resume.education.map { item in
                (item.dates, { sheet, style in
                    Blocks.education([item], on: sheet, style: style, labels: labels)
                })
            }

        case .projects:
            let items = resume.projects.filter { !$0.dates.isEmpty }
            guard items.count == resume.projects.count, !items.isEmpty else { return nil }
            return items.map { item in
                (item.dates, { sheet, style in
                    Blocks.projects([item], on: sheet, style: style, labels: labels)
                })
            }

        default:
            return nil
        }
    }

    private func render(
        _ entries: [(dates: DateRange, draw: (Sheet, Blocks.Style) -> Void)],
        on sheet: Sheet,
        style: Blocks.Style,
        bodyX: Double,
        labels: Labels
    ) {
        for (index, entry) in entries.enumerated() {
            if index > 0 { sheet.gap(style.entryGap) }

            // The rail is drawn against the entry's own top, so the break has
            // to happen first — otherwise the dates land at the bottom of one
            // page and the role at the top of the next.
            sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 3.4)
            let top = sheet.cursor

            let dates = entry.dates.rendered(present: labels.present, dash: labels.dateSeparator)
            if !dates.isEmpty {
                // Right-aligned against the gutter, so the dates form a clean
                // edge facing the content rather than a ragged one.
                sheet.pdf.cell(dates, x: sheet.left, boxWidth: railWidth, size: 8.6,
                               color: sheet.muted, align: .right, face: sheet.medium)

                // A short tick between the two columns. Fixed height, so it
                // cannot be orphaned by a page break part-way down an entry.
                let markerTop = top - 4
                sheet.pdf.line(
                    from: bodyX - gutter / 2, markerTop,
                    to: bodyX - gutter / 2, markerTop - sheet.leading(style.roleSize) * 1.6,
                    color: sheet.hairline, thickness: 1.1
                )
            }

            sheet.pdf.move(to: top)
            entry.draw(sheet, style)
        }
    }

    // MARK: Masthead

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 21, size: 24,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.35)

        var y = top - 39
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.5,
                       color: sheet.muted, face: sheet.regular)
            y -= 17
        }

        pdf.move(to: y)
        sheet.contactFlow(profile.contactLine() + profile.links.map(\.label), size: 8.6)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, size: 8.4)
        }

        sheet.rigidGap(4)
        // A rule only under the rail, rather than the full width. It marks the
        // column the dates will run down before any of them appear.
        sheet.rule(width: railWidth, color: sheet.accent, thickness: 2)
        sheet.gap(19)
    }
}
