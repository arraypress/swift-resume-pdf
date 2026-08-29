//
//  DocxTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé as a .docx: everything the PDF carries, in the same order,
//  under the same headings — and read back by the system's own reader to
//  prove the order survives.
//

import Foundation
import TextDocx
import XCTest
@testable import ResumePDF

final class DocxTests: XCTestCase {

    private func body(of resume: Resume, theme: Theme = .plain) throws -> String {
        let members = Docx.members(of: resume.docx(theme: theme))
        return try XCTUnwrap(String(data: try XCTUnwrap(members["word/document.xml"]), encoding: .utf8))
    }

    private func styles(of resume: Resume, theme: Theme = .plain) throws -> String {
        let members = Docx.members(of: resume.docx(theme: theme))
        return try XCTUnwrap(String(data: try XCTUnwrap(members["word/styles.xml"]), encoding: .utf8))
    }

    private func count(_ needle: String, in haystack: String) -> Int {
        haystack.components(separatedBy: needle).count - 1
    }

    /// The text as it appears inside the XML.
    private func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: What is written

    func testEverySectionIsAHeadingInOrder() throws {
        let sample = Resume.sample
        let xml = try body(of: sample)

        XCTAssertEqual(count("<w:pStyle w:val=\"Heading1\"/>", in: xml), sample.populated().count)

        var last = xml.startIndex
        for section in sample.populated() {
            let title = escaped(sample.heading(for: section))
            let range = try XCTUnwrap(xml.range(of: ">\(title)</w:t>", range: last..<xml.endIndex), title)
            last = range.upperBound
        }
    }

    func testTheHeadIsTheNameTheHeadlineAndTheContacts() throws {
        let xml = try body(of: Resume.sample)
        XCTAssertTrue(xml.contains("<w:pStyle w:val=\"Title\"/></w:pPr><w:r><w:t xml:space=\"preserve\">Alex Moreau</w:t>"))
        XCTAssertTrue(xml.contains("<w:pStyle w:val=\"Subtitle\"/></w:pPr><w:r><w:t xml:space=\"preserve\">Senior Infrastructure Engineer</w:t>"))
        XCTAssertTrue(xml.contains("<w:hyperlink r:id=\"rId3\">"), "the email is a link")

        let rels = Docx.members(of: Resume.sample.docx())["word/_rels/document.xml.rels"].flatMap { String(data: $0, encoding: .utf8) } ?? ""
        XCTAssertTrue(rels.contains("mailto:alex@moreau.dev"), rels)
        XCTAssertTrue(rels.contains("https://github.com/alexmoreau"), rels)
    }

    func testEveryHighlightIsABullet() throws {
        let sample = Resume.sample
        let highlights = sample.experience.flatMap(\.highlights).count
            + sample.education.flatMap(\.highlights).count
            + sample.projects.flatMap(\.highlights).count
        XCTAssertEqual(count("<w:numPr>", in: try body(of: sample)), highlights)
    }

    func testADateSitsAgainstTheRightMargin() throws {
        let xml = try body(of: Resume.sample)
        XCTAssertTrue(xml.contains("<w:tab w:val=\"right\""))
        XCTAssertTrue(xml.contains("<w:r><w:tab/></w:r><w:r><w:rPr><w:color w:val=\"595959\"/><w:sz w:val=\"19\"/></w:rPr><w:t xml:space=\"preserve\">Mar 2022 – Present</w:t>"), xml)
    }

    func testNothingThePDFPrintsIsLeftOut() throws {
        let sample = Resume.sample
        let xml = try body(of: sample)
        for word in ["Stripe", "Monzo", "Deliveroo", "BSc Computer Science", "University of Bristol",
                     "First Class Honours", "Kubernetes", "ledgerfuzz", "CKA", "CNCF", "French"] {
            XCTAssertTrue(xml.contains(escaped(word)), "\(word) is missing")
        }
    }

    func testTheLabelsAreTheDocumentsOwn() throws {
        let lebenslauf = Resume(
            profile: Profile(name: "Anna Weber", email: "a@w.de", dateOfBirth: "12.03.1990", nationality: "deutsch"),
            experience: [Position(role: "Entwicklerin", organisation: "SAP", dates: .since("2020"))],
            labels: .german
        )
        let xml = try body(of: lebenslauf)
        XCTAssertTrue(xml.contains(">Berufserfahrung</w:t>"), xml)
        XCTAssertTrue(xml.contains("2020 – heute"), "the present is said in the document's language")
        XCTAssertTrue(xml.contains("Date of birth: </w:t>") && xml.contains(">12.03.1990</w:t>"), "particulars are carried")
    }

    func testCustomSectionsAreWritten() throws {
        let resume = Resume(
            profile: Profile(name: "A"),
            custom: [CustomSection("Patents", [.prose("Two granted."), .list(["GB2601234"]),
                                               .positions([Position(role: "Named inventor", organisation: "Stripe")])])],
            order: [.custom("Patents")]
        )
        let xml = try body(of: resume)
        XCTAssertTrue(xml.contains(">Patents</w:t>"))
        XCTAssertTrue(xml.contains(">Two granted.</w:t>"))
        XCTAssertEqual(count("<w:numPr>", in: xml), 1)
        XCTAssertTrue(xml.contains(">Named inventor</w:t>"))
    }

    func testTheThemeReachesTheFile() throws {
        let letter = Theme(accent: "#1F3A5F", pageSize: .letter, density: .compact)
        let xml = try body(of: Resume.sample, theme: letter)
        XCTAssertTrue(xml.contains("<w:pgSz w:w=\"12240\" w:h=\"15840\"/>"), "letter")
        XCTAssertTrue(xml.contains("w:top=\"880\""), "compact margins are 44pt")
        XCTAssertTrue(try styles(of: Resume.sample, theme: letter).contains("<w:color w:val=\"1F3A5F\"/>"))

        XCTAssertTrue(try styles(of: Resume.sample, theme: Theme(typeface: .sourceSerif)).contains("w:ascii=\"Georgia\""))
        XCTAssertTrue(try styles(of: Resume.sample, theme: .plain).contains("w:ascii=\"Calibri\""))
        XCTAssertFalse(try styles(of: Resume.sample, theme: .plain).contains("<w:caps/><w:color"),
                       "the plain theme is monochrome, so the headings take the text colour")
    }

    func testAJSONResumeWritesToo() throws {
        let resume = try Resume(jsonResumeData: Data(JSONResumeTests.canonical.utf8))
        let xml = try body(of: resume)
        XCTAssertTrue(xml.contains(">Richard Hendriks</w:t>"))
        XCTAssertTrue(xml.contains("Pied Piper"))
    }

    func testTheSameRésuméIsTheSameFile() {
        XCTAssertEqual(Resume.sample.docx(), Resume.sample.docx())
    }

    // MARK: Read back by the system

    #if os(macOS)
    private func textutil(_ resume: Resume) throws -> String {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).docx")
        try resume.saveDocx(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", "txt", "-stdout", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }

    func testTheSystemReadsItBackInOrder() throws {
        let sample = Resume.sample
        let text = try textutil(sample)

        XCTAssertTrue(text.hasPrefix("Alex Moreau"), "the name comes first: \(text.prefix(40))")

        var last = text.startIndex
        for section in sample.populated() {
            let title = sample.heading(for: section)
            let range = try XCTUnwrap(text.range(of: title, range: last..<text.endIndex), "\(title) out of order")
            last = range.upperBound
        }
        XCTAssertTrue(text.contains("Rebuilt the ledger write path"))
        XCTAssertTrue(text.contains("Mar 2022 – Present"))
    }
    #endif
}
