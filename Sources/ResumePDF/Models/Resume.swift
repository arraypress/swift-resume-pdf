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

    // MARK: The sections a CV has and a résumé does not

    /// Funding awarded. The section an academic CV is read for.
    public let grants: [Grant]

    /// Courses taught, filed as positions because that is their shape.
    public let teaching: [Position]

    /// Talks given. Invited ones are worth saying so in the venue.
    public let talks: [Publication]

    /// Reviewing, editorial work, committees — the unpaid work that a
    /// department counts and a company does not know exists.
    public let service: [Position]

    /// Professional bodies.
    public let memberships: [Credential]

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

    /// Sections the built-in set does not name.
    ///
    /// Placed by putting ``Section/custom(_:)`` in `order`; a block with no
    /// matching entry there is not drawn, which is how one gets left out
    /// without being deleted.
    public let custom: [CustomSection]

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
        grants: [Grant] = [],
        teaching: [Position] = [],
        talks: [Publication] = [],
        service: [Position] = [],
        memberships: [Credential] = [],
        interests: String = "",
        references: String = "",
        custom: [CustomSection] = [],
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
        self.grants = grants
        self.teaching = teaching
        self.talks = talks
        self.service = service
        self.memberships = memberships
        self.interests = interests
        self.references = references
        self.custom = custom
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
        case .grants: return !grants.isEmpty
        case .teaching: return !teaching.isEmpty
        case .talks: return !talks.isEmpty
        case .service: return !service.isEmpty
        case .memberships: return !memberships.isEmpty
        case .interests: return !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .references: return !references.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            // A section of your own is populated when the block matching it
            // has something in it.
            return customSection(section).map { !$0.isEmpty } ?? false
        }
    }

    /// The custom block a section names, if there is one.
    func customSection(_ section: Section) -> CustomSection? {
        guard let title = section.customTitle else { return nil }
        return custom.first { $0.title == title }
    }

    /// The heading a section is printed under.
    public func heading(for section: Section) -> String {
        labels.title(for: section)
    }
}

// MARK: - Section

/// A block of the document.
///
/// A struct rather than an enum so the set is open. The built-in names cover
/// what a résumé and a CV are made of, and there is always something they do
/// not — patents, exhibitions, press, clearances, licences by state. A closed
/// enum makes those unrepresentable, and the usual workaround is to bend an
/// existing section into holding them, which is how a "Projects" heading ends
/// up over a list of patents.
public struct Section: Hashable, Sendable, Codable, RawRepresentable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: The built-in set

    public static let summary = Section(rawValue: "summary")
    public static let experience = Section(rawValue: "experience")
    public static let education = Section(rawValue: "education")
    public static let skills = Section(rawValue: "skills")
    public static let projects = Section(rawValue: "projects")
    public static let volunteering = Section(rawValue: "volunteering")
    public static let certifications = Section(rawValue: "certifications")
    public static let publications = Section(rawValue: "publications")
    public static let awards = Section(rawValue: "awards")
    public static let languages = Section(rawValue: "languages")
    public static let grants = Section(rawValue: "grants")
    public static let teaching = Section(rawValue: "teaching")
    public static let talks = Section(rawValue: "talks")
    public static let service = Section(rawValue: "service")
    public static let memberships = Section(rawValue: "memberships")
    public static let interests = Section(rawValue: "interests")
    public static let references = Section(rawValue: "references")

    /// Every section the library names itself.
    public static let builtIn: [Section] = [
        .summary, .experience, .education, .skills, .projects, .volunteering,
        .certifications, .publications, .awards, .languages, .grants,
        .teaching, .talks, .service, .memberships, .interests, .references,
    ]

    // MARK: Sections of your own

    /// A section the built-in set does not name.
    ///
    /// The title is the identity: `.custom("Patents")` in the order matches
    /// the ``CustomSection`` titled "Patents". That means the same string
    /// appears twice, which is a small cost against the alternative of
    /// inventing an identifier nobody wants to type.
    public static func custom(_ title: String) -> Section {
        Section(rawValue: customPrefix + title)
    }

    private static let customPrefix = "custom:"

    /// The title, when this is a section of your own.
    public var customTitle: String? {
        guard rawValue.hasPrefix(Section.customPrefix) else { return nil }
        return String(rawValue.dropFirst(Section.customPrefix.count))
    }

    public var isCustom: Bool { customTitle != nil }

    // MARK: Orders

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

    /// Publications and funding carry the weight; length is not a constraint.
    ///
    /// The ordering is a discipline's convention rather than a rule — the
    /// sciences lead with grants, the humanities with publications — so this
    /// is a starting point to reorder, not an answer.
    public static let academic: [Section] = [
        .summary, .education, .publications, .grants, .experience, .teaching,
        .talks, .awards, .service, .memberships, .projects, .certifications,
        .languages, .skills, .references,
    ]

    // MARK: Titles

    /// The heading most readers, and most parsers, expect.
    ///
    /// Deliberately plain. An applicant tracking system looks for these words
    /// to work out which block is which, so "Where I've Worked" costs a
    /// candidate the entire employment history — the section is still read,
    /// but filed as nothing in particular.
    public var defaultTitle: String {
        if let custom = customTitle { return custom }
        return Section.titles[self] ?? rawValue.capitalized
    }

    private static let titles: [Section: String] = [
        .summary: "Summary",
        .experience: "Experience",
        .education: "Education",
        .skills: "Skills",
        .projects: "Projects",
        .volunteering: "Volunteering",
        .certifications: "Certifications",
        .publications: "Publications",
        .awards: "Awards",
        .languages: "Languages",
        .grants: "Grants and Funding",
        .teaching: "Teaching",
        .talks: "Talks",
        .service: "Service",
        .memberships: "Memberships",
        .interests: "Interests",
        .references: "References",
    ]
}

// MARK: - Custom section

/// A section the built-in set does not name.
///
/// Holds a list of content blocks rather than a fixed set of fields, so a
/// section of your own can be made of the same things a built-in one is —
/// prose, a list, jobs, degrees, papers, grants — in whatever order and
/// combination it needs. "Selected Works" is a list of publications;
/// "Clearances" is two lines of prose; "Fellowships" is grants with a
/// paragraph over them. None of those is a special case.
public struct CustomSection: Sendable, Equatable, Codable {

    /// Matches ``Section/custom(_:)`` in the order, and is printed as the
    /// heading.
    public let title: String

    /// Drawn in the order given.
    public let content: [Content]

    public init(_ title: String, _ content: [Content]) {
        self.title = title
        self.content = content
    }

    /// Prose, for the common case.
    public init(_ title: String, _ prose: String) {
        self.init(title, [.prose(prose)])
    }

    /// Empty, for a section kept around to fill in later.
    public init(_ title: String) {
        self.init(title, [])
    }

    /// Anything a section can be made of.
    ///
    /// The same shapes the built-in sections use, which is the point: a
    /// section of your own is not a lesser thing that only gets bullet points.
    public enum Content: Sendable, Equatable, Codable {

        /// A paragraph.
        case prose(String)

        /// Bullets.
        case list([String])

        /// Jobs, or anything shaped like one — a role, a place and dates.
        case positions([Position])

        case education([Education])
        case projects([Project])
        case publications([Publication])
        case credentials([Credential])
        case awards([Award])
        case grants([Grant])
        case skills([SkillGroup])
        case languages([Language])

        var isEmpty: Bool {
            switch self {
            case .prose(let text): return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .list(let items): return items.isEmpty
            case .positions(let items): return items.isEmpty
            case .education(let items): return items.isEmpty
            case .projects(let items): return items.isEmpty
            case .publications(let items): return items.isEmpty
            case .credentials(let items): return items.isEmpty
            case .awards(let items): return items.isEmpty
            case .grants(let items): return items.isEmpty
            case .skills(let items): return items.isEmpty
            case .languages(let items): return items.isEmpty
            }
        }
    }

    public var isEmpty: Bool { content.allSatisfy(\.isEmpty) }
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

    /// The language the headings are written in, as an ISO 639-1 code.
    ///
    /// Carried explicitly rather than inferred from whether the headings are
    /// the built-in ones. ``ATS`` warns about a heading a parser will not
    /// recognise, and that warning is only meaningful in English — a
    /// Lebenslauf saying *Berufserfahrung* is correct, not a mistake. Deriving
    /// "is this English" from the labels being untouched gets it exactly
    /// backwards: renaming a single heading is the case that most needs
    /// flagging, and it is also the case that stops them being untouched.
    public let language: String

    public init(
        _ overrides: [Section: String] = [:],
        present: String = "Present",
        dateSeparator: String = "–",
        language: String = "en"
    ) {
        self.overrides = overrides
        self.present = present
        self.dateSeparator = dateSeparator
        self.language = language
    }

    public func title(for section: Section) -> String {
        overrides[section] ?? section.defaultTitle
    }

    /// Replaces one heading, leaving the rest.
    public func naming(_ section: Section, _ title: String) -> Labels {
        var copy = overrides
        copy[section] = title
        return Labels(copy, present: present, dateSeparator: dateSeparator, language: language)
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
            .grants: "Drittmittel",
            .teaching: "Lehre",
            .talks: "Vorträge",
            .service: "Akademische Selbstverwaltung",
            .memberships: "Mitgliedschaften",
            .interests: "Interessen",
            .references: "Referenzen",
        ],
        present: "heute",
        dateSeparator: "–",
        language: "de"
    )
}
