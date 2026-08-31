//
//  SupportRuleTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The extracted rules pinned directly — dates, dial strings and colour
//  arithmetic, none of it needing a résumé built first.
//

import Foundation
import TextPDF
import XCTest
@testable import ResumePDF

final class SupportRuleTests: XCTestCase {

    func testJSONResumeDatesPrintAsAResumeWrites() {
        XCTAssertEqual(JSONResume.date("2022-03-15"), "Mar 2022")
        XCTAssertEqual(JSONResume.date("2022-03"), "Mar 2022")
        XCTAssertEqual(JSONResume.date("2022"), "2022")
        XCTAssertEqual(JSONResume.date("Summer 2019"), "Summer 2019", "somebody who typed it meant it")
        XCTAssertEqual(JSONResume.date(nil), "")
    }

    func testDateRangeRules() {
        XCTAssertEqual(JSONResume.dated("2020-01", "2020-01").rendered(), "Jan 2020",
                       "started and finished in one month is a date, not a range")
        XCTAssertEqual(JSONResume.ongoing("2020-01", nil).rendered(), "Jan 2020 \u{2013} Present")
        XCTAssertEqual(JSONResume.dated("2020-01", "2021-02").rendered(), "Jan 2020 \u{2013} Feb 2021")
    }

    func testDialStrings() {
        XCTAssertEqual(ContactRules.dialable("+44 (0)20 7946 0958"), "+442079460958",
                       "the trunk digit comes out of the dial string")
        XCTAssertEqual(ContactRules.dialURL("+44 (0)20 7946 0958"), "tel:+442079460958")
        XCTAssertEqual(ContactRules.dialURL("ask reception"), "", "words are not a number")
    }

    func testLinkShortening() {
        XCTAssertEqual(Link.shorten("https://www.github.com/alexmorgan/"), "github.com/alexmorgan")
        XCTAssertEqual(Link.shorten("http://example.com"), "example.com")
    }

    func testColourArithmetic() {
        XCTAssertEqual(Color.grey(0).lightened(by: 1), Color.grey(255))
        XCTAssertEqual(Color.grey(200).darkened(by: 1), Color.grey(0))
        XCTAssertGreaterThan(Color(red: 0, green: 255, blue: 0).luminance,
                             Color(red: 0, green: 0, blue: 255).luminance,
                             "the eye weights green over blue")
    }
}
