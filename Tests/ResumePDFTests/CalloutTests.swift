//
//  CalloutTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Achievements, strengths, the time ring, language levels drawn, and the
//  two skill settings added with them.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class CalloutTests: XCTestCase {

    private func text(of resume: Resume, design: any Design = Blueprint.ledger) throws -> String {
        let data = try resume.render(design: design)
        return try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    private var withCallouts: Resume {
        Resume(
            profile: Profile(name: "Alex Moreau", email: "alex@moreau.dev"),
            summary: "Infrastructure engineer.",
            experience: [Position(role: "Engineer", organisation: "Stripe", dates: .since("2022"))],
            languages: [Language("English", "Native"), Language("French", "C1"), Language("Welsh", "some")],
            achievements: [
                Achievement(title: "Latency halved", summary: "p99 from 340ms to 45ms.", icon: "bolt"),
                Achievement(title: "Zero-downtime migration", summary: "Forty services, one weekend."),
                Achievement(title: "Paging cut 60%"),
            ],
            strengths: [Strength(title: "Calm under paging", summary: "Ran the channel for both big outages.")],
            time: [TimeSlice("Building", 40), TimeSlice("Reviewing", 25), TimeSlice("Incidents", 15), TimeSlice("Mentoring", 20)]
        )
    }

    // MARK: Language levels

    func testALevelsWordsAreWorthAKnownFractionOrNothing() {
        XCTAssertEqual(LanguageLevels.fraction(for: "Native"), 1.0)
        XCTAssertEqual(LanguageLevels.fraction(for: "native speaker"), 1.0)
        XCTAssertEqual(LanguageLevels.fraction(for: "C1"), 0.8)
        XCTAssertEqual(LanguageLevels.fraction(for: "Fluent (business)"), 0.8)
        XCTAssertEqual(LanguageLevels.fraction(for: "B2"), 0.6)
        XCTAssertEqual(LanguageLevels.fraction(for: "Conversational"), 0.6)
        XCTAssertEqual(LanguageLevels.fraction(for: "A1"), 0.2)
        XCTAssertEqual(LanguageLevels.fraction(for: "Muttersprache"), 1.0)
        // The important answer: words the scale does not know draw nothing.
        XCTAssertNil(LanguageLevels.fraction(for: "some"))
        XCTAssertNil(LanguageLevels.fraction(for: ""))
        XCTAssertNil(LanguageLevels.fraction(for: "Klingon-curious"))
    }

    // MARK: Time shares

    func testSharesAreWeightsAndPercentagesAddUpToAHundred() {
        let thirds = [TimeSlice("A", 1), TimeSlice("B", 1), TimeSlice("C", 1)]
        let percents = TimeShares.percentages(of: thirds).map(\.percent)
        XCTAssertEqual(percents.reduce(0, +), 100, "the rounding error goes to a slice, not to the total")
        XCTAssertEqual(Set(percents), [33, 34])

        let same = TimeShares.fractions(of: [TimeSlice("A", 3), TimeSlice("B", 2), TimeSlice("C", 1)]).map(\.fraction)
        let scaled = TimeShares.fractions(of: [TimeSlice("A", 50), TimeSlice("B", 33.33), TimeSlice("C", 16.67)]).map(\.fraction)
        for (a, b) in zip(same, scaled) { XCTAssertEqual(a, b, accuracy: 0.001) }

        XCTAssertTrue(TimeShares.fractions(of: [TimeSlice("Nothing", 0), TimeSlice("  ", 5)]).isEmpty,
                      "a weightless or nameless slice is dropped, and a ring of nothing is no ring")
        XCTAssertEqual(TimeShares.letter(0), "A")
        XCTAssertEqual(TimeShares.letter(5), "F")
    }

    // MARK: Rendering

    func testAchievementsStrengthsAndTimeAreDrawnAndReadable() throws {
        // Case-insensitively: a heading is set in capitals by most designs.
        let extracted = try text(of: withCallouts).lowercased()
        for word in ["Key Achievements", "Latency halved", "p99 from 340ms to 45ms.", "Paging cut 60%",
                     "Strengths", "Calm under paging",
                     "How I Split My Time", "Building", "40%", "Mentoring", "20%"] {
            XCTAssertTrue(extracted.contains(word.lowercased()), "missing \(word)")
        }
    }

    func testTheSectionsSurviveEveryDesignAndBothColumnWidths() throws {
        // Two abreast in a wide column, stacked in a side; a card per
        // achievement under a card design; nothing lost anywhere.
        for blueprint in Blueprint.starting {
            let extracted = try text(of: withCallouts, design: blueprint)
            XCTAssertTrue(extracted.contains("Latency halved"), blueprint.name)
            XCTAssertTrue(extracted.contains("Calm under paging"), blueprint.name)
            XCTAssertTrue(extracted.contains("Mentoring"), blueprint.name)
        }
    }

    func testAnUnnamedIconTakesTheCycleAndANamedOneIsKept() {
        XCTAssertEqual(Icon(rawValue: "bolt"), .bolt)
        XCTAssertNil(Icon(rawValue: ""), "empty resolves through the cycle, not to a mark called nothing")
        XCTAssertEqual(Icon.cycle.count, 4)
        XCTAssertTrue(Icon.cycle.allSatisfy { !$0.path.isEmpty })
    }

    func testTheFlatFormatsCarryThemToo() {
        let outline = withCallouts.outline()
        XCTAssertTrue(outline.contains(.heading("Key Achievements")))
        XCTAssertTrue(outline.contains { if case .leadIns(let items) = $0 { return items.contains { $0.lead == "Latency halved" } }; return false })
        XCTAssertTrue(outline.contains(.pair("Building", "40%")))

        let plain = withCallouts.plainText()
        XCTAssertTrue(plain.contains("Latency halved"))
        XCTAssertTrue(plain.contains("Mentoring"))
    }

    // MARK: Reading them in

    func testTheJSONShapeIsTheOneSomebodyWouldType() throws {
        let json = """
        {
          "profile": { "name": "Alex Moreau" },
          "achievements": [ { "title": "Latency halved", "summary": "p99 down 88%", "icon": "bolt" }, { "title": "Paging cut" } ],
          "strengths": [ { "title": "Calm" } ],
          "time": [ { "label": "Building", "share": 3 }, { "label": "Reviewing" } ],
          "custom": [ { "title": "Passions", "content": [ { "achievements": [ { "title": "Cycling", "icon": "heart" } ] } ] } ],
          "order": ["achievements", "strengths", "time", "custom:Passions"]
        }
        """
        let resume = try JSONDecoder().decode(Resume.self, from: XCTUnwrap(json.data(using: .utf8)))
        XCTAssertEqual(resume.achievements.count, 2)
        XCTAssertEqual(resume.achievements[1].icon, "", "a missing icon is empty, and the renderer cycles")
        XCTAssertEqual(resume.time[1].share, 1, "a slice with no share is one part")
        XCTAssertEqual(resume.populated(), [.achievements, .strengths, .time, .custom("Passions")])
        XCTAssertTrue(try text(of: resume).contains("Cycling"), "a custom section made of achievements renders as one")
    }

    func testTheBlueprintNamesTheNewSettings() throws {
        let blueprint = try JSONDecoder().decode(Blueprint.self, from: XCTUnwrap(
            #"{"name": "mine", "entries": {"skills": "underlined", "languages": "dots"}}"#.data(using: .utf8)))
        XCTAssertEqual(blueprint.entries.skills, .underlined)
        XCTAssertEqual(blueprint.entries.languages, .dots)
        XCTAssertNoThrow(try withCallouts.render(design: blueprint))

        var inline = blueprint; inline.entries.skills = .inline; inline.entries.languages = .bars
        XCTAssertNoThrow(try Resume.sample.render(design: inline))

        XCTAssertThrowsError(try JSONDecoder().decode(Blueprint.self, from: XCTUnwrap(
            #"{"entries": {"languages": "stars"}}"#.data(using: .utf8)))) {
            XCTAssertTrue("\($0)".contains("dots"), "it should list the real ones: \($0)")
        }
    }
}
