//
//  Entries.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The repeated blocks a résumé is made of.
//
//  Dates are strings, deliberately, for the same reason money is a string in
//  the invoice templates: rendering one correctly means knowing a locale's
//  conventions, and a layout type has no business guessing. "Jan 2022" and
//  "01/2022" and "January 2022" are all right somewhere.
//
//  The difference here is that the string is then *checked*. An applicant
//  tracking system reads dates by pattern, and a range it cannot parse becomes
//  a gap in an employment history that somebody has to explain. So the format
//  stays the caller's decision and ``ATS`` reports the ones that will not
//  survive the trip. See ``DateRange``.
//

import Foundation

// MARK: - Date range

/// When something started and stopped.
public struct DateRange: Sendable, Equatable, Codable {

    public let start: String

    /// Empty means there is no second date — a prize, a certification, a
    /// project that happened in one year.
    ///
    /// Not the same as ongoing. Treating an absent end as "Present" is the
    /// obvious shortcut and it is wrong in exactly the case that matters: a
    /// project dated 2023 becomes "2023 – Present", which claims something
    /// nobody wrote. Say ``since(_:)`` when a thing has not ended.
    public let end: String

    public init(_ start: String, _ end: String = "") {
        self.start = start
        self.end = end
    }

    /// A position that has not ended.
    ///
    /// The word stored is English; ``rendered(present:dash:)`` substitutes
    /// whatever the document's ``Labels`` call it, so a Lebenslauf says
    /// *heute* without the data having to know.
    public static func since(_ start: String) -> DateRange {
        DateRange(start, "Present")
    }

    /// Words that mean "still going", in the languages the labels cover.
    private static let ongoingWords: Set<String> = [
        "present", "current", "now", "to date", "ongoing", "date",
        "heute", "aktuell", "présent", "actuel",
    ]

    /// Whether this is a current position.
    public var isCurrent: Bool {
        Self.ongoingWords.contains(end.trimmingCharacters(in: .whitespaces).lowercased())
    }

    /// The range as one string, using `dash` between the two.
    public func rendered(present: String = "Present", dash: String = "–") -> String {
        let from = start.trimmingCharacters(in: .whitespaces)
        let trimmedEnd = end.trimmingCharacters(in: .whitespaces)

        guard !trimmedEnd.isEmpty else { return from }

        let to = isCurrent ? present : trimmedEnd
        return from.isEmpty ? to : "\(from) \(dash) \(to)"
    }

    public var isEmpty: Bool {
        start.trimmingCharacters(in: .whitespaces).isEmpty
            && end.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Position

/// A job, or anything shaped like one.
///
/// Also used for volunteering, which is the same block with a different
/// heading — the distinction is what it is filed under, not how it is set.
public struct Position: Sendable, Equatable, Codable {

    /// "Senior Infrastructure Engineer".
    public let role: String

    /// "Stripe".
    public let organisation: String

    /// "London" or "Remote". A city, not an address.
    public let location: String

    public let dates: DateRange

    /// One line about the role or the company, where the name alone does not
    /// carry it. A reader knows what Stripe is; they do not know what a
    /// forty-person logistics company in Rotterdam is.
    public let summary: String

    /// What was actually achieved, one per line.
    ///
    /// The part of a résumé anybody reads closely. A bullet that names a
    /// result and a number is doing the work; one that restates the job title
    /// in longer form is taking up the space that one could have used.
    public let highlights: [String]

    /// Technologies or methods, where a design shows them separately.
    public let skills: [String]

    public init(
        role: String,
        organisation: String = "",
        location: String = "",
        dates: DateRange = DateRange(""),
        summary: String = "",
        highlights: [String] = [],
        skills: [String] = []
    ) {
        self.role = role
        self.organisation = organisation
        self.location = location
        self.dates = dates
        self.summary = summary
        self.highlights = highlights
        self.skills = skills
    }
}

// MARK: - Education

/// A qualification.
public struct Education: Sendable, Equatable, Codable {

    /// "BSc Computer Science".
    public let qualification: String

    /// "University of Bristol".
    public let institution: String

    public let location: String
    public let dates: DateRange

    /// "First Class Honours", "3.8 GPA", "Distinction".
    ///
    /// Conventions do not travel: a GPA means nothing to a British reader and
    /// a 2:1 means nothing to an American one. Written out as it is understood
    /// where the application is going, which is why this is a free string.
    public let grade: String

    /// Thesis title, relevant modules, societies.
    public let highlights: [String]

    public init(
        qualification: String,
        institution: String = "",
        location: String = "",
        dates: DateRange = DateRange(""),
        grade: String = "",
        highlights: [String] = []
    ) {
        self.qualification = qualification
        self.institution = institution
        self.location = location
        self.dates = dates
        self.grade = grade
        self.highlights = highlights
    }
}

// MARK: - Project

/// Something built, with or without an employer attached.
public struct Project: Sendable, Equatable, Codable {

    public let name: String

    /// "Author", "Maintainer", "Contributor" — where it is not obvious.
    public let role: String

    public let link: Link?
    public let dates: DateRange
    public let summary: String
    public let highlights: [String]
    public let skills: [String]

    public init(
        name: String,
        role: String = "",
        link: Link? = nil,
        dates: DateRange = DateRange(""),
        summary: String = "",
        highlights: [String] = [],
        skills: [String] = []
    ) {
        self.name = name
        self.role = role
        self.link = link
        self.dates = dates
        self.summary = summary
        self.highlights = highlights
        self.skills = skills
    }
}

// MARK: - Skills

/// One skill, optionally rated.
///
/// The rating exists because a great many résumé designs ask for it, and it
/// is worth being clear about what it is: a number the candidate chose about
/// themselves, on a scale nobody defined, which no reader can check and no
/// parser can read. "Java 95%" is a claim about nothing.
///
/// It is here, it renders, and ``ATS`` says so.
public struct Skill: Sendable, Equatable, Codable, ExpressibleByStringLiteral {

    public let name: String

    /// 0 to 1, or `nil` when the skill is simply listed.
    public let level: Double?

    public init(_ name: String, _ level: Double? = nil) {
        self.name = name
        self.level = level.map { min(max($0, 0), 1) }
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// Decodes from either `"Swift"` or `{"name": "Swift", "level": 0.9}`.
    ///
    /// Both spellings, because a skills list is the part of a résumé most
    /// likely to be written by hand, and making somebody type an object per
    /// item to say "I know Swift" is a tax on the common case.
    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let name = try? single.decode(String.self) {
            self.init(name)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .name),
            try container.decodeIfPresent(Double.self, forKey: .level)
        )
    }

    public func encode(to encoder: Encoder) throws {
        guard let level else {
            var single = encoder.singleValueContainer()
            try single.encode(name)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(level, forKey: .level)
    }

    private enum CodingKeys: String, CodingKey { case name, level }
}

/// A named group of skills.
///
/// Grouped rather than one long list, because an unlabelled run of thirty
/// words is read as noise. "Languages: Swift, Go, Rust" is read.
public struct SkillGroup: Sendable, Equatable, Codable {

    public let name: String
    public let items: [Skill]

    public init(_ name: String, _ items: [Skill]) {
        self.name = name
        self.items = items
    }

    /// The names alone, for the designs that only list them.
    public var names: [String] { items.map(\.name) }

    /// Whether anything here carries a rating.
    public var isRated: Bool { items.contains { $0.level != nil } }
}

// MARK: - Credential

/// A certification or licence.
public struct Credential: Sendable, Equatable, Codable {

    public let name: String
    public let issuer: String
    public let date: String

    /// The number a reader would use to verify it, where one exists.
    public let identifier: String

    public init(name: String, issuer: String = "", date: String = "", identifier: String = "") {
        self.name = name
        self.issuer = issuer
        self.date = date
        self.identifier = identifier
    }
}

// MARK: - Publication

/// A paper, article or talk.
public struct Publication: Sendable, Equatable, Codable {

    public let title: String

    /// Journal, conference or publisher.
    public let venue: String

    public let date: String

    /// As they appear on the work, in that order. The author's own name is
    /// left in place rather than elided — position in the list is the
    /// information.
    public let authors: String

    public let link: Link?

    public init(
        title: String, venue: String = "", date: String = "",
        authors: String = "", link: Link? = nil
    ) {
        self.title = title
        self.venue = venue
        self.date = date
        self.authors = authors
        self.link = link
    }
}

// MARK: - Award

/// A prize, grant or recognition.
public struct Award: Sendable, Equatable, Codable {

    public let name: String
    public let issuer: String
    public let date: String
    public let summary: String

    public init(name: String, issuer: String = "", date: String = "", summary: String = "") {
        self.name = name
        self.issuer = issuer
        self.date = date
        self.summary = summary
    }
}

// MARK: - Language

/// A spoken language and how well.
public struct Language: Sendable, Equatable, Codable {

    public let name: String

    /// "Native", "Fluent", or a CEFR level such as "C1".
    ///
    /// CEFR where the reader will know it, which in Europe is everywhere and
    /// in the US is almost nowhere.
    public let level: String

    public init(_ name: String, _ level: String = "") {
        self.name = name
        self.level = level
    }
}
