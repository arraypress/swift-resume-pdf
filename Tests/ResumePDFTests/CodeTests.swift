//
//  CodeTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import CoreImage
import PDFKit
import XCTest
@testable import ResumePDF

final class CodeTests: XCTestCase {

    private let address = "https://moreau.dev/cv"

    private func resume(qr: String = "https://moreau.dev/cv", links: [Link] = []) -> Resume {
        Resume(
            profile: Profile(
                name: "Alex Moreau", headline: "Senior Infrastructure Engineer",
                location: "London, UK", email: "alex@moreau.dev",
                links: links, qr: qr
            ),
            summary: "Infrastructure engineer with eleven years on payment systems.",
            experience: [Position(role: "Engineer", organisation: "Stripe", dates: .since("2022"))],
            skills: [SkillGroup("Systems", ["Go", "Rust"])]
        )
    }

    /// Reads the code off the finished page, the way a phone would.
    private func scan(_ data: Data) throws -> String? {
        let page = try XCTUnwrap(PDFDocument(data: data)?.page(at: 0))
        var box = CGRect(x: 0, y: 0, width: 1400, height: 1980)
        let image = try XCTUnwrap(
            page.thumbnail(of: box.size, for: .mediaBox)
                .cgImage(forProposedRect: &box, context: nil, hints: nil)
        )
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return (detector?.features(in: CIImage(cgImage: image)) as? [CIQRCodeFeature])?
            .first?.messageString
    }

    // MARK: Drawing

    func testTheCodeScansOffTheFinishedPage() throws {
        for design in DesignKind.allCases where design.showsCode {
            let data = try resume().render(design: design,
                                           theme: Theme(typeface: design.intendedTypeface))
            XCTAssertEqual(try scan(data), address, design.rawValue)
        }
    }

    func testDesignsThatDoNotClaimOneDrawNone() throws {
        for design in DesignKind.allCases where !design.showsCode {
            let data = try resume().render(design: design)
            XCTAssertNil(try scan(data), "\(design.rawValue) drew a code it does not claim")
        }
    }

    func testAtLeastOneDesignPlacesOne() {
        // Otherwise the field is a promise nothing keeps.
        XCTAssertFalse(DesignKind.allCases.filter(\.showsCode).isEmpty)
    }

    func testNothingIsDrawnWithoutAnAddress() throws {
        let data = try resume(qr: "   ").render(design: .ledger)
        XCTAssertNil(try scan(data))
    }

    func testTheNameStillFitsBesideIt() throws {
        // The masthead measures the name against what is left, not the page.
        let long = Resume(
            profile: Profile(name: "Wolfeschlegelsteinhausenbergerdorff Alexandrina",
                             email: "a@b.co", qr: address),
            experience: [Position(role: "Engineer", dates: .since("2022"))]
        )

        for design in [DesignKind.ledger, .swiss] {
            let text = try XCTUnwrap(
                PDFDocument(data: try long.render(design: design))?.string
            )
            XCTAssertTrue(text.contains("Wolfeschlegel"), "\(design.rawValue) lost the name")
            XCTAssertEqual(try scan(try long.render(design: design)), address, design.rawValue)
        }
    }

    func testNothingIsDrawnThroughTheCode() throws {
        // It was: Swiss drew the code in the contact band and then set the
        // summary straight over it, because nothing reserved the height.
        for design in DesignKind.allCases where design.showsCode {
            let data = try resume(links: [Link(address)])
                .render(design: design, theme: Theme(typeface: design.intendedTypeface))

            let document = try XCTUnwrap(PDFDocument(data: data))
            let page = try XCTUnwrap(document.page(at: 0))
            let bounds = page.bounds(for: .mediaBox)

            // The square the code occupies, generously bounded.
            let square = CGRect(x: bounds.maxX - 120, y: bounds.maxY - 190,
                                width: 100, height: 130)
            let inside = page.selection(for: square)?.string ?? ""

            XCTAssertTrue(
                inside.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "\(design.rawValue) ran text under the code: \(inside)"
            )
        }
    }

    // MARK: A design of your own

    func testABlueprintCanAskForOne() throws {
        var blueprint = Blueprint.ledger
        blueprint.masthead.qr = 60

        XCTAssertTrue(blueprint.showsCode)
        XCTAssertEqual(try scan(try resume().render(design: blueprint)), address)
    }

    func testABlueprintWithoutOneDrawsNothing() throws {
        XCTAssertFalse(Blueprint.ledger.showsCode)
        XCTAssertNil(try scan(try resume().render(design: Blueprint.ledger)))
    }

    func testItSurvivesJSON() throws {
        var blueprint = Blueprint.ledger
        blueprint.masthead.qr = 64

        let decoded = try JSONDecoder().decode(Blueprint.self, from: try blueprint.encoded())
        XCTAssertEqual(decoded.masthead.qr, 64)
    }

    func testItReadsFromASmallBlueprint() throws {
        let blueprint = try JSONDecoder().decode(
            Blueprint.self, from: XCTUnwrap(#"{"name":"mine","masthead":{"qr":58}}"#.data(using: .utf8))
        )
        XCTAssertEqual(blueprint.masthead.qr, 58)
        XCTAssertTrue(blueprint.showsCode)
    }

    // MARK: What the checks say

    func testACodeOnADesignWithNowhereToPutItIsReported() throws {
        let report = try resume(links: [Link(address)]).check(design: .sidebar)
        XCTAssertTrue(report.findings.contains { $0.message.contains("nowhere to put it") },
                      report.findings.map(\.message).joined(separator: " | "))
    }

    func testACodeThatIsTheOnlyCopyOfAnAddressIsReported() throws {
        // A parser reads text; a code is a picture. An address that exists
        // only inside one is an address no tracking system will ever see.
        let report = try resume(links: []).check(design: .ledger)
        XCTAssertTrue(report.findings.contains { $0.message.contains("only place") },
                      report.findings.map(\.message).joined(separator: " | "))
    }

    func testTheSameAddressInWritingIsNotReported() throws {
        let report = try resume(links: [Link(address)]).check(design: .ledger)
        XCTAssertFalse(report.findings.contains { $0.message.contains("only place") })
    }

    func testNoCodeMeansNothingToSay() throws {
        let report = try resume(qr: "").check(design: .ledger)
        XCTAssertFalse(report.findings.contains { $0.message.lowercased().contains("code") })
    }

    // MARK: Archival

    func testAResumeCanBeWrittenAsPDFA() throws {
        // Some academic and government applications ask for one by name, and
        // it is free here: the typefaces travel with the document already.
        let data = try Resume.sample.render(design: .ledger, archival: true)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        XCTAssertTrue(raw.hasPrefix("%PDF-1.7"))
        XCTAssertTrue(raw.contains("<pdfaid:part>3</pdfaid:part>"))
        XCTAssertTrue(raw.contains("GTS_PDFA1"), "no output intent")
        XCTAssertNotNil(PDFDocument(data: data))
    }

    func testEveryDesignCanClaimIt() throws {
        // The claim is only honest if no design falls back to a font the
        // reader has to supply.
        for design in DesignKind.allCases {
            let document = try Resume.sample.document(
                design: design, theme: Theme(typeface: design.intendedTypeface)
            )
            _ = document.render()
            XCTAssertEqual(document.conformanceIssues(for: .pdfA3b), [], design.rawValue)
        }
    }

    func testAnOrdinaryRenderClaimsNothing() throws {
        let raw = try XCTUnwrap(
            String(data: try Resume.sample.render(design: .ledger), encoding: .isoLatin1)
        )
        XCTAssertFalse(raw.contains("pdfaid"))
    }
}

extension CodeTests {

    func testADesignOfYourOwnCanBeArchivalToo() throws {
        // The parameter was added to one overload and not the other, so a
        // blueprint could not be written as PDF/A at all.
        var blueprint = Blueprint.ledger
        blueprint.masthead.qr = 58

        let data = try resume().render(design: blueprint, archival: true)
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))

        XCTAssertTrue(raw.contains("<pdfaid:part>3</pdfaid:part>"))
        XCTAssertEqual(try scan(data), address)
    }
}

extension CodeTests {

    func testAResumeCanBeLocked() throws {
        // Rarely what you want — a recruiter who cannot open it does not ring
        // to ask — but a document sent to a payroll or a background checker
        // is a different errand.
        let data = try Resume.sample.render(design: .ledger, password: "correct horse battery")

        let document = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertTrue(document.isLocked)
        XCTAssertFalse(document.unlock(withPassword: "wrong"))
        XCTAssertTrue(document.unlock(withPassword: "correct horse battery"))
        XCTAssertTrue(try XCTUnwrap(document.string).contains("Alex Moreau"))
    }

    func testTheNameIsNotReadableWithoutIt() throws {
        let data = try Resume.sample.render(design: .ledger, password: "correct horse battery")
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))
        XCTAssertFalse(raw.contains("Alex Moreau"), "the name is in the clear")
    }
}
