//
//  TimeShares.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Weights to proportions, once, so the ring and the flat text agree.
//

import Foundation

/// The arithmetic behind a time ring.
enum TimeShares {

    /// Each slice with the fraction of the whole it takes, dropping any that
    /// weigh nothing or say nothing. Empty when nothing is left.
    static func fractions(of slices: [TimeSlice]) -> [(label: String, fraction: Double)] {
        let kept = slices.filter { $0.share > 0 && !$0.label.isBlank }
        let total = kept.reduce(0) { $0 + $1.share }
        guard total > 0 else { return [] }
        return kept.map { ($0.label, $0.share / total) }
    }

    /// The same as whole percentages that add up to a hundred: rounded, then
    /// the rounding error given to the largest slice, where a point is
    /// least visible and the total still reads as a whole.
    static func percentages(of slices: [TimeSlice]) -> [(label: String, percent: Int)] {
        let parts = fractions(of: slices)
        guard !parts.isEmpty else { return [] }
        var rounded = parts.map { Int(($0.fraction * 100).rounded()) }
        let drift = 100 - rounded.reduce(0, +)
        if drift != 0, let largest = parts.indices.max(by: { parts[$0].fraction < parts[$1].fraction }) {
            rounded[largest] += drift
        }
        return zip(parts, rounded).map { ($0.label, $1) }
    }

    /// The letter a slice is keyed by in the legend — A, B, C…
    static func letter(_ index: Int) -> String {
        let scalar = UnicodeScalar(65 + index % 26)!
        return String(Character(scalar))
    }
}
