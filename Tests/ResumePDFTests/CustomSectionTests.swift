//
//  CustomSectionTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Sections the library does not name.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class CustomSectionTests: XCTestCase {

    private func patentsResume(order: [Section]? = nil) -> Resume {
        Resume(
            profile: Profile(name: "Alex Moreau", email: "alex@moreau.dev"),
            summary: "Infrastructure engineer.",
            experience: [Position(role: "Engineer", organisation: "Stripe", dates: .since("2022"))],
            custom: [
                CustomSection("Patents", [
                    .prose("Two granted, one pending."),
                    .list(["GB2601234 — Ledger write ordering", "US11987654 — Idempotent settlement"]),
                ]),
                CustomSection("Speaking", [
                    .positions([Position(role: "Keynote", organisation: "SREcon",
                                         dates: DateRange("2024"))]),
                ]),
            ],
            order: order ?? [.summary, .experience, .custom("Patents"), .custom("Speaking")]
        )
    }

    private func read(_ resume: Resume, design: DesignKind = .ledger) throws -> String {
        let data = try resume.render(design: design)
        return try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    // MARK: Identity

    func testACustomSectionCarriesItsTitle() {
        XCTAssertEqual(Section.custom("Patents").customTitle, "Patents")
        XCTAssertTrue(Section.custom("Patents").isCustom)

        XCTAssertNil(Section.experience.customTitle)
        XCTAssertFalse(Section.experience.isCustom)
    }

    func testACustomSectionCannotCollideWithABuiltInOne() {
        // The prefix is what keeps .custom("Skills") from being .skills.
        XCTAssertNotEqual(Section.custom("Skills"), Section.skills)
        XCTAssertEqual(Section.custom("Skills").defaultTitle, "Skills")
    }

    func testTheTitleIsTheHeading() {
        XCTAssertEqual(Section.custom("Board Positions").defaultTitle, "Board Positions")
    }

    // MARK: Rendering

    func testACustomSectionRenders() throws {
        let text = try read(patentsResume())

        XCTAssertTrue(text.contains("PATENTS") || text.contains("Patents"), text)
        XCTAssertTrue(text.contains("Two granted, one pending."))
        XCTAssertTrue(text.contains("GB2601234"))
        XCTAssertTrue(text.contains("US11987654"))
    }

    func testEveryContentShapeRenders() throws {
        let text = try read(patentsResume())
        XCTAssertTrue(text.contains("Two granted"), "prose missing")
        XCTAssertTrue(text.contains("Ledger write ordering"), "list missing")
        XCTAssertTrue(text.contains("SREcon"), "positions missing")
    }

    func testACustomSectionCanHoldTheSameShapesABuiltInOneDoes() throws {
        // The point of the content model: a section of your own is not a
        // lesser thing that only gets bullet points.
        let resume = Resume(
            profile: Profile(name: "Dr Sørensen", email: "i@ed.ac.uk"),
            custom: [
                CustomSection("Selected Works", [
                    .prose("Chosen for relevance rather than recency."),
                    .publications([Publication(title: "Unsupervised segmentation",
                                               venue: "Computational Linguistics", date: "2023")]),
                ]),
                CustomSection("Fellowships", [
                    .grants([Grant(title: "Turing Fellowship", funder: "ATI",
                                   amount: "£240k", role: "Fellow")]),
                ]),
                CustomSection("Qualifications", [
                    .education([Education(qualification: "PhD Linguistics",
                                          institution: "Copenhagen")]),
                    .credentials([Credential(name: "PGCert HE", issuer: "Edinburgh")]),
                ]),
                CustomSection("Toolchain", [
                    .skills([SkillGroup("Methods", ["Bayesian inference"])]),
                    .languages([Language("Danish", "Native")]),
                ]),
            ],
            order: [.custom("Selected Works"), .custom("Fellowships"),
                    .custom("Qualifications"), .custom("Toolchain")]
        )

        let text = try read(resume)
        for expected in ["Chosen for relevance", "Unsupervised segmentation", "Turing Fellowship",
                         "£240k", "PhD Linguistics", "PGCert HE", "Bayesian inference", "Danish"] {
            XCTAssertTrue(text.contains(expected), "\"\(expected)\" missing")
        }
    }

    func testItAppearsWhereTheOrderPutsIt() throws {
        let text = try read(patentsResume(
            order: [.summary, .custom("Patents"), .experience]
        ))

        func at(_ needle: String) throws -> Int {
            let range = try XCTUnwrap(text.range(of: needle), needle)
            return text.distance(from: text.startIndex, to: range.lowerBound)
        }

        XCTAssertLessThan(try at("Two granted"), try at("Stripe"),
                          "the custom section did not land before experience")
    }

    func testABlockWithNoPlaceInTheOrderIsNotDrawn() throws {
        // Left out without being deleted, which is how somebody keeps a
        // section around for the next application.
        let text = try read(patentsResume(order: [.summary, .experience]))
        XCTAssertFalse(text.contains("Two granted"))
        XCTAssertTrue(text.contains("Stripe"))
    }

    func testAnOrderEntryWithNoBlockIsSkipped() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", dates: .since("2022"))],
            order: [.experience, .custom("Nothing Here")]
        )
        XCTAssertNoThrow(try read(resume))
        XCTAssertFalse(try read(resume).contains("Nothing Here"))
    }

    func testAnEmptyBlockIsNotDrawn() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", dates: .since("2022"))],
            custom: [CustomSection("Patents")],
            order: [.experience, .custom("Patents")]
        )
        XCTAssertFalse(try read(resume).contains("PATENTS"))
    }

    func testEveryDesignHandlesACustomSection() throws {
        for design in DesignKind.allCases {
            let text = try read(patentsResume(), design: design)
            XCTAssertTrue(text.contains("GB2601234"), "\(design.rawValue) dropped it")
        }
    }

    // MARK: Codable

    func testACustomSectionSurvivesJSON() throws {
        let resume = patentsResume()
        let decoded = try JSONDecoder().decode(Resume.self, from: JSONEncoder().encode(resume))
        XCTAssertEqual(decoded, resume)
    }

    func testTheOrderEncodesAsPlainStrings() throws {
        let encoded = try JSONEncoder().encode([Section.experience, Section.custom("Patents")])
        let json = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        XCTAssertTrue(json.contains("\"experience\""), json)
        XCTAssertTrue(json.contains("custom:Patents"), json)
    }

    // MARK: Bringing your own typeface

    func testACustomTypefaceIsUsed() throws {
        let arial = "/System/Library/Fonts/Supplemental/Arial.ttf"
        let bold = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
        try XCTSkipUnless(
            [arial, bold].allSatisfy(FileManager.default.fileExists(atPath:)),
            "Arial is not installed in separate files"
        )

        let face = Typeface.custom(
            name: "Arial",
            regular: URL(fileURLWithPath: arial),
            bold: URL(fileURLWithPath: bold)
        )
        let data = try Resume.sample.render(theme: Theme(typeface: face))
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        XCTAssertTrue(raw.contains("Arial"), "the supplied face was not embedded")
        XCTAssertFalse(raw.contains("Inter"), "a bundled face was used instead")

        // And the document still reads correctly.
        let text = try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
        XCTAssertTrue(text.contains("Alex Moreau"))
    }

    func testAThemeWithACustomTypefaceSurvivesJSON() throws {
        let face = Typeface.custom(name: "Arial", regular: URL(fileURLWithPath: "/tmp/a.ttf"))
        let theme = Theme(typeface: face, accent: "#123456")

        let decoded = try JSONDecoder().decode(Theme.self, from: JSONEncoder().encode(theme))
        XCTAssertEqual(decoded, theme)
        XCTAssertEqual(decoded.typeface.displayName, "Arial")
    }

    func testAMissingWeightFallsBackRatherThanFailing() throws {
        let arial = "/System/Library/Fonts/Supplemental/Arial.ttf"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: arial), "Arial is not installed")

        // One file only. Every weight a design asks for resolves to it.
        let face = Typeface.custom(name: "Arial", regular: URL(fileURLWithPath: arial))
        let family = try Typography.family(face)

        XCTAssertNotNil(family.face(.regular))
        XCTAssertNotNil(family.face(.bold))
        XCTAssertNotNil(family.face(.semibold, italic: true))
    }

    // MARK: Monospace

    func testTheTerminalDesignUsesTheMonoFamily() throws {
        let data = try Resume.sample.render(design: .terminal)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        XCTAssertTrue(raw.contains("JetBrainsMono"), "the mono face was not embedded")

        // And the prose is still proportional — the whole point of the design.
        XCTAssertTrue(raw.contains("Inter"), "the body face is missing")
    }

    func testTheMonoFamilyLoads() throws {
        let mono = try Typography.mono()
        XCTAssertFalse(mono.isEmpty)

        let regular = try XCTUnwrap(mono.face(.regular))
        // A monospaced face gives every character the same advance.
        XCTAssertEqual(regular.widthOf("i", size: 10), regular.widthOf("W", size: 10), accuracy: 0.001)
    }

    func testOtherDesignsDoNotPayForTheMonoFamily() throws {
        let data = try Resume.sample.render(design: .ledger)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))
        XCTAssertFalse(raw.contains("JetBrainsMono"), "mono was embedded by a design that never used it")
    }
}

// MARK: - Designs of your own

/// The smallest design that does something: a name and every section.
private struct Broadside: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.line(resume.profile.name, size: 30, face: sheet.semibold)
        sheet.gap(10)
        sheet.rule(color: sheet.accent, thickness: 2)
        sheet.gap(16)

        let style = Blocks.Style(x: sheet.left, width: sheet.width)
        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .ruled)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(16)
        }
        sheet.footer(name: resume.profile.name)
    }
}

/// One that uses the components rather than the section renderer.
private struct Dashboard: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.pdf.roundedRect(x: sheet.left, y: sheet.cursor - 60, width: sheet.width,
                              height: 60, radius: 8, color: sheet.wash)
        sheet.gap(18)
        sheet.line(resume.profile.name, x: sheet.left + 14, size: 20, face: sheet.semibold)
        sheet.gap(28)

        sheet.icon(.skills, x: sheet.left, y: sheet.cursor - 14, size: 14)
        sheet.line("CAPABILITY", x: sheet.left + 20, size: 8, face: sheet.medium, tracking: 1)
        sheet.gap(6)

        for group in resume.skills {
            sheet.chips(group.names, size: 8.4)
        }
        sheet.dots(0.8, x: sheet.left, y: sheet.cursor - 6)
        sheet.dial(0.62, x: sheet.left + 120, y: sheet.cursor - 30, radius: 22, caption: "Coverage")
        sheet.pdf.move(to: sheet.cursor - 70)
    }
}

extension CustomSectionTests {

    func testADesignOfYourOwnRenders() throws {
        let data = try Resume.sample.render(design: Broadside())
        let text = try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)

        XCTAssertTrue(text.contains("Alex Moreau"))
        XCTAssertTrue(text.contains("Stripe"))
        XCTAssertTrue(text.contains("University of Bristol"))
    }

    func testADesignOfYourOwnGetsTheTheme() throws {
        let data = try Resume.sample.render(design: Broadside(), theme: .midnight)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        // The dark page is painted by Sheet, not by the design, so a design of
        // your own gets light and dark for free.
        XCTAssertTrue(raw.contains(" re\n") || raw.contains(" rg\n"))
        XCTAssertNotNil(PDFDocument(data: data))
    }

    func testTheComponentsAreReachableFromOutside() throws {
        // chips, dots, dials, icons and the raw Document — the point of making
        // Sheet public is that a design of your own is not limited to the
        // section renderer.
        let data = try Resume.sample.render(design: Dashboard())
        let document = try XCTUnwrap(PDFDocument(data: data))

        XCTAssertEqual(document.pageCount, 1)
        let text = try XCTUnwrap(document.string)
        XCTAssertTrue(text.contains("Alex Moreau"))
        XCTAssertTrue(text.contains("Kubernetes"))
        XCTAssertTrue(text.contains("62"), "the dial's figure is missing")
    }

    func testSavingADesignOfYourOwn() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("broadside-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: url) }

        let bytes = try Resume.sample.save(to: url, design: Broadside())
        XCTAssertGreaterThan(bytes, 1000)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}

// MARK: - Written by hand

extension CustomSectionTests {

    private func decodeSection(_ json: String) throws -> CustomSection {
        try JSONDecoder().decode(CustomSection.self, from: XCTUnwrap(json.data(using: .utf8)))
    }

    func testABlockIsNamedByItsKind() throws {
        // Not {"list": {"_0": [...]}}, which is what the synthesised coding
        // produces and what nobody would type. Custom sections are the whole
        // extensibility story; theirs has to be a shape somebody can write.
        let section = try decodeSection("""
            { "title": "Patents",
              "content": [
                { "prose": "Two granted, one pending." },
                { "list": ["GB2601234 — Ledger write ordering"] }
              ] }
            """)

        XCTAssertEqual(section.title, "Patents")
        XCTAssertEqual(section.content, [
            .prose("Two granted, one pending."),
            .list(["GB2601234 — Ledger write ordering"])
        ])
    }

    func testEveryKindOfBlockCanBeWritten() throws {
        let section = try decodeSection("""
            { "title": "Everything",
              "content": [
                { "positions": [{ "role": "Engineer" }] },
                { "education": [{ "qualification": "BSc" }] },
                { "projects": [{ "name": "Ledger" }] },
                { "publications": [{ "title": "On write ordering" }] },
                { "credentials": [{ "name": "AWS SA" }] },
                { "awards": [{ "name": "Prize" }] },
                { "grants": [{ "title": "EPSRC" }] },
                { "skills": [{ "name": "Systems", "items": ["Go"] }] },
                { "languages": ["English"] }
              ] }
            """)

        XCTAssertEqual(section.content.count, 9)
        XCTAssertFalse(section.content.contains(where: \.isEmpty))
    }

    func testABlockOfNothingIsRefused() {
        XCTAssertThrowsError(try decodeSection(#"{"title":"X","content":[{}]}"#)) {
            XCTAssertTrue("\($0)".contains("needs one of"), "\($0)")
        }
    }

    func testABlockOfTwoThingsIsRefused() {
        // Ambiguous rather than generous: which one was meant to render?
        XCTAssertThrowsError(
            try decodeSection(#"{"title":"X","content":[{"prose":"a","list":["b"]}]}"#)
        )
    }

    func testAMisspelledKindNamesTheOnesThereAre() {
        XCTAssertThrowsError(try decodeSection(#"{"title":"X","content":[{"bullets":["a"]}]}"#)) {
            XCTAssertTrue("\($0)".contains("prose, list"), "\($0)")
        }
    }

    func testABlockSurvivesARoundTrip() throws {
        let section = CustomSection("Patents", [
            .prose("Two granted."),
            .list(["GB2601234"]),
            .positions([Position(role: "Engineer", organisation: "Stripe")])
        ])

        let encoded = try JSONEncoder().encode(section)
        XCTAssertEqual(try JSONDecoder().decode(CustomSection.self, from: encoded), section)

        // And what it wrote is the shape it documents.
        let written = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertTrue(written.contains(#""list":["#), written)
        XCTAssertFalse(written.contains("_0"), written)
    }
}

extension CustomSectionTests {

    func testTheOrderIsWrittenAsPlainNames() throws {
        // Documented as ["summary", "experience", "custom:Patents"], so it had
        // better not be [{"rawValue": "summary"}].
        let resume = try JSONDecoder().decode(Resume.self, from: XCTUnwrap("""
            { "profile": { "name": "A" },
              "summary": "Something.",
              "custom": [{ "title": "Patents", "content": [{ "list": ["GB2601234"] }] }],
              "order": ["summary", "custom:Patents"] }
            """.data(using: .utf8)))

        XCTAssertEqual(resume.order, [.summary, .custom("Patents")])
        XCTAssertEqual(resume.populated(), [.summary, .custom("Patents")])

        let written = try XCTUnwrap(String(data: JSONEncoder().encode(resume), encoding: .utf8))
        XCTAssertTrue(written.contains(#""custom:Patents""#), written)
    }
}
