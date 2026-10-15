//
//  StrictContentTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A résumé, a letter and a card are typed by hand, so a misspelt key is
//  refused with the one it was probably meant to be — never ignored, which
//  would print a résumé with a role quietly missing.
//

import XCTest
@testable import ResumePDF

final class StrictContentTests: XCTestCase {

    private func refusal<T: Decodable>(_ json: String, as type: T.Type) -> String {
        do { _ = try JSONDecoder().decode(type, from: Data(json.utf8)); return "(read)" } catch {
            return Decoding.describe(error)
        }
    }

    func testAMisspeltResumeKeyIsRefused() {
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "experiance": []}"#, as: Resume.self),
                       "experiance is not a résumé field — did you mean experience?")
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "experience": [{"role": "R", "organization": "O"}]}"#, as: Resume.self),
                       "experience.0.organization is not a résumé field — did you mean experience.0.organisation?")
        XCTAssertEqual(refusal(#"{"profile": {"name": "A", "emial": "a@b.co"}}"#, as: Resume.self),
                       "profile.emial is not a profile field — did you mean profile.email?")
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "education": [{"qualification": "BSc", "dates": {"start": "2010", "edn": "2013"}}]}"#, as: Resume.self),
                       "education.0.dates.edn is not a résumé field — did you mean education.0.dates.end?")
    }

    func testTheToolsKeysBesideTheDocumentAreLetThrough() throws {
        let resume = try JSONDecoder().decode(Resume.self, from: Data(
            ##"{"profile": {"name": "A"}, "design": "split", "theme": {"accent": "#111111"}, "letterDesign": "panel", "extends": "b.json"}"##.utf8))
        XCTAssertEqual(resume.profile.name, "A")
    }

    func testAMisspeltLetterOrCardKeyIsRefused() {
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "recipient": {"name": "B"}, "bodyy": ["x"]}"#, as: CoverLetter.self),
                       "bodyy is not a letter field — did you mean body?")
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "recipient": {"name": "B", "organization": "O"}}"#, as: CoverLetter.self),
                       "recipient.organization is not a letter field — did you mean recipient.organisation?")
        XCTAssertEqual(refusal(#"{"profile": {"name": "A"}, "taglin": "x"}"#, as: Card.self),
                       "taglin is not a card field — did you mean tagline?")
    }

    func testEverySampleStillReads() throws {
        for resume in [Resume.sample, Resume.academicSample, Resume.brief] {
            XCTAssertEqual(try JSONDecoder().decode(Resume.self, from: JSONEncoder().encode(resume)), resume)
        }
        XCTAssertEqual(try JSONDecoder().decode(CoverLetter.self, from: JSONEncoder().encode(CoverLetter.sample)), CoverLetter.sample)
        XCTAssertEqual(try JSONDecoder().decode(Card.self, from: JSONEncoder().encode(Card.sample)), Card.sample)
    }
}
