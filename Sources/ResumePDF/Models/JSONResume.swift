//
//  JSONResume.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The JSON Resume schema (jsonresume.org), read into a ``Resume``.
//
//  Thousands of people already have a `resume.json` in this shape, and a
//  tool that made them retype it into another one would not be used. The
//  mapping is one-way and lossy in a few named places — the schema carries
//  things this model does not print, and vice versa — and every loss is
//  written down here rather than discovered on a rendered page.
//
//  The shape is decoded tolerantly: every key is optional, unknown keys are
//  ignored, and the old `company` spelling of a work entry's `name` is read.
//  Files in the wild were written against three versions of the schema and
//  by hand, and a decoder that rejected one for a missing `url` would be
//  refusing the ordinary case.
//

import Foundation

/// A résumé in the JSON Resume schema, as it is decoded.
///
/// Public so a caller can inspect what was read before converting it, and
/// so the conversion is one line rather than a private ritual.
public struct JSONResume: Codable, Sendable, Equatable {

    public struct Basics: Codable, Sendable, Equatable {
        public var name: String?
        public var label: String?
        public var image: String?
        public var email: String?
        public var phone: String?
        public var url: String?
        public var summary: String?
        public var location: Location?
        public var profiles: [SocialProfile]?
    }

    public struct Location: Codable, Sendable, Equatable {
        public var address: String?
        public var postalCode: String?
        public var city: String?
        public var countryCode: String?
        public var region: String?
    }

    public struct SocialProfile: Codable, Sendable, Equatable {
        public var network: String?
        public var username: String?
        public var url: String?
    }

    public struct Work: Codable, Sendable, Equatable {
        public var name: String?
        /// The pre-1.0 spelling of `name`. Still common in files people have.
        public var company: String?
        public var position: String?
        public var url: String?
        public var location: String?
        /// What the employer does, where the name alone does not say.
        public var description: String?
        public var startDate: String?
        public var endDate: String?
        public var summary: String?
        public var highlights: [String]?
    }

    public struct Volunteer: Codable, Sendable, Equatable {
        public var organization: String?
        public var position: String?
        public var url: String?
        public var startDate: String?
        public var endDate: String?
        public var summary: String?
        public var highlights: [String]?
    }

    public struct Education: Codable, Sendable, Equatable {
        public var institution: String?
        public var url: String?
        public var area: String?
        public var studyType: String?
        public var startDate: String?
        public var endDate: String?
        public var score: String?
        public var courses: [String]?
    }

    public struct Award: Codable, Sendable, Equatable {
        public var title: String?
        public var date: String?
        public var awarder: String?
        public var summary: String?
    }

    public struct Certificate: Codable, Sendable, Equatable {
        public var name: String?
        public var date: String?
        public var issuer: String?
        public var url: String?
    }

    public struct Publication: Codable, Sendable, Equatable {
        public var name: String?
        public var publisher: String?
        public var releaseDate: String?
        public var url: String?
        public var summary: String?
    }

    public struct Skill: Codable, Sendable, Equatable {
        public var name: String?
        public var level: String?
        public var keywords: [String]?
    }

    public struct Language: Codable, Sendable, Equatable {
        public var language: String?
        public var fluency: String?
    }

    public struct Interest: Codable, Sendable, Equatable {
        public var name: String?
        public var keywords: [String]?
    }

    public struct Reference: Codable, Sendable, Equatable {
        public var name: String?
        public var reference: String?
    }

    public struct Project: Codable, Sendable, Equatable {
        public var name: String?
        public var description: String?
        public var highlights: [String]?
        public var keywords: [String]?
        public var startDate: String?
        public var endDate: String?
        public var url: String?
        public var roles: [String]?
        public var entity: String?
        public var type: String?
    }

    public struct Meta: Codable, Sendable, Equatable {
        public var canonical: String?
        public var version: String?
        public var lastModified: String?
    }

    /// The `$schema` line, when the file carries one.
    public var schema: String?
    public var basics: Basics?
    public var work: [Work]?
    public var volunteer: [Volunteer]?
    public var education: [Education]?
    public var awards: [Award]?
    public var certificates: [Certificate]?
    public var publications: [Publication]?
    public var skills: [Skill]?
    public var languages: [Language]?
    public var interests: [Interest]?
    public var references: [Reference]?
    public var projects: [Project]?
    public var meta: Meta?

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case basics, work, volunteer, education, awards, certificates, publications
        case skills, languages, interests, references, projects, meta
    }

    // MARK: Reading

    public init(data: Data) throws {
        self = try JSONDecoder().decode(JSONResume.self, from: data)
    }

    public init(contentsOf url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    /// Whether some JSON is in this schema rather than the library's own.
    ///
    /// `basics` is the tell: no key of that name exists in ``Resume``, and
    /// every JSON Resume file has one. A tool can read either shape from
    /// the same flag without asking which it was given.
    public static func looksLikeOne(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return object["basics"] != nil && object["profile"] == nil
    }

    // MARK: Dates

    /// `2022-03-15`, `2022-03` or `2022` as a résumé prints it: `Mar 2022`,
    /// `Mar 2022`, `2022`. Anything else is passed through as written —
    /// somebody who typed "Summer 2019" meant it.
    public static func date(_ iso: String?) -> String {
        guard let iso = iso?.trimmingCharacters(in: .whitespaces), !iso.isEmpty else { return "" }
        let parts = iso.split(separator: "-").map(String.init)
        guard let year = parts.first, year.count == 4, year.allSatisfy(\.isNumber) else { return iso }
        guard parts.count >= 2, let month = Int(parts[1]), (1...12).contains(month) else { return year }
        return "\(Self.months[month - 1]) \(year)"
    }

    private static let months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    /// A range where an absent end means still going.
    static func ongoing(_ start: String?, _ end: String?) -> DateRange {
        let from = date(start)
        let to = date(end)
        if to.isEmpty { return from.isEmpty ? DateRange("") : .since(from) }
        return DateRange(from, to)
    }

    /// A range where an absent end is just a single date — a project that
    /// happened in one year did not continue.
    static func dated(_ start: String?, _ end: String?) -> DateRange {
        let from = date(start)
        let to = date(end)
        // Started and finished in the same month is one date, not a range
        // whose two ends say the same thing.
        return from == to ? DateRange(from) : DateRange(from, to)
    }
}

// MARK: - Conversion

extension Resume {

    /// A JSON Resume file, read as a résumé.
    public init(jsonResumeData data: Data) throws {
        self.init(jsonResume: try JSONResume(data: data))
    }

    /// The mapping. Every property of the v1.0.0 schema is decoded; these are
    /// the ones that are not printed, and why:
    ///
    /// - `basics.location.address` and `postalCode`: a street address is not
    ///   wanted on a résumé and never was; the city and region are kept.
    /// - `work[].url`, `volunteer[].url`, `education[].url` and
    ///   `certificates[].url`: an entry carries no link of its own here — the
    ///   links on a résumé are the person's, in the profile. `projects[].url`
    ///   and `publications[].url` are kept, because those *are* the work.
    /// - `skills[].level`: a word ("Master") rather than a number, and a
    ///   printed proficiency label is the thing recruiters most distrust.
    /// - `publications[].summary` and `projects[].type`: no equivalent, and a
    ///   rendered guess would be worse than the omission.
    /// - `meta` and ``: about the file, not the person.
    ///
    /// And the ones that are folded into something: `work[].description`
    /// joins the summary, `projects[].entity` rides on the role line,
    /// `interests[].keywords` go in brackets after the interest, and
    /// `education[].courses` are the entry's highlights.
    public init(jsonResume source: JSONResume) {
        let basics = source.basics ?? JSONResume.Basics()

        var links: [Link] = []
        if let url = basics.url?.trimmingCharacters(in: .whitespaces), !url.isEmpty {
            links.append(Link(url))
        }
        for profile in basics.profiles ?? [] {
            guard let url = profile.url?.trimmingCharacters(in: .whitespaces), !url.isEmpty else { continue }
            links.append(Link(url))
        }

        let profile = Profile(
            name: basics.name ?? "",
            headline: basics.label ?? "",
            location: Self.place(basics.location),
            email: basics.email ?? "",
            phone: basics.phone ?? "",
            links: links,
            photo: basics.image ?? ""
        )

        let experience = (source.work ?? []).map { job in
            Position(
                role: job.position ?? "",
                organisation: job.name ?? job.company ?? "",
                location: job.location ?? "",
                dates: JSONResume.ongoing(job.startDate, job.endDate),
                summary: Self.joined(job.description, job.summary),
                highlights: job.highlights ?? []
            )
        }

        let volunteering = (source.volunteer ?? []).map { post in
            Position(
                role: post.position ?? "",
                organisation: post.organization ?? "",
                dates: JSONResume.ongoing(post.startDate, post.endDate),
                summary: post.summary ?? "",
                highlights: post.highlights ?? []
            )
        }

        let education = (source.education ?? []).map { entry in
            ResumePDF.Education(
                qualification: Self.qualification(entry.studyType, entry.area),
                institution: entry.institution ?? "",
                dates: JSONResume.ongoing(entry.startDate, entry.endDate),
                grade: entry.score ?? "",
                highlights: entry.courses ?? []
            )
        }

        // A skill with keywords is a group; one without is a skill on its
        // own, and those are gathered under one heading rather than each
        // becoming a group of one.
        var groups: [SkillGroup] = []
        var loose: [Skill] = []
        for entry in source.skills ?? [] {
            let name = entry.name ?? ""
            let keywords = (entry.keywords ?? []).filter { !$0.isEmpty }
            if keywords.isEmpty {
                if !name.isEmpty { loose.append(Skill(name)) }
            } else {
                groups.append(SkillGroup(name, keywords.map { Skill($0) }))
            }
        }
        if !loose.isEmpty { groups.append(SkillGroup("Skills", loose)) }

        let projects = (source.projects ?? []).map { project in
            ResumePDF.Project(
                name: project.name ?? "",
                role: Self.joined((project.roles ?? []).joined(separator: ", "), project.entity, with: " · "),
                link: project.url.flatMap { $0.isEmpty ? nil : Link($0) },
                dates: JSONResume.dated(project.startDate, project.endDate),
                summary: project.description ?? "",
                highlights: project.highlights ?? [],
                skills: project.keywords ?? []
            )
        }

        let certifications = (source.certificates ?? []).map { cert in
            Credential(name: cert.name ?? "", issuer: cert.issuer ?? "", date: JSONResume.date(cert.date))
        }

        let publications = (source.publications ?? []).map { paper in
            ResumePDF.Publication(
                title: paper.name ?? "",
                venue: paper.publisher ?? "",
                date: JSONResume.date(paper.releaseDate),
                link: paper.url.flatMap { $0.isEmpty ? nil : Link($0) }
            )
        }

        let awards = (source.awards ?? []).map { award in
            ResumePDF.Award(
                name: award.title ?? "", issuer: award.awarder ?? "",
                date: JSONResume.date(award.date), summary: award.summary ?? ""
            )
        }

        let languages = (source.languages ?? []).compactMap { entry -> ResumePDF.Language? in
            guard let name = entry.language, !name.isEmpty else { return nil }
            return ResumePDF.Language(name, entry.fluency ?? "")
        }

        let interests = (source.interests ?? []).compactMap { interest -> String? in
            guard let name = interest.name, !name.isEmpty else { return nil }
            let keywords = (interest.keywords ?? []).filter { !$0.isEmpty }
            return keywords.isEmpty ? name : "\(name) (\(keywords.joined(separator: ", ")))"
        }.joined(separator: ", ")

        let references = (source.references ?? []).compactMap { entry -> String? in
            let quote = entry.reference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let name = entry.name?.trimmingCharacters(in: .whitespaces) ?? ""
            switch (quote.isEmpty, name.isEmpty) {
            case (true, true): return nil
            case (true, false): return name
            case (false, true): return quote
            case (false, false): return "\(quote) — \(name)"
            }
        }.joined(separator: "\n")

        self.init(
            profile: profile,
            summary: basics.summary ?? "",
            experience: experience,
            education: education,
            skills: groups,
            projects: projects,
            volunteering: volunteering,
            certifications: certifications,
            publications: publications,
            awards: awards,
            languages: languages,
            interests: interests,
            references: references
        )
    }

    /// Two things on one line, either of which may be absent.
    private static func joined(_ first: String?, _ second: String?, with separator: String = " — ") -> String {
        let a = first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = second?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch (a.isEmpty, b.isEmpty) {
        case (true, true): return ""
        case (false, true): return a
        case (true, false): return b
        case (false, false): return a + separator + b
        }
    }

    /// "London, England" from the schema's five address fields.
    private static func place(_ location: JSONResume.Location?) -> String {
        guard let location else { return "" }
        let parts = [location.city, location.region ?? location.countryCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    /// "Bachelor of Science, Computer Science" — the degree and then the
    /// subject, which is how both a parser and a person expect to read it.
    private static func qualification(_ studyType: String?, _ area: String?) -> String {
        let degree = studyType?.trimmingCharacters(in: .whitespaces) ?? ""
        let subject = area?.trimmingCharacters(in: .whitespaces) ?? ""
        switch (degree.isEmpty, subject.isEmpty) {
        case (true, true): return ""
        case (false, true): return degree
        case (true, false): return subject
        case (false, false): return "\(degree), \(subject)"
        }
    }
}
