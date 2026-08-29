//
//  Strings.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Two questions asked of a string all over the library, answered once.
//

import Foundation

extension String {

    /// Whether there is anything here but space.
    ///
    /// Every field in the model is a string that may have been left empty,
    /// and "left empty" includes a stray space or a newline in a JSON file:
    /// a phone number of `" "` is no phone number, and should earn neither
    /// a separator on the contact line nor a pass from the checks.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The first letter up and the rest as written — `ledger` → `Ledger`.
    ///
    /// Not Foundation's `capitalized`, which capitalises every word and
    /// lowercases the rest, and would list a design called `iOS` as `Ios`.
    var capitalised: String {
        prefix(1).uppercased() + dropFirst()
    }
}
