//
//  BlueprintDecoding.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Reading a blueprint that names only what it wants changed, and naming the
//  alternatives when a value is not one of them.

import Foundation
import TextPDF

// MARK: - Reading a partial one

//  A design is written by hand — that is the entire point of the format — so
//  the same rule applies here as to a résumé: name what you want changed, and
//  leave the rest out. Swift's synthesised decoder would demand all thirty-odd
//  keys to say "ledger, but with a marker heading".

extension Blueprint {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.value(.name, or: "custom"),
            masthead: try container.value(.masthead, or: Masthead()),
            column: try container.value(.column, or: Column()),
            heading: try container.value(.heading, or: Heading()),
            entries: try container.value(.entries, or: Entries()),
            ornament: try container.value(.ornament, or: .none),
            sectionGap: try container.value(.sectionGap, or: 17),
            footer: try container.value(.footer, or: true),
            skip: try container.value(.skip, or: []),
            palette: try container.maybe(.palette),
            typeface: try container.value(.typeface, or: .sans),
            sections: try container.value(.sections, or: [:]),
            side: try container.maybe(.side)
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, masthead, column, heading, entries
        case ornament, sectionGap, footer, skip, palette, typeface, sections, side
    }
}

extension Blueprint.Masthead {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Masthead()
        self.init(
            align: try container.value(.align, or: defaults.align),
            nameSize: try container.value(.nameSize, or: defaults.nameSize),
            uppercase: try container.value(.uppercase, or: defaults.uppercase),
            tracking: try container.value(.tracking, or: defaults.tracking),
            headlineSize: try container.value(.headlineSize, or: defaults.headlineSize),
            headlineColour: try container.value(.headlineColour, or: defaults.headlineColour),
            contactSize: try container.value(.contactSize, or: defaults.contactSize),
            panel: try container.maybe(.panel),
            photo: try container.maybe(.photo),
            qr: try container.value(.qr, or: defaults.qr),
            // A rule is on by default, so leaving the key out keeps it and
            // "rule": null is how you say you do not want one.
            rule: container.contains(.rule) ? try container.maybe(.rule) : defaults.rule,
            monospaced: try container.value(.monospaced, or: defaults.monospaced),
            gapAfter: try container.value(.gapAfter, or: defaults.gapAfter),
            nameWeight: try container.value(.nameWeight, or: defaults.nameWeight),
            nameColour: try container.value(.nameColour, or: defaults.nameColour),
            headlineItalic: try container.value(.headlineItalic, or: defaults.headlineItalic),
            separator: try container.value(.separator, or: defaults.separator),
            contacts: try container.value(.contacts, or: defaults.contacts),
            twin: try container.value(.twin, or: defaults.twin),
            body: try container.maybe(.body),
            band: try container.maybe(.band)
        )
    }

    /// Written out with `rule` always present, null included.
    ///
    /// The synthesised encoder omits a nil optional, and this decoder reads an
    /// absent `rule` as "as it comes" — so a design that deliberately has no
    /// rule came back with one. Absent and refused have to stay different in
    /// both directions or the format does not round-trip.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(align, forKey: .align)
        try container.encode(nameSize, forKey: .nameSize)
        try container.encode(uppercase, forKey: .uppercase)
        try container.encode(tracking, forKey: .tracking)
        try container.encode(headlineSize, forKey: .headlineSize)
        try container.encode(headlineColour, forKey: .headlineColour)
        try container.encode(contactSize, forKey: .contactSize)
        try container.encodeIfPresent(panel, forKey: .panel)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encode(qr, forKey: .qr)
        try container.encode(rule, forKey: .rule)
        try container.encode(monospaced, forKey: .monospaced)
        try container.encode(gapAfter, forKey: .gapAfter)
        try container.encode(nameWeight, forKey: .nameWeight)
        try container.encode(nameColour, forKey: .nameColour)
        try container.encode(headlineItalic, forKey: .headlineItalic)
        try container.encode(separator, forKey: .separator)
        try container.encode(contacts, forKey: .contacts)
        try container.encode(twin, forKey: .twin)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(band, forKey: .band)
    }

    enum CodingKeys: String, CodingKey {
        case align, nameSize, uppercase, tracking, headlineSize
        case headlineColour, contactSize, panel, photo, qr, rule, monospaced, gapAfter
        case nameWeight, nameColour, headlineItalic, separator, contacts, twin, body, band
    }
}

extension Blueprint.Panel {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Panel()
        self.init(
            fill: try container.value(.fill, or: defaults.fill),
            height: try container.value(.height, or: defaults.height),
            dip: try container.value(.dip, or: defaults.dip)
        )
    }

    enum CodingKeys: String, CodingKey { case fill, height, dip }
}

extension Blueprint.Photo {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Photo()
        self.init(
            diameter: try container.value(.diameter, or: defaults.diameter),
            align: try container.value(.align, or: defaults.align)
        )
    }

    enum CodingKeys: String, CodingKey { case diameter, align }
}

extension Blueprint.Rule {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Rule()
        self.init(
            colour: try container.value(.colour, or: defaults.colour),
            thickness: try container.value(.thickness, or: defaults.thickness),
            double: try container.value(.double, or: defaults.double),
            width: try container.value(.width, or: defaults.width),
            underName: try container.value(.underName, or: defaults.underName)
        )
    }

    enum CodingKeys: String, CodingKey { case colour, thickness, double, width, underName }
}

extension Blueprint.Column {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Column()
        self.init(
            labelWidth: try container.value(.labelWidth, or: defaults.labelWidth),
            gutter: try container.value(.gutter, or: defaults.gutter),
            labelAlign: try container.value(.labelAlign, or: defaults.labelAlign),
            headAtMargin: try container.value(.headAtMargin, or: defaults.headAtMargin),
            ruled: try container.value(.ruled, or: defaults.ruled)
        )
    }

    enum CodingKeys: String, CodingKey { case labelWidth, gutter, labelAlign, headAtMargin, ruled }
}

extension Blueprint.Side {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Side()
        self.init(
            width: try container.value(.width, or: defaults.width),
            edge: try container.value(.edge, or: defaults.edge),
            sections: try container.value(.sections, or: defaults.sections),
            // A fill is on by default, so leaving the key out keeps it and
            // "fill": null is how you say you do not want one.
            fill: container.contains(.fill) ? try container.maybe(.fill) : defaults.fill,
            divider: try container.value(.divider, or: defaults.divider),
            inset: try container.value(.inset, or: defaults.inset),
            gutter: try container.value(.gutter, or: defaults.gutter),
            head: try container.value(.head, or: defaults.head),
            heading: try container.value(.heading, or: defaults.heading),
            entries: try container.value(.entries, or: defaults.entries)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(edge, forKey: .edge)
        try container.encode(sections, forKey: .sections)
        try container.encode(fill, forKey: .fill)
        try container.encode(divider, forKey: .divider)
        try container.encode(inset, forKey: .inset)
        try container.encode(gutter, forKey: .gutter)
        try container.encode(head, forKey: .head)
        try container.encode(heading, forKey: .heading)
        try container.encode(entries, forKey: .entries)
    }

    enum CodingKeys: String, CodingKey {
        case width, edge, sections, fill, divider, inset, gutter, head, heading, entries
    }
}


extension Blueprint.Heading {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Heading()
        self.init(
            style: try container.value(.style, or: defaults.style),
            size: try container.value(.size, or: defaults.size),
            colour: try container.value(.colour, or: defaults.colour),
            icon: try container.value(.icon, or: defaults.icon)
        )
    }

    enum CodingKeys: String, CodingKey { case style, size, colour, icon }
}

extension Blueprint.Entries {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Blueprint.Entries()
        self.init(
            dates: try container.value(.dates, or: defaults.dates),
            roleSize: try container.value(.roleSize, or: defaults.roleSize),
            bodySize: try container.value(.bodySize, or: defaults.bodySize),
            detailSize: try container.value(.detailSize, or: defaults.detailSize),
            dateSize: try container.value(.dateSize, or: defaults.dateSize),
            entryGap: try container.value(.entryGap, or: defaults.entryGap),
            accentRoles: try container.value(.accentRoles, or: defaults.accentRoles),
            skills: try container.value(.skills, or: defaults.skills)
        )
    }

    enum CodingKeys: String, CodingKey {
        case dates, roleSize, bodySize, detailSize, dateSize, entryGap, accentRoles, skills
    }
}

extension Blueprint.PaletteOverride {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            page: try container.maybe(.page),
            ink: try container.maybe(.ink),
            muted: try container.maybe(.muted),
            hairline: try container.maybe(.hairline),
            wash: try container.maybe(.wash),
            accent: try container.maybe(.accent)
        )
    }

    enum CodingKeys: String, CodingKey { case page, ink, muted, hairline, wash, accent }
}

// MARK: - Naming what there is

extension Blueprint.Heading.Style {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "heading style") }
}

extension Blueprint.Entries.Dates {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "date placement") }
}

extension Blueprint.Entries.Skills {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "skill style") }
}

extension Blueprint.Ornament {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "ornament") }
}

extension Blueprint.Alignment {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "alignment") }
}

extension Blueprint.Face {
    public init(from decoder: Decoder) throws { self = try decoder.choice(Self.self, called: "typeface") }
}
