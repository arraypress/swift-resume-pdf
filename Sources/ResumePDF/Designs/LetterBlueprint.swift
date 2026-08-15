//
//  LetterBlueprint.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A letter design described rather than written.
//
//  Smaller than ``Blueprint``, because a letter is smaller: ``LetterLayout``
//  asks for the masthead and nothing else, and ``Letters/body(_:on:)`` sets
//  the recipient, the argument and the sign-off the same way for every design.
//  That is not an omission. The shape of a letter is older and less negotiable
//  than a résumé's, and moving those parts about does not make it look modern —
//  it makes it look like it was written by somebody who has not read one.
//
//  So what a letter design gets to decide is the head: how the name is set,
//  where the contact details sit, and what closes it off. Which is exactly
//  what separates the four built-in ones.
//

import Foundation
import TextPDF

/// A letter design written as data.
///
/// ```swift
/// let mine = try LetterBlueprint(contentsOf: url)
/// try letter.save(to: out, design: mine)
/// ```
public struct LetterBlueprint: LetterLayout, Codable, Sendable, Equatable {

    /// What this design is called.
    public var name: String

    public var masthead: Masthead

    /// The résumé design this was drawn to sit beside.
    ///
    /// A suggestion rather than a constraint, and the reason it is here at all:
    /// the two documents arrive in the same email, and an application whose
    /// halves were plainly made by different tools is answering a question
    /// nobody asked.
    public var pairsWith: DesignKind

    public init(
        name: String,
        masthead: Masthead = Masthead(),
        pairsWith: DesignKind = .ledger
    ) {
        self.name = name
        self.masthead = masthead
        self.pairsWith = pairsWith
    }

    // MARK: Reading one

    public init(contentsOf url: URL) throws {
        self = try JSONDecoder().decode(LetterBlueprint.self, from: try Data(contentsOf: url))
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    public var displayName: String { name }

    // MARK: Drawing

    public func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        masthead.draw(letter, on: sheet)
    }
}

// MARK: - The head

extension LetterBlueprint {

    public struct Masthead: Codable, Sendable, Equatable {

        public var align: Blueprint.Alignment
        public var nameSize: Double
        public var uppercase: Bool
        public var tracking: Double

        /// Whether the name is set in the heavier weight. A letterhead often
        /// sets it in the regular, which reads as printed stationery rather
        /// than as a title.
        public var nameBold: Bool

        public var headlineSize: Double
        public var headlineColour: Blueprint.Paint
        public var headlineItalic: Bool

        /// How the contact details are arranged.
        public var contacts: Contacts
        public var contactSize: Double

        /// A round portrait, where the profile carries one.
        public var photo: Blueprint.Photo?

        /// What closes the head off.
        public var finish: Finish
        public var rule: Blueprint.Rule

        /// Space between the head and the date.
        public var gapAfter: Double

        public init(
            align: Blueprint.Alignment = .left,
            nameSize: Double = 22,
            uppercase: Bool = false,
            tracking: Double = -0.3,
            nameBold: Bool = true,
            headlineSize: Double = 10.2,
            headlineColour: Blueprint.Paint = .accent,
            headlineItalic: Bool = false,
            contacts: Contacts = .flow,
            contactSize: Double = 8.7,
            photo: Blueprint.Photo? = nil,
            finish: Finish = .rule,
            rule: Blueprint.Rule = Blueprint.Rule(),
            gapAfter: Double = 22
        ) {
            self.align = align
            self.nameSize = nameSize
            self.uppercase = uppercase
            self.tracking = tracking
            self.nameBold = nameBold
            self.headlineSize = headlineSize
            self.headlineColour = headlineColour
            self.headlineItalic = headlineItalic
            self.contacts = contacts
            self.contactSize = contactSize
            self.photo = photo
            self.finish = finish
            self.rule = rule
            self.gapAfter = gapAfter
        }

        /// How the contact details are arranged.
        public enum Contacts: String, Codable, Sendable, CaseIterable {

            /// Flowed on one line under the name, separated by dots.
            case flow

            /// Stacked and ranged right against the name, the way a printed
            /// letterhead sets it.
            case ranged

            /// In a filled panel, each with its mark.
            case panel

            /// Left off. A letter sent as an email attachment already has the
            /// address on it.
            case none
        }

        /// What closes the head off.
        public enum Finish: String, Codable, Sendable, CaseIterable {

            /// A rule across the measure.
            case rule

            /// A short rule with a mark at each end, inset well short of the
            /// margins so it reads as a flourish rather than a division.
            case capped

            case none
        }

        // MARK: Drawing

        func draw(_ letter: CoverLetter, on sheet: Sheet) {
            let pdf = sheet.pdf
            let profile = letter.profile
            let top = pdf.height() - sheet.theme.density.margin

            var textWidth = sheet.width
            if let photo, Sheet.photo(at: profile.photo) != nil {
                let diameter = photo.diameter
                let originX = photo.align == .left ? sheet.left : sheet.right - diameter
                sheet.portrait(profile.photo, x: originX, y: top - diameter + 6, diameter: diameter)
                textWidth = sheet.width - diameter - 20
            }

            // Ranged contact details sit beside the name, so the name cannot
            // have the measure to itself.
            if contacts == .ranged { textWidth = min(textWidth, sheet.width * 0.62) }

            let label = uppercase ? profile.name.uppercased() : profile.name
            pdf.textAt(pdf.fit(label, into: textWidth, size: nameSize,
                               face: nameBold ? sheet.semibold : sheet.regular),
                       x: sheet.left, y: top - nameSize * 0.88, size: nameSize,
                       color: sheet.ink, align: align.textAlign,
                       boxWidth: align == .centre ? sheet.width : textWidth,
                       face: nameBold ? sheet.semibold : sheet.regular,
                       tracking: tracking)

            var y = top - nameSize * 0.88 - nameSize * 0.74

            if !profile.headline.isEmpty {
                let tint = sheet.theme.isMonochrome && headlineColour == .accent
                    ? sheet.muted
                    : headlineColour.colour(on: sheet)
                pdf.textAt(pdf.fit(profile.headline, into: textWidth, size: headlineSize,
                                   face: headlineItalic ? sheet.italic : sheet.regular),
                           x: sheet.left, y: y, size: headlineSize, color: tint,
                           align: align.textAlign,
                           boxWidth: align == .centre ? sheet.width : textWidth,
                           face: headlineItalic ? sheet.italic : sheet.regular)
                y -= headlineSize * 1.55
            }

            pdf.move(to: y)
            drawContacts(profile, on: sheet, top: top)
            close(on: sheet)
            sheet.gap(gapAfter)
        }

        private func drawContacts(_ profile: Profile, on sheet: Sheet, top: Double) {
            let pdf = sheet.pdf

            switch contacts {
            case .none:
                break

            case .flow:
                sheet.contactFlow(Letters.contact(profile), size: contactSize,
                                  align: align.textAlign)

            case .ranged:
                // Ranged right against the name — the two together make the
                // head, and neither is a list.
                var y = top - contactSize * 1.6
                for entry in Letters.contact(profile) {
                    let measured = pdf.width(of: entry.text, size: contactSize, face: sheet.regular)
                    let originX = sheet.right - measured

                    if entry.url.isEmpty {
                        pdf.textAt(entry.text, x: originX, y: y, size: contactSize,
                                   color: sheet.muted, face: sheet.regular)
                    } else {
                        pdf.linked(entry.text, url: entry.url, x: originX, y: y,
                                   size: contactSize, color: sheet.muted, face: sheet.regular)
                    }
                    y -= contactSize * 1.5
                }
                pdf.move(to: min(pdf.cursor(), y - 6))

            case .panel:
                drawPanel(profile, on: sheet)
            }
        }

        /// The contact details in a filled panel, each with its mark.
        private func drawPanel(_ profile: Profile, on sheet: Sheet) {
            let pdf = sheet.pdf

            let entries: [(Icon, String)] = [
                (.email, profile.email),
                (.phone, profile.phone),
                (.location, profile.location),
            ].filter { !$0.1.trimmingCharacters(in: .whitespaces).isEmpty }
                + profile.links.map { (Icon.link, $0.label) }

            guard !entries.isEmpty else { return }

            let columns = entries.count > 2 ? 2 : 1
            let rows = (entries.count + columns - 1) / columns
            let rowStep = 19.0
            let padding = 15.0
            let height = Double(rows) * rowStep + padding * 2 - 4

            let fill = sheet.theme.accentIsDark && !sheet.theme.isMonochrome
                ? sheet.accent
                : sheet.wash
            let palette = Sheet.Palette.against(fill, accent: sheet.theme.accentColor)

            let panelTop = pdf.cursor() - 6
            pdf.roundedRect(x: sheet.left, y: panelTop - height, width: sheet.width,
                            height: height, radius: 9, color: fill)

            let columnWidth = (sheet.width - padding * 2) / Double(columns)
            for (index, entry) in entries.enumerated() {
                let originX = sheet.left + padding + Double(index % columns) * columnWidth
                let baseline = panelTop - padding - Double(index / columns) * rowStep

                sheet.icon(entry.0, x: originX, y: baseline - 11.5, size: 12, color: palette.accent)
                pdf.textAt(entry.1, x: originX + 18, y: baseline - 9.6, size: contactSize + 0.2,
                           color: palette.ink, face: sheet.regular)
            }

            pdf.move(to: panelTop - height)
        }

        private func close(on sheet: Sheet) {
            let pdf = sheet.pdf

            switch finish {
            case .none:
                break

            case .rule:
                sheet.rigidGap(5)
                sheet.rule(color: rule.colour.colour(on: sheet), thickness: rule.thickness)

            case .capped:
                sheet.gap(12)
                let inset = sheet.width * 0.28
                let y = pdf.cursor()
                let from = sheet.left + inset
                let to = sheet.right - inset

                pdf.line(from: from, y, to: to, y,
                         color: rule.colour.colour(on: sheet), thickness: rule.thickness)
                pdf.circle(x: from, y: y, radius: 2.6, color: sheet.accent)
                pdf.circle(x: to, y: y, radius: 2.6, color: sheet.accent)
                pdf.move(to: y - 4)
            }
        }
    }
}

// MARK: - Starting points

extension LetterBlueprint {

    /// The built-in letter designs, as blueprints to start from.
    public static let starting: [LetterBlueprint] = [.memo, .letterheaded, .panelled, .monogrammed]

    /// A small ruled head and one column.
    public static let memo = LetterBlueprint(name: "memo")

    /// Serif stationery: name at the left, contact ranged right against it.
    public static let letterheaded = LetterBlueprint(
        name: "letterheaded",
        masthead: Masthead(
            nameSize: 24, tracking: 0.2, nameBold: false,
            headlineSize: 11, headlineColour: .muted, headlineItalic: true,
            contacts: .ranged, contactSize: 8.8,
            rule: Blueprint.Rule(colour: .ink, thickness: 0.7), gapAfter: 24
        ),
        pairsWith: .broadsheet
    )

    /// Contact details in a filled panel under the name.
    public static let panelled = LetterBlueprint(
        name: "panelled",
        masthead: Masthead(
            nameSize: 25, tracking: -0.4, headlineSize: 11,
            contacts: .panel, photo: Blueprint.Photo(diameter: 74),
            finish: .none, gapAfter: 22
        ),
        pairsWith: .plaque
    )

    /// A centred name over a capped rule.
    public static let monogrammed = LetterBlueprint(
        name: "monogrammed",
        masthead: Masthead(
            align: .centre, nameSize: 25, headlineSize: 10.6,
            finish: .capped, rule: Blueprint.Rule(colour: .ink, thickness: 0.8), gapAfter: 20
        ),
        pairsWith: .bulletin
    )
}

// MARK: - Reading a partial one

extension LetterBlueprint {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.value(.name, or: "custom"),
            masthead: try container.value(.masthead, or: Masthead()),
            pairsWith: try container.value(.pairsWith, or: .ledger)
        )
    }

    enum CodingKeys: String, CodingKey { case name, masthead, pairsWith }
}

extension LetterBlueprint.Masthead {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = LetterBlueprint.Masthead()
        self.init(
            align: try container.value(.align, or: defaults.align),
            nameSize: try container.value(.nameSize, or: defaults.nameSize),
            uppercase: try container.value(.uppercase, or: defaults.uppercase),
            tracking: try container.value(.tracking, or: defaults.tracking),
            nameBold: try container.value(.nameBold, or: defaults.nameBold),
            headlineSize: try container.value(.headlineSize, or: defaults.headlineSize),
            headlineColour: try container.value(.headlineColour, or: defaults.headlineColour),
            headlineItalic: try container.value(.headlineItalic, or: defaults.headlineItalic),
            contacts: try container.value(.contacts, or: defaults.contacts),
            contactSize: try container.value(.contactSize, or: defaults.contactSize),
            photo: try container.maybe(.photo),
            finish: try container.value(.finish, or: defaults.finish),
            rule: try container.value(.rule, or: defaults.rule),
            gapAfter: try container.value(.gapAfter, or: defaults.gapAfter)
        )
    }

    enum CodingKeys: String, CodingKey {
        case align, nameSize, uppercase, tracking, nameBold
        case headlineSize, headlineColour, headlineItalic
        case contacts, contactSize, photo, finish, rule, gapAfter
    }
}

extension LetterBlueprint.Masthead.Contacts {
    public init(from decoder: Decoder) throws {
        self = try decoder.choice(Self.self, called: "contact arrangement")
    }
}

extension LetterBlueprint.Masthead.Finish {
    public init(from decoder: Decoder) throws {
        self = try decoder.choice(Self.self, called: "finish")
    }
}
