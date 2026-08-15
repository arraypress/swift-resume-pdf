//
//  Decoding.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Reading a résumé out of JSON without demanding every field.
//
//  Swift's synthesised decoder does not use a property's default value: a
//  type whose Swift initialiser lets you omit nine arguments still refuses
//  JSON that omits nine keys. For a type nobody writes by hand that is a
//  detail; for this one it is the difference between
//
//      { "role": "Engineer", "organisation": "Stripe" }
//
//  and having to spell out an empty location, an empty summary, an empty
//  date range and three empty arrays to say the same thing.
//
//  So the decoders are written out. Each type requires the one field that
//  identifies it — a position without a role is not a position — and defaults
//  the rest, which is the same contract the Swift initialisers offer.
//

import Foundation

extension KeyedDecodingContainer {

    /// The value at `key`, or `fallback` when it is absent or null.
    func value<T: Decodable>(_ key: Key, or fallback: T) -> T {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback
    }

    /// The value at `key`, or nothing.
    func maybe<T: Decodable>(_ key: Key) -> T? {
        (try? decodeIfPresent(T.self, forKey: key)) ?? nil
    }
}

// MARK: - Dates

extension DateRange {

    public init(from decoder: Decoder) throws {
        // A bare string is a single date, which is what somebody writing
        // "2023" by hand means and is tedious to spell as an object.
        if let single = try? decoder.singleValueContainer(),
           let text = try? single.decode(String.self) {
            self.init(text)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(container.value(.start, or: ""), container.value(.end, or: ""))
    }

    enum CodingKeys: String, CodingKey { case start, end }
}

// MARK: - Entries

extension Position {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            role: try container.decode(String.self, forKey: .role),
            organisation: container.value(.organisation, or: ""),
            location: container.value(.location, or: ""),
            dates: container.value(.dates, or: DateRange("")),
            summary: container.value(.summary, or: ""),
            highlights: container.value(.highlights, or: []),
            skills: container.value(.skills, or: [])
        )
    }

    enum CodingKeys: String, CodingKey {
        case role, organisation, location, dates, summary, highlights, skills
    }
}

extension Education {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            qualification: try container.decode(String.self, forKey: .qualification),
            institution: container.value(.institution, or: ""),
            location: container.value(.location, or: ""),
            dates: container.value(.dates, or: DateRange("")),
            grade: container.value(.grade, or: ""),
            highlights: container.value(.highlights, or: [])
        )
    }

    enum CodingKeys: String, CodingKey {
        case qualification, institution, location, dates, grade, highlights
    }
}

extension Project {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            role: container.value(.role, or: ""),
            link: container.maybe(.link),
            dates: container.value(.dates, or: DateRange("")),
            summary: container.value(.summary, or: ""),
            highlights: container.value(.highlights, or: []),
            skills: container.value(.skills, or: [])
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, role, link, dates, summary, highlights, skills
    }
}

extension Publication {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            venue: container.value(.venue, or: ""),
            date: container.value(.date, or: ""),
            authors: container.value(.authors, or: ""),
            link: container.maybe(.link)
        )
    }

    enum CodingKeys: String, CodingKey { case title, venue, date, authors, link }
}

extension Credential {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            issuer: container.value(.issuer, or: ""),
            date: container.value(.date, or: ""),
            identifier: container.value(.identifier, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, issuer, date, identifier }
}

extension Award {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            issuer: container.value(.issuer, or: ""),
            date: container.value(.date, or: ""),
            summary: container.value(.summary, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, issuer, date, summary }
}

extension Grant {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            funder: container.value(.funder, or: ""),
            amount: container.value(.amount, or: ""),
            dates: container.value(.dates, or: DateRange("")),
            role: container.value(.role, or: ""),
            identifier: container.value(.identifier, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case title, funder, amount, dates, role, identifier }
}

extension Language {

    public init(from decoder: Decoder) throws {
        // "English" alone is a language somebody knows; the level is a
        // refinement rather than part of the fact.
        if let single = try? decoder.singleValueContainer(),
           let name = try? single.decode(String.self) {
            self.init(name)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .name),
            container.value(.level, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, level }
}

extension SkillGroup {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .name),
            container.value(.items, or: [])
        )
    }

    enum CodingKeys: String, CodingKey { case name, items }
}

// MARK: - Profile

extension Profile {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            headline: container.value(.headline, or: ""),
            location: container.value(.location, or: ""),
            email: container.value(.email, or: ""),
            phone: container.value(.phone, or: ""),
            links: container.value(.links, or: []),
            photo: container.value(.photo, or: ""),
            dateOfBirth: container.value(.dateOfBirth, or: ""),
            nationality: container.value(.nationality, or: ""),
            maritalStatus: container.value(.maritalStatus, or: ""),
            placeOfBirth: container.value(.placeOfBirth, or: "")
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, headline, location, email, phone, links, photo
        case dateOfBirth, nationality, maritalStatus, placeOfBirth
    }
}

extension Link {

    public init(from decoder: Decoder) throws {
        // A bare string is the common case, and writing {"url": …, "label": …}
        // for every link is a tax on it.
        if let single = try? decoder.singleValueContainer(),
           let url = try? single.decode(String.self) {
            self.init(url)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .url),
            label: container.value(.label, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case url, label }
}

// MARK: - Documents

extension Resume {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            profile: try container.decode(Profile.self, forKey: .profile),
            summary: container.value(.summary, or: ""),
            experience: container.value(.experience, or: []),
            education: container.value(.education, or: []),
            skills: container.value(.skills, or: []),
            projects: container.value(.projects, or: []),
            volunteering: container.value(.volunteering, or: []),
            certifications: container.value(.certifications, or: []),
            publications: container.value(.publications, or: []),
            awards: container.value(.awards, or: []),
            languages: container.value(.languages, or: []),
            grants: container.value(.grants, or: []),
            teaching: container.value(.teaching, or: []),
            talks: container.value(.talks, or: []),
            service: container.value(.service, or: []),
            memberships: container.value(.memberships, or: []),
            interests: container.value(.interests, or: ""),
            references: container.value(.references, or: ""),
            custom: container.value(.custom, or: []),
            order: container.value(.order, or: Section.conventional),
            labels: container.value(.labels, or: .english)
        )
    }

    enum CodingKeys: String, CodingKey {
        case profile, summary, experience, education, skills, projects
        case volunteering, certifications, publications, awards, languages
        case grants, teaching, talks, service, memberships
        case interests, references, custom, order, labels
    }
}

extension CustomSection {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .title),
            container.value(.content, or: [])
        )
    }

    enum CodingKeys: String, CodingKey { case title, content }
}

extension CoverLetter {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            profile: try container.decode(Profile.self, forKey: .profile),
            recipient: container.value(.recipient, or: Recipient()),
            date: container.value(.date, or: ""),
            subject: container.value(.subject, or: ""),
            salutation: container.value(.salutation, or: ""),
            body: container.value(.body, or: []),
            highlights: container.value(.highlights, or: []),
            closing: container.value(.closing, or: ""),
            signature: container.value(.signature, or: ""),
            postscript: container.value(.postscript, or: "")
        )
    }

    enum CodingKeys: String, CodingKey {
        case profile, recipient, date, subject, salutation, body
        case highlights, closing, signature, postscript
    }
}

extension Recipient {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: container.value(.name, or: ""),
            role: container.value(.role, or: ""),
            organisation: container.value(.organisation, or: ""),
            address: container.value(.address, or: [])
        )
    }

    enum CodingKeys: String, CodingKey { case name, role, organisation, address }
}

extension Highlight {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .title),
            container.value(.detail, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case title, detail }
}

extension Labels {

    public init(from decoder: Decoder) throws {
        // "de" alone is what somebody means by a language, and spelling out
        // every heading to get German ones is not a thing to ask.
        if let single = try? decoder.singleValueContainer(),
           let code = try? single.decode(String.self) {
            self = code.lowercased() == "de" ? .german : .english
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            container.value(.overrides, or: [:]),
            present: container.value(.present, or: "Present"),
            dateSeparator: container.value(.dateSeparator, or: "–"),
            language: container.value(.language, or: "en")
        )
    }

    enum CodingKeys: String, CodingKey { case overrides, present, dateSeparator, language }
}
