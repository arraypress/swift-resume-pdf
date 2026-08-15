//
//  Theme.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  How a design looks, separated from which design it is.
//
//  A theme changes the typeface, the accent and how tightly the page is set.
//  It does not change the arrangement — that is the design's job, and the
//  reason there is more than one.
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

    public init(
        typeface: Typeface = .inter,
        accent: String = "#111111",
        pageSize: PageSize = .a4,
        density: Density = .normal
    ) {
        self.typeface = typeface
        self.accent = accent
        self.pageSize = pageSize
        self.density = density
    }

    // MARK: Palette

    public var accentColor: Color { .hex(accent) }

    /// Body text. Not pure black — slightly lifted reads better in print and
    /// on screen, and is what well-set documents use.
    public var ink: Color { .grey(26) }

    /// Dates, locations, and anything the eye should pass over on the way to
    /// something else.
    public var muted: Color { .grey(120) }

    /// Rules and borders.
    public var hairline: Color { .grey(216) }

    /// Faint fill for a panel.
    public var wash: Color { .grey(247) }

    /// Whether the theme is effectively monochrome.
    ///
    /// Worth knowing: a design that reverses text out of the accent has to
    /// keep its hands off a near-black one, or the heading disappears.
    public var isMonochrome: Bool {
        let colour = accentColor
        return colour.red == colour.green && colour.green == colour.blue
    }

    /// Whether text reversed out of the accent will be legible.
    ///
    /// Perceived luminance rather than a plain average — the eye is far more
    /// sensitive to green than to blue, so a mid yellow and a mid blue with
    /// the same arithmetic mean are nothing alike behind white text.
    public var accentIsDark: Bool {
        let colour = accentColor
        let luminance = (0.299 * Double(colour.red) + 0.587 * Double(colour.green) + 0.114 * Double(colour.blue))
        return luminance < 140
    }

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
