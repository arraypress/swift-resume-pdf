//
//  CoverLetter.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The letter that goes with the résumé.
//
//  A genuinely different document rather than a résumé with prose in it: it is
//  addressed to somebody, it argues rather than lists, and it is read in order
//  from the top instead of scanned. That is why it has its own designs — the
//  furniture a résumé needs, ruled sections and a date rail, is exactly what a
//  letter must not have.
//
//  It shares ``Profile`` with the résumé on purpose. The two documents are
//  from the same person and arrive in the same email, and nothing looks less
//  considered than an application whose two halves disagree about a phone
//  number.
//

import Foundation

/// A letter of application.
public struct CoverLetter: Sendable, Equatable, Codable {

    /// The sender. The same profile the résumé uses.
    public let profile: Profile

    public let recipient: Recipient

    /// As it should read on the page — "14 August 2026".
    ///
    /// A string, like every other date here: the format is a locale's business
    /// and the caller knows which locale this is going to.
    public let date: String

    /// "Re: Senior Infrastructure Engineer".
    ///
    /// Optional and worth having. A recruiter with forty open roles is sorting
    /// by which one you mean before they read a word of the argument.
    public let subject: String

    /// "Dear Ms Okonkwo," — derived from the recipient when left empty.
    public let salutation: String

    /// The letter itself, one string per paragraph.
    public let body: [String]

    /// Optional lead-in bullets between paragraphs.
    ///
    /// Three at most, and only where the letter is making a list of claims it
    /// intends to evidence. A letter that is entirely bullets is a résumé with
    /// a greeting on it.
    public let highlights: [Highlight]

    /// "Yours sincerely," — which is the correct one when the recipient is
    /// named, and "Yours faithfully," when the letter opens "Dear Sir or
    /// Madam". The distinction is still observed in British correspondence and
    /// getting it wrong is noticed by exactly the people who would notice.
    public let closing: String

    /// The name under the closing. Falls back to the profile's.
    public let signature: String

    /// After the signature. Rare, and read more often than the third
    /// paragraph — which is worth knowing before spending one.
    public let postscript: String

    public init(
        profile: Profile,
        recipient: Recipient = Recipient(),
        date: String = "",
        subject: String = "",
        salutation: String = "",
        body: [String] = [],
        highlights: [Highlight] = [],
        closing: String = "",
        signature: String = "",
        postscript: String = ""
    ) {
        self.profile = profile
        self.recipient = recipient
        self.date = date
        self.subject = subject
        self.salutation = salutation
        self.body = body
        self.highlights = highlights
        self.closing = closing
        self.signature = signature
        self.postscript = postscript
    }

    /// The greeting, worked out when it was not given.
    ///
    /// "Dear Hiring Manager" is the fallback and not a good one — a letter
    /// addressed to a job title is visibly one of forty. ``ATS`` says so.
    public var greeting: String {
        let written = salutation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !written.isEmpty { return written }

        let named = recipient.name.trimmingCharacters(in: .whitespaces)
        return named.isEmpty ? "Dear Hiring Manager," : "Dear \(named),"
    }

    /// The sign-off, worked out when it was not given.
    public var signOff: String {
        let written = closing.trimmingCharacters(in: .whitespacesAndNewlines)
        if !written.isEmpty { return written }

        // The British rule, which costs nothing to observe and is noticed by
        // the people who observe it.
        return recipient.name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Yours faithfully,"
            : "Yours sincerely,"
    }

    /// The name printed under the sign-off.
    public var signedName: String {
        let written = signature.trimmingCharacters(in: .whitespaces)
        return written.isEmpty ? profile.name : written
    }

    /// Roughly how many words the letter runs to.
    ///
    /// The number that decides whether it gets read. Between about 250 and 400
    /// is a letter; past 500 it is an essay, and the reader has forty of them.
    public var wordCount: Int {
        let text = body.joined(separator: " ")
            + " " + highlights.map { "\($0.title) \($0.detail)" }.joined(separator: " ")
        return text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}

// MARK: - Recipient

/// Who the letter is to.
public struct Recipient: Sendable, Equatable, Codable {

    /// "Ms Adaeze Okonkwo". Empty where it could not be found — which is worth
    /// ten minutes of looking, because a named letter is read differently.
    public let name: String

    /// "Head of Infrastructure".
    public let role: String

    public let organisation: String

    /// Postal address, one line each. Conventional on a printed letter and
    /// increasingly omitted on one sent as a PDF.
    public let address: [String]

    public init(name: String = "", role: String = "", organisation: String = "", address: [String] = []) {
        self.name = name
        self.role = role
        self.organisation = organisation
        self.address = address
    }

    /// The block as it is set, one string per line.
    public func lines() -> [String] {
        ([name, role, organisation] + address)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    public var isEmpty: Bool { lines().isEmpty }
}

// MARK: - Highlight

/// A claim with a lead-in.
public struct Highlight: Sendable, Equatable, Codable {

    /// Set in the heavier weight and read first — "Ledger reliability."
    public let title: String

    public let detail: String

    public init(_ title: String, _ detail: String) {
        self.title = title
        self.detail = detail
    }
}
