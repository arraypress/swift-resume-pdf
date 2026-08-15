//
//  Card.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Every entry on a panel of its own.
//
//  The arrangement product interfaces settled on and paper never quite did:
//  each job is an object with an edge, so the page is a list of things rather
//  than a column of text. It suits a career with several short roles, where
//  the boundaries between them are the information, and it is unkind to one
//  long role with twelve bullets — that becomes a single enormous card with
//  nothing to compare it to.
//
//  The panels are recorded as the page is laid out and painted in the
//  background pass, because a panel has to go down before the words on it and
//  its height is not known until they have been placed.
//

import Foundation
import TextPDF

struct Card: Design {

    private let padding = 13.0

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        masthead(resume, on: sheet)

        let panels = Panels()
        let fill = sheet.wash
        let radius = 7.0
        sheet.background { doc, page, _ in
            for panel in panels.rects(onPage: page) {
                doc.roundedRect(x: panel.x, y: panel.bottom, width: panel.width,
                                height: panel.top - panel.bottom, radius: radius, color: fill)
            }
        }

        var style = Blocks.Style(x: sheet.left + padding, width: sheet.width - padding * 2)
        style.entryGap = 0
        style.skills = .chips

        for section in resume.populated() {
            sheet.sectionHeading(
                resume.heading(for: section),
                style: .plain,
                color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent,
                size: 8.2
            )

            // Sections made of repeated entries get one panel each; the rest
            // get a single panel around the whole block.
            for entry in Cards.entries(of: section, in: resume) {
                let page = pdf.pageCount()
                let top = pdf.cursor() + padding
                pdf.gap(2)

                entry(sheet, style)

                if pdf.pageCount() == page {
                    panels.add(page: page, x: sheet.left, width: sheet.width,
                               top: top, bottom: pdf.cursor() - padding + 4)
                }
                sheet.gap(padding + 6)
            }
            sheet.gap(8)
        }

        sheet.footer(name: resume.profile.name)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 26,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        var y = top - 43
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 11,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
            y -= 18
        }

        pdf.move(to: y - 2)
        sheet.contactFlow(profile.contactEntries(), size: 8.7)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" }, size: 8.4)
        }
        sheet.gap(14)
    }
}

/// Splits a section into the units that get a panel each.
private enum Cards {

    static func entries(
        of section: Section, in resume: Resume
    ) -> [(Sheet, Blocks.Style) -> Void] {
        let labels = resume.labels

        switch section {
        case .experience, .volunteering, .teaching, .service:
            let items: [Position]
            switch section {
            case .experience: items = resume.experience
            case .volunteering: items = resume.volunteering
            case .teaching: items = resume.teaching
            default: items = resume.service
            }
            return items.map { item in
                { sheet, style in Blocks.position(item, on: sheet, style: style, labels: labels) }
            }

        case .education:
            return resume.education.map { item in
                { sheet, style in Blocks.education([item], on: sheet, style: style, labels: labels) }
            }

        case .projects:
            return resume.projects.map { item in
                { sheet, style in Blocks.projects([item], on: sheet, style: style, labels: labels) }
            }

        default:
            // One panel around the whole thing.
            return [{ sheet, style in
                Blocks.render(section, of: resume, on: sheet, style: style)
            }]
        }
    }
}

/// Panels recorded during layout, drawn afterwards.
private final class Panels {

    struct Rect {
        let page: Int
        let x: Double
        let width: Double
        let top: Double
        let bottom: Double
    }

    private var recorded: [Rect] = []

    func add(page: Int, x: Double, width: Double, top: Double, bottom: Double) {
        guard top > bottom else { return }
        recorded.append(Rect(page: page, x: x, width: width, top: top, bottom: bottom))
    }

    func rects(onPage page: Int) -> [Rect] {
        recorded.filter { $0.page == page }
    }
}
