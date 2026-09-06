//
//  CardGeometry.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  How big a card is, and what a printer needs around it.
//
//  Pure arithmetic, so the one thing that is expensive to get wrong — a file
//  whose trim is a millimetre out, discovered after five hundred are printed —
//  is assertable without rendering anything.
//

import Foundation

/// Points per millimetre. Card sizes are quoted in millimetres everywhere
/// except the United States, and in points nowhere.
let pointsPerMillimetre = 72.0 / 25.4

/// How big the card is, before any bleed.
public struct CardSize: Sendable, Equatable, Codable {

    /// The trimmed width in points — what the card measures in the hand.
    public var width: Double

    /// The trimmed height in points.
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    /// A size in millimetres, which is how a printer quotes one.
    public static func millimetres(_ width: Double, _ height: Double) -> CardSize {
        CardSize(width: width * pointsPerMillimetre, height: height * pointsPerMillimetre)
    }

    /// 85 × 55 mm. The European standard, and what most of the world's
    /// printers quote by default.
    public static let standard = CardSize.millimetres(85, 55)

    /// 3.5 × 2 in — 88.9 × 50.8 mm. The North American standard, and a
    /// noticeably wider, shorter card.
    public static let us = CardSize(width: 3.5 * 72, height: 2 * 72)

    /// 55 × 55 mm.
    public static let square = CardSize.millimetres(55, 55)
}

/// The page a card is written on, and the marks around it.
///
/// A card sent to a printer is not the size of the card: it carries a bleed —
/// artwork run past the trim, so that the guillotine cutting a millimetre off
/// true leaves ink at the edge rather than a white line. The marks say where
/// the trim is.
enum CardGeometry {

    /// A bleed in millimetres, as printers ask for it. Three is the usual
    /// request; some ask for none, and a card read on a screen wants none.
    static func bleed(millimetres: Double) -> Double {
        max(0, millimetres) * pointsPerMillimetre
    }

    /// The page's size: the trim, plus the bleed on all four sides.
    static func page(for size: CardSize, bleed: Double) -> (width: Double, height: Double) {
        (size.width + bleed * 2, size.height + bleed * 2)
    }

    /// Where the card's own bottom-left corner sits on that page.
    static func origin(bleed: Double) -> (x: Double, y: Double) { (bleed, bleed) }

    /// The crop marks: eight lines, two at each corner, drawn in the bleed
    /// and stopping short of the trim so no mark is left on the finished card.
    ///
    /// Empty when there is no bleed to draw them in — a mark inside the trim
    /// is a mark on somebody's card.
    static func cropMarks(for size: CardSize, bleed: Double) -> [(x1: Double, y1: Double, x2: Double, y2: Double)] {
        // The gap keeps the mark off the artwork; the length is what is left
        // of the bleed. Below about 1.5mm of bleed there is no room for both,
        // and the marks are left off rather than drawn into the card.
        let gap = min(bleed * 0.35, 1.2 * pointsPerMillimetre)
        let length = bleed - gap
        guard length > 1 else { return [] }

        let left = bleed, right = bleed + size.width
        let bottom = bleed, top = bleed + size.height

        var marks: [(x1: Double, y1: Double, x2: Double, y2: Double)] = []
        for x in [left, right] {
            marks.append((x, bottom - gap, x, bottom - gap - length))
            marks.append((x, top + gap, x, top + gap + length))
        }
        for y in [bottom, top] {
            marks.append((left - gap, y, left - gap - length, y))
            marks.append((right + gap, y, right + gap + length, y))
        }
        return marks
    }
}
