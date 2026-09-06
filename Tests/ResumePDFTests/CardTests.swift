//
//  CardTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The card: what it encodes, how big it is, and what a printer gets.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class CardTests: XCTestCase {

    private func text(of data: Data) throws -> String {
        try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).string)
    }

    // MARK: The contact record

    func testTheCodeIsAVCardBuiltFromTheProfile() {
        let payload = Card.sample.codePayload

        XCTAssertTrue(payload.hasPrefix("BEGIN:VCARD\r\nVERSION:3.0"), payload)
        XCTAssertTrue(payload.hasSuffix("END:VCARD"))
        XCTAssertTrue(payload.contains("FN:Alex Moreau"))
        XCTAssertTrue(payload.contains("ORG:Stripe"))
        XCTAssertTrue(payload.contains("TITLE:Infrastructure Engineer"))
        XCTAssertTrue(payload.contains("TEL;TYPE=WORK,VOICE:+44 7700 900123"))
        XCTAssertTrue(payload.contains("EMAIL;TYPE=WORK,INTERNET:alex@moreau.dev"))
        XCTAssertTrue(payload.contains("URL:https://github.com/alexmoreau"))

        // CRLF throughout, which the specification requires and some readers
        // enforce.
        XCTAssertFalse(payload.contains("\n") && !payload.contains("\r\n"))
    }

    func testAnEmptyFieldIsDroppedRatherThanWrittenBlank() {
        let bare = Card(profile: Profile(name: "Alex Moreau"))
        let payload = bare.codePayload

        XCTAssertTrue(payload.contains("FN:Alex Moreau"))
        XCTAssertFalse(payload.contains("TEL"), "a blank phone number is worse than none")
        XCTAssertFalse(payload.contains("EMAIL"))
        XCTAssertFalse(payload.contains("ORG"))
        XCTAssertFalse(payload.contains("ADR"))
    }

    func testACardCanPointSomewhereElseInstead() {
        let card = Card(profile: Profile(name: "Alex Moreau"), code: "https://alexmoreau.dev")
        XCTAssertEqual(card.codePayload, "https://alexmoreau.dev",
                       "a card that names a payload gets it, not a vCard")
    }

    func testTheEscapingHandlesTheThingsThatEndARecordEarly() {
        // A comma or a semicolon unescaped ends a field; a Windows newline
        // unescaped ends the line. "\r\n" is ONE Character in Swift, which is
        // how it used to sail through.
        XCTAssertEqual(VCard.escaped("Moreau, Alex"), "Moreau\\, Alex")
        XCTAssertEqual(VCard.escaped("a;b"), "a\\;b")
        XCTAssertEqual(VCard.escaped("back\\slash"), "back\\\\slash")
        XCTAssertEqual(VCard.escaped("one\r\ntwo"), "one\\ntwo")
        XCTAssertEqual(VCard.escaped("one\ntwo"), "one\\ntwo")

        let awkward = Card(profile: Profile(name: "Moreau, Alex", location: "Lyon;\r\nFrance"))
        XCTAssertTrue(awkward.codePayload.contains("FN:Moreau\\, Alex"))
        XCTAssertEqual(awkward.codePayload.components(separatedBy: "\r\n").count,
                       awkward.codePayload.components(separatedBy: "\r\n").count,
                       "the record's own line ends are the only ones in it")
        XCTAssertTrue(awkward.codePayload.contains("Lyon\\;\\nFrance"))
    }

    // MARK: The title

    func testTheCardsOwnTitleWinsOverAResumesHeadline() {
        XCTAssertEqual(Card.sample.printedTitle, "Infrastructure Engineer")

        let borrowed = Card(profile: Resume.sample.profile)
        XCTAssertEqual(borrowed.printedTitle, "Senior Infrastructure Engineer",
                       "a card that names none takes the profile's")
    }

    // MARK: How big it is, and what the printer gets

    func testAStandardCardIsEightyFiveByFiftyFiveMillimetres() {
        XCTAssertEqual(CardSize.standard.width, 240.94, accuracy: 0.01)
        XCTAssertEqual(CardSize.standard.height, 155.91, accuracy: 0.01)
        XCTAssertEqual(CardSize.us.width, 252, accuracy: 0.01)
        XCTAssertEqual(CardSize.us.height, 144, accuracy: 0.01)
    }

    func testTheBleedGrowsThePageAndTheCardKeepsItsSize() throws {
        let plain = try XCTUnwrap(PDFDocument(data: try Card.sample.render(design: .plate)))
        let trim = plain.page(at: 0)!.bounds(for: .mediaBox)
        XCTAssertEqual(trim.width, CardSize.standard.width, accuracy: 0.5)
        XCTAssertEqual(trim.height, CardSize.standard.height, accuracy: 0.5)

        // 3mm all round: the page grows by 6mm each way, and the card in the
        // middle of it is still 85 × 55.
        let bled = try XCTUnwrap(PDFDocument(data: try Card.sample.render(design: .plate, bleed: 3)))
        let page = bled.page(at: 0)!.bounds(for: .mediaBox)
        XCTAssertEqual(page.width, CardSize.standard.width + 6 * pointsPerMillimetre, accuracy: 0.5)
        XCTAssertEqual(page.height, CardSize.standard.height + 6 * pointsPerMillimetre, accuracy: 0.5)
    }

    func testCropMarksStayOutOfTheCard() {
        let bleed = CardGeometry.bleed(millimetres: 3)
        let marks = CardGeometry.cropMarks(for: .standard, bleed: bleed)
        XCTAssertEqual(marks.count, 8, "two at each corner")

        // Not one of them may touch the trimmed card: a mark inside the trim
        // is a mark on somebody's finished card.
        let left = bleed, right = bleed + CardSize.standard.width
        let bottom = bleed, top = bleed + CardSize.standard.height
        for mark in marks {
            let insideX = mark.x1 > left + 0.01 && mark.x1 < right - 0.01
            let insideY = mark.y1 > bottom + 0.01 && mark.y1 < top - 0.01
            XCTAssertFalse(insideX && insideY, "a mark inside the trim: \(mark)")
        }
    }

    func testNoBleedMeansNoMarksToDrawThemIn() {
        XCTAssertTrue(CardGeometry.cropMarks(for: .standard, bleed: 0).isEmpty)
        // And too little bleed to hold a mark clear of the trim leaves them off
        // rather than printing them on the card.
        XCTAssertTrue(CardGeometry.cropMarks(for: .standard, bleed: 1).isEmpty)
    }

    // MARK: The designs

    func testEveryDesignRendersAndCarriesTheName() throws {
        for design in CardDesign.allCases {
            let data = try Card.sample.render(design: design)
            XCTAssertNotNil(PDFDocument(data: data), design.rawValue)
            XCTAssertTrue(try text(of: data).lowercased().contains("alex moreau"), design.rawValue)
        }
    }

    func testASideIsAPage() throws {
        for design in CardDesign.allCases {
            let document = try Card.sample.document(design: design)
            let expected = design.blueprint.back == nil ? 1 : 2
            XCTAssertEqual(document.pageCount(), expected, design.rawValue)
        }
    }

    func testAnElementWithNothingToShowIsSkipped() throws {
        // The same design, a profile with nothing but a name: it renders, and
        // it does not leave a gap where the contact lines would have been.
        let bare = Card(profile: Profile(name: "Alex Moreau"))
        for design in CardDesign.allCases {
            XCTAssertNoThrow(try bare.render(design: design), design.rawValue)
        }
    }

    func testTheStartingPointsAreTheFilesInTheBundle() throws {
        let folder = try XCTUnwrap(Bundle.module.url(forResource: "Cards", withExtension: nil))
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }

        XCTAssertEqual(files.count, CardBlueprint.starting.count)
        for file in files {
            let blueprint = try CardBlueprint(contentsOf: file)
            XCTAssertEqual(blueprint.name, file.deletingPathExtension().lastPathComponent)
        }
        for design in CardDesign.allCases {
            XCTAssertTrue(CardBlueprint.starting.contains(design.blueprint), design.rawValue)
        }
    }

    // MARK: Written by hand

    func testTheSmallestCardDesignIsANameAndNothingElse() throws {
        let blueprint = try JSONDecoder().decode(
            CardBlueprint.self,
            from: XCTUnwrap(#"{"name": "mine", "front": {"content": ["name"]}}"#.data(using: .utf8))
        )
        XCTAssertEqual(blueprint.name, "mine")
        XCTAssertEqual(blueprint.front.content, [.name])
        XCTAssertNil(blueprint.back, "one side unless a design asks for two")
        XCTAssertEqual(blueprint.size, .standard)
        XCTAssertNoThrow(try Card.sample.render(design: blueprint))
    }

    func testAMisspelledElementNamesTheRealOnes() {
        XCTAssertThrowsError(try JSONDecoder().decode(
            CardBlueprint.self,
            from: XCTUnwrap(#"{"front": {"content": ["nmae"]}}"#.data(using: .utf8))
        )) {
            let message = "\($0)"
            XCTAssertTrue(message.contains("card element"), message)
            XCTAssertTrue(message.contains("organisation"), "it should list them: \(message)")
        }
    }

    func testACardReadsFromTheJSONShapeSomebodyWouldType() throws {
        let json = """
        {
          "profile": { "name": "Alex Moreau", "email": "alex@moreau.dev" },
          "organisation": "Stripe",
          "title": "Infrastructure Engineer"
        }
        """
        let card = try JSONDecoder().decode(Card.self, from: XCTUnwrap(json.data(using: .utf8)))
        XCTAssertEqual(card.organisation, "Stripe")
        XCTAssertEqual(card.printedTitle, "Infrastructure Engineer")
        XCTAssertTrue(card.tagline.isEmpty, "everything but the profile is optional")
        XCTAssertTrue(card.codePayload.contains("EMAIL;TYPE=WORK,INTERNET:alex@moreau.dev"))
    }

    // MARK: The identity set

    func testTheThreeDocumentsAgreeAboutTheSamePerson() {
        // The whole argument for one Profile: a card, a résumé and a letter
        // that disagree about a phone number look assembled.
        XCTAssertEqual(Card.sample.profile.email, Resume.sample.profile.email)
        XCTAssertEqual(Card.sample.profile.phone, CoverLetter.sample.profile.phone)

        // And every card design names the résumé design it sits beside.
        for design in CardDesign.allCases {
            XCTAssertTrue(DesignKind.allCases.contains(design.pairsWith), design.rawValue)
        }
    }
}
