//
//  Strength.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A quality named and then evidenced — "Collaboration", and the sentence
/// that shows it. Set as a lead-in and a line, never as a bare adjective,
/// because a list of adjectives is the part of a résumé a reader skips.
public struct Strength: Sendable, Equatable, Codable {

    /// The quality, in a word or two.
    public let title: String

    /// The evidence for it.
    public let summary: String

    public init(title: String, summary: String = "") {
        self.title = title
        self.summary = summary
    }
}
