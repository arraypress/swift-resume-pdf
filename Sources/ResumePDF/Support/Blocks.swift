//
//  Blocks.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The body of each section, drawn into whatever column it is given.
//
//  The designs differ in the masthead, the heading style and the shape of the
//  grid. They do not differ in what a publication looks like, and four copies
//  of that would be four places to fix the same thing.
//

import Foundation
import TextPDF

/// Where an entry's dates are set.
public enum DatePlacement {

    /// Against the right edge, on the title's line. Wants roughly 300 points
    /// of column to look right.
    case besideTitle

    /// Under the organisation. What a narrow column has room for, because
    /// beside the title the two would collide.
    case beneath

    /// Somewhere the design is drawing them itself — a rail, say. Drawn
    /// nowhere by these blocks, which is not the same as absent: a design
    /// that forgets to draw them loses them entirely, and printing them twice
    /// is the more visible mistake.
    case external
}

/// Section bodies, drawn into a column.
public enum Blocks {

    /// Column geometry and the few knobs a design varies.
    public struct Style {

        /// The left edge of the column, and how wide it is.
        public var x: Double
        public var width: Double

        /// Where an entry's dates go.
        public var dates: DatePlacement = .besideTitle

        public var roleSize: Double = 10.4
        public var bodySize: Double = 9.4
        public var detailSize: Double = 9.2
        public var dateSize: Double = 8.5

        /// Space between one entry and the next.
        public var entryGap: Double = 13

        /// Whether an entry's role is set in the accent colour.
        public var accentRoles: Bool = false

        /// How a skills section is drawn.
        public var skills: SkillStyle = .list

        /// A struct's memberwise initialiser is internal even when the struct
        /// is public, so a design written outside the package could not make
        /// one of these without an explicit one.
        public init(
            x: Double,
            width: Double,
            dates: DatePlacement = .besideTitle,
            roleSize: Double = 10.4,
            bodySize: Double = 9.4,
            detailSize: Double = 9.2,
            dateSize: Double = 8.5,
            entryGap: Double = 13,
            accentRoles: Bool = false,
            skills: SkillStyle = .list
        ) {
            self.x = x
            self.width = width
            self.dates = dates
            self.roleSize = roleSize
            self.bodySize = bodySize
            self.detailSize = detailSize
            self.dateSize = dateSize
            self.entryGap = entryGap
            self.accentRoles = accentRoles
            self.skills = skills
        }
    }

    /// How a skills section is set.
    public enum SkillStyle {

        /// Label, then the terms. Every word is a keyword a parser can read.
        case list

        /// Rounded tags. Still real words, and the only decorative treatment
        /// here that costs nothing.
        case chips

        /// Labelled bars, for the ratings a design asked for.
        case bars

        /// Five dots per skill.
        case dots
    }

    // MARK: Dispatch

    public static func render(_ section: Section, of resume: Resume, on sheet: Sheet, style: Style) {
        switch section {
        case .summary:
            sheet.paragraph(resume.summary, x: style.x, width: style.width, size: style.bodySize)

        case .experience:
            positions(resume.experience, on: sheet, style: style, labels: resume.labels)

        case .volunteering:
            positions(resume.volunteering, on: sheet, style: style, labels: resume.labels)

        case .education:
            education(resume.education, on: sheet, style: style, labels: resume.labels)

        case .skills:
            skills(resume.skills, on: sheet, style: style)

        case .projects:
            projects(resume.projects, on: sheet, style: style, labels: resume.labels)

        case .certifications:
            credentials(resume.certifications, on: sheet, style: style)

        case .publications:
            publications(resume.publications, on: sheet, style: style)

        case .awards:
            awards(resume.awards, on: sheet, style: style)

        case .languages:
            languages(resume.languages, on: sheet, style: style)

        case .grants:
            grants(resume.grants, on: sheet, style: style, labels: resume.labels)

        case .teaching:
            positions(resume.teaching, on: sheet, style: style, labels: resume.labels)

        case .service:
            positions(resume.service, on: sheet, style: style, labels: resume.labels)

        case .talks:
            publications(resume.talks, on: sheet, style: style)

        case .memberships:
            credentials(resume.memberships, on: sheet, style: style)

        case .interests:
            sheet.paragraph(resume.interests, x: style.x, width: style.width, size: style.bodySize)

        case .references:
            sheet.paragraph(resume.references, x: style.x, width: style.width, size: style.bodySize)

        default:
            custom(section, of: resume, on: sheet, style: style)
        }
    }

    // MARK: Sections of your own

    /// Whatever the block turned out to be holding, in the order it holds it.
    ///
    /// Each content block goes through the same renderer a built-in section
    /// would use, so a custom "Selected Works" made of publications is set
    /// exactly as the built-in publications section is — which is the
    /// difference between an extension point and a consolation prize.
    public static func custom(_ section: Section, of resume: Resume, on sheet: Sheet, style: Style) {
        guard let block = resume.customSection(section) else { return }
        let labels = resume.labels

        for (index, content) in block.content.enumerated() where !content.isEmpty {
            if index > 0 { sheet.rigidGap(4) }

            switch content {
            case .prose(let text):
                sheet.paragraph(text, x: style.x, width: style.width, size: style.bodySize)

            case .list(let items):
                sheet.bullets(items, x: style.x, width: style.width, size: style.bodySize)

            case .positions(let items):
                positions(items, on: sheet, style: style, labels: labels)

            case .education(let items):
                education(items, on: sheet, style: style, labels: labels)

            case .projects(let items):
                projects(items, on: sheet, style: style, labels: labels)

            case .publications(let items):
                publications(items, on: sheet, style: style)

            case .credentials(let items):
                credentials(items, on: sheet, style: style)

            case .awards(let items):
                awards(items, on: sheet, style: style)

            case .grants(let items):
                grants(items, on: sheet, style: style, labels: labels)

            case .skills(let items):
                skills(items, on: sheet, style: style)

            case .languages(let items):
                languages(items, on: sheet, style: style)
            }
        }
    }

    // MARK: Positions

    public static func positions(_ items: [Position], on sheet: Sheet, style: Style, labels: Labels) {
        for (index, item) in items.enumerated() {
            if index > 0 { sheet.gap(style.entryGap) }
            position(item, on: sheet, style: style, labels: labels)
        }
    }

    public static func position(_ item: Position, on sheet: Sheet, style: Style, labels: Labels) {
        let dates = item.dates.rendered(present: labels.present, dash: labels.dateSeparator)

        // The whole header, plus a line of what follows, kept together. A role
        // stranded at the foot of a page with its employer overleaf is the
        // one break that actually misleads.
        sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 3.2)

        heading(
            item.role, dates: dates, on: sheet, style: style,
            color: style.accentRoles ? sheet.accent : sheet.ink
        )

        sheet.qualified(
            item.organisation, item.location,
            x: style.x, size: style.detailSize,
            leadFace: sheet.medium, leadColor: sheet.ink
        )

        if !dates.isEmpty, style.dates == .beneath {
            sheet.line(dates, x: style.x, width: style.width,
                       size: style.dateSize, face: sheet.regular, color: sheet.muted)
        }

        if !item.summary.isEmpty {
            sheet.rigidGap(2)
            sheet.paragraph(item.summary, x: style.x, width: style.width,
                            size: style.bodySize, face: sheet.italic, color: sheet.muted)
        }

        if !item.highlights.isEmpty {
            sheet.rigidGap(4)
            sheet.bullets(item.highlights, x: style.x, width: style.width, size: style.bodySize)
        }

        if !item.skills.isEmpty {
            sheet.rigidGap(3)
            sheet.line(item.skills.joined(separator: " · "), x: style.x, width: style.width,
                       size: style.dateSize, face: sheet.regular, color: sheet.muted)
        }
    }

    // MARK: Education

    public static func education(_ items: [Education], on sheet: Sheet, style: Style, labels: Labels) {
        for (index, item) in items.enumerated() {
            if index > 0 { sheet.gap(style.entryGap * 0.72) }
            sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 2.6)

            let dates = item.dates.rendered(present: labels.present, dash: labels.dateSeparator)
            heading(item.qualification, dates: dates, on: sheet, style: style,
                    color: style.accentRoles ? sheet.accent : sheet.ink)

            sheet.qualified(
                item.institution, item.location,
                x: style.x, size: style.detailSize,
                leadFace: sheet.medium, leadColor: sheet.ink
            )

            if !dates.isEmpty, style.dates == .beneath {
                sheet.line(dates, x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.regular, color: sheet.muted)
            }
            if !item.grade.isEmpty {
                sheet.line(item.grade, x: style.x, width: style.width,
                           size: style.detailSize, face: sheet.regular, color: sheet.ink)
            }
            if !item.highlights.isEmpty {
                sheet.rigidGap(3)
                sheet.bullets(item.highlights, x: style.x, width: style.width, size: style.bodySize)
            }
        }
    }

    // MARK: Skills

    public static func skills(_ groups: [SkillGroup], on sheet: Sheet, style: Style) {
        switch style.skills {
        case .list:
            listedSkills(groups, on: sheet, style: style)

        case .chips:
            for group in groups {
                // The label and its first row of chips, kept together: a group
                // name alone at the foot of a page names nothing.
                sheet.pdf.breakIfNeeded(sheet.leading(style.dateSize) + style.dateSize * 2.4)
                sheet.line(group.name, x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted)
                sheet.chips(group.names, x: style.x, width: style.width, size: style.dateSize)
                sheet.rigidGap(3)
            }

        case .bars:
            // Anything unrated falls back to being listed rather than being
            // drawn as an empty bar, which reads as a score of zero.
            for group in groups {
                sheet.line(group.name.uppercased(), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted,
                           tracking: style.dateSize * 0.1)

                let rated = group.items.filter { $0.level != nil }
                for skill in rated {
                    sheet.gauge(skill.name, skill.level ?? 0, x: style.x,
                                width: style.width, labelWidth: style.width * 0.52,
                                size: style.detailSize)
                }
                let plain = group.items.filter { $0.level == nil }.map(\.name)
                if !plain.isEmpty {
                    sheet.paragraph(plain.joined(separator: ", "), x: style.x,
                                    width: style.width, size: style.detailSize, color: sheet.ink)
                }
                sheet.rigidGap(5)
            }

        case .dots:
            for group in groups {
                sheet.line(group.name.uppercased(), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted,
                           tracking: style.dateSize * 0.1)

                for skill in group.items {
                    let top = sheet.cursor
                    sheet.pdf.cell(skill.name, x: style.x, boxWidth: style.width * 0.62,
                                   size: style.detailSize, color: sheet.ink, face: sheet.regular)
                    if let level = skill.level {
                        sheet.dots(level, x: style.x + style.width * 0.66,
                                   y: top - style.detailSize * 0.72, size: 4)
                    }
                    sheet.pdf.move(to: top - sheet.leading(style.detailSize))
                }
                sheet.rigidGap(5)
            }
        }
    }

    /// Label on the left, terms beside it.
    private static func listedSkills(_ groups: [SkillGroup], on sheet: Sheet, style: Style) {
        // A label column wide enough for the longest name, within reason: past
        // a third of the column the terms have nowhere to go, and the label is
        // not the thing being read.
        let longest = groups
            .map { sheet.pdf.width(of: $0.name, size: style.detailSize, face: sheet.medium) }
            .max() ?? 0
        let labelWidth = min(max(longest + 14, 62), style.width * 0.34)

        // Below that, the label and the terms are fighting for the same room,
        // so they stack instead.
        guard style.width > 210 else {
            for group in groups {
                sheet.line(group.name, x: style.x, width: style.width,
                           size: style.detailSize, face: sheet.medium, color: sheet.ink)
                sheet.paragraph(group.names.joined(separator: ", "), x: style.x,
                                width: style.width, size: style.detailSize, color: sheet.muted)
                sheet.rigidGap(4)
            }
            return
        }

        for group in groups {
            sheet.skillRow(group, x: style.x, width: style.width,
                           labelWidth: labelWidth, size: style.detailSize)
        }
    }

    // MARK: Projects

    public static func projects(_ items: [Project], on sheet: Sheet, style: Style, labels: Labels) {
        for (index, item) in items.enumerated() {
            if index > 0 { sheet.gap(style.entryGap * 0.8) }
            sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 2.6)

            let dates = item.dates.rendered(present: labels.present, dash: labels.dateSeparator)
            heading(item.name, dates: dates, on: sheet, style: style,
                    color: style.accentRoles ? sheet.accent : sheet.ink)

            let detail = [item.role, item.link?.label ?? ""].filter { !$0.isEmpty }
            if !detail.isEmpty {
                sheet.line(detail.joined(separator: "  ·  "), x: style.x, width: style.width,
                           size: style.detailSize, face: sheet.regular, color: sheet.muted)
            }
            if !item.summary.isEmpty {
                sheet.paragraph(item.summary, x: style.x, width: style.width, size: style.bodySize)
            }
            if !item.highlights.isEmpty {
                sheet.rigidGap(3)
                sheet.bullets(item.highlights, x: style.x, width: style.width, size: style.bodySize)
            }
            if !item.skills.isEmpty {
                sheet.rigidGap(3)
                sheet.line(item.skills.joined(separator: " · "), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.regular, color: sheet.muted)
            }
        }
    }

    // MARK: Grants

    public static func grants(_ items: [Grant], on sheet: Sheet, style: Style, labels: Labels) {
        for item in items {
            let dates = item.dates.rendered(present: labels.present, dash: labels.dateSeparator)
            heading(item.title, dates: dates, on: sheet, style: style,
                    size: style.detailSize, face: sheet.medium,
                    color: style.accentRoles ? sheet.accent : sheet.ink)

            // Funder and amount on one line, because they are read together:
            // a reader is asking who backed it and for how much, in that
            // order, and separating them makes them look like two facts.
            let detail = [item.funder, item.amount, item.role, item.identifier]
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            if !detail.isEmpty {
                sheet.paragraph(detail.joined(separator: "  ·  "), x: style.x, width: style.width,
                                size: style.dateSize, color: sheet.muted)
            }
            sheet.rigidGap(5)
        }
    }

    // MARK: Short entries

    public static func credentials(_ items: [Credential], on sheet: Sheet, style: Style) {
        for item in items {
            heading(item.name, dates: item.date, on: sheet, style: style,
                    size: style.detailSize, face: sheet.medium,
                    color: style.accentRoles ? sheet.accent : sheet.ink)

            let detail = [item.issuer, item.identifier].filter { !$0.isEmpty }
            if !detail.isEmpty {
                sheet.line(detail.joined(separator: "  ·  "), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.regular, color: sheet.muted)
            }
            sheet.rigidGap(4)
        }
    }

    public static func publications(_ items: [Publication], on sheet: Sheet, style: Style) {
        for item in items {
            sheet.pdf.breakIfNeeded(sheet.leading(style.bodySize) * 2.4)

            // The title carries the emphasis rather than the authors, because
            // a reader scanning a publication list is looking for what the
            // work was, not for a name they already have at the top.
            sheet.paragraph(item.title, x: style.x, width: style.width,
                            size: style.bodySize, face: sheet.medium)

            let detail = [item.authors, item.venue, item.date].filter { !$0.isEmpty }
            if !detail.isEmpty {
                sheet.paragraph(detail.joined(separator: "  ·  "), x: style.x, width: style.width,
                                size: style.dateSize, face: sheet.italic, color: sheet.muted)
            }
            if let link = item.link {
                sheet.line(link.label, x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.regular, color: sheet.muted)
            }
            sheet.rigidGap(5)
        }
    }

    public static func awards(_ items: [Award], on sheet: Sheet, style: Style) {
        for item in items {
            heading(item.name, dates: item.date, on: sheet, style: style,
                    size: style.detailSize, face: sheet.medium,
                    color: style.accentRoles ? sheet.accent : sheet.ink)

            if !item.issuer.isEmpty {
                sheet.line(item.issuer, x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.regular, color: sheet.muted)
            }
            if !item.summary.isEmpty {
                sheet.paragraph(item.summary, x: style.x, width: style.width,
                                size: style.dateSize, color: sheet.muted)
            }
            sheet.rigidGap(4)
        }
    }

    public static func languages(_ items: [Language], on sheet: Sheet, style: Style) {
        guard !items.isEmpty else { return }

        // The level sits just past the longest name rather than against the
        // right margin. Aligned to the margin on a full-width column it is
        // four hundred points from the language it describes, with nothing in
        // between — the eye has to travel the gap and there is no reason for
        // it to be there. The levels still line up, which was the only thing
        // the right edge was buying.
        let longest = items
            .map { sheet.pdf.width(of: $0.name, size: style.detailSize, face: sheet.regular) }
            .max() ?? 0
        let column = min(longest + 22, style.width * 0.5)

        for item in items {
            let top = sheet.cursor
            sheet.pdf.cell(item.name, x: style.x, boxWidth: column, size: style.detailSize,
                           color: sheet.ink, face: sheet.regular)
            if !item.level.isEmpty {
                sheet.pdf.cell(item.level, x: style.x + column, boxWidth: style.width - column,
                               size: style.detailSize, color: sheet.muted, face: sheet.regular)
            }
            sheet.pdf.move(to: top - sheet.leading(style.detailSize))
        }
    }

    // MARK: Shared

    /// An entry's title, with its dates where the design puts them.
    ///
    /// The title wraps rather than being drawn as one line and allowed to run
    /// out of its column — a certification name is half a sentence long and a
    /// sidebar is a hundred and forty points wide, so overflow is the normal
    /// case there rather than the unlucky one.
    private static func heading(
        _ title: String,
        dates: String,
        on sheet: Sheet,
        style: Style,
        size: Double? = nil,
        face: EmbeddedFont? = nil,
        color: Color? = nil
    ) {
        let pointSize = size ?? style.roleSize
        let resolved = face ?? sheet.semibold
        let besideTitle = style.dates == .besideTitle && !dates.isEmpty

        // Broken before the dates go down, so a break cannot land between them
        // and the title they belong to.
        sheet.pdf.breakIfNeeded(sheet.leading(pointSize) * 1.8)
        let top = sheet.cursor

        var available = style.width
        if besideTitle {
            let dateWidth = sheet.pdf.width(of: dates, size: style.dateSize, face: sheet.regular)
            available = style.width - dateWidth - 12

            sheet.pdf.cell(dates, x: style.x, boxWidth: style.width, size: style.dateSize,
                           color: sheet.muted, align: .right, face: sheet.regular)
            sheet.pdf.move(to: top)
        }

        // A column too narrow to hold the dates and anything else has no
        // business trying: the title takes the width and the dates go under.
        if besideTitle, available < style.width * 0.4 {
            available = style.width
        }

        sheet.paragraph(title, x: style.x, width: available, size: pointSize,
                        face: resolved, color: color ?? sheet.ink)
    }
}

// MARK: - Section by entry

extension Blocks {

    /// One drawable entry, and the dates it carries.
    ///
    /// A design that wants to do something *per entry* — a panel around each,
    /// a date in a rail beside each — needs the section broken up rather than
    /// rendered whole. `Card` and `Timeline` each kept a private copy of this
    /// mapping, which is two places for a new section to be forgotten.
    public struct Entry {

        /// Empty where the thing has no dates, which is most of a skills list.
        public let dates: DateRange

        /// Draws this one entry, at whatever the cursor is when it is called.
        public let draw: (Sheet, Style) -> Void
    }

    /// A section's entries, one at a time.
    ///
    /// `nil` where the section is not a list of dated things — skills,
    /// interests, references — because giving those a rail leaves a hundred
    /// points of white down the left of a skills list, and a panel each turns
    /// three words into three boxes.
    public static func entries(of section: Section, in resume: Resume) -> [Entry]? {
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
                Entry(dates: item.dates) { sheet, style in
                    Blocks.position(item, on: sheet, style: style, labels: labels)
                }
            }

        case .education:
            return resume.education.map { item in
                Entry(dates: item.dates) { sheet, style in
                    Blocks.education([item], on: sheet, style: style, labels: labels)
                }
            }

        case .projects:
            return resume.projects.map { item in
                Entry(dates: item.dates) { sheet, style in
                    Blocks.projects([item], on: sheet, style: style, labels: labels)
                }
            }

        case .grants:
            return resume.grants.map { item in
                Entry(dates: item.dates) { sheet, style in
                    Blocks.grants([item], on: sheet, style: style, labels: labels)
                }
            }

        case .publications, .talks:
            let items = section == .publications ? resume.publications : resume.talks
            return items.map { item in
                Entry(dates: DateRange(item.date)) { sheet, style in
                    Blocks.publications([item], on: sheet, style: style)
                }
            }

        case .certifications, .memberships:
            let items = section == .certifications ? resume.certifications : resume.memberships
            return items.map { item in
                Entry(dates: DateRange(item.date)) { sheet, style in
                    Blocks.credentials([item], on: sheet, style: style)
                }
            }

        case .awards:
            return resume.awards.map { item in
                Entry(dates: DateRange(item.date)) { sheet, style in
                    Blocks.awards([item], on: sheet, style: style)
                }
            }

        default:
            return nil
        }
    }

    /// The same, as one entry covering the whole section.
    ///
    /// So a design can treat every section the same way without asking which
    /// kind it is: the ones that break up do, and the ones that do not come
    /// back as a single block.
    public static func entriesOrWhole(of section: Section, in resume: Resume) -> [Entry] {
        entries(of: section, in: resume) ?? [
            Entry(dates: DateRange("")) { sheet, style in
                Blocks.render(section, of: resume, on: sheet, style: style)
            }
        ]
    }
}
