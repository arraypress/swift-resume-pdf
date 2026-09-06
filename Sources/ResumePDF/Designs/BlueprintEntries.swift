//
//  BlueprintEntries.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  How the entries under a heading are set.

import Foundation
import TextPDF

// MARK: - Entries

extension Blueprint {

    /// How the entries under a heading are set.
    public struct Entries: Codable, Sendable, Equatable {

        public var dates: Dates
        public var roleSize: Double
        public var bodySize: Double
        public var detailSize: Double
        public var dateSize: Double
        public var entryGap: Double
        public var accentRoles: Bool
        public var skills: Skills

        /// How a language's level is shown: as written, or with dots or a
        /// bar drawn from what the words mean.
        public var languages: Languages

        public init(
            dates: Dates = .besideTitle,
            roleSize: Double = 10.4,
            bodySize: Double = 9.4,
            detailSize: Double = 9.2,
            dateSize: Double = 8.5,
            entryGap: Double = 13,
            accentRoles: Bool = false,
            skills: Skills = .list,
            languages: Languages = .text
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

        /// Where an entry's dates go.
        public enum Dates: String, Codable, Sendable, CaseIterable {

            /// Against the right edge, on the title's line. Wants a wide column.
            case besideTitle

            /// Under the organisation, which is what a narrow column has room for.
            case beneath
        }

        /// How a skills section is drawn. All four are real words on the page,
        /// so all four survive a parser.
        public enum Skills: String, Codable, Sendable, CaseIterable {
            case list, chips, bars, dots, underlined, inline
        }

        /// How a language's level is shown. `text` is the words as written;
        /// `dots` and `bars` draw what they mean, and draw nothing for words
        /// the scale does not know.
        public enum Languages: String, Codable, Sendable, CaseIterable {
            case text, dots, bars
        }

        func style(x: Double, width: Double) -> Blocks.Style {
            Blocks.Style(
                x: x, width: width,
                dates: dates == .besideTitle ? .besideTitle : .beneath,
                roleSize: roleSize, bodySize: bodySize,
                detailSize: detailSize, dateSize: dateSize,
                entryGap: entryGap, accentRoles: accentRoles,
                skills: skills.blocks, languages: languages.blocks
            )
        }
    }
}

extension Blueprint.Entries.Skills {

    var blocks: Blocks.SkillStyle {
        switch self {
        case .list: return .list
        case .chips: return .chips
        case .bars: return .bars
        case .dots: return .dots
        case .underlined: return .underlined
        case .inline: return .inline
        }
    }
}

extension Blueprint.Entries.Languages {

    var blocks: Blocks.LanguageStyle {
        switch self {
        case .text: return .text
        case .dots: return .dots
        case .bars: return .bars
        }
    }
}
