//
//  LetterTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class LetterTests: XCTestCase {

    private func messages(_ report: Report) -> String {
        report.findings.map(\.message).joined(separator: " | ")
    }

    private func read(_ letter: CoverLetter, design: LetterDesign) throws -> String {
        let data = try letter.render(design: design, theme: Theme(typeface: design.intendedTypeface))
        let document = try XCTUnwrap(PDFDocument(data: data), "PDFKit refused \(design.rawValue)")
        return try XCTUnwrap(document.string)
    }

    // MARK: Rendering

    func testEveryLetterDesignRenders() throws {
        for design in LetterDesign.allCases {
            let text = try read(.sample, design: design)

            for expected in ["Alex Moreau", "Ms Adaeze Okonkwo", "Northwind Payments",
                             "Dear Ms Adaeze Okonkwo,", "Yours sincerely,"] {
                XCTAssertTrue(text.contains(expected), "\(design.rawValue) lost \"\(expected)\"")
            }
        }
    }

    func testALetterFitsOnOnePage() throws {
        for design in LetterDesign.allCases {
            let pages = try CoverLetter.sample.document(design: design).pageCount()
            XCTAssertEqual(pages, 1, "\(design.rawValue) ran to \(pages) pages")
        }
    }

    func testTheLeadInAndItsDetailAreOneRun() throws {
        // The bug this replaced: the whole bullet was drawn in the regular
        // weight and the lead-in re-stamped over it in semibold. The two faces
        // are not the same width, so it came out double-struck — and the text
        // extracted with the lead-in twice.
        let text = try read(.sample, design: .memo)
        let occurrences = text.components(separatedBy: "Ledger reliability").count - 1
        XCTAssertEqual(occurrences, 1, "the lead-in was drawn more than once")
        XCTAssertTrue(text.contains("Ledger reliability. Rebuilt a write path"), text)
    }

    // MARK: Conventions

    func testTheSignOffFollowsTheRecipient() {
        let named = CoverLetter(
            profile: Profile(name: "A"),
            recipient: Recipient(name: "Ms Okonkwo")
        )
        XCTAssertEqual(named.signOff, "Yours sincerely,")
        XCTAssertEqual(named.greeting, "Dear Ms Okonkwo,")

        let anonymous = CoverLetter(profile: Profile(name: "A"))
        XCTAssertEqual(anonymous.signOff, "Yours faithfully,")
        XCTAssertEqual(anonymous.greeting, "Dear Hiring Manager,")
    }

    func testAnExplicitSalutationWins() {
        let letter = CoverLetter(
            profile: Profile(name: "A"),
            recipient: Recipient(name: "Ms Okonkwo"),
            salutation: "Dear Adaeze,",
            closing: "Best regards,"
        )
        XCTAssertEqual(letter.greeting, "Dear Adaeze,")
        XCTAssertEqual(letter.signOff, "Best regards,")
    }

    func testTheSignatureFallsBackToTheProfile() {
        XCTAssertEqual(CoverLetter(profile: Profile(name: "Alex Moreau")).signedName, "Alex Moreau")
        XCTAssertEqual(
            CoverLetter(profile: Profile(name: "Alex Moreau"), signature: "A. Moreau").signedName,
            "A. Moreau"
        )
    }

    func testWordCountCoversBodyAndHighlights() {
        let letter = CoverLetter(
            profile: Profile(name: "A"),
            body: ["one two three"],
            highlights: [Highlight("four", "five six")]
        )
        XCTAssertEqual(letter.wordCount, 6)
    }

    // MARK: Checks

    func testAGoodLetterIsClean() throws {
        let report = try CoverLetter.sample.check()
        XCTAssertTrue(report.isClean, messages(report))
        XCTAssertEqual(report.pages, 1)
    }

    func testAnEmptyLetterBlocks() throws {
        let report = try CoverLetter(profile: Profile(name: "A", email: "a@b.co")).check()
        XCTAssertFalse(report.isClean)
        XCTAssertTrue(report.findings(.blocker).contains { $0.message.contains("no body") }, messages(report))
    }

    func testALetterThatNeverNamesTheEmployerIsReported() throws {
        let letter = CoverLetter(
            profile: Profile(name: "A", email: "a@b.co"),
            recipient: Recipient(name: "Ms Okonkwo", organisation: "Northwind Payments"),
            date: "14 August 2026",
            subject: "Re: Engineer",
            body: [String(repeating: "I am a hard-working team player with excellent communication. ", count: 5)]
        )
        let report = try letter.check()
        XCTAssertTrue(
            report.findings.contains { $0.message.contains("never mentions Northwind Payments") },
            messages(report)
        )
    }

    func testNamingTheEmployerSatisfiesTheCheck() throws {
        let report = try CoverLetter.sample.check()
        XCTAssertFalse(report.findings.contains { $0.message.contains("never mentions") }, messages(report))
    }

    func testAnUnaddressedLetterIsNoted() throws {
        let letter = CoverLetter(
            profile: Profile(name: "A", email: "a@b.co"),
            recipient: Recipient(organisation: "Northwind"),
            date: "14 August 2026",
            body: ["Northwind is why I am writing, and here is a paragraph of reasons that runs on for a while so the length check stays quiet about it being too short to bother reading at all."]
        )
        let report = try letter.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("Not addressed to anybody") }, messages(report))
    }

    func testAnOverlongLetterIsReported() throws {
        let letter = CoverLetter(
            profile: Profile(name: "A", email: "a@b.co"),
            recipient: Recipient(name: "Ms Okonkwo", organisation: "Northwind"),
            date: "14 August 2026",
            body: [String(repeating: "Northwind ", count: 500)]
        )
        let report = try letter.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("words") }, messages(report))
    }

    func testTheWrongSignOffIsNoted() throws {
        let letter = CoverLetter(
            profile: Profile(name: "A", email: "a@b.co"),
            recipient: Recipient(name: "Ms Okonkwo", organisation: "Northwind"),
            date: "14 August 2026",
            body: ["Northwind is the reason I am writing this letter, and here is a sentence long enough to keep the length check quiet."],
            closing: "Yours faithfully,"
        )
        let report = try letter.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("faithfully") }, messages(report))
    }

    // MARK: Codable

    func testALetterSurvivesJSON() throws {
        let decoded = try JSONDecoder().decode(
            CoverLetter.self, from: JSONEncoder().encode(CoverLetter.sample)
        )
        XCTAssertEqual(decoded, CoverLetter.sample)
    }

    func testEachLetterDesignPairsWithAResume() {
        for design in LetterDesign.allCases {
            XCTAssertTrue(DesignKind.allCases.contains(design.pairsWith), design.rawValue)
        }
    }
}

// MARK: - Letter layouts of your own

/// Written the way a caller would write one.
private struct Broadsheet2: LetterLayout {
    func masthead(_ letter: CoverLetter, on sheet: Sheet) {
        sheet.line(letter.profile.name, size: 26, face: sheet.semibold)
        sheet.gap(6)
        sheet.rule(color: sheet.accent, thickness: 2)
        sheet.gap(18)
    }
}

extension LetterTests {

    func testALetterLayoutCanBeWrittenOutside() throws {
        let data = try CoverLetter.sample.render(design: Broadsheet2())
        let text = try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)

        XCTAssertTrue(text.contains("Alex Moreau"))
        // The body is still set by the library — only the masthead is yours.
        XCTAssertTrue(text.contains("Dear Ms Adaeze Okonkwo,"))
        XCTAssertTrue(text.contains("Yours sincerely,"))
    }

    func testSavingALetterLayoutOfYourOwn() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("letter-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertGreaterThan(try CoverLetter.sample.save(to: url, design: Broadsheet2()), 1000)
    }

    func testTheBuiltInMastheadsAreConstructible() {
        // Public types with public inits, so one can be subclassed in spirit —
        // reused inside a layout of your own rather than reimplemented.
        XCTAssertNotNil(MemoLetter())
        XCTAssertNotNil(LetterheadLetter())
        XCTAssertNotNil(PanelLetter())
        XCTAssertNotNil(MonogramLetter())
    }

    func testAPanelLetterCarriesAPortrait() throws {
        let jpeg = "/private/tmp/claude-501/-Users-davidsherlock-Developer-Swift-Libraries/ff8e37d5-9238-42d7-88ba-bc4b95ec3dba/scratchpad/portrait.jpg"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: jpeg), "no test portrait")

        let withPhoto = CoverLetter(
            profile: Profile(name: "Alex Moreau", email: "a@b.co", photo: jpeg),
            recipient: Recipient(name: "Ms Okonkwo", organisation: "Northwind"),
            body: ["Northwind is why I am writing, at sufficient length to keep the checks quiet."]
        )
        let raw = try XCTUnwrap(String(data: try withPhoto.render(design: .panel), encoding: .isoLatin1))
        XCTAssertTrue(raw.contains("/DCTDecode"), "the portrait was not embedded")
    }
}
