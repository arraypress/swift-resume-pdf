//
//  OverflowTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What happens past the bottom of the page.
//
//  Every one of these is a regression test for a bug that lived below the
//  margin: content drawn with `cell` and `move` never looks at it, so a list
//  long enough simply carried on off the sheet, and nothing said so. The
//  sheets here are built with an empty family where a test needs to read the
//  finished pages back — base-14 text is written as escaped literals, where
//  an embedded family's runs are glyph hex nothing can grep.
//

import TextPDF
import XCTest
@testable import ResumePDF

final class OverflowTests: XCTestCase {

    /// A sheet whose page streams `Fixtures.pageStreams` can read back.
    private func plainSheet() -> Sheet {
        Sheet(theme: .plain, family: FontFamily(name: ""), labels: .english)
    }

    // MARK: The Swiss name

    func testALongNameIsSizedToTheMeasure() throws {
        let family = try Typography.family(.inter)
        let sheet = Sheet(theme: .plain, family: family, labels: .english)

        // Twenty-seven characters — a real name, not a stress fixture. The
        // old character-count formula left it at 52pt, which drew it two
        // hundred points past the edge of the page.
        let name = "Alexandra Konstantinopoulos"
        let size = Swiss.nameSize(for: name, fitting: sheet.width, on: sheet)

        XCTAssertLessThan(size, 52)
        XCTAssertLessThanOrEqual(
            sheet.pdf.width(of: name, size: size, face: sheet.semibold),
            sheet.width + 0.01,
            "the name should be sized to fit the measure it is drawn into"
        )
    }

    func testAShortNameKeepsTheIdealSize() throws {
        let family = try Typography.family(.inter)
        let sheet = Sheet(theme: .plain, family: family, labels: .english)

        XCTAssertEqual(Swiss.nameSize(for: "Alex Moreau", fitting: sheet.width, on: sheet), 52)
    }

    func testTheSwissPageRendersALongNameWhole() throws {
        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: "Alexandra Konstantinopoulos",
                             headline: sample.profile.headline,
                             email: sample.profile.email),
            summary: sample.summary,
            experience: sample.experience,
            education: sample.education,
            skills: sample.skills
        )

        let document = try resume.document(design: .swiss)
        _ = document.render()
        XCTAssertTrue(document.drawnText.contains("Alexandra Konstantinopoulos"),
                      "a name that fits after resizing should be drawn whole, not truncated")
    }

    // MARK: The sidebar rail

    func testAnOverflowingRailLeavesTheMainColumnOnPageOne() {
        let sheet = plainSheet()
        Sidebar().render(Resume.long, on: sheet)
        let streams = Fixtures.pageStreams(sheet.pdf.render())

        XCTAssertGreaterThan(streams.count, 1, "the long résumé should cross pages")

        // The experience is main-column content. When the rail overflowed,
        // it page-broke during layout and the whole main column landed on
        // page two — page one was a rail and nothing else.
        XCTAssertTrue(streams[0].contains("Carried the pager"),
                      "the main column should start on page one")
    }

    func testARailSectionThatMovesIsDrawnExactlyOnce() {
        let sheet = plainSheet()
        Sidebar().render(Resume.long, on: sheet)
        let text = String(data: sheet.pdf.render(), encoding: .isoLatin1) ?? ""

        // Twelve education entries cannot fit the rail, so the section moves
        // to the main column — moved, not duplicated and not dropped.
        for needle in ["cohort 12", "cohort 7"] {
            XCTAssertEqual(text.components(separatedBy: needle).count - 1, 1,
                           "\(needle) should appear exactly once")
        }
    }

    func testARailThatFitsStaysOnOnePage() {
        let sheet = plainSheet()
        Sidebar().render(Resume.sample, on: sheet)
        let streams = Fixtures.pageStreams(sheet.pdf.render())

        XCTAssertEqual(streams.count, 1)
        XCTAssertTrue(streams[0].contains("BSc Computer Science"),
                      "a rail section that fits should not be moved")
    }

    // MARK: Lead-ins

    func testALongLeadInDetailBreaksThePageInsteadOfRunningOffIt() {
        let sheet = plainSheet()
        let step = sheet.leading(9.4)

        // Just over two lines of room — enough that the old fixed two-line
        // break was satisfied, and nowhere near enough for the detail.
        sheet.pdf.move(to: sheet.theme.density.margin + step * 2.2)

        let detail = Array(repeating: "a claim long enough to wrap and wrap again", count: 30)
            .joined(separator: " ")
        sheet.runOn("Ledger reliability.", detail)

        XCTAssertEqual(sheet.pdf.pageCount(), 2,
                       "a detail with no room should move to the next page")
        XCTAssertGreaterThanOrEqual(sheet.pdf.remaining(), 0,
                                    "nothing should be drawn past the bottom margin")
    }

    func testALetterWithALongHighlightKeepsInsideTheMargins() {
        let sheet = plainSheet()

        let paragraph = Array(repeating: "a sentence that fills the measure", count: 25)
            .joined(separator: " ")
        let detail = Array(repeating: "evidence that runs to many lines", count: 60)
            .joined(separator: " ")

        let letter = CoverLetter(
            profile: Resume.sample.profile,
            recipient: Recipient(name: "Ms Adaeze Okonkwo", organisation: "Northwind"),
            body: [paragraph, paragraph, paragraph, paragraph, paragraph],
            highlights: [Highlight("Ledger reliability", detail)]
        )

        Letters.body(letter, on: sheet)
        XCTAssertGreaterThanOrEqual(sheet.pdf.pageCount(), 2)
        XCTAssertGreaterThanOrEqual(sheet.pdf.remaining(), 0)
    }

    // MARK: Dates beside titles

    func testDatesStayWithTheTitleTheyBelongTo() {
        let sheet = plainSheet()
        let style = Blocks.Style(x: sheet.left, width: sheet.width)

        // Room for the old one-and-four-fifths-line lookahead, but not for
        // the two lines this title actually needs. The dates used to go down
        // first, the title's own break then fired, and the dates were left
        // stranded at the foot of the page.
        let step = sheet.leading(style.detailSize)
        sheet.pdf.move(to: sheet.theme.density.margin + step * 1.9)

        let credential = Credential(
            name: "Advanced Professional Certificate in the Administration of Very Large "
                + "Distributed Database Systems and the Operation Thereof",
            issuer: "An Issuing Body",
            date: "March 2024"
        )
        Blocks.credentials([credential], on: sheet, style: style)

        let streams = Fixtures.pageStreams(sheet.pdf.render())
        XCTAssertEqual(streams.count, 2)
        XCTAssertFalse(streams[0].contains("March 2024"),
                       "the dates should not be stranded on the page before their title")
        XCTAssertTrue(streams[1].contains("March 2024"))
        XCTAssertTrue(streams[1].contains("Advanced Professional Certificate"))
    }

    func testANarrowColumnDropsTheDatesBeneathTheTitle() {
        let sheet = plainSheet()
        let style = Blocks.Style(x: sheet.left, width: 150)

        let credential = Credential(
            name: "Chartered Institute Fellowship Award",
            date: "January 2024 – December 2025"
        )
        Blocks.credentials([credential], on: sheet, style: style)

        let drawn = sheet.pdf.drawnText
        let title = drawn.firstIndex { $0.contains("Chartered") }
        let dates = drawn.firstIndex { $0.contains("December 2025") }

        XCTAssertNotNil(title)
        XCTAssertNotNil(dates, "dates a column cannot hold beside the title must still be drawn")
        if let title, let dates {
            XCTAssertLessThan(title, dates,
                              "demoted dates go beneath the title, not on its line through it")
        }
    }

    // MARK: Rows placed by hand

    func testALongRatedSkillsListBreaksAcrossPages() {
        for treatment in [Blocks.SkillStyle.bars, .dots] {
            let sheet = plainSheet()
            var style = Blocks.Style(x: sheet.left, width: sheet.width)
            style.skills = treatment

            Blocks.skills(Resume.long.skills, on: sheet, style: style)

            XCTAssertGreaterThanOrEqual(sheet.pdf.pageCount(), 2,
                                        "\(treatment) rows should break onto further pages")
            XCTAssertGreaterThanOrEqual(sheet.pdf.remaining(), 0,
                                        "\(treatment) rows should never pass the bottom margin")
        }
    }

    func testALongLanguageListBreaksAcrossPages() {
        let sheet = plainSheet()
        let style = Blocks.Style(x: sheet.left, width: sheet.width)

        Blocks.languages(Resume.long.languages, on: sheet, style: style)

        XCTAssertGreaterThanOrEqual(sheet.pdf.pageCount(), 2)
        XCTAssertGreaterThanOrEqual(sheet.pdf.remaining(), 0)
    }

    // MARK: The running foot

    func testTheFooterSitsBelowTheContentAtEveryDensity() {
        for density in Density.allCases {
            let band = Sheet.footerBand(margin: density.margin)
            XCTAssertLessThan(band.rule, density.margin,
                              "\(density) put the footer rule inside the text column")
            XCTAssertLessThan(band.text, band.rule)
        }

        // Normal density keeps the positions every existing document has.
        XCTAssertEqual(Sheet.footerBand(margin: Density.normal.margin).rule, 46)
        XCTAssertEqual(Sheet.footerBand(margin: Density.normal.margin).text, 34)
    }
}
