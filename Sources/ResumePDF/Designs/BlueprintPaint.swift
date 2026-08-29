//
//  BlueprintPaint.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The colours a blueprint names, the alignments, the face — and the
//  colours the named paints resolve to on a theme.

import Foundation
import TextPDF

// MARK: - Colours

extension Blueprint {

    /// A colour, named or given.
    ///
    /// The named ones follow the theme, so a blueprint that says `accent`
    /// works under every accent somebody sets rather than pinning one.
    public struct Paint: Codable, Sendable, Equatable, RawRepresentable,
                         ExpressibleByStringLiteral {

        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }

        public static let ink = Paint(rawValue: "ink")
        public static let muted = Paint(rawValue: "muted")
        public static let accent = Paint(rawValue: "accent")
        public static let hairline = Paint(rawValue: "hairline")
        public static let wash = Paint(rawValue: "wash")
        public static let page = Paint(rawValue: "page")

        /// The accent lightened to a wash, for a rail down the page.
        public static let rail = Paint(rawValue: "rail")

        /// The page reversed: near-black on a light theme, near-white on a
        /// dark one.
        public static let inverse = Paint(rawValue: "inverse")

        /// Near-black whatever the theme; `darkest` a step below it.
        public static let dark = Paint(rawValue: "dark")
        public static let darkest = Paint(rawValue: "darkest")

        public static let named: [Paint] = [.ink, .muted, .accent, .hairline, .wash, .page, .rail, .inverse, .dark, .darkest]

        func colour(on sheet: Sheet, fallback: Color? = nil) -> Color {
            switch rawValue {
            case "ink": return sheet.ink
            case "muted": return sheet.muted
            case "accent": return sheet.accent
            case "hairline": return sheet.hairline
            case "wash": return sheet.wash
            case "page": return sheet.page
            case "rail": return sheet.theme.railTint
            case "inverse": return sheet.theme.inverse
            case "dark": return sheet.theme.dark
            case "darkest": return sheet.theme.dark.darkened(by: 0.55)
            default:
                // A hex value, or a name nobody defined — in which case the
                // theme's own ink is a better answer than black.
                return rawValue.hasPrefix("#") ? .hex(rawValue) : (fallback ?? sheet.ink)
            }
        }

        /// Whether this is a name the renderer knows or a colour it can read.
        public var isValid: Bool {
            Paint.named.contains(self) || (rawValue.hasPrefix("#") && rawValue.count == 7)
        }
    }

    /// Theme colours a design overrides for its own identity.
    public struct PaletteOverride: Codable, Sendable, Equatable {

        public var page: Paint?
        public var ink: Paint?
        public var muted: Paint?
        public var hairline: Paint?
        public var wash: Paint?
        public var accent: Paint?

        public init(
            page: Paint? = nil, ink: Paint? = nil, muted: Paint? = nil,
            hairline: Paint? = nil, wash: Paint? = nil, accent: Paint? = nil
        ) {
            self.page = page
            self.ink = ink
            self.muted = muted
            self.hairline = hairline
            self.wash = wash
            self.accent = accent
        }

        func resolved(on sheet: Sheet) -> Sheet.Palette {
            Sheet.Palette(
                page: page?.colour(on: sheet) ?? sheet.page,
                ink: ink?.colour(on: sheet) ?? sheet.ink,
                muted: muted?.colour(on: sheet) ?? sheet.muted,
                hairline: hairline?.colour(on: sheet) ?? sheet.hairline,
                wash: wash?.colour(on: sheet) ?? sheet.wash,
                accent: accent?.colour(on: sheet) ?? sheet.accent
            )
        }
    }

    /// Where something sits in its column.
    public enum Alignment: String, Codable, Sendable, CaseIterable {
        case left, centre, right

        var textAlign: Align {
            switch self {
            case .left: return .left
            case .centre: return .center
            case .right: return .right
            }
        }
    }
}


// MARK: - The colours the paints name

extension Theme {

    /// The accent lightened to a wash — or the wash itself on a monochrome
    /// theme, where there is no accent to lighten.
    var railTint: Color {
        guard !isMonochrome else { return wash }
        return scheme == .dark
            ? accentColor.darkened(by: 0.72).lightened(by: 0.06)
            : accentColor.lightened(by: 0.93)
    }

    /// The page reversed.
    var inverse: Color {
        scheme == .dark ? page.lightened(by: 0.93) : page.darkened(by: 0.9)
    }

    /// Near-black whatever the theme: a dark theme's page as it is, a light
    /// theme's taken most of the way to black.
    var dark: Color {
        scheme == .dark ? page : page.darkened(by: 0.88)
    }
}

extension Sheet {

    /// A panel dark enough to reverse type out of: the accent taken down,
    /// or a plain dark grey where the theme has no accent.
    var accentPanel: Color {
        guard !theme.isMonochrome else { return .grey(46) }
        return theme.accentColor.darkened(by: theme.accentIsDark ? 0.15 : 0.62)
    }
}
