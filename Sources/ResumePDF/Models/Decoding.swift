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

    /// The value at `key`, or `fallback` when the key is absent or null.
    ///
    /// Absent and *wrong* are different answers. Written with `try?` this
    /// defaults both, so one mistyped key inside `experience[3]` would drop
    /// the entire employment history and render a résumé that looked finished
    /// — the failure this library exists to prevent, committed by its own
    /// decoder. A malformed value throws and names itself.
    func value<T: Decodable>(_ key: Key, or fallback: T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback
    }

    /// The value at `key`, or nothing when it is absent or null.
    func maybe<T: Decodable>(_ key: Key) throws -> T? {
        try decodeIfPresent(T.self, forKey: key)
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
        self.init(try container.value(.start, or: ""), try container.value(.end, or: ""))
    }

    enum CodingKeys: String, CodingKey { case start, end }
}

// MARK: - Entries

extension Position {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            role: try container.decode(String.self, forKey: .role),
            organisation: try container.value(.organisation, or: ""),
            location: try container.value(.location, or: ""),
            dates: try container.value(.dates, or: DateRange("")),
            summary: try container.value(.summary, or: ""),
            highlights: try container.value(.highlights, or: []),
            skills: try container.value(.skills, or: [])
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
            institution: try container.value(.institution, or: ""),
            location: try container.value(.location, or: ""),
            dates: try container.value(.dates, or: DateRange("")),
            grade: try container.value(.grade, or: ""),
            highlights: try container.value(.highlights, or: [])
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
            role: try container.value(.role, or: ""),
            link: try container.maybe(.link),
            dates: try container.value(.dates, or: DateRange("")),
            summary: try container.value(.summary, or: ""),
            highlights: try container.value(.highlights, or: []),
            skills: try container.value(.skills, or: [])
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
            venue: try container.value(.venue, or: ""),
            date: try container.value(.date, or: ""),
            authors: try container.value(.authors, or: ""),
            link: try container.maybe(.link)
        )
    }

    enum CodingKeys: String, CodingKey { case title, venue, date, authors, link }
}

extension Credential {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            issuer: try container.value(.issuer, or: ""),
            date: try container.value(.date, or: ""),
            identifier: try container.value(.identifier, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, issuer, date, identifier }
}

extension Award {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            issuer: try container.value(.issuer, or: ""),
            date: try container.value(.date, or: ""),
            summary: try container.value(.summary, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, issuer, date, summary }
}

extension Grant {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            funder: try container.value(.funder, or: ""),
            amount: try container.value(.amount, or: ""),
            dates: try container.value(.dates, or: DateRange("")),
            role: try container.value(.role, or: ""),
            identifier: try container.value(.identifier, or: "")
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
            try container.value(.level, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case name, level }
}

extension SkillGroup {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .name),
            try container.value(.items, or: [])
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
            headline: try container.value(.headline, or: ""),
            location: try container.value(.location, or: ""),
            email: try container.value(.email, or: ""),
            phone: try container.value(.phone, or: ""),
            links: try container.value(.links, or: []),
            photo: try container.value(.photo, or: ""),
            qr: try container.value(.qr, or: ""),
            dateOfBirth: try container.value(.dateOfBirth, or: ""),
            nationality: try container.value(.nationality, or: ""),
            maritalStatus: try container.value(.maritalStatus, or: ""),
            placeOfBirth: try container.value(.placeOfBirth, or: "")
        )
    }

    enum CodingKeys: String, CodingKey {
        case name, headline, location, email, phone, links, photo, qr
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
            label: try container.value(.label, or: "")
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
            summary: try container.value(.summary, or: ""),
            experience: try container.value(.experience, or: []),
            education: try container.value(.education, or: []),
            skills: try container.value(.skills, or: []),
            projects: try container.value(.projects, or: []),
            volunteering: try container.value(.volunteering, or: []),
            certifications: try container.value(.certifications, or: []),
            publications: try container.value(.publications, or: []),
            awards: try container.value(.awards, or: []),
            languages: try container.value(.languages, or: []),
            grants: try container.value(.grants, or: []),
            teaching: try container.value(.teaching, or: []),
            talks: try container.value(.talks, or: []),
            service: try container.value(.service, or: []),
            memberships: try container.value(.memberships, or: []),
            interests: try container.value(.interests, or: ""),
            references: try container.value(.references, or: ""),
            custom: try container.value(.custom, or: []),
            order: try container.value(.order, or: Section.conventional),
            labels: try container.value(.labels, or: .english)
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
            try container.value(.content, or: [])
        )
    }

    enum CodingKeys: String, CodingKey { case title, content }
}

extension CustomSection.Content {

    /// Read and written as `{ "list": ["…"] }`.
    ///
    /// Swift's synthesised coding for an enum with associated values names the
    /// payload by position — `{"list": {"_0": ["…"]}}` — which is a shape
    /// nobody would write and nobody could guess. Custom sections are the
    /// whole extensibility story of this library; theirs has to be the shape
    /// somebody would type.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Kind.self)

        guard let kind = container.allKeys.first, container.allKeys.count == 1 else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: container.allKeys.isEmpty
                    ? "A block of a custom section needs one of: "
                        + Kind.allCases.map(\.rawValue).joined(separator: ", ")
                    : "A block holds one kind of content, not "
                        + container.allKeys.map(\.rawValue).joined(separator: " and ")
            ))
        }

        switch kind {
        case .prose: self = .prose(try container.decode(String.self, forKey: .prose))
        case .list: self = .list(try container.decode([String].self, forKey: .list))
        case .positions: self = .positions(try container.decode([Position].self, forKey: .positions))
        case .education: self = .education(try container.decode([Education].self, forKey: .education))
        case .projects: self = .projects(try container.decode([Project].self, forKey: .projects))
        case .publications: self = .publications(try container.decode([Publication].self, forKey: .publications))
        case .credentials: self = .credentials(try container.decode([Credential].self, forKey: .credentials))
        case .awards: self = .awards(try container.decode([Award].self, forKey: .awards))
        case .grants: self = .grants(try container.decode([Grant].self, forKey: .grants))
        case .skills: self = .skills(try container.decode([SkillGroup].self, forKey: .skills))
        case .languages: self = .languages(try container.decode([Language].self, forKey: .languages))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Kind.self)

        switch self {
        case .prose(let value): try container.encode(value, forKey: .prose)
        case .list(let value): try container.encode(value, forKey: .list)
        case .positions(let value): try container.encode(value, forKey: .positions)
        case .education(let value): try container.encode(value, forKey: .education)
        case .projects(let value): try container.encode(value, forKey: .projects)
        case .publications(let value): try container.encode(value, forKey: .publications)
        case .credentials(let value): try container.encode(value, forKey: .credentials)
        case .awards(let value): try container.encode(value, forKey: .awards)
        case .grants(let value): try container.encode(value, forKey: .grants)
        case .skills(let value): try container.encode(value, forKey: .skills)
        case .languages(let value): try container.encode(value, forKey: .languages)
        }
    }

    enum Kind: String, CodingKey, CaseIterable {
        case prose, list, positions, education, projects, publications
        case credentials, awards, grants, skills, languages
    }
}

extension CoverLetter {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            profile: try container.decode(Profile.self, forKey: .profile),
            recipient: try container.value(.recipient, or: Recipient()),
            date: try container.value(.date, or: ""),
            subject: try container.value(.subject, or: ""),
            salutation: try container.value(.salutation, or: ""),
            body: try container.value(.body, or: []),
            highlights: try container.value(.highlights, or: []),
            closing: try container.value(.closing, or: ""),
            signature: try container.value(.signature, or: ""),
            postscript: try container.value(.postscript, or: "")
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
            name: try container.value(.name, or: ""),
            role: try container.value(.role, or: ""),
            organisation: try container.value(.organisation, or: ""),
            address: try container.value(.address, or: [])
        )
    }

    enum CodingKeys: String, CodingKey { case name, role, organisation, address }
}

extension Highlight {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .title),
            try container.value(.detail, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case title, detail }
}

extension Theme {

    /// Decodes a theme the way somebody writes one: name what you want
    /// changed, and leave the rest out.
    ///
    /// An absent `typeface` matters most — it decodes as *no preference*,
    /// which is what lets the design's own face through. Only a theme that
    /// names one has made a choice.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            typeface: try container.maybe(.typeface),
            accent: try container.value(.accent, or: "#111111"),
            pageSize: try container.value(.pageSize, or: .a4),
            density: try container.value(.density, or: .normal),
            scheme: try container.value(.scheme, or: .light),
            tint: try container.maybe(.tint),
            justified: try container.value(.justified, or: false)
        )
    }

    enum CodingKeys: String, CodingKey {
        case typeface, accent, pageSize, density, scheme, tint, justified
    }
}

extension Labels {

    public init(from decoder: Decoder) throws {
        // "de" alone is what somebody means by a language, and spelling out
        // every heading to get German ones is not a thing to ask. A code
        // there is no label set for throws rather than quietly becoming
        // English — "fr" used to do that, and a Lebenslauf's neighbour
        // rendered with the wrong headings and no error is exactly the
        // silent failure this library exists to prevent.
        if let single = try? decoder.singleValueContainer(),
           let code = try? single.decode(String.self) {
            switch code.lowercased() {
            case "en": self = .english
            case "de": self = .german
            default:
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "There is no label set for \"\(code)\" — one of: en, de. "
                        + "For another language, spell the labels out: "
                        + "{\"present\": …, \"overrides\": {\"experience\": …}}."
                ))
            }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.value(.overrides, or: [:]),
            present: try container.value(.present, or: "Present"),
            dateSeparator: try container.value(.dateSeparator, or: "–"),
            language: try container.value(.language, or: "en")
        )
    }

    enum CodingKeys: String, CodingKey { case overrides, present, dateSeparator, language }
}
