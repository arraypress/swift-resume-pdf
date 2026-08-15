//
//  BlueprintTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class BlueprintTests: XCTestCase {

    private func decode(_ json: String) throws -> Blueprint {
        try JSONDecoder().decode(Blueprint.self, from: XCTUnwrap(json.data(using: .utf8)))
    }

    private func text(of data: Data) throws -> String {
        try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    // MARK: Writing one by hand

    func testTheSmallestBlueprintIsANameAndNothingElse() throws {
        // The whole point of the format. Swift's synthesised decoder would
        // demand all thirty-odd keys to say "the default, called mine".
        let blueprint = try decode(#"{"name": "mine"}"#)

        XCTAssertEqual(blueprint.name, "mine")
        XCTAssertEqual(blueprint.heading.style, .ruled)
        XCTAssertEqual(blueprint.entries.skills, .list)
        XCTAssertEqual(blueprint.ornament, .none)
        XCTAssertNoThrow(try Resume.sample.render(design: blueprint))
    }

    func testEvenTheNameCanBeLeftOut() throws {
        XCTAssertEqual(try decode("{}").name, "custom")
    }

    func testOneChangeIsOneKey() throws {
        let blueprint = try decode("""
            { "name": "mine", "heading": { "style": "marker" }, "entries": { "skills": "chips" } }
            """)

        XCTAssertEqual(blueprint.heading.style, .marker)
        XCTAssertEqual(blueprint.entries.skills, .chips)
        XCTAssertEqual(blueprint.heading.size, Blueprint.Heading().size, "the rest should be left alone")
        XCTAssertEqual(blueprint.entries.roleSize, Blueprint.Entries().roleSize)
    }

    func testARuleIsKeptUnlessItIsRefused() throws {
        // Absent means "as it comes"; null means "not that". The difference
        // matters for anything whose default is on.
        XCTAssertNotNil(try decode(#"{"masthead": {"nameSize": 30}}"#).masthead.rule)
        XCTAssertNil(try decode(#"{"masthead": {"rule": null}}"#).masthead.rule)
    }

    // MARK: Being told what is wrong

    func testAMisspelledChoiceNamesTheRealOnes() {
        XCTAssertThrowsError(try decode(#"{"heading": {"style": "tabbed"}}"#)) {
            let message = "\($0)"
            XCTAssertTrue(message.contains("no heading style called"), message)
            XCTAssertTrue(message.contains("marker"), "it should list them: \(message)")
        }

        XCTAssertThrowsError(try decode(#"{"ornament": "stripes"}"#)) {
            XCTAssertTrue("\($0)".contains("bands"), "\($0)")
        }
    }

    func testAFieldOfTheWrongTypeIsAnError() {
        XCTAssertThrowsError(try decode(#"{"sectionGap": "wide"}"#))
        XCTAssertThrowsError(try decode(#"{"masthead": {"nameSize": "big"}}"#))
    }

    // MARK: Colours

    func testColoursAreNamedOrGiven() throws {
        let blueprint = try decode(##"{"heading": {"colour": "#B00020"}}"##)
        XCTAssertEqual(blueprint.heading.colour.rawValue, "#B00020")
        XCTAssertTrue(blueprint.heading.colour.isValid)

        XCTAssertTrue(Blueprint.Paint.accent.isValid)
        XCTAssertFalse(Blueprint.Paint(rawValue: "burgundy").isValid)
    }

    func testANamedColourFollowsTheTheme() throws {
        // A blueprint saying "accent" has to work under whatever accent
        // somebody sets, or it is a design with one colour pinned into it.
        let blueprint = Blueprint(name: "mine", heading: Blueprint.Heading(colour: .accent))

        let red = try Resume.sample.render(design: blueprint, theme: Theme(accent: "#B00020"))
        let blue = try Resume.sample.render(design: blueprint, theme: Theme(accent: "#1F3A5F"))

        XCTAssertNotEqual(red, blue, "the accent made no difference")
    }

    // MARK: Rendering

    func testEveryStartingBlueprintRenders() throws {
        for blueprint in Blueprint.starting {
            let data = try Resume.sample.render(design: blueprint)
            XCTAssertNotNil(PDFDocument(data: data), "\(blueprint.name) did not produce a PDF")
            XCTAssertTrue(try text(of: data).contains("Alex Moreau"), blueprint.name)
        }
    }

    func testABlueprintLosesNothingTheDefaultDesignPrints() throws {
        // A design is a way of setting a document, not a way of dropping parts
        // of it. Whatever ledger prints, a blueprint prints.
        let compiled = try text(of: try Resume.sample.render(design: .ledger))

        for blueprint in Blueprint.starting {
            let written = try text(of: try Resume.sample.render(design: blueprint))

            for word in ["Stripe", "Monzo", "BSc Computer Science", "Kubernetes", "ledgerfuzz"] {
                XCTAssertTrue(written.contains(word), "\(blueprint.name) dropped \"\(word)\"")
            }
            XCTAssertTrue(compiled.contains("Stripe"))
        }
    }

    func testEveryStartingBlueprintIsMachineReadable() throws {
        // The property that makes this format safe to hand somebody: a design
        // written as data cannot accidentally produce a document a tracking
        // system cannot read, because there is no way to say "two columns".
        for blueprint in Blueprint.starting {
            let report = try Resume.sample.check(design: blueprint)
            XCTAssertTrue(report.isClean, "\(blueprint.name): \(report.findings.map(\.message))")
        }
    }

    func testASkippedSectionIsNotDrawn() throws {
        var blueprint = Blueprint.ledger
        blueprint.skip = [.summary]

        let written = try text(of: try Resume.sample.render(design: blueprint))
        XCTAssertFalse(written.contains(Resume.sample.summary), "the skipped section was drawn anyway")
        XCTAssertTrue(written.contains("Stripe"), "it skipped more than it was told to")
    }

    func testShadingSurvivesAPageBreak() throws {
        // A rectangle whose corners are on different sheets of paper is not a
        // shape. The bands are dropped rather than drawn wrong.
        let long = Resume(
            profile: Resume.sample.profile,
            experience: Array(repeating: Resume.sample.experience, count: 6).flatMap { $0 }
        )

        for ornament in [Blueprint.Ornament.bands, .cards] {
            var blueprint = Blueprint.ledger
            blueprint.ornament = ornament

            let data = try long.render(design: blueprint)
            let document = try XCTUnwrap(PDFDocument(data: data))
            XCTAssertGreaterThan(document.pageCount, 1, "the fixture should run over a page")
            XCTAssertTrue(try text(of: data).contains("Stripe"))
        }
    }

    func testAPanelMastheadStaysReadableUnderAPaleAccent() throws {
        // Reversing white out of a pale accent is the commonest fault in this
        // shape of design, and it is one a blueprint author cannot see until
        // somebody else renders it under their own colour.
        var blueprint = Blueprint.plaqued

        for accent in ["#F2E8A0", "#111111", "#1F3A5F"] {
            blueprint.masthead.panel = Blueprint.Panel()
            let data = try Resume.sample.render(design: blueprint, theme: Theme(accent: accent))
            XCTAssertTrue(try text(of: data).contains("Alex Moreau"), "accent \(accent)")
        }
    }

    // MARK: Round trip

    func testABlueprintSurvivesJSON() throws {
        for blueprint in Blueprint.starting {
            let encoded = try blueprint.encoded()
            XCTAssertEqual(try JSONDecoder().decode(Blueprint.self, from: encoded), blueprint,
                           blueprint.name)
        }
    }

    func testWhatItWritesIsWhatItDocuments() throws {
        let written = try XCTUnwrap(String(data: try Blueprint.register.encoded(), encoding: .utf8))

        XCTAssertTrue(written.contains("\"ornament\" : \"bands\""), written)
        XCTAssertTrue(written.contains("\"style\" : \"margin\""), written)
        XCTAssertFalse(written.contains("_0"), "an enum leaked its synthesised shape")
    }

    func testABlueprintReadsFromAFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).json")
        try Blueprint.marked.encoded().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(try Blueprint(contentsOf: url), Blueprint.marked)
    }

    // MARK: The starting points

    func testTheStartingPointsAreDistinct() throws {
        // Eight names that produce the same file would be eight of nothing.
        // Compared as documents rather than as text: a panel or a band is a
        // real difference that extracts to the same words.
        var seen: Set<Data> = []
        for blueprint in Blueprint.starting {
            let data = try Resume.sample.render(design: blueprint)
            XCTAssertTrue(seen.insert(data).inserted, "\(blueprint.name) renders identically to another")
        }
        XCTAssertEqual(Set(Blueprint.starting.map(\.name)).count, Blueprint.starting.count)
    }
}
