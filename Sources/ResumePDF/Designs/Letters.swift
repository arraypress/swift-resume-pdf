//
//  Letters.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Four arrangements for a letter.
//
//  Each one pairs with a résumé design, because the two documents arrive
//  together and an application whose halves were plainly made by different
//  tools is answering a question nobody asked. The pairing is a suggestion
//  rather than a constraint — any letter renders under any theme.
//
//  What they share is the shape of a letter, which is older and less
//  negotiable than a résumé's: sender, recipient, date, greeting, argument,
//  sign-off. Moving those about does not make a letter look modern; it makes
//  it look like it was written by somebody who has not read one.
//

import Foundation
import TextPDF

/// One of the built-in letter arrangements.
public enum LetterDesign: String, Sendable, CaseIterable, Codable {

    /// A small ruled head and one column. Pairs with `ledger`.
    case memo

    /// Serif, name at the left and contact ranged right. Pairs with
    /// `broadsheet`, and the right choice for law and academia.
    case letterhead

    /// Contact details in a filled panel under the name. Pairs with `plaque`.
    case panel

    /// Centred name, with the body between two rules. Pairs with `marker` and
    /// `bulletin`.
    case monogram

    public var displayName: String {
        switch self {
        case .memo: return "Memo"
        case .letterhead: return "Letterhead"
        case .panel: return "Panel"
        case .monogram: return "Monogram"
        }
    }

    /// The résumé design this was drawn to sit beside.
    public var pairsWith: DesignKind {
        switch self {
        case .memo: return .ledger
        case .letterhead: return .broadsheet
        case .panel: return .plaque
        case .monogram: return .bulletin
        }
    }

    public var intendedTypeface: Typeface {
        self == .letterhead ? .sourceSerif : .inter
    }

    var design: any LetterLayout {
        switch self {
        case .memo: return MemoLetter()
        case .letterhead: return LetterheadLetter()
        case .panel: return PanelLetter()
        case .monogram: return MonogramLetter()
        }
    }
}

/// An arrangement of a letter on a page.
protocol LetterLayout: Sendable {

    /// Draws the masthead, and leaves the cursor where the body starts.
    func masthead(_ letter: CoverLetter, on sheet: Sheet)
}

// MARK: - Rendering

extension CoverLetter {

    /// Lays the letter out.
    public func document(design: LetterDesign = .memo, theme: Theme = .plain) throws -> Document {
        let family = try Typography.family(theme.typeface)
        let sheet = Sheet(theme: theme, family: family, labels: .english)
        sheet.pdf.language = "en"

        design.design.masthead(self, on: sheet)
        Letters.body(self, on: sheet)
        return sheet.pdf
    }

    public func render(design: LetterDesign = .memo, theme: Theme = .plain) throws -> Data {
        try document(design: design, theme: theme).render(metadata: [
            "Title": profile.name.isEmpty ? "Cover letter" : "\(profile.name) — cover letter",
            "Author": profile.name,
            "Subject": subject.isEmpty ? "Letter of application" : subject,
            "Creator": "ResumePDF",
        ])
    }

    @discardableResult
    public func save(
        to url: URL, design: LetterDesign = .memo, theme: Theme = .plain
    ) throws -> Int {
        let data = try render(design: design, theme: theme)
        try data.write(to: url, options: .atomic)
        return data.count
    }
}

// MARK: - Shared body

/// The parts of a letter every design sets the same way.
enum Letters {

    /// Recipient, greeting, argument, sign-off.
    static func body(_ letter: CoverLetter, on sheet: Sheet) {
        let size = 9.8

        if !letter.date.isEmpty {
            sheet.line(letter.date, size: 9, face: sheet.regular, color: sheet.muted)
            sheet.gap(10)
        }

        if !letter.recipient.isEmpty {
            sheet.line("To:", size: 8, face: sheet.italic, color: sheet.muted)
            sheet.rigidGap(1)
            for line in letter.recipient.lines() {
                sheet.line(line, size: 10, face: sheet.regular, color: sheet.ink)
            }
            sheet.gap(16)
        }

        if !letter.subject.isEmpty {
            sheet.paragraph(letter.subject, size: size, face: sheet.semibold)
            sheet.gap(12)
        }

        sheet.paragraph(letter.greeting, size: size)
        sheet.gap(11)

        for paragraph in letter.body {
            sheet.paragraph(paragraph, size: size)
            sheet.gap(10)
        }

        if !letter.highlights.isEmpty {
            sheet.rigidGap(2)
            for highlight in letter.highlights {
                leadIn(highlight, on: sheet, size: size)
            }
            sheet.gap(8)
        }

        sheet.gap(14)
        sheet.paragraph(letter.signOff, size: size)
        sheet.rigidGap(2)

        // Room for a signature between the sign-off and the name, because a
        // printed letter gets signed there and a PDF one is often printed.
        sheet.gap(20)
        sheet.line(letter.signedName, size: size, face: sheet.medium)

        if !letter.postscript.isEmpty {
            sheet.gap(16)
            sheet.paragraph(letter.postscript, size: 9.2, face: sheet.italic, color: sheet.muted)
        }
    }

    /// A bullet whose opening phrase is set in the heavier weight.
    private static func leadIn(_ highlight: Highlight, on sheet: Sheet, size: Double) {
        let pdf = sheet.pdf
        let indent = size * 1.3
        let lead = highlight.title.hasSuffix(".") ? highlight.title : highlight.title + "."

        pdf.breakIfNeeded(sheet.leading(size) * 2.4)
        let top = pdf.cursor()

        pdf.cell("•", x: sheet.left, boxWidth: indent, size: size,
                 color: sheet.accent, face: sheet.regular)
        pdf.move(to: top)

        sheet.runOn(lead, highlight.detail,
                    x: sheet.left + indent, width: sheet.width - indent, size: size)
        sheet.rigidGap(4)
    }

    /// The contact line every letter head carries, linked where it can be.
    static func contact(_ profile: Profile) -> [(text: String, url: String)] {
        profile.contactEntries()
    }
}

// MARK: - Memo

struct MemoLetter: LetterLayout {

    func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = letter.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 20, size: 22,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.3)

        var y = top - 38
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.2,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
            y -= 16
        }

        pdf.move(to: y - 2)
        sheet.contactFlow(Letters.contact(profile), size: 8.7)
        sheet.rigidGap(5)
        sheet.rule(color: sheet.ink, thickness: 0.9)
        sheet.gap(22)
    }
}

// MARK: - Letterhead

struct LetterheadLetter: LetterLayout {

    func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = letter.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 24,
                   color: sheet.ink, face: sheet.regular, tracking: 0.2)

        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: top - 40, size: 11,
                       color: sheet.muted, face: sheet.italic)
        }

        // Contact ranged right against the name, the way a printed letterhead
        // sets it — the two together make the head, and neither is a list.
        var y = top - 14
        for entry in Letters.contact(profile) {
            let measured = pdf.width(of: entry.text, size: 8.8, face: sheet.regular)
            let originX = sheet.right - measured
            if entry.url.isEmpty {
                pdf.textAt(entry.text, x: originX, y: y, size: 8.8,
                           color: sheet.muted, face: sheet.regular)
            } else {
                pdf.linked(entry.text, url: entry.url, x: originX, y: y, size: 8.8,
                           color: sheet.muted, face: sheet.regular)
            }
            y -= 13
        }

        pdf.move(to: min(top - 56, y - 6))
        sheet.rule(color: sheet.ink, thickness: 0.7)
        sheet.gap(24)
    }
}

// MARK: - Panel

struct PanelLetter: LetterLayout {

    func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = letter.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, face: sheet.semibold, tracking: -0.4)

        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: top - 42, size: 11,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       face: sheet.regular)
        }

        let entries: [(Icon, String)] = [
            (.email, profile.email),
            (.phone, profile.phone),
            (.location, profile.location),
        ].filter { !$0.1.trimmingCharacters(in: .whitespaces).isEmpty }
            + profile.links.map { (Icon.link, $0.label) }

        guard !entries.isEmpty else {
            pdf.move(to: top - 66)
            sheet.gap(20)
            return
        }

        let columns = entries.count > 2 ? 2 : 1
        let rows = (entries.count + columns - 1) / columns
        let rowStep = 19.0
        let padding = 15.0
        let height = Double(rows) * rowStep + padding * 2 - 4

        let fill = sheet.theme.accentIsDark && !sheet.theme.isMonochrome ? sheet.accent : sheet.wash
        let palette = Sheet.Palette.against(fill, accent: sheet.theme.accentColor)

        let panelTop = top - 58
        pdf.roundedRect(x: sheet.left, y: panelTop - height, width: sheet.width,
                        height: height, radius: 9, color: fill)

        let columnWidth = (sheet.width - padding * 2) / Double(columns)
        for (index, entry) in entries.enumerated() {
            let originX = sheet.left + padding + Double(index % columns) * columnWidth
            let baseline = panelTop - padding - Double(index / columns) * rowStep

            sheet.icon(entry.0, x: originX, y: baseline - 11.5, size: 12, color: palette.accent)
            pdf.textAt(entry.1, x: originX + 18, y: baseline - 9.6, size: 8.9,
                       color: palette.ink, face: sheet.regular)
        }

        pdf.move(to: panelTop - height)
        sheet.gap(22)
    }
}

// MARK: - Monogram

struct MonogramLetter: LetterLayout {

    func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        let pdf = sheet.pdf
        let profile = letter.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: sheet.left, y: top - 22, size: 25,
                   color: sheet.ink, align: .center, boxWidth: sheet.width,
                   face: sheet.semibold, tracking: -0.3)

        var y = top - 42
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: sheet.left, y: y, size: 10.6,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       align: .center, boxWidth: sheet.width, face: sheet.regular)
            y -= 18
        }

        pdf.move(to: y)
        sheet.contactFlow(Letters.contact(profile), size: 8.7, align: .center)
        sheet.gap(12)
        capped(on: sheet)
        sheet.gap(20)
    }

    /// A rule with a mark at each end.
    ///
    /// Inset well short of the margins: a full-width rule reads as a division
    /// of the page, and this is meant to read as a flourish under a name.
    private func capped(on sheet: Sheet) {
        let pdf = sheet.pdf
        let inset = sheet.width * 0.28
        let y = pdf.cursor()
        let from = sheet.left + inset
        let to = sheet.right - inset

        pdf.line(from: from, y, to: to, y, color: sheet.ink, thickness: 0.8)
        pdf.circle(x: from, y: y, radius: 2.6, color: sheet.accent)
        pdf.circle(x: to, y: y, radius: 2.6, color: sheet.accent)
        pdf.move(to: y - 4)
    }
}
