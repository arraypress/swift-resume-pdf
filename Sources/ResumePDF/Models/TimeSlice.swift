//
//  TimeSlice.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One part of how a working week goes — "Writing code", and how much of
/// it. Drawn as a ring divided in proportion, with a lettered legend.
///
/// Shares are weights, not percentages: `3, 2, 1` and `50, 33, 17` draw the
/// same ring, so nobody has to make a list add up to a hundred by hand.
public struct TimeSlice: Sendable, Equatable, Codable {

    /// What the time went on.
    public let label: String

    /// How much of it, relative to the other slices. Zero or less is dropped.
    public let share: Double

    public init(_ label: String, _ share: Double) {
        self.label = label
        self.share = share
    }
}
