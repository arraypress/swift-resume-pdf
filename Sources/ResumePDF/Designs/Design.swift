//
//  Design.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Which arrangement the document takes.
//
//  Four, because they are genuinely different documents rather than one
//  document with the colours changed — and because the good-looking ones and
//  the machine-readable ones are not the same set. A design declares which it
//  is, and ``ATS`` reports it, so the choice is made with the trade-off in
//  view rather than discovered after an application disappears.
//

import Foundation
import TextPDF

/// One of the built-in arrangements.
public enum DesignKind: String, Sendable, CaseIterable, Codable {

    /// Single column, ruled sections, set in the sans. The one to send when
    /// nothing is known about what will read it.
    case ledger

    /// Single column set in the serif, with a centred masthead. Reads as
    /// considered rather than current — academia, law, medicine, and senior
    /// roles where looking current is not the point.
    case broadsheet

    /// A date rail down the left with entries hung off a hairline. The
    /// employment history is the shape of the page, which suits a clean
    /// progression and flatters nothing else.
    case timeline

    /// A tinted rail carrying contact, skills and languages, with the
    /// experience beside it. The best-looking of the set and the only one
    /// that will not survive an applicant tracking system.
    case sidebar

    /// Section names hung in the left margin, content in one column beside
    /// them. Book typography, and the calmest page here.
    case margin

    /// A light band at the top and the rest of the page reversed out.
    /// Striking on a screen, expensive on somebody's office printer.
    case nocturne

    /// A coloured panel across the top with the name reversed out of it.
    case plaque

    /// Section headings as tabs with a mark beside each. Navigable at a
    /// glance, which suits a long CV.
    case bulletin

    /// Alternate sections on a tinted band, labels in the margin.
    case register

    /// Headings struck through with a highlighter. The least formal of them.
    case marker

    public var displayName: String {
        switch self {
        case .ledger: return "Ledger"
        case .broadsheet: return "Broadsheet"
        case .timeline: return "Timeline"
        case .sidebar: return "Sidebar"
        case .margin: return "Margin"
        case .nocturne: return "Nocturne"
        case .plaque: return "Plaque"
        case .bulletin: return "Bulletin"
        case .register: return "Register"
        case .marker: return "Marker"
        }
    }

    /// What the design is for, in one line.
    public var summary: String {
        switch self {
        case .ledger: return "Single column, ruled sections. Safe anywhere."
        case .broadsheet: return "Serif, centred masthead. Academic and formal."
        case .timeline: return "A date rail down the left edge."
        case .sidebar: return "Two columns with a tinted rail. Not machine-readable."
        case .margin: return "Section names hung in the left margin."
        case .nocturne: return "Light masthead, reversed body."
        case .plaque: return "A coloured panel across the top."
        case .bulletin: return "Headings as tabs, each with a mark."
        case .register: return "Alternating tinted bands."
        case .marker: return "Highlighter headings. Informal."
        }
    }

    /// Whether the text of the page runs in one column.
    ///
    /// The single fact that decides whether a résumé survives being parsed.
    /// An applicant tracking system extracts the text and reads it in order;
    /// where two columns sit side by side, a line of the left one is followed
    /// by a line of the right, and an employment history comes out
    /// interleaved with a skills list. Nobody reads the result — it is
    /// scored, and it scores badly.
    public var isSingleColumn: Bool { self != .sidebar }

    /// The typeface the design was drawn for.
    ///
    /// A theme may override it. Broadsheet in a grotesque is a different
    /// document and not an improvement, but it is the caller's page.
    public var intendedTypeface: Typeface {
        self == .broadsheet ? .sourceSerif : .inter
    }

    /// Whether the design has somewhere to put a photograph.
    ///
    /// Reported rather than silently ignored: a résumé that carries a portrait
    /// and renders without one should say which design dropped it.
    public var showsPhoto: Bool {
        switch self {
        case .plaque, .bulletin, .nocturne, .sidebar: return true
        case .ledger, .broadsheet, .timeline, .margin, .register, .marker: return false
        }
    }

    var design: any Design {
        switch self {
        case .ledger: return Ledger()
        case .broadsheet: return Broadsheet()
        case .timeline: return Timeline()
        case .sidebar: return Sidebar()
        case .margin: return Margin()
        case .nocturne: return Nocturne()
        case .plaque: return Plaque()
        case .bulletin: return Bulletin()
        case .register: return Register()
        case .marker: return Marker()
        }
    }
}

/// An arrangement of a résumé on a page.
protocol Design: Sendable {

    /// Lays the document out on a prepared sheet.
    func render(_ resume: Resume, on sheet: Sheet)
}

// MARK: - Rendering

extension Resume {

    /// Lays the résumé out, ready to render or save.
    ///
    /// The typeface is loaded here rather than cached, because an embedded
    /// font accumulates the glyphs it is asked to draw in order to subset
    /// itself — so one shared between two documents carries the first one's
    /// characters into the second one's file.
    public func document(design: DesignKind = .ledger, theme: Theme = .plain) throws -> Document {
        let family = try Typography.family(theme.typeface)
        let sheet = Sheet(theme: theme, family: family, labels: labels)
        design.design.render(self, on: sheet)
        return sheet.pdf
    }

    /// The finished PDF bytes.
    public func render(design: DesignKind = .ledger, theme: Theme = .plain) throws -> Data {
        try document(design: design, theme: theme).render(metadata: metadata(design: design))
    }

    /// Renders and writes to a file, returning the byte count.
    @discardableResult
    public func save(
        to url: URL, design: DesignKind = .ledger, theme: Theme = .plain
    ) throws -> Int {
        let data = try render(design: design, theme: theme)
        try data.write(to: url, options: .atomic)
        return data.count
    }

    /// Document properties.
    ///
    /// The title is what a browser tab and a recruiter's file list will show,
    /// so it carries the name — an attachment called "Document1" is a small
    /// own goal, and the default title is whatever the writer put there.
    func metadata(design: DesignKind) -> [String: String] {
        var fields = [
            "Title": profile.name.isEmpty ? "Résumé" : "\(profile.name) — \(profile.headline.isEmpty ? "CV" : profile.headline)",
            "Author": profile.name,
            "Creator": "ResumePDF",
        ]
        // Keywords are read by some tracking systems, and skills are the terms
        // being matched against.
        let terms = skills.flatMap(\.names)
        if !terms.isEmpty { fields["Keywords"] = terms.joined(separator: ", ") }
        fields["Subject"] = design.displayName
        return fields
    }
}
