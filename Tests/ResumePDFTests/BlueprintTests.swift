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
            // Case-insensitively: a masthead may set the name in capitals, and
            // a one-page document carries no footer to spell it the other way.
            XCTAssertTrue(try text(of: data).lowercased().contains("alex moreau"), blueprint.name)
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

    func testEveryStartingBlueprintIsCheckedHonestly() throws {
        // The property that makes this format safe to hand somebody: a
        // blueprint is checked exactly as a compiled design was. One column
        // is clean; a side column is the blocker it is, and says so.
        for blueprint in Blueprint.starting {
            let report = try Resume.sample.check(design: blueprint)
            if blueprint.isSingleColumn {
                XCTAssertTrue(report.isClean, "\(blueprint.name): \(report.findings.map(\.message))")
            } else {
                XCTAssertFalse(report.isClean, "\(blueprint.name) has a side column and must be reported")
                XCTAssertTrue(report.findings.contains { $0.severity == .blocker && $0.message.contains("two columns") },
                              "\(blueprint.name): \(report.findings.map(\.message))")
            }
        }
        XCTAssertEqual(Blueprint.starting.filter { !$0.isSingleColumn }.map(\.name),
                       ["sidebar", "gazette", "split", "wing", "foyer", "pillar", "flank", "marquee"])
    }

    // MARK: Two columns

    func testASplitHeadSetsTheNameOverTheMainColumn() throws {
        // The third place a masthead can go: the name over the main column,
        // the portrait and the contact details at the head of the side. It
        // is still two columns, and still says so.
        let blueprint = try decode(#"{"name": "mine", "side": {"head": "main", "fill": null}}"#)
        XCTAssertEqual(blueprint.side?.head, .main)
        XCTAssertFalse(blueprint.isSingleColumn)

        let data = try Resume.sample.render(design: blueprint)
        XCTAssertTrue(try text(of: data).lowercased().contains("alex moreau"))
        XCTAssertTrue(try text(of: data).contains("alex@moreau.dev"), "the contact details moved, not vanished")
    }

    func testEveryTwoColumnDesignFoldsIntoOneAParserReadsInOrder() throws {
        // The answer to the blocker: the same design, one column. Checked
        // clean, and the text comes back in the résumé's own order — which
        // the two-column original does not: measured, PDFKit hands a pair of
        // side-by-side headings back as one line.
        for blueprint in Blueprint.starting where !blueprint.isSingleColumn {
            let folded = blueprint.singleColumn
            XCTAssertTrue(folded.isSingleColumn, blueprint.name)
            XCTAssertEqual(folded.name, blueprint.name, "the same design, not a different one")
            XCTAssertTrue(try Resume.sample.check(design: folded).isClean, blueprint.name)

            let extracted = try text(of: try Resume.sample.render(design: folded))
            let positions = ["SUMMARY", "EXPERIENCE", "EDUCATION", "SKILLS"]
                .compactMap { extracted.range(of: $0)?.lowerBound }
            XCTAssertEqual(positions.count, 4, "\(blueprint.name): a heading went missing")
            XCTAssertEqual(positions, positions.sorted(), "\(blueprint.name): sections out of order once folded")
        }
        XCTAssertEqual(Blueprint.ledger.singleColumn, Blueprint.ledger, "one column already; nothing to fold")
    }

    func testADarkRailIsDrawnInAPaletteDerivedFromIt() throws {
        // The rule a masthead panel applies, applied to a rail: reversed type
        // only where the fill can carry it, the page's own palette where it
        // cannot — so sidebar's pale rail is untouched and flank's near-black
        // one gets light ink under every theme.
        let sheet = Sheet(theme: .plain, family: try Typography.family(.inter), labels: Resume.sample.labels)

        let dark = try XCTUnwrap(Blueprint.flank.side?.palette(on: sheet), "a near-black rail derives a palette")
        XCTAssertGreaterThan(dark.ink.luminance, 0.5, "light ink on a dark rail")
        XCTAssertNil(Blueprint.sidebar.side?.palette(on: sheet), "a pale rail keeps the page's palette")
        XCTAssertNil(Blueprint.gazette.side?.palette(on: sheet), "no fill, nothing to derive from")
    }

    func testAPanelIsAsTallAsItsHeadAndNeverShorterThanItsHeight() throws {
        // The band used to be a fixed height plus a flat allowance for a
        // portrait, painted before anything was measured — the same tall
        // band over one contact line as over three. It is now measured from
        // the head's lowest point, with the design's height as a floor.
        let sheet = Sheet(theme: .plain, family: try Typography.family(.inter), labels: Resume.sample.labels)
        let page = sheet.pdf.height()
        let flat = Blueprint.Panel(fill: .ink, height: 120, dip: 0)

        // A head that ends 130 down: the footroom below it, past the floor.
        XCTAssertEqual(flat.bottom(under: page - 130, on: sheet),
                       page - 130 - Blueprint.Panel.footroom, accuracy: 0.01)
        // A head that ends 50 down: the floor holds.
        XCTAssertEqual(flat.bottom(under: page - 50, on: sheet), page - 120, accuracy: 0.01)
        // A dipped edge keeps its sides — where the words are — clear too.
        let dipped = Blueprint.Panel(fill: .accent, height: 100, dip: 26)
        XCTAssertEqual(dipped.bottom(under: page - 130, on: sheet),
                       page - 130 - Blueprint.Panel.footroom - 26, accuracy: 0.01)
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
        try Blueprint.marker.encoded().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(try Blueprint(contentsOf: url), Blueprint.marker)
    }

    // MARK: Every design is a blueprint

    func testEveryDesignIsItsBlueprint() throws {
        // Not cousins: the design and its blueprint are the same bytes, so
        // what `--blueprint ledger` hands back is what `--design ledger` draws.
        for kind in DesignKind.allCases {
            let blueprint = kind.blueprint
            XCTAssertEqual(blueprint.name, kind.rawValue)
            XCTAssertTrue(Blueprint.starting.contains(blueprint), "\(kind.rawValue) is not a starting point")
            // Pinned to one creation date, or a second boundary between the
            // two renders would be the only difference.
            let stamped = Date(timeIntervalSince1970: 1_776_000_000)
            let theme = Theme(typeface: kind.intendedTypeface)
            XCTAssertEqual(try Resume.sample.document(design: kind, theme: theme).render(creationDate: stamped),
                           try Resume.sample.document(design: blueprint, theme: theme).render(creationDate: stamped),
                           "\(kind.rawValue) drawn by name differs from its blueprint")
        }
    }

    func testTheDesignsAreTheFilesInTheBundle() throws {
        // A design lives in Resources/Designs as JSON, and the Swift only
        // names it. Every file decodes, names itself after its filename, and
        // is one of the starting points — so a file added or dropped without
        // the list following is caught here rather than in a release.
        let folder = try XCTUnwrap(Bundle.module.url(forResource: "Designs", withExtension: nil))
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        XCTAssertEqual(files.count, Blueprint.starting.count)

        for file in files {
            let blueprint = try Blueprint(contentsOf: file)
            XCTAssertEqual(blueprint.name, file.deletingPathExtension().lastPathComponent)
            XCTAssertTrue(Blueprint.starting.contains(blueprint), "\(blueprint.name) is a file but not a starting point")
        }
        for kind in DesignKind.allCases {
            XCTAssertTrue(files.contains { $0.lastPathComponent == "\(kind.rawValue).json" }, "\(kind.rawValue).json is missing")
        }
    }

    func testTheLetterDesignsAreTheFilesInTheBundle() throws {
        let folder = try XCTUnwrap(Bundle.module.url(forResource: "Letters", withExtension: nil))
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        XCTAssertEqual(files.count, LetterBlueprint.starting.count)
        XCTAssertEqual(files.count, LetterDesign.allCases.count, "every letter design is a file, and nothing else is")

        for file in files {
            let blueprint = try LetterBlueprint(contentsOf: file)
            XCTAssertEqual(blueprint.name, file.deletingPathExtension().lastPathComponent)
            XCTAssertNotNil(LetterDesign(rawValue: blueprint.name), "\(blueprint.name).json is not a letter design")
        }
    }

    func testTheSideColumnAndThePaintedBodySurviveJSON() throws {
        let written = try JSONDecoder().decode(Blueprint.self, from: Data("""
            { "masthead": { "twin": true, "body": "inverse", "band": "darkest" },
              "ornament": "tabs",
              "side": { "width": 152, "edge": "right", "sections": ["education", "skills"],
                        "fill": null, "divider": true, "head": "above" } }
            """.utf8))
        XCTAssertTrue(written.masthead.twin)
        XCTAssertEqual(written.masthead.body, .inverse)
        XCTAssertEqual(written.masthead.band, .darkest)
        XCTAssertEqual(written.ornament, .tabs)
        XCTAssertEqual(written.side?.edge, .right)
        XCTAssertEqual(written.side?.sections, [.education, .skills])
        XCTAssertNil(written.side?.fill, "\"fill\": null is no fill; leaving it out would have kept the rail")
        XCTAssertTrue(written.side?.divider ?? false)
        XCTAssertEqual(written.side?.head, .above)
        XCTAssertFalse(written.isSingleColumn)
        XCTAssertEqual(try JSONDecoder().decode(Blueprint.self, from: try written.encoded()), written)

        let railed = try JSONDecoder().decode(Blueprint.self, from: Data(#"{"side": {}}"#.utf8))
        XCTAssertEqual(railed.side?.fill, .rail, "a side is a tinted rail unless told otherwise")
    }

    func testTheNewKeysSurviveJSON() throws {
        // The touches the compiled designs had, now data: every one of them
        // must read back as it was written, or a design edited by hand
        // loses them silently.
        let written = try JSONDecoder().decode(Blueprint.self, from: Data("""
            { "masthead": { "nameWeight": "regular", "nameColour": "accent", "headlineItalic": true,
                            "separator": "▪", "contacts": "labelled",
                            "rule": { "double": true, "width": 96, "underName": true } },
              "column": { "headAtMargin": true, "ruled": true },
              "heading": { "style": "underlined" } }
            """.utf8))
        XCTAssertEqual(written.masthead.nameWeight, .regular)
        XCTAssertEqual(written.masthead.nameColour, .accent)
        XCTAssertTrue(written.masthead.headlineItalic)
        XCTAssertEqual(written.masthead.separator, "▪")
        XCTAssertEqual(written.masthead.contacts, .labelled)
        XCTAssertEqual(written.masthead.rule?.double, true)
        XCTAssertEqual(written.masthead.rule?.width, 96)
        XCTAssertEqual(written.masthead.rule?.underName, true)
        XCTAssertTrue(written.column.headAtMargin)
        XCTAssertTrue(written.column.ruled)
        XCTAssertEqual(written.heading.style, .underlined)
        XCTAssertEqual(try JSONDecoder().decode(Blueprint.self, from: try written.encoded()), written)
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
        // Set in one face for all of them: a serif wraps a paragraph on a
        // different word, and the test is about the words, not the wrapping.
        let bodies = try LetterBlueprint.starting.map { blueprint -> String in
            let written = try text(of: try CoverLetter.sample.render(design: blueprint, theme: Theme(typeface: .inter)))
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
            XCTAssertEqual(report.design, blueprint.displayName)
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
        XCTAssertEqual(LetterBlueprint.letterhead.pairsWith, .broadsheet)
        XCTAssertEqual(try decode(#"{"pairsWith": "marker"}"#).pairsWith, .marker)
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
        let written = try text(of: try Resume.sample.render(design: Blueprint.timeline))

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
        XCTAssertNoThrow(try resume.render(design: Blueprint.timeline))
        XCTAssertTrue(try text(of: try resume.render(design: Blueprint.timeline)).contains("Rust"))
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
        for blueprint in [Blueprint.timeline, .terminal] {
            let theme = Theme(typeface: blueprint.typeface.typeface)
            let report = try Resume.sample.check(design: blueprint, theme: theme)
            XCTAssertTrue(report.isClean, "\(blueprint.name): \(report.findings.map(\.message))")
        }
    }
}
