//
//  ModelTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import ResumePDF

final class ModelTests: XCTestCase {

    // MARK: Dates

    func testASingleDateIsNotOngoing() {
        // The bug this replaced: an absent end date was read as "still there",
        // so a project dated 2023 rendered as "2023 – Present" and claimed
        // something nobody wrote.
        XCTAssertEqual(DateRange("2023").rendered(), "2023")
        XCTAssertFalse(DateRange("2023").isCurrent)
    }

    func testSinceIsOngoing() {
        XCTAssertEqual(DateRange.since("Mar 2022").rendered(), "Mar 2022 – Present")
        XCTAssertTrue(DateRange.since("Mar 2022").isCurrent)
    }

    func testAClosedRangeRendersBothEnds() {
        XCTAssertEqual(DateRange("Jun 2019", "Feb 2022").rendered(), "Jun 2019 – Feb 2022")
    }

    func testTheOngoingWordIsTranslated() {
        // The data says "Present"; the document says whatever its labels do.
        let german = Labels.german
        XCTAssertEqual(
            DateRange.since("März 2022").rendered(present: german.present, dash: german.dateSeparator),
            "März 2022 – heute"
        )
    }

    func testOngoingIsRecognisedHoweverItIsWritten() {
        for word in ["Present", "present", "Current", "now", "heute", "Ongoing"] {
            XCTAssertTrue(DateRange("2022", word).isCurrent, "\"\(word)\" should read as ongoing")
        }
        XCTAssertFalse(DateRange("2022", "Feb 2024").isCurrent)
    }

    func testAnEmptyRangeIsEmpty() {
        XCTAssertTrue(DateRange("").isEmpty)
        XCTAssertFalse(DateRange("2023").isEmpty)
    }

    // MARK: Links

    func testLinksArePrintedWithoutTheirScheme() {
        XCTAssertEqual(Link("https://github.com/alexmoreau").label, "github.com/alexmoreau")
        XCTAssertEqual(Link("https://www.example.com/").label, "example.com")
        XCTAssertEqual(Link("http://example.com/a/b/").label, "example.com/a/b")
    }

    func testAnExplicitLabelWins() {
        XCTAssertEqual(Link("https://github.com/x", label: "GitHub").label, "GitHub")
    }

    func testTheAbsoluteFormKeepsAScheme() {
        XCTAssertEqual(Link("github.com/x").absolute, "https://github.com/x")
        XCTAssertEqual(Link("https://github.com/x").absolute, "https://github.com/x")
        XCTAssertEqual(Link("alex@moreau.dev").absolute, "mailto:alex@moreau.dev")
    }

    // MARK: Sections

    func testEmptySectionsAreDropped() {
        let resume = Resume(profile: Profile(name: "A"), experience: [Position(role: "Engineer")])
        let populated = resume.populated()

        XCTAssertEqual(populated, [.experience])
        XCTAssertFalse(populated.contains(.education))
        XCTAssertFalse(populated.contains(.summary))
    }

    func testOrderIsRespected() {
        let resume = Resume(
            profile: Profile(name: "A"),
            summary: "Something.",
            experience: [Position(role: "Engineer")],
            education: [Education(qualification: "BSc")],
            order: [.education, .experience, .summary]
        )
        XCTAssertEqual(resume.populated(), [.education, .experience, .summary])
    }

    func testGermanLabelsRenameTheSections() {
        let resume = Resume(profile: Profile(name: "A"), labels: .german)
        XCTAssertEqual(resume.heading(for: .experience), "Berufserfahrung")
        XCTAssertEqual(resume.heading(for: .education), "Ausbildung")
        XCTAssertEqual(Resume(profile: Profile(name: "A")).heading(for: .experience), "Experience")
    }

    func testOneHeadingCanBeRenamedWithoutTheRest() {
        let labels = Labels.english.naming(.experience, "Selected Work")
        XCTAssertEqual(labels.title(for: .experience), "Selected Work")
        XCTAssertEqual(labels.title(for: .education), "Education")
    }

    // MARK: Contact

    func testTheContactLineDropsWhatIsMissing() {
        let profile = Profile(name: "A", location: "London", email: "a@b.co")
        XCTAssertEqual(profile.contactLine(), ["a@b.co", "London"])
    }

    func testParticularsAreEmptyUnlessSet() {
        XCTAssertTrue(Profile(name: "A").particulars().isEmpty)

        let lebenslauf = Profile(name: "A", dateOfBirth: "4 März 1990", nationality: "Deutsch")
        XCTAssertEqual(lebenslauf.particulars().map(\.label), ["Date of birth", "Nationality"])
    }

    // MARK: Codable

    func testAResumeSurvivesJSON() throws {
        let encoded = try JSONEncoder().encode(Resume.sample)
        let decoded = try JSONDecoder().decode(Resume.self, from: encoded)
        XCTAssertEqual(decoded, Resume.sample)
    }

    func testThemeSurvivesJSON() throws {
        let theme = Theme(typeface: .sourceSerif, accent: "#1F3A5F", pageSize: .letter, density: .compact)
        let decoded = try JSONDecoder().decode(Theme.self, from: JSONEncoder().encode(theme))
        XCTAssertEqual(decoded, theme)
    }
}

// MARK: - JSON that leaves things out

extension ModelTests {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: XCTUnwrap(json.data(using: .utf8)))
    }

    func testAPositionNeedsOnlyItsRole() throws {
        // Swift's synthesised decoder ignores an initialiser's defaults, so a
        // type you can build in Swift with one argument used to need every key
        // spelled out in JSON. That is the difference between a schema
        // somebody writes by hand and one they give up on.
        let position = try decode(Position.self, #"{"role": "Engineer"}"#)

        XCTAssertEqual(position.role, "Engineer")
        XCTAssertEqual(position.organisation, "")
        XCTAssertTrue(position.highlights.isEmpty)
        XCTAssertTrue(position.dates.isEmpty)
    }

    func testEveryEntryTypeNeedsOnlyItsName() throws {
        XCTAssertEqual(try decode(Education.self, #"{"qualification":"BSc"}"#).qualification, "BSc")
        XCTAssertEqual(try decode(Project.self, #"{"name":"x"}"#).name, "x")
        XCTAssertEqual(try decode(Publication.self, #"{"title":"x"}"#).title, "x")
        XCTAssertEqual(try decode(Credential.self, #"{"name":"x"}"#).name, "x")
        XCTAssertEqual(try decode(Award.self, #"{"name":"x"}"#).name, "x")
        XCTAssertEqual(try decode(Grant.self, #"{"title":"x"}"#).title, "x")
        XCTAssertEqual(try decode(Profile.self, #"{"name":"Alex"}"#).name, "Alex")
    }

    func testTheIdentifyingFieldIsStillRequired() {
        // A position without a role is not a position. Defaulting it would
        // turn a typo into a blank line on somebody's résumé.
        XCTAssertThrowsError(try decode(Position.self, #"{"organisation": "Stripe"}"#))
        XCTAssertThrowsError(try decode(Profile.self, #"{"email": "a@b.co"}"#))
    }

    func testAResumeNeedsOnlyAProfile() throws {
        let resume = try decode(Resume.self, #"{"profile":{"name":"Alex Moreau"}}"#)

        XCTAssertEqual(resume.profile.name, "Alex Moreau")
        XCTAssertTrue(resume.experience.isEmpty)
        XCTAssertEqual(resume.order, Section.conventional)
        XCTAssertEqual(resume.labels.language, "en")
    }

    func testShorthandsForTheThingsWrittenMostOften() throws {
        // A date that is one date, a link that is one URL, a language that is
        // one language, and a whole label set named by its language code.
        XCTAssertEqual(try decode(DateRange.self, #""2023""#).rendered(), "2023")
        XCTAssertEqual(try decode(Link.self, #""https://github.com/x""#).label, "github.com/x")
        XCTAssertEqual(try decode(Language.self, #""English""#).name, "English")

        let german = try decode(Labels.self, #""de""#)
        XCTAssertEqual(german.title(for: .experience), "Berufserfahrung")
        XCTAssertEqual(german.present, "heute")
    }

    func testTheLongFormStillWorks() throws {
        XCTAssertEqual(
            try decode(DateRange.self, #"{"start":"Mar 2022","end":"Present"}"#).rendered(),
            "Mar 2022 – Present"
        )
        XCTAssertEqual(
            try decode(Link.self, #"{"url":"https://x.dev","label":"Portfolio"}"#).label,
            "Portfolio"
        )
    }

    func testALetterNeedsOnlyAProfile() throws {
        let letter = try decode(CoverLetter.self, #"{"profile":{"name":"Alex"}}"#)
        XCTAssertEqual(letter.profile.name, "Alex")
        XCTAssertTrue(letter.recipient.isEmpty)
        XCTAssertEqual(letter.signOff, "Yours faithfully,")
    }

    func testRoundTrippingStillWorks() throws {
        // Everything written out has to read back, or the encoder and the
        // hand-written decoders have drifted.
        let encoded = try JSONEncoder().encode(Resume.sample)
        XCTAssertEqual(try JSONDecoder().decode(Resume.self, from: encoded), Resume.sample)

        let letter = try JSONEncoder().encode(CoverLetter.sample)
        XCTAssertEqual(try JSONDecoder().decode(CoverLetter.self, from: letter), CoverLetter.sample)
    }
}
