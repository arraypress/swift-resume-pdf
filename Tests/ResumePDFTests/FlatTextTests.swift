//
//  FlatTextTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé as the text somebody pastes into a form, and as Markdown.
//

import TextDocx
import XCTest
@testable import ResumePDF

final class FlatTextTests: XCTestCase {

    func testTheTextIsTheDocumentInOrder() {
        let text = Resume.sample.plainText()
        XCTAssertTrue(text.hasPrefix("Alex Moreau\nSenior Infrastructure Engineer\n"), text.prefix(60).description)
        XCTAssertTrue(text.contains("alex@moreau.dev | +44 7700 900123 | London, UK"), "contacts on one line, separated")

        var last = text.startIndex
        for section in Resume.sample.populated() {
            let title = Resume.sample.heading(for: section).uppercased()
            guard let range = text.range(of: "\n\(title)\n", range: last..<text.endIndex) else {
                return XCTFail("\(title) out of order in:\n\(text)")
            }
            last = range.upperBound
        }
    }

    func testAnEntryCarriesItsDateAndItsBullets() {
        let text = Resume.sample.plainText()
        XCTAssertTrue(text.contains("Senior Infrastructure Engineer (Mar 2022 – Present)\nStripe · London\n- Rebuilt the ledger write path"), text)
        XCTAssertTrue(text.contains("\nGo, Postgres, Kubernetes, Terraform\n"), "skills under an entry")
        XCTAssertTrue(text.contains("Languages: Go, Swift, Python, SQL"), "a skill group")
        XCTAssertTrue(text.contains("English — Native"), "a language and its level")
    }

    func testNothingIsWrapped() {
        // A form reflows its own text; a hard break inside a sentence is what
        // makes a pasted résumé look pasted.
        let text = Resume.sample.plainText()
        for line in text.split(separator: "\n") where line.hasPrefix("- ") {
            XCTAssertTrue(line.hasSuffix(".") || line.count < 60, "a bullet was broken: \(line)")
        }
        XCTAssertTrue(text.contains(Resume.sample.summary), "the summary is one line however long")
    }

    func testTheLabelsAreTheDocumentsOwn() {
        let lebenslauf = Resume(
            profile: Profile(name: "Anna Weber", dateOfBirth: "12.03.1990"),
            experience: [Position(role: "Entwicklerin", organisation: "SAP", dates: .since("2020"))],
            labels: .german
        )
        let text = lebenslauf.plainText()
        XCTAssertTrue(text.contains("\nBERUFSERFAHRUNG\n"))
        XCTAssertTrue(text.contains("(2020 – heute)"))
        XCTAssertTrue(text.contains("Date of birth: 12.03.1990"))
    }

    func testMarkdownKeepsTheEmphasis() {
        let markdown = Resume.sample.markdown()
        XCTAssertTrue(markdown.hasPrefix("# Alex Moreau\n**Senior Infrastructure Engineer**\n"))
        XCTAssertTrue(markdown.contains("[github.com/alexmoreau](https://github.com/alexmoreau)"), "links are links")
        XCTAssertTrue(markdown.contains("\n## Experience\n"))
        XCTAssertTrue(markdown.contains("**Senior Infrastructure Engineer** — _Mar 2022 – Present_"))
        XCTAssertTrue(markdown.contains("\n- Rebuilt the ledger write path"))
        XCTAssertTrue(markdown.contains("**Languages:** Go, Swift, Python, SQL"))
    }

    func testALetterReadsTopToBottom() {
        let text = CoverLetter.sample.plainText()
        XCTAssertTrue(text.hasPrefix("Alex Moreau\n"))
        for expected in ["14 August 2026", "Ms Adaeze Okonkwo\nHead of Infrastructure\nNorthwind Payments",
                         "Re: Staff Infrastructure Engineer", "Dear Ms Adaeze Okonkwo,",
                         "- Ledger reliability. Rebuilt a write path", "Yours sincerely,", "Alex Moreau\n"] {
            XCTAssertTrue(text.contains(expected), "\(expected) is missing from:\n\(text)")
        }
        let date = text.range(of: "14 August 2026")!.lowerBound
        let greeting = text.range(of: "Dear Ms")!.lowerBound
        let signOff = text.range(of: "Yours sincerely")!.lowerBound
        XCTAssertLessThan(date, greeting)
        XCTAssertLessThan(greeting, signOff)

        let markdown = CoverLetter.sample.markdown()
        XCTAssertTrue(markdown.contains("**Re: Staff Infrastructure Engineer (ref. NW-2291)**"))
        XCTAssertTrue(markdown.contains("- **Ledger reliability.** Rebuilt"))
    }

    func testEveryWordOfTheWordDocumentIsInTheText() throws {
        // The two are the same outline; a block that reached one and not the
        // other would be a renderer dropping something on the floor.
        let members = Docx.members(of: Resume.sample.docx())
        let xml = try XCTUnwrap(String(data: try XCTUnwrap(members["word/document.xml"]), encoding: .utf8))
        let text = Resume.sample.plainText()
        for word in ["Stripe", "Monzo", "Deliveroo", "University of Bristol", "ledgerfuzz", "CNCF", "French"] {
            XCTAssertTrue(xml.contains(word) && text.contains(word), word)
        }
    }
}
