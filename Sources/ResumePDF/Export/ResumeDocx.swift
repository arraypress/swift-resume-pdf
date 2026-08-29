//
//  ResumeDocx.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé as a Word document.
//
//  One layout, not sixteen. A .docx goes where a form demands one, and
//  the thing on the other side of that form is a parser: it wants the
//  name at the top, headings it recognises, entries in order, and real
//  bullets. That is what this writes, in the theme's typeface and colour
//  and nothing more — a design is a property of the PDF, and the .docx is
//  the same document set the way a parser reads it.
//
//  Every section the PDF can carry is written, in the résumé's own order,
//  with the same labels. What is not carried is the photograph and the
//  code: a form that wants a .docx is not a form that wants either.
//

import Foundation
import TextDocx
import TextPDF

extension Resume {

    /// The finished `.docx`.
    public func docx(theme: Theme = .plain) -> Data {
        docxDocument(theme: theme).data()
    }

    public func saveDocx(to url: URL, theme: Theme = .plain) throws {
        try docx(theme: theme).write(to: url, options: .atomic)
    }

    /// The document before it is written, for a caller who wants to add
    /// to it — a covering note on the first page, say.
    public func docxDocument(theme: Theme = .plain) -> Docx {
        var doc = Docx(
            page: Docx.Page(size: theme.pageSize.docx, margins: Docx.Page.Margins(all: theme.density.margin)),
            typography: Docx.Typography(body: theme.docxFace, size: 10.5),
            accent: theme.isMonochrome ? nil : theme.accent,
            title: profile.name,
            author: profile.name
        )

        masthead(on: &doc)

        for section in populated() {
            doc.heading(heading(for: section))
            write(section, on: &doc)
        }
        return doc
    }

    // MARK: The head

    private func masthead(on doc: inout Docx) {
        doc.title(profile.name)
        if !profile.headline.isEmpty { doc.subtitle(profile.headline) }

        var contacts: [Docx.Run] = []
        for entry in profile.contactEntries() {
            if !contacts.isEmpty { contacts.append(Docx.Run(" · ", color: Self.muted)) }
            contacts.append(Docx.Run(entry.text, link: entry.url.isEmpty ? nil : entry.url))
        }
        if !contacts.isEmpty { doc.paragraph(contacts, spaceAfter: 4) }

        // Regional particulars, where they have been set at all.
        for item in profile.particulars() {
            doc.paragraph([Docx.Run("\(item.label): ", color: Self.muted), Docx.Run(item.value)], spaceAfter: 0)
        }
    }

    // MARK: The sections

    private func write(_ section: Section, on doc: inout Docx) {
        switch section {
        case .summary: doc.paragraph(summary)
        case .experience: positions(experience, on: &doc)
        case .volunteering: positions(volunteering, on: &doc)
        case .teaching: positions(teaching, on: &doc)
        case .service: positions(service, on: &doc)
        case .education: education(education, on: &doc)
        case .skills: skills(skills, on: &doc)
        case .projects: projects(projects, on: &doc)
        case .publications: publications(publications, on: &doc)
        case .talks: publications(talks, on: &doc)
        case .certifications: credentials(certifications, on: &doc)
        case .memberships: credentials(memberships, on: &doc)
        case .awards: awards(awards, on: &doc)
        case .languages: languages(languages, on: &doc)
        case .grants: grants(grants, on: &doc)
        case .interests: doc.paragraph(interests)
        case .references: doc.paragraph(references)
        default:
            guard let title = section.customTitle,
                  let custom = custom.first(where: { $0.title == title }) else { return }
            for content in custom.content {
                switch content {
                case .prose(let text): doc.paragraph(text)
                case .list(let items): doc.bullets(items)
                case .positions(let items): positions(items, on: &doc)
                case .education(let items): education(items, on: &doc)
                case .projects(let items): projects(items, on: &doc)
                case .publications(let items): publications(items, on: &doc)
                case .credentials(let items): credentials(items, on: &doc)
                case .awards(let items): awards(items, on: &doc)
                case .grants(let items): grants(items, on: &doc)
                case .skills(let items): skills(items, on: &doc)
                case .languages(let items): languages(items, on: &doc)
                }
            }
        }
    }

    private static let muted = "#595959"

    /// The title line of an entry: bold on the left, the date against the
    /// right margin on the same line.
    private func titled(_ title: String, date: String, on doc: inout Docx) {
        var runs = [Docx.Run(title, bold: true)]
        if !date.isEmpty {
            runs += [.tab, Docx.Run(date, color: Self.muted, size: 9.5)]
        }
        doc.paragraph(runs, rightTab: !date.isEmpty, spaceAfter: 0, keepWithNext: true)
    }

    /// The second line: what is known about the thing, dotted together.
    private func detail(_ parts: [String], on doc: inout Docx, italic: Bool = false) {
        let present = parts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !present.isEmpty else { return }
        doc.paragraph([Docx.Run(present.joined(separator: " · "), italic: italic, color: Self.muted)], spaceAfter: 2)
    }

    private func dates(_ range: DateRange) -> String {
        range.rendered(present: labels.present, dash: labels.dateSeparator)
    }

    private func positions(_ items: [Position], on doc: inout Docx) {
        for item in items {
            titled(item.role, date: dates(item.dates), on: &doc)
            detail([item.organisation, item.location], on: &doc)
            if !item.summary.isEmpty { doc.paragraph([Docx.Run(item.summary, italic: true)], spaceAfter: 2) }
            doc.bullets(item.highlights)
            if !item.skills.isEmpty {
                doc.paragraph([Docx.Run(item.skills.joined(separator: " · "), color: Self.muted, size: 9.5)])
            } else {
                doc.paragraph([], spaceAfter: 2)
            }
        }
    }

    private func education(_ items: [Education], on doc: inout Docx) {
        for item in items {
            titled(item.qualification, date: dates(item.dates), on: &doc)
            detail([item.institution, item.location, item.grade], on: &doc)
            doc.bullets(item.highlights)
        }
    }

    private func skills(_ groups: [SkillGroup], on doc: inout Docx) {
        for group in groups {
            var runs: [Docx.Run] = []
            if !group.name.isEmpty { runs.append(Docx.Run(group.name + ": ", bold: true)) }
            runs.append(Docx.Run(group.names.joined(separator: ", ")))
            doc.paragraph(runs, spaceAfter: 2)
        }
    }

    private func projects(_ items: [Project], on doc: inout Docx) {
        for item in items {
            titled(item.name, date: dates(item.dates), on: &doc)
            var line: [Docx.Run] = []
            if !item.role.isEmpty { line.append(Docx.Run(item.role, color: Self.muted)) }
            if let link = item.link {
                if !line.isEmpty { line.append(Docx.Run(" · ", color: Self.muted)) }
                line.append(Docx.Run(link.label, color: Self.muted, link: link.absolute))
            }
            if !line.isEmpty { doc.paragraph(line, spaceAfter: 2) }
            if !item.summary.isEmpty { doc.paragraph(item.summary, spaceAfter: 2) }
            doc.bullets(item.highlights)
            if !item.skills.isEmpty {
                doc.paragraph([Docx.Run(item.skills.joined(separator: " · "), color: Self.muted, size: 9.5)])
            }
        }
    }

    private func publications(_ items: [Publication], on doc: inout Docx) {
        for item in items {
            titled(item.title, date: item.date, on: &doc)
            detail([item.venue, item.authors], on: &doc, italic: true)
            if let link = item.link {
                doc.paragraph([Docx.Run(link.label, color: Self.muted, link: link.absolute)], spaceAfter: 2)
            }
        }
    }

    private func credentials(_ items: [Credential], on doc: inout Docx) {
        for item in items {
            titled(item.name, date: item.date, on: &doc)
            detail([item.issuer, item.identifier], on: &doc)
        }
    }

    private func awards(_ items: [Award], on doc: inout Docx) {
        for item in items {
            titled(item.name, date: item.date, on: &doc)
            detail([item.issuer], on: &doc)
            if !item.summary.isEmpty { doc.paragraph(item.summary, spaceAfter: 2) }
        }
    }

    private func languages(_ items: [Language], on doc: inout Docx) {
        for item in items {
            var runs = [Docx.Run(item.name)]
            if !item.level.isEmpty { runs.append(Docx.Run(" — \(item.level)", color: Self.muted)) }
            doc.paragraph(runs, spaceAfter: 0)
        }
    }

    private func grants(_ items: [Grant], on doc: inout Docx) {
        for item in items {
            titled(item.title, date: dates(item.dates), on: &doc)
            detail([item.funder, item.amount, item.role, item.identifier], on: &doc)
        }
    }
}

// MARK: - The theme, in Word's terms

extension PageSize {

    var docx: Docx.Page.Size {
        switch self {
        case .a4: return .a4
        case .a5: return .a5
        case .letter: return .letter
        case .legal: return .legal
        }
    }
}

extension Theme {

    /// A face Word is likely to have. The bundled families are not embedded
    /// in a .docx — the reader substitutes freely — so the nearest common
    /// face is named instead, and a face somebody supplied is named as is.
    var docxFace: String {
        guard let face = typeface else { return "Calibri" }
        if face == .inter { return "Calibri" }
        if face == .sourceSerif { return "Georgia" }
        return face.name
    }
}
