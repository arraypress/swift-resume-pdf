//
//  Sidebar.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A tinted rail carrying the person, with the work beside it.
//
//  The best-looking of the four and the only one that will not survive being
//  parsed. An applicant tracking system extracts text in order and reads the
//  rail interleaved with the experience — a line of skills, a line of a job
//  title, a phone number in the middle of an employment history. The result
//  is not read by anybody; it is scored, and it scores badly.
//
//  So: for a design studio, a portfolio site, a hand-delivered copy, a
//  recruiter who asked for something with more personality. Not for a
//  Workday form. ``ATS`` says so rather than leaving it to be discovered.
//
//  ## One page
//
//  The rail is laid out first and the main column afterwards, because a
//  document has one cursor and cannot flow two columns at once. The main
//  column runs onto further pages perfectly well — the rail does not: it
//  lives on page one, and a rail section that will not fit what is left of
//  it moves to the main column instead. Letting it page-break was the old
//  behaviour, and the break stranded the entire main column on page two
//  beside an empty band of tint.
//

import Foundation
import TextPDF

struct Sidebar: Design {

    /// The rail is a second column, and a parser reads it interleaved with
    /// the main one. Declared here rather than inferred, because it is the
    /// single fact that decides whether this document survives a form.
    var isSingleColumn: Bool { false }

    var showsPhoto: Bool { true }

    private let railWidth = 190.0
    private let railInset = 30.0
    private let railTrailing = 24.0
    private let columnGap = 30.0

    /// What belongs beside the person rather than beside the work.
    ///
    /// Short, stable, list-shaped things. Anything with a paragraph in it goes
    /// in the main column, where there is room to read it.
    private let railSections: [Section] = [.skills, .languages, .education, .certifications, .interests]

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let tint = sheet.theme.railTint

        // The panel goes down before anything else on every page. Drawn after,
        // it would paint out the column it is supposed to sit behind.
        let width = railWidth
        sheet.background { doc, _, _ in
            doc.rect(x: 0, y: 0, width: width, height: doc.height(), color: tint)
        }

        let top = pdf.height() - sheet.theme.density.margin

        let moved = rail(resume, on: sheet, top: top)
        pdf.move(to: top)
        main(resume, on: sheet, including: moved)

        sheet.footer(name: resume.profile.name)
    }

    // MARK: Rail

    /// Lays the rail out, returning the sections that did not fit it.
    private func rail(_ resume: Resume, on sheet: Sheet, top: Double) -> [Section] {
        let pdf = sheet.pdf
        let profile = resume.profile
        let x = railInset
        let width = railWidth - railInset - railTrailing

        pdf.move(to: top)

        // A portrait sits at the head of the rail, which is the one place on
        // this design with room for one.
        if Sheet.photo(at: profile.photo) != nil {
            sheet.portrait(profile.photo, x: x, y: top - width, diameter: width)
            pdf.move(to: top - width - 16)
        }

        // Wrapped rather than placed, because a long name at this size will
        // not fit the rail on one line and a truncated name is worse than a
        // name on two.
        sheet.paragraph(profile.name, x: x, width: width, size: 18.5, face: sheet.semibold)

        if !profile.headline.isEmpty {
            sheet.rigidGap(3)
            sheet.paragraph(profile.headline, x: x, width: width, size: 9.6, color: sheet.muted)
        }

        sheet.gap(15)

        let contact = profile.contactEntries()
        if !contact.isEmpty {
            railHeading("Contact", on: sheet, x: x, width: width)
            for entry in contact {
                // One per line in a rail this narrow, and linked where it goes
                // somewhere. Wrapped rather than placed, because an email
                // address is often wider than the column.
                let top = sheet.cursor
                sheet.paragraph(entry.text, x: x, width: width, size: 8.6, color: sheet.ink)

                if !entry.url.isEmpty {
                    pdf.link(entry.url, x: x, y: sheet.cursor,
                             width: width, height: top - sheet.cursor)
                }
                sheet.rigidGap(2)
            }
            sheet.gap(13)
        }

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            railHeading("Details", on: sheet, x: x, width: width)
            for item in particulars {
                sheet.line(item.label, x: x, width: width, size: 7.8, face: sheet.regular, color: sheet.muted)
                sheet.paragraph(item.value, x: x, width: width, size: 8.6)
                sheet.rigidGap(3)
            }
            sheet.gap(13)
        }

        var style = Blocks.Style(x: x, width: width)
        style.dates = .beneath
        style.roleSize = 9.6
        style.bodySize = 8.7
        style.detailSize = 8.6
        style.dateSize = 8.0
        style.entryGap = 10

        // The rail lives on page one. Each section is rehearsed on a scratch
        // sheet from the same cursor before it is drawn for real — an exact
        // replay, so if the rehearsal page-breaks, the real run would have —
        // and one that does not fit moves to the main column, where flowing
        // onto another page is normal. Page-breaking here instead is what
        // used to strand the whole main column on page two.
        var moved: [Section] = []

        for section in resume.populated() where railSections.contains(section) {
            let scratch = Sheet(theme: sheet.theme, family: sheet.family, labels: sheet.labels)
            scratch.pdf.move(to: sheet.cursor)
            railHeading(resume.heading(for: section), on: scratch, x: x, width: width)
            Blocks.render(section, of: resume, on: scratch, style: style)

            guard scratch.pdf.pageCount() <= 1 else {
                moved.append(section)
                continue
            }

            railHeading(resume.heading(for: section), on: sheet, x: x, width: width)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(13)
        }
        return moved
    }

    private func railHeading(_ title: String, on sheet: Sheet, x: Double, width: Double) {
        sheet.sectionHeading(
            title, x: x, width: width, style: .plain,
            color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent,
            size: 7.4
        )
    }

    // MARK: Main column

    /// Draws everything that is not the rail's, plus what the rail declined.
    private func main(_ resume: Resume, on sheet: Sheet, including moved: [Section]) {
        let x = railWidth + columnGap
        let width = sheet.pdf.width() - x - sheet.theme.density.margin

        var style = Blocks.Style(x: x, width: width)
        style.entryGap = 14

        for section in resume.populated()
        where !railSections.contains(section) || moved.contains(section) {
            sheet.sectionHeading(resume.heading(for: section), x: x, width: width, style: .ruled)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(16)
        }
    }
}

// MARK: - Rail tint

extension Theme {

    /// The rail's fill.
    ///
    /// The accent lightened towards white rather than a flat grey, so a theme
    /// with a colour in it shows that colour somewhere. Lightened a long way:
    /// the rail sits behind body text for the length of a page, and anything
    /// stronger turns reading it into work.
    var railTint: Color {
        // On a dark page the rail has to step towards the light to be visible
        // at all; on a light one it steps away. Same idea, opposite direction,
        // which is the whole of what a scheme changes.
        guard !isMonochrome else { return wash }
        return scheme == .dark
            ? accentColor.darkened(by: 0.72).lightened(by: 0.06)
            : accentColor.lightened(by: 0.93)
    }
}
