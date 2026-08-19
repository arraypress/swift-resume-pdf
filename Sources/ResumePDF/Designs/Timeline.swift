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

        // A section whose entries carry dates gets the rail; the rest —
        // skills, interests — fall through to the ordinary renderer rather
        // than being given an empty rail, which would leave a hundred points
        // of white down the left of a skills list. This used to be a private
        // copy of the mapping and the drawing both; ``Blocks/entries(of:in:)``
        // and ``Blocks/railed(_:on:style:labels:railX:railWidth:gutter:)``
        // are the shared versions, which also means the dated sections the
        // copy did not know — certifications, publications, grants — now get
        // their dates in the rail instead of losing them entirely.
        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .accentBar)

            if let entries = Blocks.entries(of: section, in: resume),
               entries.contains(where: { !$0.dates.isEmpty }) {
                for (index, entry) in entries.enumerated() {
                    if index > 0 { sheet.gap(style.entryGap) }
                    Blocks.railed(entry, on: sheet, style: style, labels: resume.labels,
                                  railX: sheet.left, railWidth: railWidth, gutter: gutter)
                }
            } else {
                Blocks.render(section, of: resume, on: sheet, style: style)
            }
            sheet.gap(17)
        }

        sheet.footer(name: resume.profile.name)
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
        sheet.contactFlow(profile.contactEntries(), size: 8.6)

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
