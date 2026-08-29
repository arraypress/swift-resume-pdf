//
//  ResumeDocx.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé, and the letter, as a Word document.
//
//  One layout, not eighteen. A .docx goes where a form demands one, and
//  the thing on the other side of that form is a parser: it wants the
//  name at the top, headings it recognises, entries in order, and real
//  bullets. That is what this writes, in the theme's typeface and colour
//  and nothing more — a design is a property of the PDF, and the .docx is
//  the same document set the way a parser reads it.
//
//  Built on the ``Outline``, so every section the PDF carries is written,
//  in the document's own order, with the same labels. What is not carried
//  is the photograph and the code: a form that wants a .docx wants neither.
//

import Foundation
import TextDocx
import TextPDF

extension Outlined {

    /// The finished `.docx` — the résumé, or the letter, for the form that
    /// takes nothing else.
    public func docx(theme: Theme = .plain) -> Data {
        docxDocument(theme: theme).data()
    }

    public func saveDocx(to url: URL, theme: Theme = .plain) throws {
        try docx(theme: theme).write(to: url, options: .atomic)
    }

    /// The document before it is written, for a caller who wants to add
    /// to it — a covering note on the first page, say.
    public func docxDocument(theme: Theme = .plain) -> Docx {
        Docx.from(outline(), theme: theme, name: profile.name)
    }
}

// MARK: - Blocks, in Word's terms

extension Docx {

    fileprivate static let muted = "#595959"

    /// A document from an outline: each block in the style Word has for it.
    static func from(_ blocks: [Outline.Block], theme: Theme, name: String) -> Docx {
        var doc = Docx(
            page: Docx.Page(size: theme.pageSize.docx, margins: Docx.Page.Margins(all: theme.density.margin)),
            typography: Docx.Typography(body: theme.docxFace, size: 10.5),
            accent: theme.isMonochrome ? nil : theme.accent,
            title: name,
            author: name
        )

        for block in blocks {
            switch block {
            case .title(let text):
                doc.title(text)

            case .subtitle(let text):
                doc.subtitle(text)

            case .contacts(let items):
                var runs: [Docx.Run] = []
                for item in items {
                    if !runs.isEmpty { runs.append(Docx.Run(" · ", color: muted)) }
                    runs.append(Docx.Run(item.text, link: item.url))
                }
                doc.paragraph(runs, spaceAfter: 4)

            case .particular(let label, let value):
                doc.paragraph([Docx.Run("\(label): ", color: muted), Docx.Run(value)], spaceAfter: 0)

            case .heading(let text):
                doc.heading(text)

            case .entry(let title, let date):
                // Bold on the left, the date against the right margin on the
                // same line.
                var runs = [Docx.Run(title, bold: true)]
                if !date.isEmpty { runs += [.tab, Docx.Run(date, color: muted, size: 9.5)] }
                doc.paragraph(runs, rightTab: !date.isEmpty, spaceAfter: 0, keepWithNext: true)

            case .detail(let fragments, let italic):
                let present = fragments.filter { !$0.text.isBlank }
                guard !present.isEmpty else { break }
                var runs: [Docx.Run] = []
                for fragment in present {
                    if !runs.isEmpty { runs.append(Docx.Run(" · ", color: muted)) }
                    runs.append(Docx.Run(fragment.text, italic: italic, color: muted, link: fragment.url))
                }
                doc.paragraph(runs, spaceAfter: 2)

            case .paragraph(let text):
                doc.paragraph(text, spaceAfter: 2)

            case .note(let text):
                doc.paragraph([Docx.Run(text, italic: true)], spaceAfter: 2)

            case .emphasis(let text):
                doc.paragraph([Docx.Run(text, bold: true)], spaceAfter: 2)

            case .lines(let items):
                for item in items { doc.paragraph([Docx.Run(item)], spaceAfter: 0) }

            case .bullets(let items):
                doc.bullets(items)

            case .leadIns(let items):
                doc.bullets(items.map { [Docx.Run($0.lead + " ", bold: true), Docx.Run($0.detail)] })

            case .skills(let group, let items):
                var runs: [Docx.Run] = []
                if !group.isEmpty { runs.append(Docx.Run(group + ": ", bold: true)) }
                runs.append(Docx.Run(items.joined(separator: ", ")))
                doc.paragraph(runs, spaceAfter: 2)

            case .keywords(let items):
                doc.paragraph([Docx.Run(items.joined(separator: " · "), color: muted, size: 9.5)])

            case .pair(let name, let level):
                var runs = [Docx.Run(name)]
                if !level.isEmpty { runs.append(Docx.Run(" — \(level)", color: muted)) }
                doc.paragraph(runs, spaceAfter: 0)

            case .spacer:
                doc.paragraph([], spaceAfter: 2)
            }
        }
        return doc
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
