//
//  ATS.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Whether the document will survive being read by a machine.
//
//  Most applications are not read by a person first. They are parsed by an
//  applicant tracking system — Workday, Greenhouse, Lever, Taleo, iCIMS —
//  which extracts the text, tries to work out which block is the employment
//  history, and scores the result against the posting. A résumé that a person
//  would call handsome and a parser cannot read is not a good résumé; it is a
//  résumé that never reaches the person.
//
//  None of this is a standard. Every vendor parses differently and none of
//  them publish how, so these are the failures that are well attested rather
//  than a specification anybody can be measured against. They are also all
//  things this library can actually see: the checks are about the document,
//  not about whether somebody is a good candidate.
//

import Foundation
import ImageIO
import TextPDF

/// How badly something matters.
public enum Severity: String, Sendable, CaseIterable, Codable, Comparable {

    /// The document will not be read correctly. Fix before sending.
    case blocker

    /// Likely to be read wrongly, or to cost the reader something.
    case warning

    /// Worth knowing. Often a matter of convention rather than function.
    case note

    private var rank: Int {
        switch self {
        case .blocker: return 0
        case .warning: return 1
        case .note: return 2
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rank < rhs.rank }
}

/// Something found in a résumé.
public struct Finding: Sendable, Equatable, Codable {

    public let severity: Severity

    /// What is wrong, in one line.
    public let message: String

    /// Why it matters, and what to do instead.
    ///
    /// Carried separately because a warning nobody understands is a warning
    /// people turn off.
    public let detail: String

    public init(_ severity: Severity, _ message: String, _ detail: String) {
        self.severity = severity
        self.message = message
        self.detail = detail
    }
}

/// The result of checking a résumé.
public struct Report: Sendable, Equatable, Codable {

    public let findings: [Finding]

    /// How many pages it came to.
    public let pages: Int

    /// The design it was checked as, by name.
    ///
    /// A name rather than a ``DesignKind``: a report on a design of your own —
    /// a ``Blueprint`` read from a file, say — is still a report, and one that
    /// could only name the built-in fourteen would have nothing to say about
    /// the design somebody actually sent.
    public let design: String
    public let region: Region

    /// Nothing that would stop it being read.
    public var isClean: Bool { !findings.contains { $0.severity == .blocker } }

    public func findings(_ severity: Severity) -> [Finding] {
        findings.filter { $0.severity == severity }
    }
}

// MARK: - Checking

extension Resume {

    /// Renders the résumé and reports what is wrong with it.
    ///
    /// Rendering is part of the check rather than beside it, because the two
    /// most useful facts — how many pages it runs to, and whether the design
    /// can be parsed at all — are properties of the finished document.
    public func check(
        design: DesignKind = .ledger,
        theme: Theme = .plain,
        region: Region = .international
    ) throws -> Report {
        try check(design: design.design, theme: theme, region: region)
    }

    /// The same, for a design of your own.
    ///
    /// Every check here reads either the résumé or the finished page, so a
    /// design written outside the package is checked exactly as the built-in
    /// ones are — which is the difference between an extension point and a
    /// hole in the safety net.
    public func check(
        design: any Design,
        theme: Theme = .plain,
        region: Region = .international
    ) throws -> Report {
        let document = try document(design: design, theme: theme)
        _ = document.render()
        let pages = document.pageCount()

        var findings = ATS.check(self, design: design, pages: pages)
        findings += region.check(self, design: design, pages: pages)
        findings += ATS.substitutions(in: document)

        return Report(
            findings: findings.sorted { $0.severity < $1.severity },
            pages: pages,
            design: design.displayName,
            region: region
        )
    }
}

/// Machine-readability checks.
public enum ATS {

    static func check(_ resume: Resume, design: any Design, pages: Int) -> [Finding] {
        var findings: [Finding] = []

        findings += columnLayout(design)
        findings += contactDetails(resume)
        findings += portrait(resume)
        findings += scannableCode(resume, design: design)
        findings += headings(resume)
        findings += dates(resume)
        findings += ordering(resume)
        findings += keywords(resume)
        findings += length(resume, design: design, pages: pages)

        return findings
    }

    /// A code is for a person holding paper, and nothing else reads it.
    private static func scannableCode(_ resume: Resume, design: any Design) -> [Finding] {
        let code = resume.profile.qr.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return [] }

        var findings: [Finding] = []

        if !design.showsCode {
            findings.append(Finding(
                .note,
                "A code is set, and the \(design.displayName) design has nowhere to put it.",
                "Designs that place one: "
                    + DesignKind.allCases.filter(\.showsCode).map(\.displayName).joined(separator: ", ")
                    + "."
            ))
        }

        // The failure worth naming: a URL that exists only inside a picture of
        // a square is a URL no tracking system will ever see.
        let written = resume.profile.links.map(\.absolute) + [resume.profile.email]
        if !written.contains(where: { $0.contains(code) || code.contains($0) }) {
            findings.append(Finding(
                .note,
                "The code is the only place that address appears.",
                "A parser reads text, and a code is a picture. Put the same address in "
                    + "Profile.links as well, so the machine reading this can follow it too."
            ))
        }

        return findings
    }

    // MARK: The photograph

    /// Whether the photograph named can actually reach the page.
    ///
    /// ``Sheet/photo(at:)`` is deliberately silent at render time — a résumé
    /// that refuses to render because a JPEG moved is worse than one with a
    /// gap where a face was — so this is where the reason surfaces: a file
    /// that cannot be read, a format the writer refuses, or an EXIF
    /// orientation that will not be applied. The writer hands JPEG bytes to
    /// the reader exactly as they arrived, so a phone portrait shot the
    /// natural way round carries a rotation flag nothing will honour, and it
    /// renders on its side.
    static func portrait(_ resume: Resume) -> [Finding] {
        let path = resume.profile.photo.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else { return [] }

        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        do {
            _ = try EmbeddedImage.load(url)
        } catch {
            return [Finding(
                .warning,
                "The photograph cannot be used, so the page will have a gap where it was meant to go.",
                (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            )]
        }

        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let orientation = properties[kCGImagePropertyOrientation] as? UInt32,
           orientation != 1 {
            return [Finding(
                .warning,
                "The photograph will render rotated.",
                "The file carries an EXIF orientation the writer does not apply — the bytes go into the document exactly as they arrived, so the picture comes out the way the camera sensor saw it. Open it in Preview and export it, which bakes the rotation into the pixels."
            )]
        }
        return []
    }

    // MARK: Layout

    private static func columnLayout(_ design: any Design) -> [Finding] {
        guard !design.isSingleColumn else { return [] }
        return [Finding(
            .blocker,
            "The \(design.displayName) design is laid out in two columns.",
            """
            A tracking system extracts the text in order and does not know the \
            rail is a separate column, so the sidebar comes out interleaved with \
            the experience — a phone number in the middle of an employment \
            history. Send this one where a person will open it, and use Ledger, \
            Broadsheet or Timeline for anything that goes through a form.
            """
        )]
    }

    // MARK: Contact

    private static func contactDetails(_ resume: Resume) -> [Finding] {
        var findings: [Finding] = []
        let profile = resume.profile

        if profile.email.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .blocker,
                "No email address.",
                "The field a tracking system keys the whole application on. Without it a parsed résumé has no candidate attached to it."
            ))
        } else if !profile.email.contains("@") || !profile.email.contains(".") {
            findings.append(Finding(
                .warning,
                "\"\(profile.email)\" does not look like an email address.",
                "Parsers match a pattern rather than reading it. Anything that does not look like one is dropped."
            ))
        }

        if profile.name.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(.blocker, "No name.", "There is nothing to file the application under."))
        }

        if profile.phone.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .note,
                "No phone number.",
                "Not required, and increasingly not expected. Worth having where a recruiter is likely to call rather than write."
            ))
        }

        if profile.location.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .note,
                "No location.",
                "Used to match against a posting's location and to decide whether a visa question arises. A city and country is enough — a street address is not wanted and never was."
            ))
        }
        return findings
    }

    // MARK: Headings

    /// Section headings a parser is looking for.
    ///
    /// It works out which block is the employment history by matching the
    /// heading above it. "Where I've Worked" is read — as prose, filed under
    /// nothing, and scored as though the candidate has never had a job.
    private static let expected: [Section: Set<String>] = [
        .experience: ["experience", "work experience", "employment", "employment history",
                      "professional experience", "work history", "career history"],
        .education: ["education", "academic background", "qualifications", "education and training"],
        .skills: ["skills", "technical skills", "core skills", "competencies", "expertise"],
        .summary: ["summary", "profile", "professional summary", "about", "objective"],
        .publications: ["publications", "selected publications", "papers", "publications and preprints"],
        .grants: ["grants", "funding", "grants and funding", "research funding", "awarded funding"],
        .teaching: ["teaching", "teaching experience", "courses taught", "teaching and supervision"],
        .talks: ["talks", "invited talks", "presentations", "conference presentations", "speaking"],
        .service: ["service", "academic service", "professional service", "committees", "reviewing"],
        .memberships: ["memberships", "professional memberships", "affiliations",
                       "professional affiliations", "societies"],
        .projects: ["projects", "selected projects", "personal projects", "open source"],
        .awards: ["awards", "honours", "honors", "awards and honours", "awards and honors"],
        .certifications: ["certifications", "certificates", "licences", "licenses",
                          "certifications and licences"],
        .languages: ["languages", "language skills", "spoken languages"],
    ]

    private static func headings(_ resume: Resume) -> [Finding] {
        var findings: [Finding] = []

        for (section, accepted) in expected where resume.isPopulated(section) {
            let heading = resume.heading(for: section)
                .trimmingCharacters(in: .whitespaces)
                .lowercased()

            // A translated heading is a deliberate choice for a document in
            // that language, not a mistake to report.
            guard resume.labels.language == "en" else { continue }
            guard !accepted.contains(heading) else { continue }

            findings.append(Finding(
                .warning,
                "\"\(resume.heading(for: section))\" is not a heading a parser will recognise.",
                """
                A tracking system decides which block is which by matching the \
                heading above it, so an unusual one costs the whole section — it \
                is still read, and filed as nothing in particular. Expected here: \
                \(accepted.sorted().prefix(3).joined(separator: ", ")).
                """
            ))
        }
        return findings
    }

    // MARK: Dates

    /// A four-digit year between 1900 and 2099, anywhere in the string.
    static func year(in text: String) -> Int? {
        let scalars = Array(text.unicodeScalars)
        var index = 0

        while index + 3 < scalars.count {
            let window = scalars[index..<(index + 4)]
            if window.allSatisfy({ $0.properties.numericType != nil && $0.value < 128 }),
               let value = Int(String(String.UnicodeScalarView(window))),
               (1900...2099).contains(value) {
                return value
            }
            index += 1
        }
        return nil
    }

    private static func dates(_ resume: Resume) -> [Finding] {
        var findings: [Finding] = []

        func inspect(_ range: DateRange, what: String) {
            guard !range.isEmpty else {
                findings.append(Finding(
                    .warning,
                    "\(what) has no dates.",
                    "A tracking system builds an employment timeline from them, and an entry with none becomes an unexplained gap for somebody to ask about."
                ))
                return
            }
            if year(in: range.start) == nil {
                findings.append(Finding(
                    .warning,
                    "\"\(range.start)\" has no four-digit year (\(what)).",
                    "Parsers look for one. \"Mar 22\" and \"'22\" are read as no date at all — write \"Mar 2022\"."
                ))
            }
            if !range.end.isEmpty, !range.isCurrent, year(in: range.end) == nil {
                findings.append(Finding(
                    .warning,
                    "\"\(range.end)\" has no four-digit year (\(what)).",
                    "Parsers look for one. Write the year in full."
                ))
            }
        }

        for item in resume.experience {
            inspect(item.dates, what: "\(item.role) at \(item.organisation)")
        }
        for item in resume.education {
            inspect(item.dates, what: item.qualification)
        }

        // More than one current role is legitimate and is also the commonest
        // way a résumé says something its author did not mean.
        let current = resume.experience.filter(\.dates.isCurrent)
        if current.count > 1 {
            findings.append(Finding(
                .note,
                "\(current.count) roles are marked as current.",
                "Right for concurrent posts and consulting. Where it is not deliberate, an end date is missing from \(current.dropFirst().map(\.role).joined(separator: ", "))."
            ))
        }
        return findings
    }

    // MARK: Ordering

    private static func ordering(_ resume: Resume) -> [Finding] {
        let years = resume.experience.compactMap { year(in: $0.dates.start) }
        guard years.count == resume.experience.count, years.count > 1 else { return [] }

        let sorted = years.sorted(by: >)
        guard years != sorted else { return [] }

        return [Finding(
            .warning,
            "Experience is not in reverse-chronological order.",
            """
            The most recent role goes first. Readers assume it without checking, \
            and a parser building a timeline from the order will date the career \
            wrongly. Current order: \(years.map(String.init).joined(separator: ", ")).
            """
        )]
    }

    // MARK: Keywords

    private static func keywords(_ resume: Resume) -> [Finding] {
        var findings: [Finding] = []

        if resume.skills.isEmpty {
            findings.append(Finding(
                .warning,
                "No skills section.",
                "Scoring is largely term matching against the posting, and this is where the terms are. Without it the match rests on whatever the prose happens to mention."
            ))
        }

        if resume.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            findings.append(Finding(
                .note,
                "No summary.",
                "The most-read three lines on the page, and the only place to say what you are looking for rather than what you have done."
            ))
        }

        let boilerplate = "references available on request"
        if resume.references.lowercased().contains(boilerplate) {
            findings.append(Finding(
                .note,
                "\"References available on request\" is taking up a line.",
                "It is assumed. Printing it says only that the space was going spare — name referees or drop the section."
            ))
        }
        return findings
    }

    // MARK: Length

    private static func length(_ resume: Resume, design: any Design, pages: Int) -> [Finding] {
        var findings: [Finding] = []

        // An academic CV has no length convention worth enforcing; a
        // publication list is as long as it is.
        let academic = !resume.publications.isEmpty

        if pages > 2, !academic {
            findings.append(Finding(
                .warning,
                "\(pages) pages.",
                "One page for most people, two for a long career. Past that it stops being read rather than being read slowly. Try Density.compact, or cut the oldest roles to a line each."
            ))
        }

        if !design.isSingleColumn, pages > 1 {
            findings.append(Finding(
                .warning,
                "The document has run past the rail.",
                "The rail lives on page one; the pages after it carry the main column beside an empty band of tint. Rail sections that did not fit page one were flowed into the main column rather than dropped. Cut content, or use a single-column design."
            ))
        }

        let long = resume.experience.flatMap(\.highlights).filter { $0.count > 240 }
        if !long.isEmpty {
            findings.append(Finding(
                .note,
                "\(long.count) bullet\(long.count == 1 ? " is" : "s are") over three lines.",
                "A bullet that long is a paragraph wearing a bullet, and it is skimmed rather than read. Two lines is the point where it stops landing."
            ))
        }
        return findings
    }

    // MARK: Glyphs

    /// Characters the document could not draw.
    ///
    /// Reported because they reach the page as question marks, and a name
    /// printed as `???????` is something to fix rather than something a
    /// recruiter finds.
    static func substitutions(in document: Document) -> [Finding] {
        document.substitutions.map { substitution in
            Finding(
                .blocker,
                "\"\(substitution.text)\" cannot be drawn.",
                substitution.unsupportedScript.map {
                    "\($0) needs bidirectional layout and contextual shaping, which the writer does not do. It would render as disconnected letters in the wrong order."
                } ?? "No bundled face covers these characters, so they print as question marks."
            )
        }
    }
}
