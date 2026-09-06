//
//  CardBlueprint.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A card design described rather than written.
//
//  Smaller again than ``LetterBlueprint``, because a card is smaller: two
//  sides, a fill each, and an ordered list of what sits on them. There is no
//  layout language here for the same reason there is none in ``Blueprint`` —
//  a general one lets somebody build a card that overlaps itself, and the
//  failure mode of a bad layout language is a document that renders looking
//  wrong rather than an error saying what is wrong.
//
//  So a side is a composition of known-good parts, and every ordering of them
//  produces a card that reads. What separates the built-in designs is which
//  parts, in what order, on which side, and what colour it sits on.
//

import Foundation
import TextPDF

/// A card design written as data.
///
/// ```swift
/// let mine = try CardBlueprint(contentsOf: url)
/// try card.save(to: out, design: mine)
/// ```
public struct CardBlueprint: Codable, Sendable, Equatable {

    /// What this design is called — and what its file is called.
    public var name: String

    /// The side that faces up.
    public var front: Side

    /// The other one. Nil is a single-sided card, which is what a printer
    /// charges less for and what a design with nothing to say on the back
    /// should be.
    public var back: Side?

    /// How big the card is. Most designs take the standard 85 × 55 mm; one
    /// that is drawn for a square card says so.
    public var size: CardSize

    /// The type scale, shared by both sides.
    public var type: TypeScale

    /// A round portrait, where a side lists ``Element/portrait`` and the
    /// profile carries one.
    public var photo: Blueprint.Photo?

    /// The résumé design this was drawn to sit beside, so an identity set
    /// made of all three does not look assembled.
    public var pairsWith: DesignKind

    /// The face the card is drawn for. A theme that names one still wins.
    public var typeface: Blueprint.Face

    public init(
        name: String,
        front: Side = Side(),
        back: Side? = nil,
        size: CardSize = .standard,
        type: TypeScale = TypeScale(),
        photo: Blueprint.Photo? = nil,
        pairsWith: DesignKind = .ledger,
        typeface: Blueprint.Face = .sans
    ) {
        self.name = name
        self.front = front
        self.back = back
        self.size = size
        self.type = type
        self.photo = photo
        self.pairsWith = pairsWith
        self.typeface = typeface
    }

    // MARK: What it declares

    /// Its own name, capitalised.
    public var displayName: String { name.capitalised }

    /// The family the design names for itself.
    public var intendedTypeface: Typeface? { typeface.typeface }

    /// Whether either side has somewhere to put a portrait.
    public var showsPhoto: Bool {
        photo != nil && sides.contains { $0.content.contains(.portrait) }
    }

    /// Whether either side has somewhere to put a code.
    public var showsCode: Bool { sides.contains { $0.content.contains(.code) } }

    /// The sides there are, front first.
    public var sides: [Side] { [front] + (back.map { [$0] } ?? []) }
}

// MARK: - A side

extension CardBlueprint {

    /// One face of the card: what is behind it, and what is on it.
    public struct Side: Codable, Sendable, Equatable {

        /// What is painted behind the whole side, edge to edge and into the
        /// bleed. `page` leaves it the paper.
        public var fill: Blueprint.Paint

        /// Where the content sits across the side.
        public var align: Blueprint.Alignment

        /// Where the content sits down the side.
        public var anchor: Anchor

        /// What is on it, in the order it is drawn down the side.
        ///
        /// An element with nothing to show — a code on a card with no
        /// payload, a portrait on a profile with no photograph — is skipped
        /// rather than left as a gap, so one design serves a profile that
        /// carries a face and one that does not.
        public var content: [Element]

        /// The margin kept from every trimmed edge, in points.
        ///
        /// A card's margin is the one measurement most home-made cards get
        /// wrong: type closer than about 4mm to a trimmed edge looks like a
        /// mistake even when the trim is perfect, because the eye reads the
        /// nearness rather than the distance.
        public var padding: Double

        public init(
            fill: Blueprint.Paint = .page,
            align: Blueprint.Alignment = .left,
            anchor: Anchor = .middle,
            content: [Element] = [.name, .title, .organisation, .rule, .contacts],
            padding: Double = 17
        ) {
            self.fill = fill
            self.align = align
            self.anchor = anchor
            self.content = content
            self.padding = padding
        }

        /// Where a side's content sits down it.
        public enum Anchor: String, Codable, Sendable, CaseIterable {
            case top, middle, bottom
        }
    }

    /// One thing that can sit on a side.
    public enum Element: String, Codable, Sendable, CaseIterable {

        /// The name, in the design's largest size.
        case name

        /// What is printed under it — ``Card/printedTitle``.
        case title

        /// The organisation.
        case organisation

        /// Email, phone, location and links, one per line.
        case contacts

        /// The scannable code — a vCard by default, which is what makes a
        /// card worth scanning rather than reading.
        case code

        /// The line the card carries about what its holder does.
        case tagline

        /// The round portrait.
        case portrait

        /// A short rule in the accent, to separate what is above from below.
        case rule

        /// Space, where a design wants air rather than another thing.
        case space
    }

    /// The type scale, which both sides share so the two halves of one card
    /// are set the same.
    ///
    /// Not called `Type`: that is Swift's word for a metatype, and an
    /// extension on one cannot be written.
    public struct TypeScale: Codable, Sendable, Equatable {

        public var nameSize: Double
        public var nameWeight: Blueprint.Masthead.Weight
        public var uppercase: Bool

        /// Letter spacing for the name. Positive opens small capitals out,
        /// which is most of what makes a card look printed rather than typed.
        public var tracking: Double

        public var titleSize: Double
        public var titleColour: Blueprint.Paint

        /// Contact lines, the organisation and the tagline.
        public var bodySize: Double

        /// The code's side, in points. Below about 40 a phone has to be held
        /// still; below 30 it fails on a printed card.
        public var codeSize: Double

        public init(
            nameSize: Double = 15,
            nameWeight: Blueprint.Masthead.Weight = .semibold,
            uppercase: Bool = false,
            tracking: Double = -0.2,
            titleSize: Double = 8.2,
            titleColour: Blueprint.Paint = .accent,
            bodySize: Double = 7.6,
            codeSize: Double = 52
        ) {
            self.nameSize = nameSize
            self.nameWeight = nameWeight
            self.uppercase = uppercase
            self.tracking = tracking
            self.titleSize = titleSize
            self.titleColour = titleColour
            self.bodySize = bodySize
            self.codeSize = codeSize
        }
    }
}

// MARK: - The designs that ship

extension CardBlueprint: BundledBlueprint {

    /// The card designs the package carries, read from their JSON files.
    public static let starting: [CardBlueprint] = readBundled()

    public static let subdirectory = "Cards"

    public static let bundledNames = ["plate", "reverse", "portrait", "minimal"]

    // No `static let plate` here, unlike ``Blueprint``: a card is rendered
    // through an overload that takes either a ``CardDesign`` or one of these,
    // and two things called `plate` in scope make `design: .plate` ambiguous
    // at every call site. ``CardDesign/blueprint`` is the way to the data.
}
