//
//  PostingTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Reading a posting for its terms, and matching them against a page. The
//  fixture is the shape of a real advertisement: a title, prose about the
//  company, bulleted requirements, and the boilerplate at the end.
//

import XCTest
@testable import ResumePDF

final class PostingTests: XCTestCase {

    static let advertisement = """
        Senior Infrastructure Engineer — Northwind Payments
        London (Hybrid). Northwind is a payments company serving retailers across Europe.
        We are looking for an engineer who has run production systems at scale.

        Requirements:
        • 5+ years with Go or Rust in production
        • Kubernetes, Terraform and AWS; Postgres or MySQL
        • Experience with CI/CD pipelines (GitHub Actions, ArgoCD)
        • Familiarity with Node.js and TypeScript is a plus
        • Strong written English and/or French, e.g. for customer documentation
        Nice to have: SOC 2, PCI-DSS, Datadog. Postgres experience is preferred.

        Northwind is an equal opportunity employer. Apply by March 3. Salary $180K plus RSUs and a 401(k).
        """

    private var posting: Posting { Posting(Self.advertisement) }

    // MARK: Reading the posting

    func testTheTechnologiesAreTheTerms() {
        let terms = posting.terms
        for expected in ["Go", "Rust", "Kubernetes", "Terraform", "AWS", "Postgres", "MySQL",
                         "CI/CD", "GitHub Actions", "ArgoCD", "Node.js", "TypeScript",
                         "SOC 2", "PCI-DSS", "Datadog"] {
            XCTAssertTrue(terms.contains(expected), "\(expected) should be a term; got \(terms)")
        }
    }

    func testTheProseIsNot() {
        let terms = posting.terms
        for unwanted in ["Northwind", "London", "Hybrid", "Europe", "March", "Requirements",
                         "Experience", "Familiarity", "Strong", "Senior", "Infrastructure",
                         "Engineer", "Payments", "We", "Apply", "Salary", "RSUs", "401(k)", "$180K", "180K",
                         "5+", "and/or", "e.g", "e.g.", "English", "Nice"] {
            XCTAssertFalse(terms.contains(unwanted), "\(unwanted) is not a term; got \(terms)")
        }
    }

    func testATermIsListedOnce() {
        // Postgres appears twice in the posting, differently placed.
        XCTAssertEqual(posting.terms.filter { $0.lowercased() == "postgres" }.count, 1)
    }

    func testTermsKeepTheOrderTheyAppearIn() {
        let terms = posting.terms
        let go = try? XCTUnwrap(terms.firstIndex(of: "Go"))
        let datadog = try? XCTUnwrap(terms.firstIndex(of: "Datadog"))
        XCTAssertLessThan(go ?? 0, datadog ?? 0)
    }

    func testOneHardTokenDoesNotMakeProseAList() {
        // The customers named beside a product are not requirements.
        XCTAssertEqual(Posting("Trusted by OpenAI, Stripe, Ramp and Supreme worldwide.").terms, ["OpenAI"])
    }

    func testAPossessiveIsTheName() {
        XCTAssertEqual(Posting("• Vercel's AI Gateway and Vercel").terms, ["Vercel", "AI Gateway"])
    }

    func testPlacesAreNotTerms() {
        XCTAssertEqual(Posting("• Kubernetes in London, Berlin or San Francisco").terms, ["Kubernetes"])
    }

    func testAProperNounInProseIsNotATerm() {
        // Nothing hard on the line, no bullet: the capitalised words are a
        // company and a city, not requirements.
        XCTAssertTrue(Posting("Acme Widgets is based in Reading and hiring.").terms.isEmpty)
    }

    func testAProperNounBesideAHardTermIs() {
        XCTAssertEqual(Posting("We use Kafka and Go, with ES6 and PostgreSQL on the front end.").terms, ["Kafka", "Go", "ES6", "PostgreSQL"])
    }

    func testAWordOpeningASentenceIsGivenTheBenefitOfTheDoubt() {
        // Kafka here is a technology and Acme is a company, and nothing on
        // the line tells them apart. Prose loses both; lists keep both.
        XCTAssertEqual(Posting("Kafka and Go, with ES6 and PostgreSQL on the front end.").terms, ["Go", "ES6", "PostgreSQL"])
        XCTAssertEqual(Posting("• Kafka, Go and ES6").terms, ["Kafka", "Go", "ES6"])
    }

    func testABulletThatOpensWithAListKeepsItsFirstWord() {
        XCTAssertEqual(Posting("• Kubernetes, Terraform and Postgres").terms, ["Kubernetes", "Terraform", "Postgres"])
        XCTAssertEqual(Posting("• Experience with Terraform").terms, ["Terraform"])
    }

    func testMultiwordNamesStayTogether() {
        XCTAssertEqual(Posting("• Google Cloud Platform, Visual Studio Code").terms,
                       ["Google Cloud Platform", "Visual Studio Code"])
    }

    func testTheHardEdgedTokens() {
        XCTAssertTrue(Posting.isHard("C++"))
        XCTAssertTrue(Posting.isHard("C#"))
        XCTAssertTrue(Posting.isHard("Node.js"))
        XCTAssertTrue(Posting.isHard("socket.io"))
        XCTAssertTrue(Posting.isHard("CI/CD"))
        XCTAssertTrue(Posting.isHard("ES6"))
        XCTAssertTrue(Posting.isHard("AWS"))
        XCTAssertTrue(Posting.isHard("PostgreSQL"))
        XCTAssertTrue(Posting.isHard("iOS"))
        XCTAssertFalse(Posting.isHard("5+"), "a number with a plus is a count, not a name")
        XCTAssertFalse(Posting.isHard("and/or"))
        XCTAssertFalse(Posting.isHard("e.g"))
        XCTAssertFalse(Posting.isHard("AND"))
        XCTAssertFalse(Posting.isHard("LinkedIn"))
        XCTAssertFalse(Posting.isHard("Kubernetes"), "a plain capitalised word is a proper noun, not a hard token")
    }

    func testAnEmptyPostingHasNoTerms() {
        XCTAssertTrue(Posting("").terms.isEmpty)
        XCTAssertTrue(Posting("\n\n  \n").terms.isEmpty)
    }

    // MARK: Matching against a page

    func testCoverageAgainstTheSample() {
        let coverage = Resume.sample.coverage(of: posting)

        for present in ["Go", "Kubernetes", "Terraform", "AWS", "Postgres"] {
            XCTAssertTrue(coverage.found.contains(present), "\(present) is on the sample; found \(coverage.found)")
        }
        for absent in ["Rust", "MySQL", "Datadog", "TypeScript", "ArgoCD"] {
            XCTAssertTrue(coverage.missing.contains(absent), "\(absent) is not on the sample; missing \(coverage.missing)")
        }
        XCTAssertEqual(coverage.total, posting.terms.count)
        XCTAssertGreaterThan(coverage.ratio, 0.2)
        XCTAssertLessThan(coverage.ratio, 0.6)
    }

    func testSpellingVariantsMatch() {
        let resume = Resume(
            profile: Profile(name: "A"),
            skills: [SkillGroup("Stack", ["NodeJS", "CI CD", "Postgres", "Containers", "TypeScript"])]
        )
        let coverage = resume.coverage(of: Posting("• Node.js, CI/CD, PostgreSQL, Container, Typescript, Rust"))

        XCTAssertEqual(coverage.found, ["Node.js", "CI/CD", "Container", "Typescript"])
        XCTAssertEqual(coverage.missing, ["PostgreSQL", "Rust"],
                       "Postgres is not PostgreSQL to a scorer, and it is not for this to pretend otherwise")
    }

    func testAMultiwordTermNeedsTheWholePhrase() {
        let resume = Resume(profile: Profile(name: "A"), summary: "Ran GitHub Actions for a hundred repositories.")
        XCTAssertEqual(resume.coverage(of: Posting("• GitHub Actions, GitHub Copilot")).missing, ["GitHub Copilot"])
    }

    func testEveryFieldIsSearched() {
        let resume = Resume(
            profile: Profile(name: "A", headline: "Rust engineer"),
            projects: [Project(name: "x", skills: ["Datadog"])],
            certifications: [Credential(name: "CKA", issuer: "CNCF")],
            custom: [CustomSection("Patents", [.list(["A Terraform provider"])])]
        )
        let coverage = resume.coverage(of: Posting("• Rust, Datadog, CKA, Terraform, MySQL"))
        XCTAssertEqual(coverage.missing, ["MySQL"])
    }

    // MARK: In the report

    func testACheckWithAPostingReportsWhatIsMissing() throws {
        let report = try Resume.sample.check(design: .ledger, posting: posting)
        let coverage = try XCTUnwrap(report.coverage)
        XCTAssertFalse(coverage.missing.isEmpty)

        let warning = try XCTUnwrap(report.findings.first { $0.message.contains("from the posting are not on the page") })
        XCTAssertEqual(warning.severity, .warning)
        XCTAssertTrue(warning.message.contains("Rust"), warning.message)
        XCTAssertTrue(report.isClean, "a keyword miss lowers a score; it does not stop the document being read")
    }

    func testACheckWithoutAPostingSaysNothingAboutOne() throws {
        let report = try Resume.sample.check(design: .ledger)
        XCTAssertNil(report.coverage)
        XCTAssertFalse(report.findings.contains { $0.message.contains("posting") })
    }

    func testFullCoverageIsANote() throws {
        let report = try Resume.sample.check(design: .ledger, posting: Posting("• Go, Kubernetes, Terraform"))
        let note = try XCTUnwrap(report.findings.first { $0.message.contains("Every term") })
        XCTAssertEqual(note.severity, .note)
        XCTAssertEqual(report.coverage?.ratio, 1)
    }

    func testAPostingWithNoTermsIsSaidSo() throws {
        let report = try Resume.sample.check(design: .ledger, posting: Posting("We are hiring. Apply now."))
        XCTAssertTrue(report.findings.contains { $0.message == "Nothing in the posting reads as a term." })
        XCTAssertEqual(report.coverage?.total, 0)
        XCTAssertEqual(report.coverage?.ratio, 1)
    }
}
