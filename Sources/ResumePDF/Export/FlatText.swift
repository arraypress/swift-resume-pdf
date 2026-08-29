//
//  FlatText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé as text, for the box that says "paste your résumé here".
//
//  The commonest way a résumé reaches a tracking system is not a file at
//  all: it is pasted into a form. Everything here is single-column by
//  construction, the headings are the words a parser matches on, and
//  nothing is wrapped — a form reflows its own text, and a hard line break
//  in the middle of a sentence is what makes a pasted résumé look pasted.
//
//  Markdown is the same walk with the emphasis kept, for a README, a
//  profile page, or anywhere that renders it.
//

import Foundation

extension Outlined {

    /// The document as plain text, in its own order and labels, with the
    /// headings in capitals and a dash before every bullet — the résumé for
    /// the form, the letter for the "covering note" box.
    public func plainText() -> String {
        Outline.plainText(outline())
    }

    /// The document as Markdown.
    public func markdown() -> String {
        Outline.markdown(outline())
    }
}

extension Outline {

    /// What a block is followed by: nothing, or a blank line.
    private static func breathes(_ block: Block) -> Bool {
        switch block {
        case .paragraph, .bullets, .leadIns, .spacer, .emphasis, .note, .lines: return true
        default: return false
        }
    }

    static func plainText(_ blocks: [Block]) -> String {
        var lines: [String] = []
        var previous: Block?

        for block in blocks {
            // A heading, and an entry that does not directly follow one,
            // gets a blank line before it. Everything else runs on.
            switch block {
            case .heading:
                if !lines.isEmpty { lines.append("") }
            case .entry:
                if let previous, case .heading = previous {} else { lines.append("") }
            case .skills, .pair:
                if let previous, case .heading = previous {} else if let previous, breathes(previous) { lines.append("") }
            default:
                if let previous, breathes(previous) { lines.append("") }
            }

            switch block {
            case .title(let text), .subtitle(let text), .paragraph(let text), .note(let text), .emphasis(let text):
                lines.append(text)
            case .contacts(let items):
                lines.append(items.map(\.text).joined(separator: " | "))
            case .particular(let label, let value):
                lines.append("\(label): \(value)")
            case .heading(let text):
                lines.append(text.uppercased())
            case .entry(let title, let date):
                lines.append(date.isEmpty ? title : "\(title) (\(date))")
            case .detail(let fragments, _):
                let present = fragments.map(\.text).filter { !$0.isEmpty }
                if !present.isEmpty { lines.append(present.joined(separator: " · ")) }
            case .lines(let items):
                lines += items
            case .bullets(let items):
                lines += items.map { "- " + $0 }
            case .leadIns(let items):
                lines += items.map { "- \($0.lead) \($0.detail)" }
            case .skills(let group, let items):
                lines.append(group.isEmpty ? items.joined(separator: ", ") : "\(group): " + items.joined(separator: ", "))
            case .keywords(let items):
                lines.append(items.joined(separator: ", "))
            case .pair(let name, let level):
                lines.append(level.isEmpty ? name : "\(name) — \(level)")
            case .spacer:
                break
            }
            previous = block
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func markdown(_ blocks: [Block]) -> String {
        var lines: [String] = []
        var previous: Block?

        func link(_ fragment: Fragment) -> String {
            guard let url = fragment.url else { return fragment.text }
            return "[\(fragment.text)](\(url))"
        }

        for block in blocks {
            switch block {
            case .heading:
                if !lines.isEmpty { lines.append("") }
            case .entry:
                if let previous, case .heading = previous {} else { lines.append("") }
            case .skills, .pair:
                if let previous, case .heading = previous {} else if let previous, breathes(previous) { lines.append("") }
            default:
                if let previous, breathes(previous) { lines.append("") }
            }

            switch block {
            case .title(let text): lines.append("# " + text)
            case .subtitle(let text): lines.append("**" + text + "**")
            case .contacts(let items): lines.append(items.map(link).joined(separator: " · "))
            case .particular(let label, let value): lines.append("\(label): \(value)  ")
            case .heading(let text): lines.append("## " + text)
            case .entry(let title, let date):
                lines.append(date.isEmpty ? "**\(title)**" : "**\(title)** — _\(date)_")
            case .detail(let fragments, let italic):
                let present = fragments.filter { !$0.text.isEmpty }.map(link)
                if !present.isEmpty {
                    let joined = present.joined(separator: " · ")
                    lines.append(italic ? "_\(joined)_" : joined)
                }
            case .paragraph(let text): lines.append(text)
            case .note(let text): lines.append("_\(text)_")
            case .emphasis(let text): lines.append("**\(text)**")
            case .lines(let items): lines += items.map { $0 + "  " }
            case .bullets(let items): lines += items.map { "- " + $0 }
            case .leadIns(let items): lines += items.map { "- **\($0.lead)** \($0.detail)" }
            case .skills(let group, let items):
                lines.append(group.isEmpty ? items.joined(separator: ", ") : "**\(group):** " + items.joined(separator: ", "))
            case .keywords(let items): lines.append("_" + items.joined(separator: " · ") + "_")
            case .pair(let name, let level): lines.append(level.isEmpty ? "**\(name)**" : "**\(name)** — \(level)")
            case .spacer: break
            }
            previous = block
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
