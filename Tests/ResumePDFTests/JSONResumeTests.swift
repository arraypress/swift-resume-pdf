//
//  JSONResumeTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Reading the JSON Resume schema, checked against the schema project's own
//  sample file — the one every JSON Resume tool is tried on first, and so
//  the one a file in the wild most resembles.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class JSONResumeTests: XCTestCase {

    /// `sample.resume.json` from jsonresume/resume-schema, v1.0.0, verbatim.
    static let canonical = #"""
{
  "$schema": "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json",
  "basics": {
    "name": "Richard Hendriks",
    "label": "Programmer",
    "image": "",
    "email": "richard.hendriks@mail.com",
    "phone": "(912) 555-4321",
    "url": "http://richardhendricks.example.com",
    "summary": "Richard hails from Tulsa. He has earned degrees from the University of Oklahoma and Stanford. (Go Sooners and Cardinal!) Before starting Pied Piper, he worked for Hooli as a part time software developer. While his work focuses on applied information theory, mostly optimizing lossless compression schema of both the length-limited and adaptive variants, his non-work interests range widely, everything from quantum computing to chaos theory. He could tell you about it, but THAT would NOT be a “length-limited” conversation!",
    "location": {
      "address": "2712 Broadway St",
      "postalCode": "CA 94115",
      "city": "San Francisco",
      "countryCode": "US",
      "region": "California"
    },
    "profiles": [
      {
        "network": "Twitter",
        "username": "neutralthoughts",
        "url": "https://www.twitter.com"
      },
      {
        "network": "SoundCloud",
        "username": "dandymusicnl",
        "url": "https://soundcloud.example.com/dandymusicnl"
      }
    ]
  },
  "work": [
    {
      "name": "Pied Piper",
      "location": "Palo Alto, CA",
      "description": "Awesome compression company",
      "position": "CEO/President",
      "url": "http://piedpiper.example.com",
      "startDate": "2013-12-01",
      "endDate": "2014-12-01",
      "summary": "Pied Piper is a multi-platform technology based on a proprietary universal compression algorithm that has consistently fielded high Weisman Scores™ that are not merely competitive, but approach the theoretical limit of lossless compression.",
      "highlights": [
        "Build an algorithm for artist to detect if their music was violating copy right infringement laws",
        "Successfully won Techcrunch Disrupt",
        "Optimized an algorithm that holds the current world record for Weisman Scores"
      ]
    }
  ],
  "volunteer": [
    {
      "organization": "CoderDojo",
      "position": "Teacher",
      "url": "http://coderdojo.example.com/",
      "startDate": "2012-01-01",
      "endDate": "2013-01-01",
      "summary": "Global movement of free coding clubs for young people.",
      "highlights": [
        "Awarded 'Teacher of the Month'"
      ]
    }
  ],
  "education": [
    {
      "institution": "University of Oklahoma",
      "url": "https://www.ou.edu/",
      "area": "Information Technology",
      "studyType": "Bachelor",
      "startDate": "2011-06-01",
      "endDate": "2014-01-01",
      "score": "4.0",
      "courses": [
        "DB1101 - Basic SQL",
        "CS2011 - Java Introduction"
      ]
    }
  ],
  "awards": [
    {
      "title": "Digital Compression Pioneer Award",
      "date": "2014-11-01",
      "awarder": "Techcrunch",
      "summary": "There is no spoon."
    }
  ],
  "publications": [
    {
      "name": "Video compression for 3d media",
      "publisher": "Hooli",
      "releaseDate": "2014-10-01",
      "url": "http://en.wikipedia.org/wiki/Silicon_Valley_(TV_series)",
      "summary": "Innovative middle-out compression algorithm that changes the way we store data."
    }
  ],
  "skills": [
    {
      "name": "Web Development",
      "level": "Master",
      "keywords": [
        "HTML",
        "CSS",
        "Javascript"
      ]
    },
    {
      "name": "Compression",
      "level": "Master",
      "keywords": [
        "Mpeg",
        "MP4",
        "GIF"
      ]
    }
  ],
  "languages": [
    {
      "language": "English",
      "fluency": "Native speaker"
    }
  ],
  "interests": [
    {
      "name": "Wildlife",
      "keywords": [
        "Ferrets",
        "Unicorns"
      ]
    }
  ],
  "references": [
    {
      "name": "Erlich Bachman",
      "reference": "It is my pleasure to recommend Richard, his performance working as a consultant for Main St. Company proved that he will be a valuable addition to any company."
    }
  ],
  "projects": [
    {
      "name": "Miss Direction",
      "description": "A mapping engine that misguides you",
      "highlights": [
        "Won award at AIHacks 2016",
        "Built by all women team of newbie programmers",
        "Using modern technologies such as GoogleMaps, Chrome Extension and Javascript"
      ],
      "keywords": [
        "GoogleMaps", "Chrome Extension", "Javascript"
      ],
      "startDate": "2016-08-24",
      "endDate": "2016-08-24",
      "url": "http://missdirection.example.com",
      "roles": [
        "Team lead", "Designer"
      ],
      "entity": "Smoogle",
      "type": "application"
    }
  ],
  "meta": {
    "canonical": "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/sample.resume.json",
    "version": "v1.0.0",
    "lastModified": "2017-12-24T15:53:00"
  }
}
"""#

    private func canonical() throws -> Resume {
        try Resume(jsonResumeData: Data(Self.canonical.utf8))
    }

    private func read(_ json: String) throws -> Resume {
        try Resume(jsonResumeData: Data(json.utf8))
    }

    // MARK: Telling the shapes apart

    func testAJSONResumeIsRecognisedByItsBasics() {
        XCTAssertTrue(JSONResume.looksLikeOne(Data(Self.canonical.utf8)))
        XCTAssertFalse(JSONResume.looksLikeOne(Data(#"{"profile":{"name":"A"},"summary":"x"}"#.utf8)),
                       "the library's own shape is not a JSON Resume")
        XCTAssertFalse(JSONResume.looksLikeOne(Data("not json".utf8)))
        XCTAssertFalse(JSONResume.looksLikeOne(Data("[]".utf8)))
    }

    // MARK: The sample, field by field

    func testBasicsBecomeTheProfile() throws {
        let resume = try canonical()
        let profile = resume.profile

        XCTAssertEqual(profile.name, "Richard Hendriks")
        XCTAssertEqual(profile.headline, "Programmer")
        XCTAssertEqual(profile.email, "richard.hendriks@mail.com")
        XCTAssertEqual(profile.phone, "(912) 555-4321")
        // City and region; the street address and postcode are left behind.
        XCTAssertEqual(profile.location, "San Francisco, California")
        XCTAssertTrue(resume.summary.hasPrefix("Richard hails from Tulsa."))
    }

    func testTheURLAndTheProfilesBecomeLinks() throws {
        let links = try canonical().profile.links.map(\.url)
        XCTAssertEqual(links.count, 3)
        XCTAssertEqual(links[0], "http://richardhendricks.example.com")
        XCTAssertTrue(links.contains("https://soundcloud.example.com/dandymusicnl"))
    }

    func testAProfileWithoutAURLIsLeftOut() throws {
        let resume = try read(#"{"basics":{"name":"A","profiles":[{"network":"Twitter","username":"a"}]}}"#)
        XCTAssertTrue(resume.profile.links.isEmpty, "a network and a username make no address to print")
    }

    func testWorkBecomesExperience() throws {
        let job = try XCTUnwrap(try canonical().experience.first)
        XCTAssertEqual(job.role, "CEO/President")
        XCTAssertEqual(job.organisation, "Pied Piper")
        XCTAssertEqual(job.location, "Palo Alto, CA")
        XCTAssertEqual(job.dates.start, "Dec 2013")
        XCTAssertEqual(job.dates.end, "Dec 2014")
        XCTAssertEqual(job.highlights.count, 3)
        XCTAssertTrue(job.summary.hasPrefix("Awesome compression company — Pied Piper is a multi-platform"))
    }

    func testAJobWithNoEndDateIsCurrent() throws {
        let job = try XCTUnwrap(
            try read(#"{"work":[{"name":"Hooli","position":"Dev","startDate":"2020-05"}]}"#).experience.first
        )
        XCTAssertEqual(job.dates.start, "May 2020")
        XCTAssertTrue(job.dates.isCurrent, "the schema leaves endDate out for a current job")
    }

    func testTheOldCompanySpellingIsRead() throws {
        let job = try XCTUnwrap(
            try read(#"{"work":[{"company":"Hooli","position":"Dev"}]}"#).experience.first
        )
        XCTAssertEqual(job.organisation, "Hooli")
    }

    func testVolunteerBecomesVolunteering() throws {
        let post = try XCTUnwrap(try canonical().volunteering.first)
        XCTAssertEqual(post.organisation, "CoderDojo")
        XCTAssertEqual(post.role, "Teacher")
        XCTAssertEqual(post.highlights, ["Awarded 'Teacher of the Month'"])
    }

    func testEducationCarriesTheDegreeThenTheSubject() throws {
        let degree = try XCTUnwrap(try canonical().education.first)
        XCTAssertEqual(degree.qualification, "Bachelor, Information Technology")
        XCTAssertEqual(degree.institution, "University of Oklahoma")
        XCTAssertEqual(degree.grade, "4.0")
        XCTAssertEqual(degree.dates.start, "Jun 2011")
        XCTAssertEqual(degree.dates.end, "Jan 2014")
        XCTAssertEqual(degree.highlights.count, 2, "courses are the closest thing to highlights")
    }

    func testSkillsWithKeywordsAreGroups() throws {
        let skills = try canonical().skills
        XCTAssertEqual(skills.map(\.name), ["Web Development", "Compression"])
        XCTAssertEqual(skills[0].names, ["HTML", "CSS", "Javascript"])
    }

    func testSkillsWithoutKeywordsAreGatheredUnderOneHeading() throws {
        let skills = try read(#"{"skills":[{"name":"Go"},{"name":"Rust","level":"Expert"}]}"#).skills
        XCTAssertEqual(skills.count, 1)
        XCTAssertEqual(skills[0].name, "Skills")
        XCTAssertEqual(skills[0].names, ["Go", "Rust"])
    }

    func testProjectsKeepTheirRolesLinkAndKeywords() throws {
        let project = try XCTUnwrap(try canonical().projects.first)
        XCTAssertEqual(project.name, "Miss Direction")
        XCTAssertEqual(project.role, "Team lead, Designer · Smoogle")
        XCTAssertEqual(project.link?.url, "http://missdirection.example.com")
        XCTAssertEqual(project.skills, ["GoogleMaps", "Chrome Extension", "Javascript"])
        XCTAssertEqual(project.summary, "A mapping engine that misguides you")
        // Started and finished on the same day: one date, not "Aug 2016 – Aug 2016".
        XCTAssertEqual(project.dates.rendered(), "Aug 2016")
    }

    func testTheRestOfTheSections() throws {
        let resume = try canonical()

        XCTAssertEqual(resume.awards.first?.name, "Digital Compression Pioneer Award")
        XCTAssertEqual(resume.awards.first?.issuer, "Techcrunch")
        XCTAssertEqual(resume.awards.first?.date, "Nov 2014")

        XCTAssertEqual(resume.publications.first?.title, "Video compression for 3d media")
        XCTAssertEqual(resume.publications.first?.venue, "Hooli")
        XCTAssertEqual(resume.publications.first?.date, "Oct 2014")
        XCTAssertNotNil(resume.publications.first?.link)

        XCTAssertEqual(resume.languages.first?.name, "English")
        XCTAssertEqual(resume.languages.first?.level, "Native speaker")

        XCTAssertEqual(resume.interests, "Wildlife (Ferrets, Unicorns)")
        XCTAssertTrue(resume.references.hasPrefix("It is my pleasure to recommend Richard"))
        XCTAssertTrue(resume.references.hasSuffix("— Erlich Bachman"))
    }

    func testCertificatesBecomeCertifications() throws {
        let resume = try read(
            #"{"certificates":[{"name":"CKA","date":"2021-11-07","issuer":"CNCF","url":"https://x.y"}]}"#
        )
        XCTAssertEqual(resume.certifications.first?.name, "CKA")
        XCTAssertEqual(resume.certifications.first?.issuer, "CNCF")
        XCTAssertEqual(resume.certifications.first?.date, "Nov 2021")
    }

    // MARK: Dates

    func testISODatesBecomeTheOnesARésuméPrints() {
        XCTAssertEqual(JSONResume.date("2022-03-15"), "Mar 2022")
        XCTAssertEqual(JSONResume.date("2022-03"), "Mar 2022")
        XCTAssertEqual(JSONResume.date("2022"), "2022")
        XCTAssertEqual(JSONResume.date("2022-13"), "2022", "a month that does not exist is dropped")
        XCTAssertEqual(JSONResume.date("Summer 2019"), "Summer 2019", "what somebody typed is kept")
        XCTAssertEqual(JSONResume.date(""), "")
        XCTAssertEqual(JSONResume.date(nil), "")
    }

    // MARK: Tolerance

    func testUnknownKeysAndAnEmptyFileAreNotErrors() throws {
        XCTAssertNoThrow(try read(#"{"basics":{"name":"A"},"meta":{"version":"v1.0.0"},"$schema":"x","extra":1}"#))
        let empty = try read("{}")
        XCTAssertEqual(empty.profile.name, "")
        XCTAssertTrue(empty.populated().isEmpty)
    }

    func testAFileThatIsNotJSONIsAnError() {
        XCTAssertThrowsError(try read("not json"))
    }

    // MARK: The whole thing, rendered

    func testTheSampleRendersAndChecksClean() throws {
        let resume = try canonical()
        let data = try resume.render(design: .ledger)
        let text = try XCTUnwrap(PDFDocument(data: data)?.string)

        XCTAssertTrue(text.contains("Richard Hendriks"))
        XCTAssertTrue(text.contains("Pied Piper"))
        XCTAssertTrue(text.contains("CoderDojo"))
        XCTAssertTrue(text.contains("University of Oklahoma"))

        let report = try resume.check(design: .ledger)
        XCTAssertTrue(report.isClean, report.findings.map(\.message).joined(separator: "; "))
    }
}

// MARK: - The whole schema

extension JSONResumeTests {

    /// Every property the v1.0.0 `schema.json` declares, section by section,
    /// copied from the schema rather than from memory.
    static let schema: [String: [String]] = [
        "basics": ["email", "image", "label", "location", "name", "phone", "profiles", "summary", "url"],
        "basics.location": ["address", "city", "countryCode", "postalCode", "region"],
        "basics.profiles[]": ["network", "url", "username"],
        "work[]": ["description", "endDate", "highlights", "location", "name", "position", "startDate", "summary", "url"],
        "volunteer[]": ["endDate", "highlights", "organization", "position", "startDate", "summary", "url"],
        "education[]": ["area", "courses", "endDate", "institution", "score", "startDate", "studyType", "url"],
        "awards[]": ["awarder", "date", "summary", "title"],
        "certificates[]": ["date", "issuer", "name", "url"],
        "publications[]": ["name", "publisher", "releaseDate", "summary", "url"],
        "skills[]": ["keywords", "level", "name"],
        "languages[]": ["fluency", "language"],
        "interests[]": ["keywords", "name"],
        "references[]": ["name", "reference"],
        "projects[]": ["description", "endDate", "entity", "highlights", "keywords", "name", "roles", "startDate", "type", "url"],
        "meta": ["canonical", "lastModified", "version"],
    ]

    static let topLevel = ["$schema", "awards", "basics", "certificates", "education", "interests", "languages",
                           "meta", "projects", "publications", "references", "skills", "volunteer", "work"]

    /// A value of the right shape for a property, so a file with every
    /// property filled can be built from the lists above.
    private static func value(for property: String, in section: String) -> Any {
        switch property {
        case "highlights", "courses", "keywords", "roles": return ["x", "y"]
        case "profiles": return [["network": "n", "username": "u", "url": "https://example.com/u"]]
        // An object under basics; a string on a job.
        case "location" where section == "basics":
            return ["address": "a", "postalCode": "p", "city": "c", "countryCode": "cc", "region": "r"]
        default: return "value of \(property)"
        }
    }

    private static func fullFile() -> [String: Any] {
        var file: [String: Any] = ["$schema": "https://example.com/schema.json"]
        for key in topLevel where key != "$schema" {
            if let properties = schema["\(key)[]"] {
                file[key] = [Dictionary(uniqueKeysWithValues: properties.map { ($0, value(for: $0, in: key)) })]
            } else if let properties = schema[key] {
                file[key] = Dictionary(uniqueKeysWithValues: properties.map { ($0, value(for: $0, in: key)) })
            }
        }
        return file
    }

    /// Decoding and re-encoding a file with every property set must give
    /// back every property: anything the struct does not declare would be
    /// silently dropped on the way through, and that is the fault this
    /// test exists to catch when the schema gains a field.
    func testEveryPropertyInTheSchemaIsDecoded() throws {
        let data = try JSONSerialization.data(withJSONObject: Self.fullFile())
        let decoded = try JSONResume(data: data)
        let encoded = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(decoded)) as! [String: Any]

        XCTAssertEqual(Set(encoded.keys), Set(Self.topLevel), "top-level keys")

        for (section, properties) in Self.schema {
            let object: [String: Any]
            switch section {
            case "basics.location":
                object = (encoded["basics"] as! [String: Any])["location"] as! [String: Any]
            case "basics.profiles[]":
                object = ((encoded["basics"] as! [String: Any])["profiles"] as! [[String: Any]])[0]
            case let name where name.hasSuffix("[]"):
                object = (encoded[String(name.dropLast(2))] as! [[String: Any]])[0]
            default:
                object = encoded[section] as! [String: Any]
            }
            XCTAssertEqual(Set(object.keys), Set(properties), section)
        }
    }

    func testTheCanonicalSampleSurvivesARoundTrip() throws {
        let once = try JSONResume(data: Data(Self.canonical.utf8))
        let twice = try JSONDecoder().decode(JSONResume.self, from: try JSONEncoder().encode(once))
        XCTAssertEqual(once, twice)
        XCTAssertEqual(once.meta?.version, "v1.0.0")
        XCTAssertEqual(once.schema, "https://raw.githubusercontent.com/jsonresume/resume-schema/v1.0.0/schema.json")
        XCTAssertEqual(once.basics?.location?.address, "2712 Broadway St", "read even though it is not printed")
        XCTAssertEqual(once.work?.first?.description, "Awesome compression company")
    }

    // MARK: Where each property lands

    func testAWorkDescriptionJoinsTheSummary() throws {
        let job = try XCTUnwrap(try canonical().experience.first)
        XCTAssertTrue(job.summary.hasPrefix("Awesome compression company — Pied Piper is"), job.summary)

        let alone = try XCTUnwrap(
            try read(#"{"work":[{"name":"X","position":"Dev","description":"A widget shop"}]}"#).experience.first
        )
        XCTAssertEqual(alone.summary, "A widget shop")
    }

    func testAProjectEntityRidesOnTheRole() throws {
        XCTAssertEqual(try canonical().projects.first?.role, "Team lead, Designer · Smoogle")
        XCTAssertEqual(try read(#"{"projects":[{"name":"P","entity":"Acme"}]}"#).projects.first?.role, "Acme")
    }

    func testWhatIsDeliberatelyNotPrinted() throws {
        let resume = try canonical()
        let text = resume.searchableText
        XCTAssertFalse(text.contains("2712 Broadway St"), "street address")
        XCTAssertFalse(text.contains("CA 94115"), "postcode")
        XCTAssertFalse(text.contains("Master"), "skill level")
        XCTAssertFalse(text.contains("Innovative middle-out"), "publication summary")
        XCTAssertFalse(text.contains("application"), "project type")
        // …and what is kept that might look like the same category.
        XCTAssertTrue(text.contains("San Francisco, California"))
        XCTAssertTrue(text.contains("Smoogle"))
        XCTAssertTrue(text.contains("DB1101 - Basic SQL"), "courses are highlights")
    }
}
