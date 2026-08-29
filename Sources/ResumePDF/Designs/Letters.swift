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

    /// Contact details in a filled panel under the name. Pairs with `banner`.
    case panel

    /// Centred name, with the body between two rules. Pairs with `marker` and
    /// `bulletin`.
    case monogram

    /// What the design is called, in a report or a listing: its name,
    /// capitalised, the same way its blueprint says it.
    public var displayName: String { rawValue.capitalised }

    /// The thing that draws.
    ///
    /// Public for the same reason ``DesignKind/design`` is: a tool wants to
    /// treat "one of the four" and "a blueprint from a file" as one kind of
    /// thing.
    public var layout: any LetterLayout { blueprint }

    /// The design as data: the JSON file it would be handed back as. The
    /// case's name is the file's name, so there is nothing to look up.
    public var blueprint: LetterBlueprint { .bundled(rawValue) }

    /// The résumé design this was drawn to sit beside.
    public var pairsWith: DesignKind {
        switch self {
        case .memo: return .ledger
        case .letterhead: return .broadsheet
        case .panel: return .banner
        case .monogram: return .bulletin
        }
    }

    /// The typeface the design was drawn for.
    ///
    /// Asked of the layout itself, like ``Design`` asks its designs, so the
    /// declaration cannot drift from the thing that draws.
    public var intendedTypeface: Typeface {
        layout.intendedTypeface ?? .inter
    }

}

/// An arrangement of a letter on a page.
///
/// Public for the same reason ``Design`` is: a letter arrives beside a résumé,
/// and somebody who has written a design of their own for one will want the
/// other to match. Only the masthead is yours — ``Letters/body(_:on:)`` sets
/// the recipient, the argument and the sign-off, because the shape of a letter
/// is older and less negotiable than a résumé's and moving those about does
/// not make it look modern.
public protocol LetterLayout: Sendable {

    /// Draws the masthead, and leaves the cursor where the body starts.
    func masthead(_ letter: CoverLetter, on sheet: Sheet)

    /// What this design is called, in a report or a listing.
    var displayName: String { get }

    /// The typeface the design was drawn for, where it declares one.
    ///
    /// Same contract as ``Design/intendedTypeface``: honoured wherever the
    /// theme states no preference, and any face the theme names wins.
    var intendedTypeface: Typeface? { get }
}

extension LetterLayout {

    /// The type's own name, for a layout that does not choose one.
    public var displayName: String { String(describing: type(of: self)) }

    /// No opinion, which is what a layout that never says gets.
    public var intendedTypeface: Typeface? { nil }
}

// MARK: - Rendering

extension CoverLetter {

    /// Lays the letter out.
    public func document(design: LetterDesign = .memo, theme: Theme = .plain) throws -> Document {
        try document(design: design.blueprint, theme: theme)
    }

    /// The same, with a masthead of your own.
    public func document(design: any LetterLayout, theme: Theme = .plain) throws -> Document {
        let family = try Typography.family(theme.typeface(declared: design.intendedTypeface))
        let sheet = Sheet(theme: theme, family: family, labels: .english)
        sheet.pdf.language = "en"

        design.masthead(self, on: sheet)
        Letters.body(self, on: sheet)
        return sheet.pdf
    }

    /// The finished bytes, from a masthead of your own.
    public func render(design: any LetterLayout, theme: Theme = .plain) throws -> Data {
        try document(design: design, theme: theme).render(metadata: metadata)
    }

    /// The finished PDF bytes.
    public func render(design: LetterDesign = .memo, theme: Theme = .plain) throws -> Data {
        try render(design: design.blueprint, theme: theme)
    }

    /// Renders and writes to a file, returning the byte count.
    @discardableResult
    public func save(
        to url: URL, design: LetterDesign = .memo, theme: Theme = .plain
    ) throws -> Int {
        try save(to: url, design: design.blueprint, theme: theme)
    }

    /// Document properties — the title a file list shows, and the subject,
    /// which is the letter's own where it has one.
    var metadata: [String: String] {
        [
            "Title": profile.name.isEmpty ? "Cover letter" : "\(profile.name) — cover letter",
            "Author": profile.name,
            "Subject": subject.isEmpty ? "Letter of application" : subject,
            "Creator": "ResumePDF",
        ]
    }
}

// MARK: - Shared body

/// The parts of a letter every design sets the same way.
public enum Letters {

    /// Recipient, greeting, argument, sign-off.
    public static func body(_ letter: CoverLetter, on sheet: Sheet) {
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
}
