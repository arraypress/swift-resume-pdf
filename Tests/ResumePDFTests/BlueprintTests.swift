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

// MARK: - Letters written as data

final class LetterBlueprintTests: XCTestCase {

    private func decode(_ json: String) throws -> LetterBlueprint {
        try JSONDecoder().decode(LetterBlueprint.self, from: XCTUnwrap(json.data(using: .utf8)))
    }

    private func text(of data: Data) throws -> String {
        try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    func testTheSmallestLetterDesignIsANameAndNothingElse() throws {
        let blueprint = try decode(#"{"name": "mine"}"#)

        XCTAssertEqual(blueprint.name, "mine")
        XCTAssertEqual(blueprint.masthead.contacts, .flow)
        XCTAssertEqual(blueprint.masthead.finish, .rule)
        XCTAssertNoThrow(try CoverLetter.sample.render(design: blueprint))
    }

    func testOneChangeIsOneKey() throws {
        let blueprint = try decode(#"{"masthead": {"contacts": "panel", "finish": "none"}}"#)

        XCTAssertEqual(blueprint.masthead.contacts, .panel)
        XCTAssertEqual(blueprint.masthead.finish, .none)
        XCTAssertEqual(blueprint.masthead.nameSize, LetterBlueprint.Masthead().nameSize)
    }

    func testAMisspelledChoiceNamesTheRealOnes() {
        XCTAssertThrowsError(try decode(#"{"masthead": {"contacts": "sidebar"}}"#)) {
            let message = "\($0)"
            XCTAssertTrue(message.contains("no contact arrangement called"), message)
            XCTAssertTrue(message.contains("ranged"), message)
        }

        XCTAssertThrowsError(try decode(#"{"masthead": {"finish": "squiggle"}}"#)) {
            XCTAssertTrue("\($0)".contains("capped"), "\($0)")
        }
    }

    func testEveryStartingPointRenders() throws {
        for blueprint in LetterBlueprint.starting {
            let data = try CoverLetter.sample.render(design: blueprint)
            XCTAssertNotNil(PDFDocument(data: data), blueprint.name)

            let written = try text(of: data)
            XCTAssertTrue(written.contains("Alex Moreau"), blueprint.name)
            XCTAssertTrue(written.contains("Okonkwo"), "\(blueprint.name) lost the recipient")
            XCTAssertTrue(written.contains("Yours sincerely"), "\(blueprint.name) lost the sign-off")
        }
    }

    func testEveryContactArrangementDrawsTheContacts() throws {
        // Except the one that says it does not.
        for contacts in LetterBlueprint.Masthead.Contacts.allCases {
            var blueprint = LetterBlueprint.memo
            blueprint.masthead.contacts = contacts

            let written = try text(of: try CoverLetter.sample.render(design: blueprint))
            XCTAssertEqual(
                written.contains("alex@moreau.dev"), contacts != .none,
                "\(contacts.rawValue)"
            )
        }
    }

    func testTheBodyIsTheSameWhateverTheHead() throws {
        // The shape of a letter is not a setting: the recipient, the argument
        // and the sign-off are the same in every design, and a blueprint that
        // could move them would be a way of writing a letter that is not one.
        let bodies = try LetterBlueprint.starting.map { blueprint -> String in
            let written = try text(of: try CoverLetter.sample.render(design: blueprint))
            guard let start = written.range(of: "Dear") else { return written }
            return String(written[start.lowerBound...])
        }

        for body in bodies.dropFirst() {
            XCTAssertEqual(body, bodies[0], "the body differed between designs")
        }
    }

    func testAPhotographIsOnlyDrawnWhenAsked() throws {
        let letter = CoverLetter(
            profile: Profile(name: "Alex Moreau", email: "a@b.co", photo: Fixtures.photoPath),
            recipient: Recipient(name: "Ms Okonkwo"),
            body: ["A paragraph long enough to be one rather than a line of text."]
        )

        var withPhoto = LetterBlueprint.memo
        withPhoto.masthead.photo = Blueprint.Photo(diameter: 70)

        let drawn = try XCTUnwrap(String(data: try letter.render(design: withPhoto), encoding: .isoLatin1))
        XCTAssertTrue(drawn.contains("/DCTDecode"), "asked for a portrait and drew none")

        let plain = try XCTUnwrap(String(data: try letter.render(design: .memo), encoding: .isoLatin1))
        XCTAssertFalse(plain.contains("/DCTDecode"), "drew a portrait it was not asked for")
    }

    func testALetterBlueprintIsCheckedLikeAnyOther() throws {
        for blueprint in LetterBlueprint.starting {
            let report = try CoverLetter.sample.check(design: blueprint)
            XCTAssertEqual(report.design, blueprint.name)
            XCTAssertTrue(report.isClean, "\(blueprint.name): \(report.findings.map(\.message))")
        }
    }

    func testItSurvivesJSON() throws {
        for blueprint in LetterBlueprint.starting {
            let decoded = try JSONDecoder().decode(
                LetterBlueprint.self, from: try blueprint.encoded()
            )
            XCTAssertEqual(decoded, blueprint, blueprint.name)
        }
    }

    func testItSaysWhichResumeDesignItSitsBeside() throws {
        // The two documents arrive in the same email.
        XCTAssertEqual(LetterBlueprint.letterheaded.pairsWith, .broadsheet)
        XCTAssertEqual(try decode(#"{"pairsWith": "swiss"}"#).pairsWith, .swiss)
    }
}

// MARK: - The parts that were not expressible

extension BlueprintTests {

    func testADesignCanAskForTheSerif() throws {
        // broadsheet's identity is that it is set in a serif. Written as data
        // it came out in the default grotesque, which is a different document.
        XCTAssertEqual(Blueprint.broadsheet.typeface, .serif)
        XCTAssertEqual(Blueprint.broadsheet.typeface.typeface, .sourceSerif)
        XCTAssertEqual(try decode(#"{"typeface": "serif"}"#).typeface, .serif)
        XCTAssertEqual(try decode("{}").typeface, .sans, "the default should be the sans")
    }

    func testAMisspelledTypefaceNamesTheOnesThereAre() {
        XCTAssertThrowsError(try decode(#"{"typeface": "helvetica"}"#)) {
            XCTAssertTrue("\($0)".contains("serif"), "\($0)")
        }
    }

    func testTheMonospacedMastheadUsesTheMono() throws {
        var blueprint = Blueprint.ledger
        blueprint.masthead.monospaced = true

        let mono = try Resume.sample.render(design: blueprint)
        let proportional = try Resume.sample.render(design: .ledger)

        XCTAssertNotEqual(mono, proportional, "monospaced changed nothing")
        XCTAssertTrue(try text(of: mono).contains("Alex Moreau"))
        XCTAssertTrue(try text(of: mono).contains("alex@moreau.dev"), "the contacts went missing")
    }

    func testTheTerminalHeadingIsMonoAndStillReads() throws {
        var blueprint = Blueprint.ledger
        blueprint.heading.style = .terminal

        let written = try text(of: try Resume.sample.render(design: blueprint))
        XCTAssertTrue(written.contains("EXPERIENCE"), "the heading went missing")
        XCTAssertTrue(written.contains("Stripe"))
    }

    func testTheRailDrawsDatesOnceAndOnlyWhereTheyBelong() throws {
        let written = try text(of: try Resume.sample.render(design: Blueprint.railed))

        // Drawn by the rail, so the blocks must not print them as well.
        let dates = written.components(separatedBy: "Mar 2022 – Present").count - 1
        XCTAssertEqual(dates, 1, "the dates were printed twice")

        XCTAssertTrue(written.contains("Stripe"))
        XCTAssertTrue(written.contains("Kubernetes"), "the skills section fell out of the rail")
    }

    func testASectionWithNoDatesFallsOutOfTheRail() throws {
        // A skills list given a rail is a hundred points of white down its left.
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            skills: [SkillGroup("Systems", ["Go", "Rust"])]
        )
        XCTAssertNoThrow(try resume.render(design: Blueprint.railed))
        XCTAssertTrue(try text(of: try resume.render(design: Blueprint.railed)).contains("Rust"))
    }

    func testEveryEntryGetsItsOwnPanel() throws {
        var blueprint = Blueprint.carded
        blueprint.ornament = .entryCards

        let data = try Resume.sample.render(design: blueprint)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        // One rounded rectangle per entry. Three roles, one degree, one
        // project and the blocks that do not break up.
        let curves = raw.components(separatedBy: " c\n").count - 1
        XCTAssertGreaterThan(curves, 16, "there are not enough panels for one per entry")
        XCTAssertTrue(try text(of: data).contains("Backend Engineer"))
    }

    // MARK: Per-section settings

    func testOneSectionCanBeSetDifferently() throws {
        let blueprint = try decode("""
            { "name": "mine",
              "entries": { "skills": "list", "roleSize": 11 },
              "sections": { "skills": { "entries": { "skills": "chips" } } } }
            """)

        XCTAssertEqual(blueprint.entries.skills, .list)
        XCTAssertEqual(blueprint.sections[.skills]?.entries?.skills, .chips)
    }

    func testAnOverrideChangesOnlyWhatItNames() throws {
        // The trap this avoids: a patch made of defaults. A design that sets
        // 11pt roles and then overrides one section's skill style must keep
        // its 11pt roles there.
        let blueprint = try decode("""
            { "entries": { "roleSize": 11, "entryGap": 19 },
              "sections": { "skills": { "entries": { "skills": "chips" } } } }
            """)

        let patched = try XCTUnwrap(blueprint.sections[.skills]?.entries).applied(to: blueprint.entries)

        XCTAssertEqual(patched.skills, .chips)
        XCTAssertEqual(patched.roleSize, 11, "the override reset a size it never mentioned")
        XCTAssertEqual(patched.entryGap, 19)
    }

    func testAHeadingCanBeOverriddenForOneSection() throws {
        let blueprint = try decode("""
            { "heading": { "style": "ruled" },
              "sections": { "summary": { "heading": { "style": "plain" }, "sectionGap": 24 } } }
            """)

        XCTAssertEqual(blueprint.sections[.summary]?.heading?.style, .plain)
        XCTAssertEqual(blueprint.sections[.summary]?.sectionGap, 24)
        XCTAssertNoThrow(try Resume.sample.render(design: blueprint))
    }

    func testACustomSectionCanBeOverriddenToo() throws {
        let blueprint = try decode("""
            { "sections": { "custom:Patents": { "entries": { "skills": "chips" } } } }
            """)
        XCTAssertEqual(blueprint.sections[.custom("Patents")]?.entries?.skills, .chips)
    }

    func testTheNewStartingPointsRenderAndAreReadable() throws {
        for blueprint in [Blueprint.railed, .console] {
            let theme = Theme(typeface: blueprint.typeface.typeface)
            let report = try Resume.sample.check(design: blueprint, theme: theme)
            XCTAssertTrue(report.isClean, "\(blueprint.name): \(report.findings.map(\.message))")
        }
    }
}
