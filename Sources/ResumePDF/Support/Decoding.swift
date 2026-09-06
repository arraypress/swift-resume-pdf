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

    /// A named choice at `key` — a page size, a density — or `fallback`
    /// when the key is absent. A name that is none of the choices is
    /// refused with the names that are.
    func choice<T: RawRepresentable & CaseIterable>(
        _ key: Key, or fallback: T, called what: String
    ) throws -> T where T.RawValue == String {
        guard let written = try decodeIfPresent(String.self, forKey: key) else { return fallback }
        guard let matched = T.matching(written) else {
            throw DecodingError.noSuch(what, called: written, options: T.allCases.map(\.rawValue),
                                       at: codingPath + [key])
        }
        return matched
    }
}

extension Decoder {

    /// Decodes a named choice, saying what the choices are when it is not one.
    ///
    /// "There is no heading style called 'tabbed'" and a list beats "Cannot
    /// initialize Style from invalid String value tabbed", which tells
    /// somebody editing a JSON file nothing they did not already know.
    func choice<T: RawRepresentable & CaseIterable>(
        _ type: T.Type, called what: String
    ) throws -> T where T.RawValue == String {
        let raw = try singleValueContainer().decode(String.self)
        guard let value = T.matching(raw) else {
            throw DecodingError.noSuch(what, called: raw, options: T.allCases.map(\.rawValue), at: codingPath)
        }
        return value
    }

    /// A bare string where an object is also accepted — `"2023"` for a
    /// date range, `"English"` for a language, a URL for a link. Nil when
    /// what is there is not a string, so the keyed decode can go ahead.
    func shorthand() -> String? {
        guard let single = try? singleValueContainer() else { return nil }
        return try? single.decode(String.self)
    }
}

extension RawRepresentable where Self: CaseIterable, RawValue == String {

    /// The case written as `raw`, without regard to case: `"Letter"` and
    /// `"letter"` are one choice, and a file typed by hand should not be
    /// refused over a capital.
    static func matching(_ raw: String) -> Self? {
        let typed = raw.lowercased()
        return allCases.first { $0.rawValue.lowercased() == typed }
    }
}

extension DecodingError {

    /// "There is no heading style called "tabbed" — one of: …": what
    /// somebody editing a JSON file needs to read next.
    /// - Parameter advice: What to write instead, where the list is not
    ///   the whole answer.
    static func noSuch(
        _ what: String, called raw: String, options: [String], at path: [any CodingKey], advice: String = ""
    ) -> DecodingError {
        var description = "There is no \(what) called \"\(raw)\" — one of: " + options.joined(separator: ", ")
        if !advice.isEmpty { description += ". " + advice }
        return .dataCorrupted(DecodingError.Context(codingPath: path, debugDescription: description))
    }
}

// MARK: - Dates

extension DateRange {

    public init(from decoder: Decoder) throws {
        // A bare string is a single date, which is what somebody writing
        // "2023" by hand means and is tedious to spell as an object.
        if let text = decoder.shorthand() {
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
        if let name = decoder.shorthand() {
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
        if let url = decoder.shorthand() {
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
            achievements: try container.value(.achievements, or: []),
            strengths: try container.value(.strengths, or: []),
            time: try container.value(.time, or: []),
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
        case achievements, strengths, time
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
        case .achievements: self = .achievements(try container.decode([Achievement].self, forKey: .achievements))
        case .strengths: self = .strengths(try container.decode([Strength].self, forKey: .strengths))
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
        case .achievements(let value): try container.encode(value, forKey: .achievements)
        case .strengths(let value): try container.encode(value, forKey: .strengths)
        }
    }

    enum Kind: String, CodingKey, CaseIterable {
        case prose, list, positions, education, projects, publications
        case credentials, awards, grants, skills, languages, achievements, strengths
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
            pageSize: try container.choice(.pageSize, or: .a4, called: "page size"),
            density: try container.choice(.density, or: .normal, called: "density"),
            scheme: try container.choice(.scheme, or: .light, called: "scheme"),
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
        if let code = decoder.shorthand() {
            switch code.lowercased() {
            case "en": self = .english
            case "de": self = .german
            default:
                throw DecodingError.noSuch(
                    "label set", called: code, options: ["en", "de"], at: decoder.codingPath,
                    advice: "For another language, spell the labels out: "
                        + "{\"present\": …, \"overrides\": {\"experience\": …}}."
                )
            }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.value(.overrides, or: [:]),
            present: try container.value(.present, or: "Present"),
            dateSeparator: try container.value(.dateSeparator, or: "–"),
            language: try container.value(.language, or: "en"),
            contact: try container.value(.contact, or: "Contact"),
            details: try container.value(.details, or: "Details")
        )
    }

    enum CodingKeys: String, CodingKey { case overrides, present, dateSeparator, language, contact, details }
}

extension Typeface {

    /// A bundled family is its name — `"inter"`, `"sourceSerif"` — because
    /// that is what a theme file wants to say. A family of your own is the
    /// object it always was, with the files that make it.
    public init(from decoder: Decoder) throws {
        if let name = decoder.shorthand() {
            switch name.lowercased() {
            case "inter", "sans": self = .inter
            case "sourceserif", "source-serif", "serif": self = .sourceSerif
            default:
                throw DecodingError.noSuch(
                    "bundled typeface", called: name, options: ["inter", "sourceSerif"], at: decoder.codingPath,
                    advice: "A family of your own is an object: {\"name\": …, \"files\": […]}."
                )
            }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            files: try container.value(.files, or: []),
            bundled: try container.maybe(.bundled)
        )
    }

    public func encode(to encoder: Encoder) throws {
        if let bundled, files.isEmpty {
            var single = encoder.singleValueContainer()
            try single.encode(bundled)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(files, forKey: .files)
        try container.encodeIfPresent(bundled, forKey: .bundled)
    }

    enum CodingKeys: String, CodingKey { case name, files, bundled }
}

// MARK: - Achievements, strengths, time

extension Achievement {

    /// Only the title is required; a mark left out takes the next in the
    /// cycle, which is how a list of four looks finished with no icons named.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            summary: try container.value(.summary, or: ""),
            icon: try container.value(.icon, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case title, summary, icon }
}

extension Strength {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            summary: try container.value(.summary, or: "")
        )
    }

    enum CodingKeys: String, CodingKey { case title, summary }
}

extension TimeSlice {

    /// Read from `{"label": "Writing code", "share": 35}`. A slice with no
    /// share counts as one part, so a plain list of labels divides evenly.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(String.self, forKey: .label),
            try container.value(.share, or: 1)
        )
    }

    enum CodingKeys: String, CodingKey { case label, share }
}

