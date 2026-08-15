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
                CustomSection(
                    "Patents",
                    body: "Two granted, one pending.",
                    items: ["GB2601234 — Ledger write ordering", "US11987654 — Idempotent settlement"]
                ),
                CustomSection(
                    "Speaking",
                    entries: [Position(role: "Keynote", organisation: "SREcon", dates: DateRange("2024"))]
                ),
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

    func testAllThreeShapesRender() throws {
        let text = try read(patentsResume())
        XCTAssertTrue(text.contains("Two granted"), "prose missing")
        XCTAssertTrue(text.contains("Ledger write ordering"), "list missing")
        XCTAssertTrue(text.contains("SREcon"), "entries missing")
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
