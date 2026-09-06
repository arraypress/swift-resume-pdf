//
//  Card+Printed.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a card shows, as against what it holds — thin properties that
//  delegate, so ``Card`` stays a description of a card and the rules live
//  where they can be tested without one.
//

import Foundation

extension Card {

    /// What is printed under the name: the card's own title where it has one,
    /// and the profile's headline where it does not.
    public var printedTitle: String {
        title.isBlank ? profile.headline : title
    }

    /// What the code carries.
    ///
    /// A vCard built from the profile unless the card names something else —
    /// see ``Card/code``. Built here rather than stored, so a profile edited
    /// after the card was made cannot leave a stale contact record behind.
    public var codePayload: String {
        guard code.isBlank else { return code }
        return VCard.text(
            name: profile.name,
            title: printedTitle,
            organisation: organisation,
            phone: profile.phone,
            email: profile.email,
            location: profile.location,
            urls: profile.links.map(\.absolute)
        )
    }
}
