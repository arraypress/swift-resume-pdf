//
//  BlueprintSections.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  One section, set differently from the rest.

import Foundation
import TextPDF

// MARK: - One section, set differently

extension Blueprint {

    /// What a single section does differently from the rest.
    ///
    /// Every field is optional and every absent one means "as the design has
    /// it" — not "as the default has it". That distinction is the whole point:
    /// a design that sets 11pt roles and then says `{"skills": "chips"}` for
    /// one section must keep its 11pt roles there, and a patch made of
    /// defaults would quietly undo them.
    public struct SectionOverride: Codable, Sendable, Equatable {

        public var heading: HeadingPatch?
        public var entries: EntriesPatch?

        /// Space after this section, where it wants more or less air than the
        /// rest — a skills list rarely needs the same gap as an employment
        /// history.
        public var sectionGap: Double?

        public init(
            heading: HeadingPatch? = nil,
            entries: EntriesPatch? = nil,
            sectionGap: Double? = nil
        ) {
            self.heading = heading
            self.entries = entries
            self.sectionGap = sectionGap
        }
    }

    /// A heading, changed in part.
    public struct HeadingPatch: Codable, Sendable, Equatable {

        public var style: Heading.Style?
        public var size: Double?
        public var colour: Paint?
        public var icon: Bool?

        public init(
            style: Heading.Style? = nil, size: Double? = nil,
            colour: Paint? = nil, icon: Bool? = nil
        ) {
            self.style = style
            self.size = size
            self.colour = colour
            self.icon = icon
        }

        func applied(to heading: Heading) -> Heading {
            Heading(
                style: style ?? heading.style,
                size: size ?? heading.size,
                colour: colour ?? heading.colour,
                icon: icon ?? heading.icon
            )
        }
    }

    /// Entry settings, changed in part.
    public struct EntriesPatch: Codable, Sendable, Equatable {

        public var dates: Entries.Dates?
        public var roleSize: Double?
        public var bodySize: Double?
        public var detailSize: Double?
        public var dateSize: Double?
        public var entryGap: Double?
        public var accentRoles: Bool?
        public var skills: Entries.Skills?
        public var languages: Entries.Languages?

        public init(
            dates: Entries.Dates? = nil, roleSize: Double? = nil, bodySize: Double? = nil,
            detailSize: Double? = nil, dateSize: Double? = nil, entryGap: Double? = nil,
            accentRoles: Bool? = nil, skills: Entries.Skills? = nil, languages: Entries.Languages? = nil
        ) {
            self.dates = dates
            self.roleSize = roleSize
            self.bodySize = bodySize
            self.detailSize = detailSize
            self.dateSize = dateSize
            self.entryGap = entryGap
            self.accentRoles = accentRoles
            self.skills = skills
            self.languages = languages
        }

        func applied(to entries: Entries) -> Entries {
            Entries(
                dates: dates ?? entries.dates,
                roleSize: roleSize ?? entries.roleSize,
                bodySize: bodySize ?? entries.bodySize,
                detailSize: detailSize ?? entries.detailSize,
                dateSize: dateSize ?? entries.dateSize,
                entryGap: entryGap ?? entries.entryGap,
                accentRoles: accentRoles ?? entries.accentRoles,
                skills: skills ?? entries.skills,
                languages: languages ?? entries.languages
            )
        }
    }
}
