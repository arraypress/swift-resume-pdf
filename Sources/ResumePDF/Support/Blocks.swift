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

        /// How a language's level is shown beside it.
        public var languages: LanguageStyle = .text

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
            skills: SkillStyle = .list,
            languages: LanguageStyle = .text
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
            self.languages = languages
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

        /// Each term on a hairline of its own, flowed like chips without the
        /// pill — the look most résumé builders draw a skills list in.
        case underlined

        /// The terms in one bold run with a dot between each: the densest
        /// setting, for a narrow column with a long list.
        case inline
    }

    /// How a language's level is shown.
    public enum LanguageStyle {

        /// The level as written — "Native", "C1".
        case text

        /// The words, and five dots filled to what they mean. A level the
        /// scale does not know keeps the words alone — see ``LanguageLevels``.
        case dots

        /// The words, and a bar.
        case bars
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

        case .achievements:
            callouts(resume.achievements.enumerated().map { index, item in
                (icon: Icon(rawValue: item.icon) ?? Icon.cycle[index % Icon.cycle.count] as Icon?,
                 title: item.title, summary: item.summary)
            }, on: sheet, style: style)

        case .strengths:
            callouts(resume.strengths.map { (icon: nil as Icon?, title: $0.title, summary: $0.summary) },
                     on: sheet, style: style)

        case .time:
            timeSplit(resume.time, on: sheet, style: style)

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

            case .achievements(let items):
                callouts(items.enumerated().map { index, item in
                    (icon: Icon(rawValue: item.icon) ?? Icon.cycle[index % Icon.cycle.count] as Icon?,
                     title: item.title, summary: item.summary)
                }, on: sheet, style: style)

            case .strengths(let items):
                callouts(items.map { (icon: nil as Icon?, title: $0.title, summary: $0.summary) },
                         on: sheet, style: style)
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

        case .underlined:
            for group in groups {
                sheet.pdf.breakIfNeeded(sheet.leading(style.dateSize) + style.dateSize * 2.4)
                sheet.line(group.name, x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted)
                sheet.chips(group.names, x: style.x, width: style.width, size: style.dateSize, filled: false)
                sheet.rigidGap(3)
            }

        case .inline:
            // One run, the group labels dropped: the setting exists for the
            // column too narrow to spend a line on "Languages:".
            sheet.paragraph(groups.flatMap(\.names).joined(separator: "  ·  "),
                            x: style.x, width: style.width, size: style.detailSize, face: sheet.semibold)

        case .bars:
            // Anything unrated falls back to being listed rather than being
            // drawn as an empty bar, which reads as a score of zero.
            for group in groups {
                // The label and its first bar, kept together — and then a
                // break per row, because these rows are placed with `cell`
                // and `move`, which never look at the margin on their own.
                sheet.pdf.breakIfNeeded(sheet.leading(style.dateSize) + sheet.leading(style.detailSize))
                sheet.line(group.name.uppercased(), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted,
                           tracking: style.dateSize * 0.1)

                let rated = group.items.filter { $0.level != nil }
                for skill in rated {
                    sheet.pdf.breakIfNeeded(sheet.leading(style.detailSize))
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
                // Kept together with the first row, then broken per row —
                // same reason as the bars above.
                sheet.pdf.breakIfNeeded(sheet.leading(style.dateSize) + sheet.leading(style.detailSize))
                sheet.line(group.name.uppercased(), x: style.x, width: style.width,
                           size: style.dateSize, face: sheet.medium, color: sheet.muted,
                           tracking: style.dateSize * 0.1)

                for skill in group.items {
                    sheet.pdf.breakIfNeeded(sheet.leading(style.detailSize))
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
                .filter { !$0.isBlank }

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

        // Dots and bars sit against the right edge; the words keep their
        // place beside the name. The drawing takes what a level's words are
        // worth, and a level the scale does not know gets words alone — the
        // one thing worse than no dots is the wrong number of them.
        let markWidth: Double = style.languages == .text ? 0 : min(56, style.width * 0.3)
        let levelWidth = style.width - column - markWidth

        for item in items {
            // Placed with `cell` and `move`, which never look at the margin —
            // so without a break per row a long list runs off the page.
            sheet.pdf.breakIfNeeded(sheet.leading(style.detailSize))
            let top = sheet.cursor
            sheet.pdf.cell(item.name, x: style.x, boxWidth: column, size: style.detailSize,
                           color: sheet.ink, face: sheet.regular)
            if !item.level.isEmpty {
                sheet.pdf.cell(item.level, x: style.x + column, boxWidth: max(levelWidth, 20),
                               size: style.detailSize, color: sheet.muted, face: sheet.regular)
            }
            if markWidth > 0, let fraction = LanguageLevels.fraction(for: item.level) {
                let markX = style.x + style.width - markWidth
                switch style.languages {
                case .dots:
                    sheet.dots(fraction, x: markX, y: top - style.detailSize * 0.72, size: 4.2)
                case .bars:
                    sheet.pdf.meter(x: markX, y: top - style.detailSize * 1.0, width: markWidth,
                                    height: max(3.4, style.detailSize * 0.42),
                                    fraction: fraction, color: sheet.accent, track: sheet.wash)
                case .text:
                    break
                }
            }
            sheet.pdf.move(to: top - sheet.leading(style.detailSize))
        }
    }

    // MARK: Achievements and strengths

    /// A mark, a title and a sentence — set two abreast where the column is
    /// wide enough for a sentence each, stacked where it is not.
    ///
    /// The mark is optional because a strength carries none: a quality with
    /// a badge beside it reads as a merit sticker.
    public static func callouts(
        _ items: [(icon: Icon?, title: String, summary: String)],
        on sheet: Sheet, style: Style
    ) {
        let pdf = sheet.pdf
        let columns = style.width > 300 ? 2 : 1
        let gutter = 18.0
        let columnWidth = (style.width - gutter * Double(columns - 1)) / Double(columns)
        let mark = style.detailSize * 1.5
        let inset = items.contains { $0.icon != nil } ? mark + 9 : 0
        let titleSize = style.detailSize + 0.6
        let summarySize = style.bodySize - 0.6
        let textWidth = columnWidth - inset

        func height(of item: (icon: Icon?, title: String, summary: String)) -> Double {
            pdf.blockHeight(item.title, size: titleSize, width: textWidth,
                            leading: sheet.leading(titleSize), face: sheet.semibold)
                + (item.summary.isBlank ? 0 : pdf.blockHeight(item.summary, size: summarySize, width: textWidth,
                                                                 leading: sheet.leading(summarySize), face: sheet.regular))
        }

        func draw(_ item: (icon: Icon?, title: String, summary: String), x: Double) {
            let top = sheet.cursor
            if let icon = item.icon {
                sheet.icon(icon, x: x, y: top - mark - 1, size: mark, color: sheet.accent)
            }
            sheet.paragraph(item.title, x: x + inset, width: textWidth, size: titleSize,
                            face: sheet.semibold, color: style.accentRoles ? sheet.accent : sheet.ink)
            if !item.summary.isBlank {
                sheet.rigidGap(1.5)
                sheet.paragraph(item.summary, x: x + inset, width: textWidth, size: summarySize)
            }
        }

        var index = 0
        while index < items.count {
            let row = Array(items[index..<min(index + columns, items.count)])
            // The whole row kept on one page: a title on one sheet and its
            // sentence on the next is the break that misleads.
            let tallest = row.map(height(of:)).max() ?? 0
            pdf.breakIfNeeded(tallest + 6)
            let top = sheet.cursor
            var bottom = top

            for (position, item) in row.enumerated() {
                pdf.move(to: top)
                draw(item, x: style.x + Double(position) * (columnWidth + gutter))
                bottom = min(bottom, sheet.cursor)
            }
            pdf.move(to: bottom)
            index += columns
            if index < items.count { sheet.rigidGap(style.entryGap * 0.55) }
        }
    }

    // MARK: Time

    /// The measurements a time ring is drawn to, from the column it sits in.
    ///
    /// Beside its legend where the column is wide enough for both, above it
    /// where it is not — the ring is the same size either way, and the
    /// height is what a heading needs to know to stay on the same page.
    struct TimeLayout {
        let radius: Double
        let thickness: Double
        let badge = 6.6
        let beside: Bool
        let rowHeight: Double
        let rows: Int

        init(count: Int, style: Style, sheet: Sheet) {
            beside = style.width > 300
            radius = min(style.width * (beside ? 0.13 : 0.2), 52.0)
            thickness = radius * 0.46
            rowHeight = sheet.leading(style.detailSize) + 3
            rows = count
        }

        /// The ring with its badges around it.
        var ringHeight: Double { radius * 2 + badge * 2 + 14 }
        var legendHeight: Double { rowHeight * Double(rows) }
        var height: Double { beside ? max(ringHeight, legendHeight) : ringHeight + 10 + legendHeight }
    }

    /// How tall a section that is drawn as one piece will be, or nil for a
    /// section that breaks across pages on its own. A heading asks this so
    /// it is not left at the foot of one page with its ring at the top of
    /// the next.
    public static func wholeHeight(of section: Section, in resume: Resume, style: Style, on sheet: Sheet) -> Double? {
        guard section == .time else { return nil }
        let parts = TimeShares.fractions(of: resume.time)
        guard !parts.isEmpty else { return nil }
        return TimeLayout(count: parts.count, style: style, sheet: sheet).height
    }

    /// A ring divided in proportion, lettered, with the legend beside or
    /// under it.
    ///
    /// Letters rather than labels on the ring, because a label on a thin
    /// slice has nowhere to go; and the legend is real text, so the slices
    /// survive a parser as "A Writing code 40%" — which is more than a chart
    /// usually manages.
    public static func timeSplit(_ slices: [TimeSlice], on sheet: Sheet, style: Style) {
        let parts = TimeShares.fractions(of: slices)
        let percents = TimeShares.percentages(of: slices)
        guard !parts.isEmpty else { return }
        let pdf = sheet.pdf
        let layout = TimeLayout(count: parts.count, style: style, sheet: sheet)
        let badge = layout.badge

        // Kept whole: half a ring on one page and its legend on the next is
        // not a chart. The heading has already made room — see `wholeHeight`.
        pdf.breakIfNeeded(layout.height + 6)
        let top = sheet.cursor

        // Beside: the ring in a column of its own on the left, the legend
        // from just past it. Above: the ring centred, the legend under it.
        let ringColumn = layout.beside ? layout.radius * 2 + badge * 2 + 30 : style.width
        let centreX = style.x + ringColumn / 2
        let centreY = top - badge - 7 - layout.radius
        let legendX = layout.beside ? style.x + ringColumn : style.x
        let legendWidth = layout.beside ? style.width - ringColumn : style.width
        let legendTop = layout.beside ? top - 2 : top - layout.ringHeight - 10

        let ringRadius = layout.radius - layout.thickness / 2
        let gapDegrees = parts.count > 1 ? 2.2 : 0.0
        var start = 0.0
        for (index, part) in parts.enumerated() {
            let sweep = 360 * part.fraction
            let from = start + gapDegrees / 2, to = start + sweep - gapDegrees / 2
            // The first slice in the accent, each after it a step lighter —
            // one hue, so the ring reads as one thing rather than a flag.
            let tint = sheet.accent.lightened(by: min(0.78, Double(index) / Double(max(parts.count, 2)) * 0.9))
            if to > from {
                pdf.arc(x: centreX, y: centreY, radius: ringRadius, from: from, to: to,
                        thickness: layout.thickness, color: tint, rounded: false)
            }
            // The letter, just outside the slice's middle.
            let middle = (start + sweep / 2) * .pi / 180
            let badgeRadius = layout.radius + badge + 3
            let badgeX = centreX + badgeRadius * sin(middle)
            let badgeY = centreY + badgeRadius * cos(middle)
            pdf.circle(x: badgeX, y: badgeY, radius: badge, color: sheet.ink)
            pdf.textAt(TimeShares.letter(index), x: badgeX - badge, y: badgeY - badge * 0.52,
                       size: badge * 1.15, color: sheet.page, align: .center, boxWidth: badge * 2, face: sheet.semibold)
            start += sweep
        }

        pdf.move(to: legendTop)
        let legendSize = style.detailSize
        for (index, entry) in percents.enumerated() {
            let rowTop = sheet.cursor
            let centre = rowTop - badge - 1
            pdf.circle(x: legendX + badge, y: centre, radius: badge, color: sheet.ink)
            pdf.textAt(TimeShares.letter(index), x: legendX, y: centre - badge * 0.52,
                       size: badge * 1.15, color: sheet.page, align: .center, boxWidth: badge * 2, face: sheet.semibold)
            pdf.textAt(entry.label, x: legendX + badge * 2 + 8, y: centre - legendSize * 0.36,
                       size: legendSize, color: sheet.ink, face: sheet.regular)
            pdf.textAt("\(entry.percent)%", x: legendX, y: centre - legendSize * 0.36, size: legendSize,
                       color: sheet.muted, align: .right, boxWidth: legendWidth, face: sheet.regular)
            pdf.move(to: rowTop - layout.rowHeight)
        }
        pdf.move(to: top - layout.height)
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
        let wanted = style.dates == .besideTitle && !dates.isEmpty

        // A column too narrow to hold the dates and anything else has no
        // business trying: the title takes the width and the dates drop to a
        // line of their own beneath it. They used to share the line anyway —
        // the title reset to the full width and drawn straight through them.
        var besideTitle = wanted
        var available = style.width
        if wanted {
            let dateWidth = sheet.pdf.width(of: dates, size: style.dateSize, face: sheet.regular)
            if style.width - dateWidth - 12 < style.width * 0.4 {
                besideTitle = false
            } else {
                available = style.width - dateWidth - 12
            }
        }
        let beneath = wanted && !besideTitle

        // The whole heading is measured and broken before the dates go down.
        // Left to `paragraph`, the break lands after them — the title at the
        // top of the next page and the dates stranded at the foot of this one.
        let step = sheet.leading(pointSize)
        let titleHeight = sheet.pdf.blockHeight(
            title.trimmingCharacters(in: .whitespacesAndNewlines),
            size: pointSize, width: available, leading: step, face: resolved
        )
        let datesBelow = beneath ? sheet.leading(style.dateSize) : 0
        sheet.pdf.breakIfNeeded(max(titleHeight + datesBelow, step * 1.8))
        let top = sheet.cursor

        if besideTitle {
            sheet.pdf.cell(dates, x: style.x, boxWidth: style.width, size: style.dateSize,
                           color: sheet.muted, align: .right, face: sheet.regular)
            sheet.pdf.move(to: top)
        }

        sheet.paragraph(title, x: style.x, width: available, size: pointSize,
                        face: resolved, color: color ?? sheet.ink)

        if beneath {
            sheet.line(dates, x: style.x, width: style.width,
                       size: style.dateSize, face: sheet.regular, color: sheet.muted)
        }
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

        case .achievements:
            return resume.achievements.enumerated().map { index, item in
                let icon = Icon(rawValue: item.icon) ?? Icon.cycle[index % Icon.cycle.count]
                return Entry(dates: DateRange("")) { sheet, style in
                    Blocks.callouts([(icon: icon, title: item.title, summary: item.summary)], on: sheet, style: style)
                }
            }

        case .strengths:
            return resume.strengths.map { item in
                Entry(dates: DateRange("")) { sheet, style in
                    Blocks.callouts([(icon: nil, title: item.title, summary: item.summary)], on: sheet, style: style)
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

    /// Draws one entry with its dates hung in a rail to its left.
    ///
    /// Shared by everything that hangs a rail. `Timeline` and the `rail`
    /// ornament each kept a private copy of this, which was two places for
    /// the break rules to drift apart — and drift is the one failure a rail
    /// cannot hide, because the dates and the entry they belong to visibly
    /// stop lining up.
    public static func railed(
        _ entry: Entry, on sheet: Sheet, style: Style, labels: Labels,
        railX: Double, railWidth: Double, gutter: Double
    ) {
        let pdf = sheet.pdf

        // The rail is drawn against the entry's own top, so the break has to
        // happen first — otherwise the dates land at the bottom of one page
        // and the role at the top of the next.
        pdf.breakIfNeeded(sheet.leading(style.roleSize) * 3.4)
        let top = sheet.cursor

        let dates = entry.dates.rendered(present: labels.present, dash: labels.dateSeparator)
        if !dates.isEmpty {
            // Right-aligned against the gutter, so the dates form a clean
            // edge facing the content rather than a ragged one.
            pdf.cell(dates, x: railX, boxWidth: railWidth, size: style.dateSize,
                     color: sheet.muted, align: .right, face: sheet.medium)

            // A short tick down the middle of the gutter. Vertical, and a
            // fixed height, so it cannot be orphaned by a page break part-way
            // down an entry — and so the eye reads the rail as one column
            // rather than as a row of dashes.
            let markerX = railX + railWidth + gutter / 2
            let markerTop = top - 4
            pdf.line(from: markerX, markerTop,
                     to: markerX, markerTop - sheet.leading(style.roleSize) * 1.6,
                     color: sheet.hairline, thickness: 1.1)
        }

        pdf.move(to: top)
        entry.draw(sheet, style)
    }
}
