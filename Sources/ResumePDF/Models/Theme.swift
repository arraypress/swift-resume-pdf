//
//  Theme.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  How a design looks, separated from which design it is.
//
//  A theme changes the typeface, the palette and how tightly the page is set.
//  It does not change the arrangement — that is the design's job, and the
//  reason there is more than one.
//
//  The separation earns its keep on the second look at a set of templates.
//  Most of what appears to be a dozen different résumé designs is four
//  arrangements in a dozen colourways: the same two-column body on white, on
//  pale pink, on warm grey and on near-black. Making that an axis of the theme
//  rather than a new template is the difference between ten designs and forty
//  that need fixing one at a time.
//

import Foundation
import TextPDF

/// The look applied to a design.
public struct Theme: Sendable, Equatable, Codable {

    public let typeface: Typeface

    /// Brand colour as hex.
    ///
    /// Near-black by default. A résumé is read by someone with forty others
    /// on the desk, and colour on the page buys attention only if it is used
    /// on almost nothing — so the designs spend it on rules and section
    /// headings rather than on body text.
    public let accent: String

    public let pageSize: PageSize

    /// How tightly the page is set.
    public let density: Density

    /// Whether body prose is set flush to both edges.
    ///
    /// Off by default. Justification suits a letter, where the reader is going
    /// along the lines in order, and it suits a wide measure. It does not suit
    /// a narrow one — the gaps grow until they line up into rivers running
    /// down the column — so it is applied only where there is room for it,
    /// whatever this says.
    public let justified: Bool

    /// Light or dark.
    public let scheme: Scheme

    /// The page colour, as hex, overriding the scheme's default.
    ///
    /// A pale wash rather than a colour: this sits behind every word on the
    /// page, and anything with saturation in it turns reading into work. It
    /// also costs a great deal of toner, which is worth remembering about a
    /// document whose whole purpose is to be printed by a stranger.
    public let tint: String?

    public init(
        typeface: Typeface = .inter,
        accent: String = "#111111",
        pageSize: PageSize = .a4,
        density: Density = .normal,
        scheme: Scheme = .light,
        tint: String? = nil,
        justified: Bool = false
    ) {
        self.typeface = typeface
        self.accent = accent
        self.pageSize = pageSize
        self.density = density
        self.scheme = scheme
        self.tint = tint
        self.justified = justified
    }

    // MARK: Palette

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

    // MARK: Presets

    /// Restrained and monochrome. The safest thing to send anybody.
    public static let plain = Theme()

    /// A quiet ink blue.
    public static let navy = Theme(accent: "#1F3A5F")

    /// Set in the serif, for academia and law.
    public static let classic = Theme(typeface: .sourceSerif, accent: "#1A1A1A")

    /// US Letter, because a résumé printed on A4 in Chicago comes out with a
    /// margin the printer had to invent.
    public static let american = Theme(pageSize: .letter)

    /// Near-black, with a warm accent that survives it.
    public static let midnight = Theme(accent: "#E8A33D", scheme: .dark)

    /// A warm paper tint. Reads as considered; costs a lot of toner.
    public static let paper = Theme(accent: "#7A4A2B", tint: "#F6F1E8")
}

// MARK: - Scheme

/// Light or dark.
public enum Scheme: String, Sendable, CaseIterable, Codable {
    case light
    case dark
}

// MARK: - Density

/// How tightly the page is set.
///
/// The knob that gets used, because a résumé that runs four lines onto a
/// second page is the single most common formatting complaint — and the usual
/// fix, dropping the font to 8pt, makes the whole document look desperate.
/// Tightening leading and margins first buys most of the same room and costs
/// far less legibility.
public enum Density: String, Sendable, CaseIterable, Codable {

    /// For a CV with room to breathe.
    case relaxed

    case normal

    /// Squeezes perhaps six extra lines onto a page.
    case compact

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

// MARK: - Colour arithmetic

extension Color {

    /// Perceived brightness, 0 to 1.
    ///
    /// Weighted rather than averaged: the eye is far more sensitive to green
    /// than to blue, so a mid yellow and a mid blue with the same arithmetic
    /// mean are nothing alike behind white text.
    var luminance: Double {
        (0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)) / 255
    }

    /// Mixed towards white.
    func lightened(by amount: Double) -> Color {
        func lift(_ channel: Int) -> Int {
            Int((Double(channel) + (255 - Double(channel)) * amount).rounded())
        }
        return Color(red: lift(red), green: lift(green), blue: lift(blue))
    }

    /// Mixed towards black.
    func darkened(by amount: Double) -> Color {
        func drop(_ channel: Int) -> Int { Int((Double(channel) * (1 - amount)).rounded()) }
        return Color(red: drop(red), green: drop(green), blue: drop(blue))
    }
}
