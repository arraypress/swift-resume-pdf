//
//  Resume+Sections.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a résumé can say about its own sections — which have anything in
//  them, and what each is headed — kept out of the model, which states
//  only what a résumé is.
//

import Foundation

extension Resume {

    /// The sections that have anything in them, in order.
    public func populated() -> [Section] {
        order.filter { isPopulated($0) }
    }

    func isPopulated(_ section: Section) -> Bool {
        switch section {
        case .summary: return !summary.isBlank
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
        case .interests: return !interests.isBlank
        case .references: return !references.isBlank
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
