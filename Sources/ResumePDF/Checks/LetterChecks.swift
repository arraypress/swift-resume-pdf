//
//  LetterChecks.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What goes wrong with a letter, which is not what goes wrong with a résumé.
//
//  A cover letter is read by a person or not at all — no tracking system
//  scores one, and the column-layout question that decides a résumé's fate
//  does not arise. What decides a letter's fate is whether it is addressed to
//  somebody, whether it mentions the employer, and whether it is short enough
//  to finish.
//

import Foundation

extension CoverLetter {

    /// Renders the letter and reports what is wrong with it.
    public func check(
        design: LetterDesign = .memo,
        theme: Theme = .plain,
        region: Region = .international
    ) throws -> Report {
        try check(design: design.design, theme: theme, region: region)
    }

    /// The same, for a letter design of your own.
    public func check(
        design: any LetterLayout,
        theme: Theme = .plain,
        region: Region = .international
    ) throws -> Report {
        let document = try document(design: design, theme: theme)
        _ = document.render()
        let pages = document.pageCount()

        var findings = LetterChecks.check(self, pages: pages)
        findings += ATS.substitutions(in: document)

        return Report(
            findings: findings.sorted { $0.severity < $1.severity },
            pages: pages,
            design: design.displayName,
            region: region
        )
    }
}

/// Checks for a letter of application.
public enum LetterChecks {

    static func check(_ letter: CoverLetter, pages: Int) -> [Finding] {
        var findings: [Finding] = []

        findings += substance(letter)
        findings += addressing(letter)
        findings += length(letter, pages: pages)
        findings += specificity(letter)

        return findings
    }

    // MARK: Substance

    private static func substance(_ letter: CoverLetter) -> [Finding] {
        var findings: [Finding] = []

        let written = letter.body.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if written.isEmpty, letter.highlights.isEmpty {
            findings.append(Finding(
                .blocker,
                "The letter has no body.",
                "A masthead and a sign-off with nothing between them."
            ))
        }

        if letter.profile.email.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .warning,
                "No email address on the letter.",
                "A letter is often separated from the résumé it was attached to, and then it is the only thing on the reader's screen."
            ))
        }

        if letter.date.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .note,
                "No date.",
                "Conventional on a letter, and useful later: an application that resurfaces after six months is dated by it rather than guessed at."
            ))
        }

        if letter.highlights.count > 4 {
            findings.append(Finding(
                .note,
                "\(letter.highlights.count) bulleted claims.",
                "Three is the most a reader holds. Past that the letter is a résumé with a greeting on it, and they already have the résumé."
            ))
        }
        return findings
    }

    // MARK: Addressing

    private static func addressing(_ letter: CoverLetter) -> [Finding] {
        var findings: [Finding] = []
        let recipient = letter.recipient

        if recipient.name.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .note,
                "Not addressed to anybody by name.",
                """
                "Dear Hiring Manager" is visibly one of forty. The name is usually \
                on the posting, the company's team page or LinkedIn, and ten \
                minutes of looking changes how the first paragraph is read.
                """
            ))
        }

        if recipient.organisation.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .warning,
                "The employer is not named in the address block.",
                "A letter that could have been sent to anyone reads as one that was."
            ))
        }

        if letter.subject.trimmingCharacters(in: .whitespaces).isEmpty {
            findings.append(Finding(
                .note,
                "No subject line.",
                "A recruiter with a dozen open roles is working out which one you mean before they read the argument. A reference number, where the posting gives one, does the whole job."
            ))
        }

        // The British convention, which the sign-off is derived from unless it
        // was written by hand.
        let closing = letter.signOff.lowercased()
        let named = !recipient.name.trimmingCharacters(in: .whitespaces).isEmpty
        if named, closing.contains("faithfully") {
            findings.append(Finding(
                .note,
                "\"Yours faithfully\" to a named recipient.",
                "The convention is faithfully to a stranger, sincerely to a name. Only observed in British correspondence, and only noticed by the people who observe it."
            ))
        }
        if !named, closing.contains("sincerely") {
            findings.append(Finding(
                .note,
                "\"Yours sincerely\" with no name to be sincere to.",
                "The convention is sincerely to a name, faithfully to a stranger."
            ))
        }
        return findings
    }

    // MARK: Length

    private static func length(_ letter: CoverLetter, pages: Int) -> [Finding] {
        var findings: [Finding] = []
        let words = letter.wordCount

        if pages > 1 {
            findings.append(Finding(
                .warning,
                "The letter runs to \(pages) pages.",
                "One page. A second page of a covering letter is read by nobody, including the people who ask for one."
            ))
        }

        if words > 450 {
            findings.append(Finding(
                .warning,
                "About \(words) words.",
                "Between 250 and 400 is a letter. Past 450 it is an essay, and the reader has forty of them to get through this afternoon."
            ))
        } else if words > 0, words < 120 {
            findings.append(Finding(
                .note,
                "About \(words) words.",
                "Short enough to read as a formality. If there is nothing to say beyond what the résumé says, the letter is not earning its place."
            ))
        }
        return findings
    }

    // MARK: Specificity

    /// Whether the letter says anything about this particular employer.
    ///
    /// The one thing that separates a letter worth sending from a template
    /// with the name changed — and, unusually for these checks, something the
    /// library can actually test for.
    private static func specificity(_ letter: CoverLetter) -> [Finding] {
        let organisation = letter.recipient.organisation.trimmingCharacters(in: .whitespaces)
        guard !organisation.isEmpty else { return [] }

        let prose = (letter.body + letter.highlights.map { "\($0.title) \($0.detail)" })
            .joined(separator: " ")
            .lowercased()

        // The first word of the name is enough — "Northwind Payments Ltd" is
        // referred to as "Northwind" in any sentence anybody would write.
        let shortName = organisation
            .split(separator: " ")
            .first
            .map(String.init)?
            .lowercased() ?? organisation.lowercased()

        guard !prose.contains(shortName) else { return [] }

        return [Finding(
            .warning,
            "The letter never mentions \(organisation).",
            """
            A letter that names the employer only in the address block is a \
            template with the name changed, and it reads as one. Say something \
            about them that could not be said about anyone else — their product, \
            a decision they published, the specific problem the role exists to \
            solve.
            """
        )]
    }
}
