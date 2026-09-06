//
//  Cards.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Drawing a card, and getting the bytes out of it.
//
//  Two pages where a design has two sides, because that is what a printer
//  expects: page one is the front, page two the back, both the same size and
//  both carrying the same bleed. A card is small enough that the whole of it
//  is laid out here rather than in ``Blocks`` — there are no sections, no
//  entries and no page breaks, and the parts a side is made of are drawn once
//  each below.
//

import Foundation
import TextPDF

/// One of the built-in card designs.
public enum CardDesign: String, Sendable, CaseIterable, Codable {

    /// Everything on the front, the code on a dark back.
    case plate

    /// A reversed front carrying the name alone; the rest on a light back.
    case reverse

    /// A portrait beside the name.
    case portrait

    /// A centred name and nothing else, until the back.
    case minimal

    /// What it is called in a report or a listing.
    public var displayName: String { rawValue.capitalised }

    /// What it is for, in one line.
    public var summary: String {
        switch self {
        case .plate: return "Name, claim and contacts on the front; the code on a dark back."
        case .reverse: return "A reversed front carrying the name alone."
        case .portrait: return "A portrait beside the name."
        case .minimal: return "A centred name, and everything else on the back."
        }
    }

    /// The design as data. The case's name is the file's name.
    public var blueprint: CardBlueprint { .bundled(rawValue) }

    /// Whether the design has somewhere to put a portrait.
    public var showsPhoto: Bool { blueprint.showsPhoto }

    /// Whether it has somewhere to put a code.
    public var showsCode: Bool { blueprint.showsCode }

    /// The résumé design it was drawn to sit beside.
    public var pairsWith: DesignKind { blueprint.pairsWith }
}

// MARK: - Rendering

extension Card {

    /// Lays the card out, ready to render or save.
    ///
    /// - Parameter bleed: Artwork run past the trim, in millimetres, with
    ///   crop marks in it. Three is what most printers ask for; zero is right
    ///   for a card that will only ever be looked at on a screen.
    public func document(
        design: CardDesign = .plate, theme: Theme = .plain, bleed: Double = 0
    ) throws -> Document {
        try document(design: design.blueprint, theme: theme, bleed: bleed)
    }

    /// The same, under a design of your own.
    public func document(
        design: CardBlueprint, theme: Theme = .plain, bleed: Double = 0
    ) throws -> Document {
        let family = try Typography.family(theme.typeface(declared: design.intendedTypeface))
        let margin = CardGeometry.bleed(millimetres: bleed)
        let page = CardGeometry.page(for: design.size, bleed: margin)

        let sheet = Sheet(theme: theme, family: family, labels: .english,
                          page: page, margin: margin + design.front.padding)
        sheet.pdf.language = "en"

        Cards.draw(self, design: design, on: sheet, bleed: margin)
        return sheet.pdf
    }

    /// The finished bytes.
    public func render(
        design: CardDesign = .plate, theme: Theme = .plain,
        bleed: Double = 0, creationDate: Date = Date()
    ) throws -> Data {
        try render(design: design.blueprint, theme: theme, bleed: bleed, creationDate: creationDate)
    }

    /// The same, under a design of your own.
    public func render(
        design: CardBlueprint, theme: Theme = .plain,
        bleed: Double = 0, creationDate: Date = Date()
    ) throws -> Data {
        try document(design: design, theme: theme, bleed: bleed)
            .render(metadata: metadata(designName: design.displayName), creationDate: creationDate)
    }

    /// Renders and writes to a file, returning the byte count.
    @discardableResult
    public func save(
        to url: URL, design: CardDesign = .plate, theme: Theme = .plain, bleed: Double = 0
    ) throws -> Int {
        let data = try render(design: design, theme: theme, bleed: bleed)
        try data.write(to: url, options: .atomic)
        return data.count
    }

    /// Document properties. The title is what a file list shows, which for a
    /// card wants to say whose it is.
    func metadata(designName: String) -> [String: String] {
        var fields = [
            "Title": profile.name.isEmpty ? "Business card" : "\(profile.name) — business card",
            "Author": profile.name,
            "Creator": "ResumePDF",
            "Subject": designName,
        ]
        if !organisation.isBlank { fields["Keywords"] = organisation }
        return fields
    }
}

// MARK: - The drawing

/// How a card's sides are drawn.
enum Cards {

    /// Both sides, front then back, each its own page.
    static func draw(_ card: Card, design: CardBlueprint, on sheet: Sheet, bleed: Double) {
        side(design.front, of: card, design: design, on: sheet, bleed: bleed)

        if let back = design.back {
            _ = sheet.pdf.pageBreak()
            side(back, of: card, design: design, on: sheet, bleed: bleed)
        }

        // The marks go on every page, in the bleed, over the fill.
        guard bleed > 0 else { return }
        let marks = CardGeometry.cropMarks(for: design.size, bleed: bleed)
        guard !marks.isEmpty else { return }
        sheet.pdf.onEachPage { doc, _, _ in
            for mark in marks {
                doc.line(from: mark.x1, mark.y1, to: mark.x2, mark.y2,
                         color: .grey(40), thickness: 0.4)
            }
        }
    }

    /// One side: its fill, then its content, set as a block and placed.
    private static func side(
        _ side: CardBlueprint.Side, of card: Card, design: CardBlueprint,
        on sheet: Sheet, bleed: Double
    ) {
        let pdf = sheet.pdf

        // The fill runs to the paper's edge rather than the trim's, so a
        // guillotine a millimetre out still cuts through ink.
        let painted = paint(side.fill, on: sheet)
        if let painted {
            pdf.rect(x: 0, y: 0, width: pdf.width(), height: pdf.height(), color: painted.tint)
        }

        let palette = painted?.palette
        sheet.drawing(on: palette) {
            let box = measure(side, of: card, design: design, on: sheet, bleed: bleed)
            place(side, of: card, design: design, on: sheet, bleed: bleed, height: box)
        }
    }

    /// The colour behind a side, and what reads on it — nil where the side is
    /// the paper and the page's own palette already reads.
    private static func paint(
        _ fill: Blueprint.Paint, on sheet: Sheet
    ) -> (tint: Color, palette: Sheet.Palette)? {
        guard fill != .page else { return nil }
        let tint = fill.colour(on: sheet)
        return (tint, .against(tint, accent: sheet.theme.accentColor))
    }

    // MARK: Measuring, so a side can be centred

    /// How tall the side's content is, so `middle` and `bottom` have
    /// something to place against.
    ///
    /// Measured by drawing it on a scratch sheet, which is the only way to be
    /// right about wrapped text — and measured to the last thing's INK rather
    /// than to the cursor, which has already advanced past it by the gap
    /// before whatever would come next. Centring on the cursor puts that gap
    /// inside the block and sits the whole card high.
    private static func measure(
        _ side: CardBlueprint.Side, of card: Card, design: CardBlueprint,
        on sheet: Sheet, bleed: Double
    ) -> Double {
        let scratch = Sheet(theme: sheet.theme, family: sheet.family, labels: sheet.labels,
                            page: (sheet.pdf.width(), sheet.pdf.height()),
                            margin: sheet.pdf.margin)
        let top = scratch.pdf.height() - bleed - side.padding
        scratch.pdf.move(to: top)
        let ink = elements(side, of: card, design: design, on: scratch, bleed: bleed)
        return top - ink
    }

    /// Places the content down the side, then draws it.
    private static func place(
        _ side: CardBlueprint.Side, of card: Card, design: CardBlueprint,
        on sheet: Sheet, bleed: Double, height: Double
    ) {
        let pdf = sheet.pdf
        let top = pdf.height() - bleed - side.padding
        let bottom = bleed + side.padding
        let room = top - bottom

        switch side.anchor {
        case .top:
            pdf.move(to: top)
        case .middle:
            pdf.move(to: top - max(0, (room - height) / 2))
        case .bottom:
            pdf.move(to: bottom + height)
        }

        _ = elements(side, of: card, design: design, on: sheet, bleed: bleed)
    }

    /// Where the text sits on a side, and how wide it is.
    ///
    /// A portrait aligned left or right stands beside the words the way a
    /// masthead's does, and the text takes what is left; a centred one stacks
    /// above them and the text keeps the measure.
    private static func column(
        _ side: CardBlueprint.Side, of card: Card, design: CardBlueprint, on sheet: Sheet, bleed: Double
    ) -> (x: Double, width: Double, portrait: (x: Double, diameter: Double)?) {
        let inset = bleed + side.padding
        let full = sheet.pdf.width() - inset * 2

        guard let photo = design.photo,
              side.content.contains(.portrait),
              photo.align != .centre,
              Sheet.photo(at: card.profile.photo) != nil
        else { return (inset, full, nil) }

        let diameter = min(photo.diameter, full * 0.45)
        let gutter = 14.0
        switch photo.align {
        case .left:
            return (inset + diameter + gutter, full - diameter - gutter, (inset, diameter))
        default:
            return (inset, full - diameter - gutter, (inset + full - diameter, diameter))
        }
    }

    // MARK: The parts

    /// Draws each element the side lists, in order, and returns where the
    /// last of them left ink.
    ///
    /// An element with nothing to show is skipped without leaving its gap
    /// behind, so one design serves a profile that carries a photograph and
    /// one that does not.
    @discardableResult
    private static func elements(
        _ side: CardBlueprint.Side, of card: Card, design: CardBlueprint,
        on sheet: Sheet, bleed: Double
    ) -> Double {
        let pdf = sheet.pdf
        let layout = column(side, of: card, design: design, on: sheet, bleed: bleed)
        let x = layout.x
        let width = layout.width
        let type = design.type
        let align = side.align.textAlign
        let profile = card.profile

        // Where the block starts, and where the last thing drawn ended — as
        // against where the cursor has advanced to. See `measure`.
        let blockTop = pdf.cursor()
        var ink = blockTop

        for element in side.content {
            switch element {
            case .name:
                guard !profile.name.isBlank else { continue }
                let label = type.uppercase ? profile.name.uppercased() : profile.name
                let face = type.nameWeight == .regular ? sheet.regular : sheet.semibold
                // Fitted, because a card is 85mm and some names are not: it
                // steps down rather than running off the edge.
                let fitted = pdf.fit(label, into: width, size: type.nameSize, face: face)
                pdf.textAt(fitted, x: x, y: pdf.cursor() - type.nameSize,
                           size: type.nameSize, color: sheet.ink, align: align,
                           boxWidth: width, face: face, tracking: type.tracking)
                ink = pdf.cursor() - type.nameSize * 1.1
                pdf.move(to: pdf.cursor() - type.nameSize * 1.32)

            case .title:
                guard !card.printedTitle.isBlank else { continue }
                sheet.paragraph(card.printedTitle, x: x, width: width, size: type.titleSize,
                                face: sheet.medium,
                                color: sheet.headlineTint(type.titleColour, ink: sheet.ink, muted: sheet.muted),
                                align: align)
                ink = pdf.cursor()

            case .organisation:
                guard !card.organisation.isBlank else { continue }
                sheet.line(card.organisation, x: x, width: width, size: type.bodySize,
                           face: sheet.regular, color: sheet.muted, align: align)
                ink = pdf.cursor()

            case .tagline:
                guard !card.tagline.isBlank else { continue }
                sheet.paragraph(card.tagline, x: x, width: width, size: type.bodySize,
                                color: sheet.muted, align: align)
                ink = pdf.cursor()

            case .contacts:
                let entries = profile.contactEntries()
                guard !entries.isEmpty else { continue }
                for entry in entries {
                    let top = pdf.cursor()
                    pdf.cell(entry.text, x: x, boxWidth: width, size: type.bodySize,
                             color: sheet.ink, align: align, face: sheet.regular)
                    if !entry.url.isEmpty {
                        pdf.link(entry.url, x: x, y: top - type.bodySize * 1.25,
                                 width: width, height: type.bodySize * 1.4)
                    }
                    ink = top - type.bodySize * 1.15
                    pdf.move(to: top - type.bodySize * 1.55)
                }

            case .code:
                let payload = card.codePayload
                guard !payload.isBlank else { continue }
                let size = min(type.codeSize, width, pdf.cursor() - bleed - side.padding)
                guard size > 24 else { continue }
                let originX: Double
                switch side.align {
                case .left: originX = x
                case .centre: originX = x + (width - size) / 2
                case .right: originX = x + width - size
                }
                // The code is drawn in the ink of whatever it sits on: a
                // scanner wants contrast, and a dark side needs a light code.
                _ = pdf.qr(payload, x: originX, y: pdf.cursor() - size, size: size,
                           color: sheet.ink, quiet: 2)
                ink = pdf.cursor() - size
                pdf.move(to: pdf.cursor() - size - 6)

            case .portrait:
                // A portrait beside the words is drawn after the loop, so it
                // can be centred against the whole block. This is the stacked
                // one, which takes its turn.
                guard layout.portrait == nil else { continue }
                guard let photo = design.photo, Sheet.photo(at: profile.photo) != nil else { continue }
                let diameter = min(photo.diameter, width)
                let originX: Double
                switch side.align {
                case .left: originX = x
                case .centre: originX = x + (width - diameter) / 2
                case .right: originX = x + width - diameter
                }
                sheet.portrait(profile.photo, x: originX, y: pdf.cursor() - diameter, diameter: diameter)
                ink = pdf.cursor() - diameter
                pdf.move(to: pdf.cursor() - diameter - 8)

            case .rule:
                let span = min(width, 26.0)
                let originX: Double
                switch side.align {
                case .left: originX = x
                case .centre: originX = x + (width - span) / 2
                case .right: originX = x + width - span
                }
                pdf.move(to: pdf.cursor() - 5)
                pdf.rect(x: originX, y: pdf.cursor(), width: span, height: 1.6, color: sheet.accent)
                pdf.move(to: pdf.cursor() - 8)

            case .space:
                pdf.move(to: pdf.cursor() - type.bodySize)
            }
        }

        // The portrait that stands beside the words, last — centred on the
        // block it is beside, which is only known once the block is drawn.
        if let inline = layout.portrait {
            let middle = (blockTop + ink) / 2
            let bottom = middle - inline.diameter / 2
            sheet.portrait(profile.photo, x: inline.x, y: bottom, diameter: inline.diameter)
            ink = min(ink, bottom)
        }

        return ink
    }
}
