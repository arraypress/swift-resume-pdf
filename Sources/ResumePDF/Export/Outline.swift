//
//  Outline.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A document reduced to the blocks every flat format shares.
//
//  A Word document, a plain-text paste and a Markdown file want the same
//  things in the same order — the name, the headings, an entry with its
//  date, the bullets under it — and differ only in how each block is
//  spelled. So the walk over a résumé or a letter happens once, here, and
//  each format is a short renderer over the result. A section added to the
//  model is added to every flat format at the same time, or to none.
//
//  It is public so that a format this library does not write — a YAML
//  front matter, an HTML page — is the same short renderer, not a second
//  walk over the model.
//

import Foundation

/// A document that can be walked as an outline: a résumé, or a letter.
/// Everything flat — the Word document, the plain text, the Markdown — is
/// written once, over this.
public protocol Outlined {

    /// Whose document it is.
    var profile: Profile { get }

    /// The document, top to bottom, in its own order and labels.
    func outline() -> [Outline.Block]
}

/// The blocks a flat rendering of a document is made of.
public enum Outline {

    /// A run of text that may be an address.
    public struct Fragment: Equatable, Sendable {
        public let text: String
        public let url: String?

        public init(_ text: String, url: String? = nil) {
            self.text = text
            self.url = url
        }
    }

    /// A bold lead and the sentence after it, the way a letter's
    /// highlights are set.
    public struct LeadIn: Equatable, Sendable {
        public let lead: String
        public let detail: String

        public init(lead: String, detail: String) {
            self.lead = lead
            self.detail = detail
        }
    }

    public enum Block: Equatable, Sendable {
        case title(String)
        case subtitle(String)
        case contacts([Fragment])
        case particular(label: String, value: String)
        case heading(String)
        /// An entry's first line: what it is, and when, set opposite.
        case entry(title: String, date: String)
        /// The line under it — who, where — dotted together; empties dropped.
        case detail([Fragment], italic: Bool)
        case paragraph(String)
        /// An aside, set quieter.
        case note(String)
        /// A line that carries weight: a subject, a signed name.
        case emphasis(String)
        /// Consecutive lines with no space between — an address.
        case lines([String])
        case bullets([String])
        case leadIns([LeadIn])
        case skills(group: String, items: [String])
        /// Technologies under an entry, set small.
        case keywords([String])
        /// A language and its level.
        case pair(String, String)
        case spacer
    }
}

// MARK: - The head both share

extension Profile {

    /// The name, the headline, the ways to reach them — the top of every
    /// document, résumé or letter.
    func outlineHead() -> [Outline.Block] {
        var blocks: [Outline.Block] = [.title(name)]
        if !headline.isEmpty { blocks.append(.subtitle(headline)) }

        let contacts = contactEntries().map {
            Outline.Fragment($0.text, url: $0.url.isEmpty ? nil : $0.url)
        }
        if !contacts.isEmpty { blocks.append(.contacts(contacts)) }
        return blocks
    }
}

// MARK: - A résumé

extension Resume: Outlined {

    /// The résumé, section by section, in its own order and labels.
    public func outline() -> [Outline.Block] {
        var blocks = profile.outlineHead()
        for item in profile.particulars() {
            blocks.append(.particular(label: item.label, value: item.value))
        }

        for section in populated() {
            blocks.append(.heading(heading(for: section)))
            blocks += outline(section)
        }
        return blocks
    }

    private func outline(_ section: Section) -> [Outline.Block] {
        switch section {
        case .summary: return [.paragraph(summary)]
        case .experience: return positions(experience)
        case .volunteering: return positions(volunteering)
        case .teaching: return positions(teaching)
        case .service: return positions(service)
        case .education: return education(education)
        case .skills: return skills(skills)
        case .projects: return projects(projects)
        case .publications: return publications(publications)
        case .talks: return publications(talks)
        case .certifications: return credentials(certifications)
        case .memberships: return credentials(memberships)
        case .awards: return awards(awards)
        case .languages: return languages(languages)
        case .achievements: return callouts(achievements.map { ($0.title, $0.summary) })
        case .strengths: return callouts(strengths.map { ($0.title, $0.summary) })
        case .time: return timeSplit(time)
        case .grants: return grants(grants)
        case .interests: return [.paragraph(interests)]
        case .references: return [.paragraph(references)]
        default:
            guard let title = section.customTitle,
                  let custom = custom.first(where: { $0.title == title }) else { return [] }
            return custom.content.flatMap { content -> [Outline.Block] in
                switch content {
                case .prose(let text): return [.paragraph(text)]
                case .list(let items): return [.bullets(items)]
                case .positions(let items): return positions(items)
                case .education(let items): return education(items)
                case .projects(let items): return projects(items)
                case .publications(let items): return publications(items)
                case .credentials(let items): return credentials(items)
                case .awards(let items): return awards(items)
                case .grants(let items): return grants(items)
                case .skills(let items): return skills(items)
                case .languages(let items): return languages(items)
                case .achievements(let items): return callouts(items.map { ($0.title, $0.summary) })
                case .strengths(let items): return callouts(items.map { ($0.title, $0.summary) })
                }
            }
        }
    }

    private func dates(_ range: DateRange) -> String {
        range.rendered(present: labels.present, dash: labels.dateSeparator)
    }

    private func positions(_ items: [Position]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            var blocks: [Outline.Block] = [
                .entry(title: item.role, date: dates(item.dates)),
                .detail([Outline.Fragment(item.organisation), Outline.Fragment(item.location)], italic: false),
            ]
            if !item.summary.isEmpty { blocks.append(.note(item.summary)) }
            if !item.highlights.isEmpty { blocks.append(.bullets(item.highlights)) }
            blocks.append(item.skills.isEmpty ? .spacer : .keywords(item.skills))
            return blocks
        }
    }

    private func education(_ items: [Education]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            var blocks: [Outline.Block] = [
                .entry(title: item.qualification, date: dates(item.dates)),
                .detail([Outline.Fragment(item.institution), Outline.Fragment(item.location),
                         Outline.Fragment(item.grade)], italic: false),
            ]
            if !item.highlights.isEmpty { blocks.append(.bullets(item.highlights)) }
            return blocks
        }
    }

    private func skills(_ groups: [SkillGroup]) -> [Outline.Block] {
        groups.map { .skills(group: $0.name, items: $0.names) }
    }

    private func projects(_ items: [Project]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            var blocks: [Outline.Block] = [.entry(title: item.name, date: dates(item.dates))]
            var line = [Outline.Fragment(item.role)]
            if let link = item.link { line.append(Outline.Fragment(link.label, url: link.absolute)) }
            blocks.append(.detail(line, italic: false))
            if !item.summary.isEmpty { blocks.append(.paragraph(item.summary)) }
            if !item.highlights.isEmpty { blocks.append(.bullets(item.highlights)) }
            if !item.skills.isEmpty { blocks.append(.keywords(item.skills)) }
            return blocks
        }
    }

    private func publications(_ items: [Publication]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            var blocks: [Outline.Block] = [
                .entry(title: item.title, date: item.date),
                .detail([Outline.Fragment(item.venue), Outline.Fragment(item.authors)], italic: true),
            ]
            if let link = item.link {
                blocks.append(.detail([Outline.Fragment(link.label, url: link.absolute)], italic: false))
            }
            return blocks
        }
    }

    private func credentials(_ items: [Credential]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            [.entry(title: item.name, date: item.date),
             .detail([Outline.Fragment(item.issuer), Outline.Fragment(item.identifier)], italic: false)]
        }
    }

    private func awards(_ items: [Award]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            var blocks: [Outline.Block] = [
                .entry(title: item.name, date: item.date),
                .detail([Outline.Fragment(item.issuer)], italic: false),
            ]
            if !item.summary.isEmpty { blocks.append(.paragraph(item.summary)) }
            return blocks
        }
    }

    private func languages(_ items: [Language]) -> [Outline.Block] {
        items.map { .pair($0.name, $0.level) }
    }

    /// A title and the sentence under it — the shape a letter's highlights
    /// already take, so every flat format sets it already.
    private func callouts(_ items: [(title: String, summary: String)]) -> [Outline.Block] {
        [.leadIns(items.map { Outline.LeadIn(lead: $0.title, detail: $0.summary) })]
    }

    /// The ring as a list: each label with its share as a percentage, which
    /// is the only honest flat rendering of a picture of proportions.
    private func timeSplit(_ items: [TimeSlice]) -> [Outline.Block] {
        TimeShares.percentages(of: items).map { .pair($0.label, "\($0.percent)%") }
    }

    private func grants(_ items: [Grant]) -> [Outline.Block] {
        items.flatMap { item -> [Outline.Block] in
            [.entry(title: item.title, date: dates(item.dates)),
             .detail([Outline.Fragment(item.funder), Outline.Fragment(item.amount),
                      Outline.Fragment(item.role), Outline.Fragment(item.identifier)], italic: false)]
        }
    }
}

// MARK: - A letter

extension CoverLetter: Outlined {

    /// The letter, top to bottom. The shape is not a setting — see
    /// ``Letters/body(_:on:)`` — so this is the same walk in blocks.
    public func outline() -> [Outline.Block] {
        var blocks = profile.outlineHead()

        if !date.isEmpty { blocks.append(.note(date)) }
        if !recipient.isEmpty { blocks.append(.lines(recipient.lines())) }
        if !subject.isEmpty { blocks.append(.emphasis(subject)) }

        blocks.append(.paragraph(greeting))
        blocks += body.map { .paragraph($0) }
        if !highlights.isEmpty {
            blocks.append(.leadIns(highlights.map {
                Outline.LeadIn(lead: $0.title.hasSuffix(".") ? $0.title : $0.title + ".", detail: $0.detail)
            }))
        }
        blocks.append(.paragraph(signOff))
        blocks.append(.emphasis(signedName))
        if !postscript.isEmpty { blocks.append(.note(postscript)) }
        return blocks
    }
}
