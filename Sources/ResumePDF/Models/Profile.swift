//
//  Profile.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Who the document is about, and how to reach them.
//
//  The particulars at the bottom of this file — date of birth, nationality,
//  marital status, a photograph — are conventional in some countries and a
//  liability in others. They are present because a German Lebenslauf without
//  them looks incomplete, and empty by default because a US résumé carrying
//  them can be discarded before anybody reads it. See ``Region``.
//

import Foundation

/// The person the document is about.
public struct Profile: Sendable, Equatable, Codable {

    /// As it should appear at the top of the page, and nowhere else.
    public let name: String

    /// The line under the name — "Senior Infrastructure Engineer".
    ///
    /// Not a job title from the last role, which the experience section
    /// already carries. This is the claim the document is making, and it is
    /// the first thing read after the name.
    public let headline: String

    /// "London, UK" or "Remote — UK time zones".
    ///
    /// A city and country, not a street address. A full postal address on a
    /// résumé is a habit left over from posted applications: it tells a
    /// recruiter nothing they need before an offer, and it is the field most
    /// likely to be used to guess a commute and quietly rule somebody out.
    public let location: String

    public let email: String
    public let phone: String

    /// Portfolio, repository and profile links.
    public let links: [Link]

    /// A path to a baseline JPEG portrait.
    ///
    /// A path rather than the bytes, so a résumé stays a small readable
    /// document that survives being kept in version control beside the work
    /// it describes.
    ///
    /// Conventional on a Lebenslauf and on much of the résumé world outside
    /// the English-speaking part of it; a liability in the US and UK, where an
    /// employer may not consider what a photograph reveals and the cheapest
    /// way to prove they did not is never to have seen it. ``Region`` reports
    /// which situation you are in. Designs that have nowhere to put one
    /// ignore it.
    public let photo: String

    /// A URL to print as a code somebody can scan.
    ///
    /// A portfolio, a repository, a personal site. Worth the square inch on a
    /// printed CV, where a link is a thing to be typed out by hand and
    /// therefore not followed — and worth nothing on a screen, where the
    /// contact line is already clickable. Designs that have nowhere to put one
    /// ignore it, and ``ATS`` reports which.
    ///
    /// Not a substitute for the address in writing: a parser reads text, and
    /// a URL that exists only inside a picture of a square is a URL no
    /// tracking system will ever see.
    public let qr: String

    // MARK: Regional particulars

    /// Conventional on a German or Austrian Lebenslauf, and on résumés across
    /// much of Asia and Latin America. Illegal to ask for in the US and UK,
    /// and volunteering it invites an age-discrimination problem for the
    /// reader rather than for you — which is why some recruiters bin it.
    public let dateOfBirth: String

    /// Conventional in the same places, and for the same reasons a problem in
    /// the others. Where a visa question is genuinely live, right-to-work
    /// status says the useful part without the rest.
    public let nationality: String

    /// Still printed on a Lebenslauf, though the practice is fading. Nowhere
    /// else — and never in an English-language application.
    public let maritalStatus: String

    /// Place of birth, which a Lebenslauf carries beside the date.
    public let placeOfBirth: String

    public init(
        name: String,
        headline: String = "",
        location: String = "",
        email: String = "",
        phone: String = "",
        links: [Link] = [],
        photo: String = "",
        qr: String = "",
        dateOfBirth: String = "",
        nationality: String = "",
        maritalStatus: String = "",
        placeOfBirth: String = ""
    ) {
        self.name = name
        self.headline = headline
        self.location = location
        self.email = email
        self.phone = phone
        self.links = links
        self.photo = photo
        self.qr = qr
        self.dateOfBirth = dateOfBirth
        self.nationality = nationality
        self.maritalStatus = maritalStatus
        self.placeOfBirth = placeOfBirth
    }

    /// The contact line, in the order a reader scans it.
    ///
    /// Email first because it is what they will use. Everything empty is
    /// dropped rather than left as a gap or a stray separator.
    public func contactLine() -> [String] {
        [email, phone, location].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// The contact line, with somewhere to go where there is somewhere.
    ///
    /// A résumé is read from a screen far more often than from paper, and an
    /// address nobody can click is one somebody has to retype — which is the
    /// difference between a recruiter opening your GitHub and meaning to.
    ///
    /// The location has no URL. It is the one thing here that is not a way of
    /// reaching you, and putting it on a map is answering a question nobody
    /// asked.
    public func contactEntries() -> [(text: String, url: String)] {
        var entries: [(text: String, url: String)] = []

        if !email.trimmingCharacters(in: .whitespaces).isEmpty {
            entries.append((email, "mailto:\(email.trimmingCharacters(in: .whitespaces))"))
        }
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty {
            // tel: wants the number and nothing else — no spaces, no brackets.
            // The "(0)" written inside an international number is the national
            // trunk digit: dialled after a country code it reaches a wrong
            // number, so it comes out of the dial string and stays in the text.
            let dialable = phone
                .replacingOccurrences(of: "(0)", with: "")
                .filter { $0.isNumber || $0 == "+" }
            entries.append((phone, dialable.count > 5 ? "tel:\(dialable)" : ""))
        }
        if !location.trimmingCharacters(in: .whitespaces).isEmpty {
            entries.append((location, ""))
        }
        return entries + links.map { ($0.label, $0.absolute) }
    }

    /// The regional particulars that are actually set, as label and value.
    public func particulars() -> [(label: String, value: String)] {
        [
            ("Date of birth", dateOfBirth),
            ("Place of birth", placeOfBirth),
            ("Nationality", nationality),
            ("Marital status", maritalStatus),
        ].filter { !$0.1.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

// MARK: - Link

/// Somewhere to go and look at the work.
public struct Link: Sendable, Equatable, Codable {

    /// What is printed. Derived from the URL when it is not given.
    public let label: String

    public let url: String

    public init(_ url: String, label: String = "") {
        self.url = url
        self.label = label.isEmpty ? Link.shorten(url) : label
    }

    /// `https://github.com/alexmorgan/` → `github.com/alexmorgan`.
    ///
    /// The scheme and the `www.` carry no information, and on a printed page
    /// the trailing slash reads as a typo. What is left is short enough to sit
    /// on a contact line beside three other things and still be typed by hand
    /// from a printout, which is the point.
    static func shorten(_ url: String) -> String {
        var trimmed = url.trimmingCharacters(in: .whitespaces)
        for prefix in ["https://", "http://"] where trimmed.hasPrefix(prefix) {
            trimmed.removeFirst(prefix.count)
        }
        if trimmed.hasPrefix("www.") { trimmed.removeFirst(4) }
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        return trimmed
    }

    /// The URL with a scheme, for the link annotation.
    public var absolute: String {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        if trimmed.contains("@"), !trimmed.hasPrefix("mailto:") { return "mailto:\(trimmed)" }
        return "https://\(trimmed)"
    }
}
