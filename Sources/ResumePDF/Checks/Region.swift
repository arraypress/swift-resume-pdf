//
//  Region.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a résumé is expected to carry, and what it must not, by country.
//
//  The particulars are the whole of it. A Lebenslauf without a date of birth
//  looks incomplete; a US résumé carrying one can be discarded before anybody
//  reads it — not because the candidate did anything wrong, but because
//  considering it exposes the employer, and the cheapest way to prove they did
//  not consider it is not to have seen it. The same four fields, opposite
//  advice, and nobody tells you which side of the line you are on.
//
//  **Not legal advice.** These are hiring conventions, and conventions move —
//  the German practice of attaching a photograph has been receding since the
//  AGG came in, and plenty of employers now ask candidates to leave it off.
//  What is checked is whether the document matches the convention, not whether
//  the convention is a good one or still current in a particular industry.
//

import Foundation

/// Where the application is going.
public enum Region: String, Sendable, CaseIterable, Codable {

    /// No regional assumptions. Nothing about personal particulars is
    /// reported either way.
    case international

    case unitedStates
    case unitedKingdom
    case canada
    case australia
    case germany
    case france

    public var displayName: String {
        switch self {
        case .international: return "International"
        case .unitedStates: return "United States"
        case .unitedKingdom: return "United Kingdom"
        case .canada: return "Canada"
        case .australia: return "Australia"
        case .germany: return "Germany"
        case .france: return "France"
        }
    }

    /// What the document is called where it is going.
    public var documentName: String {
        switch self {
        case .unitedStates, .canada: return "résumé"
        case .germany: return "Lebenslauf"
        case .france: return "CV"
        default: return "CV"
        }
    }

    /// Whether personal particulars are unwelcome rather than expected.
    ///
    /// In these countries an employer may not take age, nationality or marital
    /// status into account, and a document volunteering them creates a record
    /// that they were visible. Recruiters at larger firms are commonly
    /// instructed to reject such a document unread for that reason — which
    /// makes it the candidate's problem regardless of whose rule it was.
    var refusesParticulars: Bool {
        switch self {
        case .unitedStates, .unitedKingdom, .canada, .australia: return true
        case .germany, .france, .international: return false
        }
    }

    /// Whether a date of birth is conventional.
    var expectsParticulars: Bool { self == .germany }

    /// How many pages the convention allows before it counts against you.
    var pageLimit: Int? {
        switch self {
        case .unitedStates, .canada: return 1
        case .unitedKingdom, .australia, .germany, .france: return 2
        case .international: return nil
        }
    }

    // MARK: Checking

    func check(_ resume: Resume, design: DesignKind, pages: Int) -> [Finding] {
        var findings: [Finding] = []
        findings += particulars(resume)
        findings += length(resume, pages: pages)
        findings += language(resume)
        findings += photograph(resume, design: design)
        return findings
    }

    private func particulars(_ resume: Resume) -> [Finding] {
        let present = resume.profile.particulars()

        if refusesParticulars, !present.isEmpty {
            let named = present.map(\.label).joined(separator: ", ")
            return [Finding(
                .warning,
                "\(named) should not be on a \(displayName) \(documentName).",
                """
                Age, nationality and marital status may not be taken into account \
                in hiring here, and a document that volunteers them creates a \
                record that they were seen. Recruiters at larger firms are \
                routinely told to reject one unread rather than argue about it \
                later — so it costs the candidate, whoever's rule it was. Where a \
                visa question is genuinely live, say right-to-work status instead.
                """
            )]
        }

        if expectsParticulars, present.isEmpty {
            return [Finding(
                .note,
                "A Lebenslauf usually carries a date and place of birth.",
                """
                Conventional here and unremarkable, though the practice has been \
                receding since the AGG and plenty of employers now prefer them \
                left off. Set them on Profile if the employer expects them.
                """
            )]
        }
        return []
    }

    private func length(_ resume: Resume, pages: Int) -> [Finding] {
        // An academic CV is as long as the publication list, everywhere.
        guard let limit = pageLimit, resume.publications.isEmpty, pages > limit else { return [] }

        return [Finding(
            .note,
            "\(pages) pages, where a \(displayName) \(documentName) is usually \(limit).",
            limit == 1
                ? "One page is the strong convention in the US for anyone short of about fifteen years' experience. Two is accepted at senior level and still unusual."
                : "Two pages is the norm. A third is read only if the first two earned it."
        )]
    }

    private func language(_ resume: Resume) -> [Finding] {
        guard self == .germany, resume.labels.language == "en" else { return [] }
        return [Finding(
            .note,
            "The headings are in English on a German Lebenslauf.",
            "Right for an English-language application to a German employer, and wrong for a German-language one. Labels.german sets Berufserfahrung, Ausbildung and the rest."
        )]
    }

    private func photograph(_ resume: Resume, design: DesignKind) -> [Finding] {
        let named = !resume.profile.photo.isEmpty

        // A photograph set on a design with nowhere to put it is the one case
        // worth saying anywhere: the file was named, so it was meant, and it
        // will not be in the document.
        if named, !design.showsPhoto {
            return [Finding(
                .note,
                "A photograph is set, and the \(design.displayName) design has nowhere to put it.",
                "Designs that place one: "
                    + DesignKind.allCases.filter(\.showsPhoto).map(\.displayName).joined(separator: ", ")
                    + "."
            )]
        }

        guard self == .germany || self == .france, !named else { return [] }

        return [Finding(
            .note,
            "A photograph is conventional here, and none is set.",
            """
            Set Profile.photo to a JPEG or PNG and render a design that places \
            one — \(DesignKind.allCases.filter(\.showsPhoto).map(\.displayName).joined(separator: ", ")). \
            The practice has been receding since the AGG and plenty of employers \
            now prefer none, so sending without is a defensible choice rather \
            than an omission.
            """
        )]
    }
}
