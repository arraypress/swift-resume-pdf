//
//  Resume.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The document, separated from how it looks.
//
//  One résumé renders through any ``Design``. That separation is the whole
//  point: the reason people keep four versions of their CV in four different
//  Word files is that the content and the formatting were never apart, so
//  changing the look means retyping the content and the four copies drift.
//

import Foundation

/// A résumé or CV.
public struct Resume: Sendable, Equatable, Codable {

    public let profile: Profile

    /// The opening paragraph. Three or four lines at most.
    ///
    /// Read by roughly everyone and skimmed by almost all of them, which makes
    /// it the most expensive real estate on the page. A summary that says
    /// "results-driven professional" has spent it on nothing.
    public let summary: String

    public let experience: [Position]
    public let education: [Education]
    public let skills: [SkillGroup]
    public let projects: [Project]

    /// The same shape as a job, filed separately.
    public let volunteering: [Position]

    public let certifications: [Credential]
    public let publications: [Publication]
    public let awards: [Award]
    public let languages: [Language]

    /// Free text. Specific ones are worth the line; "reading, travel, music"
    /// is worth none.
    public let interests: String

    /// Named referees, which an academic CV carries and a résumé does not.
    ///
    /// "References available on request" is not worth a line — it is assumed,
    /// and printing it tells a reader only that the space was going spare.
    /// ``ATS`` says so if it finds it.
    public let references: String

    /// Which sections appear, and in what order.
    ///
    /// Empty sections are dropped at render time, so this can list everything
    /// and stay correct for a graduate and a professor alike.
    public let order: [Section]

    /// The section headings and the handful of words a design has to print.
    public let labels: Labels

    public init(
        profile: Profile,
        summary: String = "",
        experience: [Position] = [],
        education: [Education] = [],
        skills: [SkillGroup] = [],
        projects: [Project] = [],
        volunteering: [Position] = [],
        certifications: [Credential] = [],
        publications: [Publication] = [],
        awards: [Award] = [],
        languages: [Language] = [],
        interests: String = "",
        references: String = "",
        order: [Section] = Section.conventional,
        labels: Labels = .english
    ) {
        self.profile = profile
        self.summary = summary
        self.experience = experience
        self.education = education
        self.skills = skills
        self.projects = projects
        self.volunteering = volunteering
        self.certifications = certifications
        self.publications = publications
        self.awards = awards
        self.languages = languages
        self.interests = interests
        self.references = references
        self.order = order
        self.labels = labels
    }

    /// The sections that have anything in them, in order.
    public func populated() -> [Section] {
        order.filter { isPopulated($0) }
    }

    func isPopulated(_ section: Section) -> Bool {
        switch section {
        case .summary: return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .experience: return !experience.isEmpty
        case .education: return !education.isEmpty
        case .skills: return !skills.isEmpty
        case .projects: return !projects.isEmpty
        case .volunteering: return !volunteering.isEmpty
        case .certifications: return !certifications.isEmpty
        case .publications: return !publications.isEmpty
        case .awards: return !awards.isEmpty
        case .languages: return !languages.isEmpty
        case .interests: return !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .references: return !references.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// The heading a section is printed under.
    public func heading(for section: Section) -> String {
        labels.title(for: section)
    }
}

// MARK: - Section

/// A block of the document.
public enum Section: String, Sendable, CaseIterable, Codable {

    case summary
    case experience
    case education
    case skills
    case projects
    case volunteering
    case certifications
    case publications
    case awards
    case languages
    case interests
    case references

    /// The order a reader expects, which is not always the best one.
    ///
    /// Experience before education for anyone who has worked; the reverse for
    /// a graduate, whose degree is the strongest thing they have. Technical
    /// résumés often lift skills above education for the same reason. All of
    /// which is a decision about a particular person, so it is a parameter
    /// rather than a rule.
    public static let conventional: [Section] = [
        .summary, .experience, .education, .skills, .projects,
        .certifications, .publications, .awards, .languages,
        .volunteering, .interests, .references,
    ]

    /// Education first, skills high — for someone whose degree is the
    /// strongest thing on the page.
    public static let graduate: [Section] = [
        .summary, .education, .skills, .projects, .experience,
        .certifications, .awards, .volunteering, .languages, .interests, .references,
    ]

    /// Publications and grants carry the weight; length is not a constraint.
    public static let academic: [Section] = [
        .summary, .education, .publications, .experience, .awards,
        .projects, .certifications, .languages, .skills, .references,
    ]
}

// MARK: - Labels

/// The words a design prints that are not the person's own.
///
/// Section headings, and the few connectives a date range needs. Separated
/// from the design because they are a matter of language rather than looks: a
/// Lebenslauf set in the same typeface and the same grid is still a Lebenslauf
/// only if it says *Berufserfahrung*.
public struct Labels: Sendable, Equatable, Codable {

    private var overrides: [Section: String]

    /// The word for a position that has not ended.
    public let present: String

    /// What separates the two ends of a date range.
    public let dateSeparator: String

    public init(
        _ overrides: [Section: String] = [:],
        present: String = "Present",
        dateSeparator: String = "–"
    ) {
        self.overrides = overrides
        self.present = present
        self.dateSeparator = dateSeparator
    }

    public func title(for section: Section) -> String {
        overrides[section] ?? section.defaultTitle
    }

    /// Replaces one heading, leaving the rest.
    public func naming(_ section: Section, _ title: String) -> Labels {
        var copy = overrides
        copy[section] = title
        return Labels(copy, present: present, dateSeparator: dateSeparator)
    }

    public static let english = Labels()

    /// A Lebenslauf's headings.
    public static let german = Labels(
        [
            .summary: "Profil",
            .experience: "Berufserfahrung",
            .education: "Ausbildung",
            .skills: "Kenntnisse",
            .projects: "Projekte",
            .volunteering: "Ehrenamt",
            .certifications: "Zertifikate",
            .publications: "Publikationen",
            .awards: "Auszeichnungen",
            .languages: "Sprachen",
            .interests: "Interessen",
            .references: "Referenzen",
        ],
        present: "heute",
        dateSeparator: "–"
    )
}

extension Section {

    /// The heading most readers, and most parsers, expect.
    ///
    /// Deliberately plain. An applicant tracking system looks for these words
    /// to work out which block is which, so "Where I've Worked" costs a
    /// candidate the entire employment history — the section is still read,
    /// but filed as nothing in particular.
    public var defaultTitle: String {
        switch self {
        case .summary: return "Summary"
        case .experience: return "Experience"
        case .education: return "Education"
        case .skills: return "Skills"
        case .projects: return "Projects"
        case .volunteering: return "Volunteering"
        case .certifications: return "Certifications"
        case .publications: return "Publications"
        case .awards: return "Awards"
        case .languages: return "Languages"
        case .interests: return "Interests"
        case .references: return "References"
        }
    }
}
