//
//  Card.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The card that goes in the wallet.
//
//  A third document from the same ``Profile`` as the résumé and the letter,
//  for the same reason they share one: they are from the same person, and
//  nothing looks less considered than an identity set whose parts disagree
//  about a phone number.
//
//  It is a genuinely different document rather than a small résumé. It is
//  85mm across, so there is room for a name, a claim and three ways to reach
//  somebody — and a card that tries to say more than that says none of it.
//  What a résumé spends a page arguing, a card spends a square inch pointing
//  at: the code carries the whole contact record, so the printed side does
//  not have to.
//

import Foundation

/// A business card.
public struct Card: Sendable, Equatable, Codable {

    /// Whose card it is. The same profile the résumé uses.
    public let profile: Profile

    /// The organisation, which a résumé keeps in its experience rather than
    /// its profile — an employer is one fact among many there, and the only
    /// other fact here.
    public let organisation: String

    /// What is printed under the name.
    ///
    /// Empty takes the profile's headline. Given separately because a
    /// résumé's headline is a claim written to be read at leisure — "Senior
    /// Project Manager | Treasury & Expense Management" — and a card has
    /// 85mm. ``printedTitle`` is the one that renders.
    public let title: String

    /// A line for the back, where a design has one. Six words about what you
    /// do, not a sentence about what you value.
    public let tagline: String

    /// What the scannable code says.
    ///
    /// Empty encodes a vCard built from the profile, which is what a card's
    /// code is for: the phone that scans it saves the contact rather than
    /// opening a page and asking the holder to type it in. Give a URL here to
    /// point at a portfolio instead. See ``codePayload``.
    public let code: String

    public init(
        profile: Profile,
        organisation: String = "",
        title: String = "",
        tagline: String = "",
        code: String = ""
    ) {
        self.profile = profile
        self.organisation = organisation
        self.title = title
        self.tagline = tagline
        self.code = code
    }
}
