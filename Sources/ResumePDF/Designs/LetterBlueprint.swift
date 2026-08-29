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

    /// The face the letter is drawn for — `serif` for the one that sits
    /// beside a serif résumé. A theme that names a face still wins.
    public var typeface: Blueprint.Face

    public init(
        name: String,
        masthead: Masthead = Masthead(),
        pairsWith: DesignKind = .ledger,
        typeface: Blueprint.Face = .sans
    ) {
        self.name = name
        self.masthead = masthead
        self.pairsWith = pairsWith
        self.typeface = typeface
    }

    // MARK: What it declares

    /// Its own name, capitalised.
    public var displayName: String { name.capitalised }

    public var intendedTypeface: Typeface? { typeface.typeface }

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

            let y = sheet.nameplate(
                Sheet.Nameplate(
                    name: profile.name, size: nameSize,
                    face: nameBold ? sheet.semibold : sheet.regular, colour: sheet.ink,
                    tracking: tracking, uppercase: uppercase,
                    // A letter's head has no second line to wrap to.
                    fitted: true, rule: nil,
                    headline: profile.headline, headlineSize: headlineSize,
                    headlineFace: headlineItalic ? sheet.italic : sheet.regular,
                    headlineColour: sheet.headlineTint(headlineColour, ink: sheet.ink, muted: sheet.muted),
                    headlineFitted: true,
                    align: align, metrics: .letter
                ),
                x: sheet.left, top: top, width: textWidth,
                // A centred head aligns on the page, and fits beside its portrait.
                boxWidth: align == .centre ? sheet.width : textWidth
            )
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
                sheet.contactFlow(profile.contactEntries(), size: contactSize,
                                  align: align.textAlign)

            case .ranged:
                // Ranged right against the name — the two together make the
                // head, and neither is a list.
                var y = top - contactSize * 1.6
                for entry in profile.contactEntries() {
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
            // Set as text rather than linked, unlike the flowed and ranged
            // arrangements — kept as it has always been drawn, so the
            // rendered examples hold.
            let entries = profile.markedContacts().map { (icon: $0.icon, text: $0.text, url: "") }
            guard !entries.isEmpty else { return }

            let columns = entries.count > 2 ? 2 : 1
            let rows = (entries.count + columns - 1) / columns
            let height = Double(rows) * Sheet.contactRow + Sheet.panelPadding * 2 - 4

            let fill = sheet.theme.accentIsDark && !sheet.theme.isMonochrome
                ? sheet.accent
                : sheet.wash

            // Under the headline with room to breathe: the panel is the
            // masthead's second half, not a caption on its first.
            sheet.contactPanel(entries, x: sheet.left, top: sheet.cursor - 17, width: sheet.width,
                               height: height, columns: columns, radius: 9, fill: fill,
                               size: contactSize + 0.2)
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

extension LetterBlueprint: BundledBlueprint {

    /// The four letter designs, read from the JSON files in the package's
    /// resources — a letter design is a JSON file, and the Swift only names
    /// it. Each is a blueprint to start from.
    public static let starting: [LetterBlueprint] = readBundled()

    public static let subdirectory = "Letters"

    public static let bundledNames = ["memo", "letterhead", "panel", "monogram"]

    /// A small ruled head and one column. Pairs with `ledger`.
    public static let memo = bundled("memo")

    /// Serif, name at the left and contact ranged right. Pairs with
    /// `broadsheet`, and the right choice for law and academia.
    public static let letterhead = bundled("letterhead")

    /// Contact details in a filled panel under the name, each with its
    /// mark, and room for a portrait. Pairs with `banner`.
    public static let panel = bundled("panel")

    /// Centred name, with the body between two rules. Pairs with `bulletin`.
    public static let monogram = bundled("monogram")
}

// MARK: - Reading a partial one

extension LetterBlueprint {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.value(.name, or: "custom"),
            masthead: try container.value(.masthead, or: Masthead()),
            pairsWith: try container.value(.pairsWith, or: .ledger),
            typeface: try container.value(.typeface, or: .sans)
        )
    }

    enum CodingKeys: String, CodingKey { case name, masthead, pairsWith, typeface }
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
