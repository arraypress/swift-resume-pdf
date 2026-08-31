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
}
