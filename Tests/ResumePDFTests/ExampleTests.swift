//
//  ExampleTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The examples in the repository, written by the library that makes them.
//
//  A design is a thing you look at, and a list of names is not one — so every
//  design, every letter design and every blueprint is committed as a PDF
//  somebody can open before installing anything.
//
//  They are generated rather than curated, so nothing can go stale quietly:
//
//      WRITE_EXAMPLES=1 swift test --filter ExampleTests
//
//  The creation date is pinned. A PDF carries one, so regenerating would
//  otherwise rewrite every file whether or not anything about it changed, and
//  a diff that is always noise is a diff nobody reads.
//

import PDFKit
import XCTest
@testable import ResumePDF

final class ExampleTests: XCTestCase {

    /// Somewhere stable, so the same content produces the same bytes.
    private static let stamped = Date(timeIntervalSince1970: 1_776_000_000)

    private var writing: Bool { ProcessInfo.processInfo.environment["WRITE_EXAMPLES"] == "1" }

    private var directory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ResumePDFTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // the package
            .appendingPathComponent("Examples", isDirectory: true)
    }

    private func put(_ data: Data, _ name: String) throws {
        // Rendered either way: the point of doing this in a test is that every
        // example is proved to render on every run, not only when written.
        XCTAssertNotNil(PDFDocument(data: data), "\(name) is not a readable PDF")
        XCTAssertGreaterThan(data.count, 2_000, "\(name) came out suspiciously small")

        guard writing else { return }
        let file = directory.appendingPathComponent(name)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: file)
    }

    // MARK: The documents

    func testEveryDesign() throws {
        for design in DesignKind.allCases {
            let document = try Resume.sample.document(
                design: design, theme: Theme(typeface: design.intendedTypeface)
            )
            try put(document.render(creationDate: Self.stamped), "designs/\(design.rawValue).pdf")
        }
    }

    func testEveryLetterDesign() throws {
        for design in LetterDesign.allCases {
            let document = try CoverLetter.sample.document(
                design: design, theme: Theme(typeface: design.intendedTypeface)
            )
            try put(document.render(creationDate: Self.stamped), "letters/\(design.rawValue).pdf")
        }
    }

    func testEveryBlueprint() throws {
        for blueprint in Blueprint.starting {
            let document = try Resume.sample.document(
                design: blueprint, theme: Theme(typeface: blueprint.typeface.typeface)
            )
            try put(document.render(creationDate: Self.stamped), "blueprints/\(blueprint.name).pdf")
        }

        for blueprint in LetterBlueprint.starting {
            let document = try CoverLetter.sample.document(design: blueprint)
            try put(document.render(creationDate: Self.stamped),
                    "blueprints/letter-\(blueprint.name).pdf")
        }

        // The one treatment no starting point uses, because it is a choice
        // about the document rather than a look: several short roles suit it,
        // one long one does not.
        var perEntry = Blueprint.carded
        perEntry.ornament = .entryCards
        try put(try Resume.sample.document(design: perEntry).render(creationDate: Self.stamped),
                "blueprints/entry-cards.pdf")
    }

    func testTheThemesEveryDesignGets() throws {
        // The axis most tools spend a dozen templates on.
        let themes: [(String, Theme)] = [
            ("navy", Theme(accent: "#1F3A5F")),
            ("dark", .midnight),
            ("paper", .paper),
            ("compact", Theme(density: .compact)),
            ("justified", Theme(justified: true)),
            ("serif", Theme(typeface: .sourceSerif, accent: "#1A1A1A")),
        ]

        for (name, theme) in themes {
            let document = try Resume.sample.document(design: .ledger, theme: theme)
            try put(document.render(creationDate: Self.stamped), "themes/\(name).pdf")
        }
    }

    func testTheOtherShapesOfDocument() throws {
        let cases: [(String, Resume, DesignKind, Theme)] = [
            ("academic-cv", .academicSample, .broadsheet, .classic),
            ("lebenslauf", Self.lebenslauf, .register, Theme(accent: "#2F4F4F")),
            ("graduate", Self.graduate, .swiss, Theme(accent: "#B0451F")),
        ]

        for (name, resume, design, theme) in cases {
            let document = try resume.document(design: design, theme: theme)
            try put(document.render(creationDate: Self.stamped), "shapes/\(name).pdf")
        }
    }
}

// MARK: - Documents the sample is not

extension ExampleTests {

    /// A Lebenslauf: German headings, and the particulars that belong on one.
    static let lebenslauf = Resume(
        profile: Profile(
            name: "Lena Vogt",
            headline: "Infrastrukturingenieurin",
            location: "Berlin, Deutschland",
            email: "lena@vogt.de",
            phone: "+49 30 901820",
            links: [Link("https://github.com/lenavogt")],
            dateOfBirth: "4. März 1990",
            nationality: "Deutsch",
            placeOfBirth: "Leipzig"
        ),
        summary: "Infrastrukturingenieurin mit elf Jahren Erfahrung in Zahlungs- und Buchungssystemen.",
        experience: [
            Position(
                role: "Senior Infrastructure Engineer",
                organisation: "SAP",
                location: "Berlin",
                dates: .since("März 2022"),
                highlights: [
                    "Latenz der Buchungsschreibung von 340 ms auf 45 ms gesenkt.",
                    "40 Dienste von einer gemeinsamen Datenbank abgelöst.",
                ],
                skills: ["Go", "Postgres", "Kubernetes"]
            ),
            Position(
                role: "Infrastructure Engineer",
                organisation: "N26",
                location: "Berlin",
                dates: DateRange("Juni 2019", "Feb 2022"),
                highlights: ["Deployments von 20 auf 200 pro Tag erhöht."]
            ),
        ],
        education: [
            Education(
                qualification: "M.Sc. Informatik",
                institution: "Technische Universität Berlin",
                dates: DateRange("2013", "2016"),
                grade: "1,3"
            )
        ],
        skills: [
            SkillGroup("Systeme", ["Go", "Rust", "Postgres"]),
            SkillGroup("Betrieb", ["Kubernetes", "Terraform", "AWS"]),
        ],
        languages: [Language("Deutsch", "Muttersprache"), Language("Englisch", "C1")],
        labels: .german
    )

    /// A first CV: the degree is the strongest thing on the page.
    static let graduate = Resume(
        profile: Profile(
            name: "Priya Raman",
            headline: "Graduate Software Engineer",
            location: "Manchester, UK",
            email: "priya@raman.dev",
            links: [Link("https://github.com/priyaraman")]
        ),
        summary: "Computer science graduate with a compilers dissertation and two internships behind it.",
        experience: [
            Position(
                role: "Software Engineering Intern",
                organisation: "Arm",
                location: "Cambridge",
                dates: DateRange("Jun 2025", "Sep 2025"),
                highlights: ["Cut a test suite from 40 minutes to 9 by sharding it."]
            )
        ],
        education: [
            Education(
                qualification: "BSc Computer Science",
                institution: "University of Manchester",
                dates: DateRange("2022", "2025"),
                grade: "First Class Honours",
                highlights: ["Dissertation: register allocation for a teaching compiler."]
            )
        ],
        skills: [
            SkillGroup("Languages", ["Rust", "Python", "C"]),
            SkillGroup("Tools", ["Git", "LLVM", "Linux"]),
        ],
        projects: [
            Project(
                name: "tinyc",
                role: "Author",
                link: Link("https://github.com/priyaraman/tinyc"),
                dates: DateRange("2024"),
                summary: "A teaching compiler for a C subset, used by two undergraduate courses."
            )
        ],
        awards: [Award(name: "Dean's Award for Academic Excellence", issuer: "University of Manchester", date: "2025")],
        order: Section.graduate
    )
}
