//
//  Achievement.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One thing worth a line of its own: a result, a first, a number that
/// moved — set apart from the job it happened in, with a mark beside it.
///
/// The section most résumé builders call "Key Achievements". It exists
/// because the best line in an employment history is routinely the fourth
/// bullet under the second job, where nobody skimming finds it.
public struct Achievement: Sendable, Equatable, Codable {

    /// "Cut p99 latency by 88%" — the claim, short enough to be a heading.
    public let title: String

    /// A sentence of how, or what it led to.
    public let summary: String

    /// The mark drawn beside it, by ``Icon`` name — `star`, `flag`, `bolt`,
    /// `check`, `diamond`, or any section's mark. Empty takes the next of a
    /// short cycle, so a list needs no icons chosen to look finished.
    public let icon: String

    public init(title: String, summary: String = "", icon: String = "") {
        self.title = title
        self.summary = summary
        self.icon = icon
    }
}
