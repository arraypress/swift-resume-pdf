//
//  Gazette.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The serif two-column: a centred masthead, the argument in a wide column,
//  the credentials in a narrow one beside it.
//
//  Where ``Sidebar`` is a product page, this is a paper — the academic and
//  executive look, set in Source Serif with a hairline down the gutter. The
//  wide column carries what is read (summary, experience, projects); the
//  narrow one carries what is checked (education, skills, certifications,
//  languages).
//
//  Two columns, so the same warning as Sidebar: an applicant tracking system
//  extracts the text in order and reads the two interleaved. Send it where
//  a person will open it. ``ATS`` blocks it from anything that goes through
//  a form, exactly as it blocks Sidebar.
//
//  ## One page of aside
//
//  Same contract as Sidebar's rail: the narrow column lives on page one, and
//  a section that will not fit what is left of it moves to the wide column —
//  rehearsed on a scratch sheet first, so the page never breaks mid-aside
//  and strands the main column on page two.
//

import Foundation
import TextPDF

struct Gazette: Design {

    /// Two columns, and a parser reads them interleaved. Declared, because
    /// it is the single fact that decides whether this document survives a
    /// form.
    var isSingleColumn: Bool { false }

    private let asideWidth = 152.0
    private let gutter = 28.0

    /// What is checked rather than read — the narrow column's sections.
    private let asideSections: [Section] = [.education, .skills, .certifications, .languages]

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        masthead(resume, on: sheet)
        let top = pdf.cursor()

        // The hairline down the gutter, page one only — it separates the
        // columns, and there is only one page on which there are two.
        pdf.line(from: sheet.right - asideWidth - gutter / 2, top,
                 to: sheet.right - asideWidth - gutter / 2, sheet.theme.density.margin,
                 color: sheet.hairline, thickness: 0.6)

        let moved = aside(resume, on: sheet, top: top)
        pdf.move(to: top)
        main(resume, on: sheet, including: moved)

        sheet.footer(name: resume.profile.name)
    }

    // MARK: The narrow column

    /// Lays the narrow column out, returning the sections that did not fit.
    private func aside(_ resume: Resume, on sheet: Sheet, top: Double) -> [Section] {
        let pdf = sheet.pdf
        let x = sheet.right - asideWidth

        var style = Blocks.Style(x: x, width: asideWidth)
        style.dates = .beneath
        style.roleSize = 9.4
        style.bodySize = 8.8
        style.detailSize = 8.8
        style.dateSize = 8.2
        style.entryGap = 10

        pdf.move(to: top)

        // Rehearsed before drawn, exactly as Sidebar rehearses its rail: a
        // section that would page-break moves to the wide column instead,
        // where flowing onto another page is normal.
        var moved: [Section] = []

        for section in resume.populated() where asideSections.contains(section) {
            let scratch = Sheet(theme: sheet.theme, family: sheet.family, labels: sheet.labels)
            scratch.pdf.move(to: sheet.cursor)
            scratch.sectionHeading(resume.heading(for: section), x: x, width: asideWidth,
                                   style: .plain, size: 7.2)
            Blocks.render(section, of: resume, on: scratch, style: style)

            guard scratch.pdf.pageCount() <= 1 else {
                moved.append(section)
                continue
            }

            sheet.sectionHeading(resume.heading(for: section), x: x, width: asideWidth,
                                 style: .plain, size: 7.2)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(14)
        }
        return moved
    }

    // MARK: The wide column

    /// Draws everything that is not the aside's, plus what it declined.
    private func main(_ resume: Resume, on sheet: Sheet, including moved: [Section]) {
        let width = sheet.width - asideWidth - gutter

        var style = Blocks.Style(x: sheet.left, width: width)
        style.roleSize = 10.6
        style.bodySize = 9.6
        style.detailSize = 9.4
        style.entryGap = 14

        for section in resume.populated()
        where !asideSections.contains(section) || moved.contains(section) {
            sheet.sectionHeading(resume.heading(for: section), x: sheet.left, width: width,
                                 style: .ruled, size: 7.6)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(17)
        }
    }

    // MARK: Masthead

    /// Centred, the way ``Broadsheet`` sets one — the two are relatives, and
    /// an application often sends this beside its letter.
    private func masthead(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name.uppercased(), x: sheet.left, y: top - 20, size: 19,
                   color: sheet.ink, align: .center, boxWidth: sheet.width,
                   face: sheet.regular, tracking: 2.2)

        var y = top - 38
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.4,
                       color: sheet.muted, align: .center, boxWidth: sheet.width,
                       face: sheet.italic)
            y -= 17
        }

        pdf.move(to: y)
        sheet.contactFlow(profile.contactEntries(), size: 8.8, align: .center)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              size: 8.5, align: .center)
        }

        sheet.rigidGap(6)
        sheet.rule(color: sheet.ink, thickness: 0.7)
        sheet.gap(18)
    }
}

extension Gazette {

    /// The serif is the design's identity, so it declares it — a theme with
    /// no preference loads it, and a theme that names a face still wins.
    var intendedTypeface: Typeface? { .sourceSerif }
}
