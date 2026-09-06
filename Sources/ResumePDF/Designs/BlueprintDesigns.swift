//
//  BlueprintDesigns.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The designs that ship with the package, read from the JSON files in its
//  resources. A design is a JSON file; the Swift here only names it.

import Foundation
import TextPDF

// MARK: - Starting points

extension Blueprint: BundledBlueprint {

    /// The designs that ship with the package, read from the JSON files in
    /// its resources — because a design is a JSON file, and the Swift here
    /// only names it. Every one is a starting point: nobody writes a design
    /// from an empty file, and "ledger with a marker heading and chips" is
    /// how one actually gets made.
    public static let starting: [Blueprint] = readBundled()

    public static let subdirectory = "Designs"

    public static let bundledNames = [
        "ledger", "broadsheet", "timeline", "sidebar", "margin", "nocturne", "eclipse",
        "bulletin", "marker", "slate", "card", "terminal", "banner", "gazette",
        "plain", "register", "plaqued", "carded",
        "split", "wing", "foyer", "pillar", "flank", "marquee",
    ]

    /// One column, a rule under each heading, a code beside the name where
    /// there is one. Restraint is the design.
    public static let ledger = bundled("ledger")

    /// Serif, centred masthead: the name in light tracked capitals, the
    /// headline in the italic, a heavy rule and a hairline under the head.
    /// Academic and formal.
    public static let broadsheet = bundled("broadsheet")

    /// Dates in a rail down the left, with a tick out to each entry. The head
    /// and the headings sit at the margin; only the entries are past the
    /// rail, so the employment history is the shape of the page.
    public static let timeline = bundled("timeline")

    /// A tinted rail carrying contact, skills and languages, with the
    /// experience beside it. The best-looking of the set and the one a
    /// tracking system reads wrong — `check` says so.
    public static let sidebar = bundled("sidebar")

    /// Section names hung in the left margin, a hairline above every
    /// section, and the contact details as the first ruled row. Book
    /// typography, and the calmest page here.
    public static let margin = bundled("margin")

    /// A light band at the top and the rest of the page reversed out.
    /// Striking on a screen, expensive on somebody's office printer.
    public static let nocturne = bundled("nocturne")

    /// Nocturne with the light band taken away: the whole page dark, the
    /// masthead a step darker still. The darkest page here.
    public static let eclipse = bundled("eclipse")

    /// Headings as rounded tabs, each with a mark, and room for a portrait.
    /// Navigable at a glance, which suits a long CV.
    public static let bulletin = bundled("bulletin")

    /// Headings struck through with a highlighter, a name ruled like a
    /// signature. The least formal of them.
    public static let marker = bundled("marker")

    /// Two panels across the head — summary on one, contact on the other —
    /// and a coloured tab beside every section.
    public static let slate = bundled("slate")

    /// Every entry on a panel of its own — a section that is a list of
    /// entries gets one each, the rest get one around the block. Suits
    /// several short roles; unkind to one long one.
    public static let card = bundled("card")

    /// A prompt before every heading, monospaced labels and dates,
    /// proportional prose, and a code beside the name where there is one.
    /// Technical without being a costume.
    public static let terminal = bundled("terminal")

    /// A near-black band across the head with the name reversed out of it,
    /// the role in the accent and the portrait inside the band; a light page
    /// under it. The modern product-company résumé.
    public static let banner = bundled("banner")

    /// The serif two-column: centred masthead, the argument in a wide
    /// column and the credentials in a narrow one behind a hairline. The
    /// academic and executive look, and the other one a parser reads wrong.
    public static let gazette = bundled("gazette")

    /// Centred name, ruled headings, no ornament, and a scale that gets a
    /// first job onto one page. The shape every careers service hands out,
    /// set properly: the one to start from when the posting says one page.
    public static let plain = bundled("plain")

    /// Alternating tinted bands, labels hung in the margin.
    public static let register = bundled("register")

    /// A coloured panel across the top, dipped, with a portrait.
    public static let plaqued = bundled("plaqued")

    /// Every section on its own rounded panel.
    public static let carded = bundled("carded")

    /// The argument in a wide left column and the credentials in a narrow
    /// right one, a portrait top right, a hairline under every heading. The
    /// commonest two-column résumé on the web, set properly; reads wrong in
    /// a parser like every two-column page.
    public static let split = bundled("split")

    /// A narrow left column of skills and projects as chips, the name across
    /// the top, no portrait. The developer's two-column.
    public static let wing = bundled("wing")

    /// The portrait and the contact details in a light left rail, the name
    /// over the main column, a mark beside every heading.
    public static let foyer = bundled("foyer")

    /// A near-black rail down the right carrying the portrait, the contact
    /// details and the credentials; the name over the main column, so
    /// nothing large is reversed out of the dark.
    public static let pillar = bundled("pillar")

    /// Sidebar with the rail near-black and the name reversed out of it.
    public static let flank = bundled("flank")

    /// Banner's dark band, with the portrait in it, over two columns.
    public static let marquee = bundled("marquee")
}
