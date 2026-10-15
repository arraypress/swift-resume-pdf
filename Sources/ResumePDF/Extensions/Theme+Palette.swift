//
//  Theme+Palette.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a résumé, a letter and a card draw from a theme: the page, the ink,
//  the muted text, the rules and washes, and an accent lifted where the page
//  would swallow it — and what each density does to the rhythm. The theme's
//  shape is DocumentTheme's; these judgements are this library's.
//

import DocumentTheme
import TextPDF

extension Theme {

    /// The page itself.
    public var page: Color {
        if let tint { return .hex(tint) }
        return scheme == .dark ? .grey(24) : .grey(255)
    }

    /// Body text.
    ///
    /// Never pure black on white or pure white on black. Full contrast at text
    /// sizes reads as a vibrating edge; a step in from either end is what
    /// well-set documents use and what is easier to read for longer.
    public var ink: Color {
        scheme == .dark ? .grey(236) : .grey(26)
    }

    /// Dates, locations, and anything the eye should pass over on the way to
    /// something else.
    public var muted: Color {
        scheme == .dark ? .grey(154) : .grey(120)
    }

    /// Rules and borders.
    public var hairline: Color {
        scheme == .dark ? .grey(74) : .grey(216)
    }

    /// Faint fill for a panel — a step away from the page, in whichever
    /// direction the page is not.
    public var wash: Color {
        scheme == .dark ? page.lightened(by: 0.07) : page.darkened(by: 0.035)
    }

    /// The accent, lifted where it would otherwise disappear.
    ///
    /// An accent chosen against white is routinely invisible on a dark page —
    /// a navy heading on near-black is a heading nobody can read. Rather than
    /// refuse the combination, the colour is moved far enough from the page to
    /// be legible and left alone when it already is.
    public var accentColor: Color {
        let chosen = Color.hex(accent)
        let separation = abs(chosen.luminance - page.luminance)
        guard separation < 0.28 else { return chosen }

        return page.luminance < 0.5
            ? chosen.lightened(by: 0.55)
            : chosen.darkened(by: 0.35)
    }

    /// Whether the theme is effectively monochrome.
    ///
    /// Worth knowing: a design that reverses text out of the accent has to
    /// keep its hands off a near-black one, or the heading disappears.
    public var isMonochrome: Bool {
        let colour = accentColor
        return colour.red == colour.green && colour.green == colour.blue
    }

    /// Whether text reversed out of the accent will be legible.
    public var accentIsDark: Bool { accentColor.luminance < 0.55 }

    /// Whether the page needs painting at all.
    public var paintsPage: Bool { scheme == .dark || tint != nil }
}

extension Density {

    /// Multiplier on the vertical rhythm.
    var leading: Double {
        switch self {
        case .relaxed: return 1.14
        case .normal: return 1.0
        case .compact: return 0.87
        }
    }

    /// Multiplier on the space between sections.
    ///
    /// Squeezed harder than the leading. The gap between blocks is where a
    /// dense page has slack — closing lines up hurts readability far sooner
    /// than closing the gaps between sections does.
    var sectionGap: Double {
        switch self {
        case .relaxed: return 1.2
        case .normal: return 1.0
        case .compact: return 0.72
        }
    }

    /// Page margin in points.
    var margin: Double {
        switch self {
        case .relaxed: return 62
        case .normal: return 54
        case .compact: return 44
        }
    }
}
