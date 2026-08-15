//
//  CheckTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import ResumePDF

final class CheckTests: XCTestCase {

    private func messages(_ report: Report) -> String {
        report.findings.map(\.message).joined(separator: " | ")
    }

    // MARK: Layout

    func testTheTwoColumnDesignIsReportedAsUnparseable() throws {
        let report = try Resume.sample.check(design: .sidebar)

        XCTAssertFalse(report.isClean, "a two-column design should block")
        XCTAssertTrue(
            report.findings(.blocker).contains { $0.message.contains("two columns") },
            messages(report)
        )
    }

    func testSingleColumnDesignsDoNotBlock() throws {
        for design in DesignKind.allCases where design.isSingleColumn {
            let report = try Resume.sample.check(design: design)
            XCTAssertTrue(report.isClean, "\(design.rawValue): \(messages(report))")
        }
    }

    // MARK: Contact

    func testAMissingEmailBlocks() throws {
        let resume = Resume(profile: Profile(name: "Alex Moreau"), experience: [Position(role: "Engineer")])
        let report = try resume.check()

        XCTAssertFalse(report.isClean)
        XCTAssertTrue(report.findings(.blocker).contains { $0.message.contains("email") }, messages(report))
    }

    func testAMalformedEmailIsReported() throws {
        let resume = Resume(profile: Profile(name: "A", email: "alex-at-moreau"))
        let report = try resume.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("does not look like an email") }, messages(report))
    }

    // MARK: Headings

    func testAnUnrecognisableHeadingIsReported() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))],
            labels: Labels.english.naming(.experience, "Where I've Worked")
        )
        let report = try resume.check()

        XCTAssertTrue(
            report.findings.contains { $0.message.contains("Where I've Worked") },
            messages(report)
        )
    }

    func testATranslatedHeadingIsNotReportedAsWrong() throws {
        // A Lebenslauf saying Berufserfahrung is correct, not a mistake.
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Ingenieur", dates: DateRange("2020", "2022"))],
            labels: .german
        )
        let report = try resume.check(region: .germany)

        XCTAssertFalse(
            report.findings.contains { $0.message.contains("Berufserfahrung") },
            messages(report)
        )
    }

    // MARK: Dates

    func testYearExtraction() {
        XCTAssertEqual(ATS.year(in: "Mar 2022"), 2022)
        XCTAssertEqual(ATS.year(in: "2019"), 2019)
        XCTAssertEqual(ATS.year(in: "03/2022"), 2022)
        XCTAssertEqual(ATS.year(in: "September 1998 to date"), 1998)
        XCTAssertNil(ATS.year(in: "Mar '22"))
        XCTAssertNil(ATS.year(in: "Present"))
        XCTAssertNil(ATS.year(in: "3022"), "outside the plausible range")
    }

    func testATwoDigitYearIsReported() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", dates: DateRange("Mar '22", "Feb '24"))]
        )
        let report = try resume.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("four-digit year") }, messages(report))
    }

    func testAnUndatedRoleIsReported() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", organisation: "Stripe")]
        )
        let report = try resume.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("no dates") }, messages(report))
    }

    func testTwoCurrentRolesAreNoted() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [
                Position(role: "Engineer", dates: .since("2022")),
                Position(role: "Adviser", dates: .since("2021")),
            ]
        )
        let report = try resume.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("marked as current") }, messages(report))
    }

    func testOutOfOrderExperienceIsReported() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [
                Position(role: "Old", dates: DateRange("2016", "2019")),
                Position(role: "New", dates: DateRange("2022", "2024")),
            ]
        )
        let report = try resume.check()
        XCTAssertTrue(
            report.findings.contains { $0.message.contains("reverse-chronological") },
            messages(report)
        )
    }

    func testCorrectlyOrderedExperienceIsNotReported() throws {
        let report = try Resume.sample.check()
        XCTAssertFalse(
            report.findings.contains { $0.message.contains("reverse-chronological") },
            messages(report)
        )
    }

    // MARK: Region

    func testPersonalParticularsAreReportedForTheUS() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co", dateOfBirth: "4 March 1990", maritalStatus: "Married"),
            experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))]
        )
        let report = try resume.check(region: .unitedStates)

        XCTAssertTrue(
            report.findings.contains { $0.message.contains("should not be on a United States") },
            messages(report)
        )
    }

    func testTheSameParticularsAreFineOnALebenslauf() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co", dateOfBirth: "4 März 1990"),
            experience: [Position(role: "Ingenieur", dates: DateRange("2020", "2022"))],
            labels: .german
        )
        let report = try resume.check(region: .germany)

        XCTAssertFalse(
            report.findings.contains { $0.message.contains("should not be") },
            messages(report)
        )
    }

    func testALebenslaufWithoutParticularsIsNoted() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Ingenieur", dates: DateRange("2020", "2022"))],
            labels: .german
        )
        let report = try resume.check(region: .germany)
        XCTAssertTrue(report.findings.contains { $0.message.contains("date and place of birth") }, messages(report))
    }

    func testTheInternationalRegionHasNoOpinionOnParticulars() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co", dateOfBirth: "1990"),
            experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))]
        )
        let report = try resume.check(region: .international)

        XCTAssertFalse(report.findings.contains { $0.message.contains("should not be") }, messages(report))
        XCTAssertFalse(report.findings.contains { $0.message.contains("usually carries") }, messages(report))
    }

    func testGermanRegionNotesEnglishHeadings() throws {
        let report = try Resume.sample.check(region: .germany)
        XCTAssertTrue(report.findings.contains { $0.message.contains("headings are in English") }, messages(report))
    }

    // MARK: Photographs

    func testAPhotographIsNotedAsMissingWhereItIsConventional() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Ingenieur", dates: DateRange("2020", "2022"))],
            labels: .german
        )
        let report = try resume.check(design: .plaque, region: .germany)
        XCTAssertTrue(report.findings.contains { $0.message.contains("none is set") }, messages(report))
    }

    func testASetPhotographIsNotReportedAsMissing() throws {
        // This note used to say the writer "has no image support, so there is
        // no way to attach a photograph" — true when it was written and false
        // since. A check that describes the library rather than the document
        // goes stale silently, so it now asks the design and the profile.
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co", photo: Fixtures.photoPath),
            experience: [Position(role: "Ingenieur", dates: DateRange("2020", "2022"))],
            labels: .german
        )
        let report = try resume.check(design: .plaque, region: .germany)

        XCTAssertFalse(report.findings.contains { $0.message.contains("photograph") }, messages(report))
    }

    func testAPhotographOnADesignWithNowhereToPutItIsReported() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co", photo: Fixtures.photoPath),
            experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))]
        )
        let report = try resume.check(design: .ledger)

        XCTAssertTrue(
            report.findings.contains { $0.message.contains("nowhere to put it") },
            messages(report)
        )
    }

    func testTheDesignsNamedAsPlacingOneActuallyDo() throws {
        // The note names designs to switch to. If one of them stopped drawing
        // a portrait the advice would send somebody to a design that drops it.
        let named = DesignKind.allCases.filter(\.showsPhoto)
        XCTAssertFalse(named.isEmpty)

        for design in named {
            let resume = Resume(
                profile: Profile(name: "A", email: "a@b.co", photo: Fixtures.photoPath),
                experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))]
            )
            let raw = try XCTUnwrap(
                String(data: try resume.render(design: design), encoding: .isoLatin1)
            )
            XCTAssertTrue(
                raw.contains("/DCTDecode"),
                "the note sends people to \(design.displayName), which drew no photograph"
            )
        }
    }

    // MARK: Content

    func testBoilerplateReferencesAreNoted() throws {
        let resume = Resume(
            profile: Profile(name: "A", email: "a@b.co"),
            experience: [Position(role: "Engineer", dates: DateRange("2020", "2022"))],
            references: "References available on request."
        )
        let report = try resume.check()
        XCTAssertTrue(report.findings.contains { $0.message.contains("References available on request") }, messages(report))
    }

    func testAnAcademicCVIsNotToldItIsTooLong() throws {
        // A publication list is as long as it is.
        let report = try Resume.academicSample.check(design: .broadsheet, region: .unitedStates)
        XCTAssertFalse(report.findings.contains { $0.message.contains("pages") }, messages(report))
    }

    func testTheReportCarriesThePageCount() throws {
        let report = try Resume.sample.check()
        XCTAssertGreaterThan(report.pages, 0)
        XCTAssertEqual(report.design, "Ledger")
    }

    func testFindingsAreOrderedBySeverity() throws {
        let report = try Resume.sample.check(design: .sidebar, region: .unitedStates)
        let severities = report.findings.map(\.severity)
        XCTAssertEqual(severities, severities.sorted(), "blockers should come first")
    }

    func testAReportSurvivesJSON() throws {
        let report = try Resume.sample.check(design: .sidebar)
        let decoded = try JSONDecoder().decode(Report.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded, report)
    }
}
