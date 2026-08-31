//
//  Color+Arithmetic.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Perceived brightness and mixing, over TextPDF's Color — the arithmetic
//  the themes lean on, pinned directly by tests.
//

import Foundation
import TextPDF

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
