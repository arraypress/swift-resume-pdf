//
//  PublicAPITests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a caller outside the package can actually reach.
//
//  Deliberately a plain `import`. The other test target uses `@testable`,
//  which makes internal declarations visible — so it would go on passing if
//  every extension point in the library were closed by accident, and the first
//  person to find out would be somebody trying to use it.
//

import PDFKit
import XCTest
import ResumePDF

/// A design written the way a caller would write one.
///
/// Named for what it is rather than `SectionwiseDesign`, which is the README's
/// example and lives in `READMEExamples.swift`.
private struct SectionwiseDesign: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.line(resume.profile.name, size: 28, face: sheet.semibold)
        sheet.gap(8)
        sheet.rule(color: sheet.accent, thickness: 2)
        sheet.gap(14)

        let style = Blocks.Style(x: sheet.left, width: sheet.width)
        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section), style: .ruled)
            Blocks.render(section, of: resume, on: sheet, style: style)
            sheet.gap(15)
        }
        sheet.footer(name: resume.profile.name)
    }
}

/// One built from the components rather than the section renderer.
private struct Dashboard: Design {

    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.pdf.roundedRect(x: sheet.left, y: sheet.cursor - 54, width: sheet.width,
                              height: 54, radius: 8, color: sheet.wash)
        sheet.gap(16)
        sheet.line(resume.profile.name, x: sheet.left + 14, size: 19, face: sheet.semibold)
        sheet.gap(24)

        sheet.icon(.skills, x: sheet.left, y: sheet.cursor - 14, size: 14)
        sheet.line("CAPABILITY", x: sheet.left + 20, size: 8, face: sheet.medium, tracking: 1)

        for group in resume.skills {
            sheet.chips(group.names, size: 8.4)
        }
        sheet.dots(0.8, x: sheet.left, y: sheet.cursor - 6)
        sheet.dial(0.62, x: sheet.left + 130, y: sheet.cursor - 32, radius: 22, caption: "Coverage")
        sheet.pdf.move(to: sheet.cursor - 74)
    }
}

final class PublicAPITests: XCTestCase {

    private func text(of data: Data) throws -> String {
        try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    // MARK: Designs

    func testADesignCanBeWrittenOutsideThePackage() throws {
        let read = try text(of: try Resume.sample.render(design: SectionwiseDesign()))
        XCTAssertTrue(read.contains("Alex Moreau"))
        XCTAssertTrue(read.contains("Stripe"))
    }

    func testTheComponentsAreReachable() throws {
        let read = try text(of: try Resume.sample.render(design: Dashboard()))
        XCTAssertTrue(read.contains("Kubernetes"))
        XCTAssertTrue(read.contains("62"), "the dial's figure is missing")
    }

    func testADesignOfYourOwnGetsTheThemeForFree() throws {
        let data = try Resume.sample.render(design: SectionwiseDesign(), theme: .midnight)
        XCTAssertNotNil(PDFDocument(data: data))
        XCTAssertTrue(try text(of: data).contains("Alex Moreau"))
    }

    // MARK: Typefaces

    func testATypefaceCanBeSupplied() throws {
        let arial = "/System/Library/Fonts/Supplemental/Arial.ttf"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: arial), "Arial is not installed")

        let face = Typeface.custom(name: "Arial", regular: URL(fileURLWithPath: arial))
        let data = try Resume.sample.render(theme: Theme(typeface: face))

        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))
        XCTAssertTrue(raw.contains("Arial"))
        XCTAssertFalse(raw.contains("Inter"))
    }

    // MARK: Sections

    func testASectionCanBeInventedAndPlaced() throws {
        let resume = Resume(
            profile: Profile(name: "Alex Moreau", email: "a@b.co"),
            experience: [Position(role: "Engineer", organisation: "Stripe", dates: .since("2022"))],
            custom: [
                CustomSection("Patents", [
                    .prose("Two granted."),
                    .list(["GB2601234"]),
                ]),
                CustomSection("Selected Works", [
                    .publications([Publication(title: "On ledgers", venue: "CL", date: "2023")]),
                ]),
            ],
            order: [.custom("Patents"), .experience, .custom("Selected Works")]
        )

        let read = try text(of: try resume.render())
        XCTAssertTrue(read.contains("Two granted."))
        XCTAssertTrue(read.contains("GB2601234"))
        XCTAssertTrue(read.contains("On ledgers"))
    }

    func testEveryContentShapeIsConstructible() {
        // If any of these stops being public the library has quietly closed.
        let shapes: [CustomSection.Content] = [
            .prose("x"),
            .list(["x"]),
            .positions([Position(role: "x")]),
            .education([Education(qualification: "x")]),
            .projects([Project(name: "x")]),
            .publications([Publication(title: "x")]),
            .credentials([Credential(name: "x")]),
            .awards([Award(name: "x")]),
            .grants([Grant(title: "x")]),
            .skills([SkillGroup("x", ["y"])]),
            .languages([Language("x", "y")]),
        ]
        XCTAssertEqual(shapes.count, 11)
    }

    // MARK: The rest of the surface

    func testTheBuiltInsAreStillReachable() throws {
        for design in DesignKind.allCases {
            XCTAssertNoThrow(try Resume.sample.render(design: design))
        }
        for letter in LetterDesign.allCases {
            XCTAssertNoThrow(try CoverLetter.sample.render(design: letter))
        }
    }

    func testCheckingIsReachable() throws {
        let report = try Resume.sample.check(design: .sidebar, region: .unitedStates)
        XCTAssertFalse(report.isClean)
        XCTAssertFalse(report.findings(.blocker).isEmpty)

        let letter = try CoverLetter.sample.check()
        XCTAssertTrue(letter.isClean)
    }

    func testFittingIsReachable() throws {
        XCTAssertNotNil(try Resume.sample.fitted(to: 2))
    }

    func testLabelsAndOrdersAreReachable() {
        XCTAssertEqual(Labels.german.title(for: .experience), "Berufserfahrung")
        XCTAssertEqual(Labels.english.naming(.skills, "Toolkit").title(for: .skills), "Toolkit")
        XCTAssertFalse(Section.academic.isEmpty)
        XCTAssertFalse(Section.builtIn.isEmpty)
    }
}
