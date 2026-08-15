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
