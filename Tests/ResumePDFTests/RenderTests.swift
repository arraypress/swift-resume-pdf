//
//  RenderTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What comes out, read back by somebody else's parser.
//
//  PDFKit extracts text the way an applicant tracking system does — in the
//  order the content stream puts it, with no idea which column anything was
//  in. That makes it a fair stand-in for the thing these documents have to
//  survive, and it is why the reading-order tests below are worth more than
//  any assertion about the bytes.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class RenderTests: XCTestCase {

    private func read(_ resume: Resume, design: DesignKind, theme: Theme = .plain) throws -> String {
        let data = try resume.render(design: design, theme: theme)
        let document = try XCTUnwrap(PDFDocument(data: data), "PDFKit refused \(design.rawValue)")
        return try XCTUnwrap(document.string)
    }

    /// Where `needle` first appears at or after `from`, or nil.
    ///
    /// Case-insensitive, because a masthead is a design decision: Broadsheet
    /// sets the name in capitals and that is not a fault to assert against.
    private func position(of needle: String, in haystack: String, after from: Int = 0) -> Int? {
        let start = haystack.index(haystack.startIndex, offsetBy: min(from, haystack.count))
        return haystack
            .range(of: needle, options: .caseInsensitive, range: start..<haystack.endIndex)
            .map { haystack.distance(from: haystack.startIndex, to: $0.lowerBound) }
    }

    // MARK: Every design

    func testEveryDesignProducesAReadableDocument() throws {
        for design in DesignKind.allCases {
            let text = try read(.sample, design: design, theme: Theme(typeface: design.intendedTypeface))

            for expected in ["Alex Moreau", "Senior Infrastructure Engineer", "Stripe", "alex@moreau.dev"] {
                XCTAssertTrue(text.contains(expected), "\(design.rawValue) lost \"\(expected)\"")
            }
        }
    }

    func testAccentedAndNonLatinNamesSurvive() throws {
        // The bundled faces cover rather more than Windows-1252, and the
        // ToUnicode map is what makes the text searchable afterwards. A name
        // that renders but does not extract fails every keyword search.
        let resume = Resume(
            profile: Profile(name: "Ingrid Sørensen", email: "i@s.dk"),
            experience: [Position(role: "Ingénieur", organisation: "Ærø Kommune", dates: DateRange("2020", "2022"))]
        )
        let text = try read(resume, design: .ledger)

        XCTAssertTrue(text.contains("Sørensen"), text)
        XCTAssertTrue(text.contains("Ingénieur"), text)
        XCTAssertTrue(text.contains("Ærø"), text)
    }

    func testCyrillicSurvivesToo() throws {
        let resume = Resume(
            profile: Profile(name: "Мария Иванова", email: "m@i.ru"),
            experience: [Position(role: "Инженер", dates: DateRange("2020", "2022"))]
        )
        let text = try read(resume, design: .ledger)
        XCTAssertTrue(text.contains("Иванова"), text)
    }

    // MARK: Reading order

    func testASingleColumnDesignExtractsInReadingOrder() throws {
        // The claim the whole library rests on. If this fails, the "safe
        // anywhere" designs are not.
        for design in DesignKind.allCases where design.isSingleColumn {
            let text = try read(.sample, design: design, theme: Theme(typeface: design.intendedTypeface))

            let name = try XCTUnwrap(position(of: "Alex Moreau", in: text), design.rawValue)
            let summary = try XCTUnwrap(position(of: "Infrastructure engineer with", in: text), design.rawValue)
            let firstRole = try XCTUnwrap(position(of: "Senior Infrastructure Engineer", in: text), design.rawValue)
            let firstEmployer = try XCTUnwrap(position(of: "Stripe", in: text), design.rawValue)
            let secondEmployer = try XCTUnwrap(position(of: "Monzo", in: text), design.rawValue)
            let education = try XCTUnwrap(position(of: "University of Bristol", in: text), design.rawValue)

            XCTAssertLessThan(name, summary, "\(design.rawValue): name after summary")
            XCTAssertLessThan(summary, firstEmployer, "\(design.rawValue): summary after experience")
            XCTAssertLessThan(firstRole, firstEmployer, "\(design.rawValue): role after its employer")
            XCTAssertLessThan(firstEmployer, secondEmployer, "\(design.rawValue): employers out of order")
            XCTAssertLessThan(secondEmployer, education, "\(design.rawValue): education before experience")
        }
    }

    func testEachRoleStaysWithItsOwnEmployer() throws {
        // Interleaving's signature failure: a role landing away from the
        // employer it belongs to. Each role should be immediately followed by
        // its own employer, with only the dates in between.
        //
        // Searched from the end of the summary, because the sample's headline
        // is the same string as its current job title — which is realistic,
        // and would otherwise match the masthead rather than the entry.
        let text = try read(.sample, design: .ledger)
        let bodyStart = try XCTUnwrap(position(of: "change safely", in: text))

        let pairs = [("Senior Infrastructure Engineer", "Stripe"),
                     ("Platform Engineer", "Monzo"),
                     ("Backend Engineer", "Deliveroo")]

        for (role, employer) in pairs {
            let rolePosition = try XCTUnwrap(position(of: role, in: text, after: bodyStart), role)
            let employerPosition = try XCTUnwrap(position(of: employer, in: text, after: bodyStart), employer)

            XCTAssertLessThan(rolePosition, employerPosition, "\(role) should precede \(employer)")
            XCTAssertLessThan(
                employerPosition - rolePosition, role.count + 40,
                "\(role) and \(employer) drifted apart — something is between them"
            )
        }
    }

    func testTheSidebarGenuinelyInterleaves() throws {
        // The warning has to be honest. If the sidebar extracted cleanly the
        // blocker would be scaremongering, and people would rightly stop
        // believing the other findings.
        let text = try read(.sample, design: .sidebar)

        let firstEmployer = try XCTUnwrap(position(of: "Stripe", in: text))
        let railSkills = try XCTUnwrap(position(of: "Kubernetes, Terraform", in: text))
        let lastMainEntry = try XCTUnwrap(position(of: "ledgerfuzz", in: text))

        // The rail's skills come out before the experience they sit beside,
        // and the education in the rail lands before the summary's own
        // section — which is precisely what a parser cannot untangle.
        XCTAssertLessThan(railSkills, firstEmployer, "the rail should extract before the main column")
        XCTAssertLessThan(railSkills, lastMainEntry)
    }

    // MARK: Structure

    func testTheDocumentIsTitledWithTheCandidatesName() throws {
        let data = try Resume.sample.render()
        let document = try XCTUnwrap(PDFDocument(data: data))
        let attributes = try XCTUnwrap(document.documentAttributes)

        let title = try XCTUnwrap(attributes[PDFDocumentAttribute.titleAttribute] as? String)
        XCTAssertTrue(title.contains("Alex Moreau"), title)
        XCTAssertEqual(attributes[PDFDocumentAttribute.authorAttribute] as? String, "Alex Moreau")
    }

    func testSkillsAreCarriedAsKeywords() throws {
        let data = try Resume.sample.render()
        let document = try XCTUnwrap(PDFDocument(data: data))
        let keywords = try XCTUnwrap(document.documentAttributes?[PDFDocumentAttribute.keywordsAttribute])

        // PDFKit hands keywords back as either a string or an array.
        let text = (keywords as? String) ?? (keywords as? [String])?.joined(separator: ", ") ?? ""
        XCTAssertTrue(text.contains("Kubernetes"), text)
    }

    func testAnEmptyResumeStillProducesAPage() throws {
        // A half-filled form should not crash the renderer.
        let data = try Resume(profile: Profile(name: "A")).render()
        let document = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertEqual(document.pageCount, 1)
    }

    func testDensityChangesTheLength() throws {
        let relaxed = try Resume.sample.document(theme: Theme(density: .relaxed)).pageCount()
        let compact = try Resume.sample.document(theme: Theme(density: .compact)).pageCount()
        XCTAssertLessThanOrEqual(compact, relaxed)

        // And the text is unchanged by it.
        let text = try read(.sample, design: .ledger, theme: Theme(density: .compact))
        XCTAssertTrue(text.contains("Rebuilt the double-entry ledger"))
    }

    func testTheLetterPageSizeIsHonoured() throws {
        let data = try Resume.sample.render(theme: .american)
        let document = try XCTUnwrap(PDFDocument(data: data))
        let bounds = try XCTUnwrap(document.page(at: 0)).bounds(for: .mediaBox)

        XCTAssertEqual(bounds.width, 612, accuracy: 1)
        XCTAssertEqual(bounds.height, 792, accuracy: 1)
    }

    func testOnlyTheUsedWeightsAreEmbedded() throws {
        // Inter ships five faces here. A document that used three should
        // carry three subsets, not five.
        let data = try Resume.sample.render()
        let raw = try XCTUnwrap(String(data: data, encoding: .isoLatin1))
        let embedded = raw.components(separatedBy: "/FontFile2").count - 1

        XCTAssertGreaterThan(embedded, 1, "more than one weight should be in use")
        XCTAssertLessThanOrEqual(embedded, 5)
    }

    func testTheFileStaysSmall() throws {
        // Three subset faces and a page of text. If this jumps, something has
        // started embedding whole fonts.
        let data = try Resume.sample.render()
        XCTAssertLessThan(data.count, 200_000, "\(data.count) bytes")
    }
}

// MARK: - Later additions

extension RenderTests {

    func testNoDesignPrintsTheSummaryTwice() throws {
        // Slate sets the summary in a masthead panel. Rendering it again as a
        // section put the same paragraph on the page twice, which reads as a
        // copy-and-paste error by the candidate rather than by the tool.
        for design in DesignKind.allCases {
            let text = try read(.sample, design: design,
                                theme: Theme(typeface: design.intendedTypeface))
            let opening = "Infrastructure engineer with eleven years"
            XCTAssertEqual(
                text.components(separatedBy: opening).count - 1, 1,
                "\(design.rawValue) printed the summary more than once"
            )
        }
    }

    func testContactDetailsAreClickable() throws {
        let data = try Resume.sample.render()
        let document = try XCTUnwrap(PDFDocument(data: data))
        let page = try XCTUnwrap(document.page(at: 0))

        let urls = page.annotations.compactMap { $0.url?.absoluteString }
        XCTAssertTrue(urls.contains("mailto:alex@moreau.dev"), "\(urls)")
        XCTAssertTrue(urls.contains { $0.contains("github.com/alexmoreau") }, "\(urls)")
    }

    func testTheLocationIsNotALink() throws {
        // It is the one contact detail that is not a way of reaching somebody.
        let data = try Resume.sample.render()
        let page = try XCTUnwrap(try XCTUnwrap(PDFDocument(data: data)).page(at: 0))
        let urls = page.annotations.compactMap { $0.url?.absoluteString }

        XCTAssertFalse(urls.contains { $0.contains("London") })
    }

    func testTheDocumentDeclaresItsLanguage() throws {
        let english = try XCTUnwrap(String(data: try Resume.sample.render(), encoding: .isoLatin1))
        XCTAssertTrue(english.contains("/Lang (en)"))

        var german = Resume.sample
        german = Resume(profile: german.profile, summary: german.summary,
                        experience: german.experience, labels: .german)
        let raw = try XCTUnwrap(String(data: try german.render(), encoding: .isoLatin1))
        XCTAssertTrue(raw.contains("/Lang (de)"))
    }

    func testFittingChoosesTheLoosestDensityThatWorks() throws {
        // The sample runs to two pages at normal density, so asking for two
        // should settle on the relaxed setting rather than tightening at all.
        let two = try XCTUnwrap(try Resume.sample.fitted(to: 2))
        XCTAssertEqual(two.density, .relaxed)

        // And a résumé that cannot be made to fit says so rather than
        // returning something that does not.
        let long = Resume(
            profile: Resume.sample.profile,
            experience: Array(repeating: Resume.sample.experience[0], count: 12)
        )
        XCTAssertNil(try long.fitted(to: 1))
    }

    func testTheCVSectionsRender() throws {
        let cv = Resume(
            profile: Profile(name: "Dr Ingrid Sørensen", email: "i@ed.ac.uk"),
            experience: [Position(role: "Reader", organisation: "Edinburgh", dates: .since("2021"))],
            grants: [Grant(title: "Morphology at scale", funder: "EPSRC", amount: "£1.2m",
                           dates: DateRange("2022", "2026"), role: "Principal investigator",
                           identifier: "EP/X01234/1")],
            teaching: [Position(role: "Computational Morphology", organisation: "Edinburgh",
                                dates: .since("2021"))],
            talks: [Publication(title: "What morphology costs a language model",
                                venue: "ACL keynote", date: "2024")],
            service: [Position(role: "Area chair", organisation: "EMNLP", dates: DateRange("2023"))],
            memberships: [Credential(name: "Association for Computational Linguistics")],
            order: Section.academic
        )

        // Case-insensitive: every design sets its section headings in
        // capitals, which is a design decision and not a fact to assert on.
        let text = try read(cv, design: .broadsheet, theme: .classic)
        for expected in ["Grants and Funding", "EPSRC", "£1.2m", "Principal investigator",
                         "Teaching", "Talks", "Service", "Memberships"] {
            XCTAssertNotNil(
                text.range(of: expected, options: .caseInsensitive),
                "\"\(expected)\" missing"
            )
        }
    }
}
