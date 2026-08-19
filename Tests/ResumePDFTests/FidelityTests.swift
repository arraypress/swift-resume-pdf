//
//  FidelityTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Whether the document that comes out matches what was declared.
//
//  A declaration nothing reads is worse than none: a blueprint that names a
//  serif and renders in the grotesque, a Subject that says "Ledger" for a
//  design somebody wrote, a PDF/A claim on a file that fails it. Each of
//  these is a regression test for a declared thing that used to be dropped
//  on the floor.
//

import TextPDF
import XCTest
@testable import ResumePDF

final class FidelityTests: XCTestCase {

    // MARK: The declared typeface

    func testADesignsDeclaredFaceIsHonouredUnderTheDefaultTheme() throws {
        let serif = try Resume.sample.document(design: .broadsheet)
        XCTAssertEqual(serif.family?.name, "Source Serif 4",
                       "broadsheet declares the serif; the default theme should load it")

        let sans = try Resume.sample.document(design: .ledger)
        XCTAssertEqual(sans.family?.name, "Inter")
    }

    func testABlueprintsDeclaredFaceIsHonouredUnderTheDefaultTheme() throws {
        let document = try Resume.sample.document(design: Blueprint.broadsheet)
        XCTAssertEqual(document.family?.name, "Source Serif 4",
                       "the blueprint says serif, and nothing used to read it")
    }

    func testAThemeThatNamesAFaceStillWins() throws {
        let document = try Resume.sample.document(
            design: .ledger, theme: Theme(typeface: .sourceSerif)
        )
        XCTAssertEqual(document.family?.name, "Source Serif 4",
                       "it is the caller's page: a named face beats the design's")
    }

    func testALetterDesignsDeclaredFaceIsHonoured() throws {
        let document = try CoverLetter.sample.document(design: .letterhead)
        XCTAssertEqual(document.family?.name, "Source Serif 4")
    }

    func testExplicitInterBeatsASerifDesign() throws {
        // Naming the family's default face is still naming a face. This is
        // the case an "Inter means unset" rule could not express, and the
        // reason the theme's typeface is a preference rather than a default.
        let document = try Resume.sample.document(
            design: .broadsheet, theme: Theme(typeface: .inter)
        )
        XCTAssertEqual(document.family?.name, "Inter")
    }

    func testAThemeWithoutATypefaceDecodesAsNoPreference() throws {
        let bare = try JSONDecoder().decode(
            Theme.self, from: Data(##"{"accent": "#123456"}"##.utf8)
        )
        XCTAssertNil(bare.typeface, "an absent key is no preference, not a choice of Inter")
        XCTAssertEqual(bare.accent, "#123456")

        let chosen = try JSONDecoder().decode(
            Theme.self, from: JSONEncoder().encode(Theme(typeface: .sourceSerif))
        )
        XCTAssertEqual(chosen.typeface, .sourceSerif)
    }

    // MARK: The photograph

    func testAMissingPhotographIsReported() throws {
        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: sample.profile.name, email: sample.profile.email,
                             photo: "/nonexistent/portrait.jpg"),
            summary: sample.summary,
            experience: sample.experience,
            education: sample.education,
            skills: sample.skills
        )

        let report = try resume.check(design: .bulletin)
        XCTAssertTrue(report.findings.contains { $0.message.contains("cannot be used") },
                      "a photograph that will silently not render must be reported")
    }

    func testARotatedPhotographIsReported() throws {
        XCTAssertFalse(Fixtures.rotatedPhotoPath.isEmpty, "the fixture failed to write")

        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: sample.profile.name, email: sample.profile.email,
                             photo: Fixtures.rotatedPhotoPath),
            summary: sample.summary,
            experience: sample.experience,
            education: sample.education,
            skills: sample.skills
        )

        let report = try resume.check(design: .bulletin)
        XCTAssertTrue(report.findings.contains { $0.message.contains("render rotated") },
                      "an EXIF orientation the writer will not apply must be reported")
    }

    func testAnUprightPhotographPassesTheChecks() throws {
        XCTAssertFalse(Fixtures.photoPath.isEmpty, "the fixture failed to write")

        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: sample.profile.name, email: sample.profile.email,
                             photo: Fixtures.photoPath),
            summary: sample.summary,
            experience: sample.experience,
            education: sample.education,
            skills: sample.skills
        )

        let report = try resume.check(design: .bulletin)
        XCTAssertFalse(report.findings.contains {
            $0.message.contains("cannot be used") || $0.message.contains("render rotated")
        })
    }

    // MARK: The archival claim

    func testArchivalRefusesADocumentTheFamilyCannotDraw() {
        let sample = Resume.sample
        let resume = Resume(
            profile: sample.profile,
            summary: "Fluent in 日本語 and English.",
            experience: sample.experience,
            education: sample.education,
            skills: sample.skills
        )

        XCTAssertThrowsError(try resume.render(design: .ledger, archival: true)) { error in
            guard case ResumeError.notArchival(let issues) = error else {
                return XCTFail("expected notArchival, got \(error)")
            }
            XCTAssertFalse(issues.isEmpty)
            XCTAssertTrue(error.localizedDescription.contains("PDF/A-3"))
        }

        // The same document without the claim renders — the text degrades,
        // the checks say so, and nothing lies about a standard.
        XCTAssertNoThrow(try resume.render(design: .ledger))
    }

    func testArchivalStillWritesACleanDocument() throws {
        let data = try Resume.sample.render(design: .ledger, archival: true)
        XCTAssertGreaterThan(data.count, 2_000)
    }

    // MARK: The subject line

    func testTheSubjectNamesTheDesignThatDrewIt() throws {
        let blueprint = Blueprint(name: "skyline")
        let data = try Resume.sample.render(design: blueprint)
        let text = String(data: data, encoding: .isoLatin1) ?? ""

        XCTAssertTrue(text.contains("/Subject (skyline)"),
                      "a design of your own used to be filed as Ledger")
    }

    // MARK: Labels by code

    func testAnUnknownLabelCodeIsRefusedByName() {
        XCTAssertThrowsError(
            try JSONDecoder().decode(Labels.self, from: Data("\"fr\"".utf8))
        ) { error in
            let message = String(describing: error)
            XCTAssertTrue(message.contains("en, de"),
                          "the refusal should name the codes that exist")
        }
    }

    func testTheKnownLabelCodesStillDecode() throws {
        let german = try JSONDecoder().decode(Labels.self, from: Data("\"de\"".utf8))
        XCTAssertEqual(german, .german)

        let english = try JSONDecoder().decode(Labels.self, from: Data("\"EN\"".utf8))
        XCTAssertEqual(english, .english)
    }

    // MARK: The dial string

    func testTheTrunkDigitStaysOutOfTheDialString() {
        let profile = Profile(name: "A", phone: "+44 (0) 20 7946 0958")
        let entry = profile.contactEntries().first { $0.text.contains("7946") }

        XCTAssertEqual(entry?.url, "tel:+442079460958",
                       "dialling the (0) after a country code reaches a wrong number")
        XCTAssertEqual(entry?.text, "+44 (0) 20 7946 0958",
                       "the printed number keeps the convention it was written in")
    }

    // MARK: The masthead portrait

    func testACentredPortraitRenders() throws {
        XCTAssertFalse(Fixtures.photoPath.isEmpty, "the fixture failed to write")

        var blueprint = Blueprint(name: "centred")
        blueprint.masthead.photo = Blueprint.Photo(diameter: 66, align: .centre)

        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: sample.profile.name, email: sample.profile.email,
                             photo: Fixtures.photoPath),
            summary: sample.summary,
            experience: sample.experience
        )

        let document = try resume.document(design: blueprint)
        _ = document.render()
        XCTAssertTrue(document.drawnText.contains(sample.profile.name),
                      "a centred portrait must not displace the name off the page")
    }

    func testAPortraitAndACodeShareTheMasthead() throws {
        XCTAssertFalse(Fixtures.photoPath.isEmpty, "the fixture failed to write")

        var blueprint = Blueprint(name: "crowded")
        blueprint.masthead.photo = Blueprint.Photo(diameter: 66, align: .right)
        blueprint.masthead.qr = 58

        let sample = Resume.sample
        let resume = Resume(
            profile: Profile(name: sample.profile.name, email: sample.profile.email,
                             photo: Fixtures.photoPath, qr: "https://alexmoreau.dev"),
            summary: sample.summary,
            experience: sample.experience
        )

        // Both were asked for; the portrait yields the right edge to the
        // code rather than being drawn through it, and everything renders.
        let document = try resume.document(design: blueprint)
        _ = document.render()
        XCTAssertTrue(document.drawnText.contains(sample.profile.name))
    }

    // MARK: The timeline rail

    func testTimelineRailsEveryDatedSection() throws {
        let document = try Resume.sample.document(design: .timeline)
        _ = document.render()

        // The certification's year. The old private rail mapping did not
        // know certifications, and their dates — marked external, drawn by
        // nobody — vanished from the document entirely.
        XCTAssertTrue(document.drawnText.contains("2021"),
                      "a dated section the rail does not know must not lose its dates")
    }
}
