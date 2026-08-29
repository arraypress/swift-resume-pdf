//
//  BlueprintColumns.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The column the sections sit in — inset with a margin for labels, or the
//  head at the page edge — and the second column that a tracking system
//  reads wrong.

import Foundation
import TextPDF

// MARK: - The column

extension Blueprint {

    /// Where the text sits, and what is beside it.
    ///
    /// `labelWidth` of zero is a full-width column — the usual case. Anything
    /// larger insets the text and leaves that much room to its left for
    /// section labels, which is how Margin and Timeline are laid
    /// out. It is still one column in reading order.
    public struct Column: Codable, Sendable, Equatable {

        /// What a rail takes when the design did not say.
        static let railWidth = 96.0
        static let railGutter = 16.0

        public var labelWidth: Double
        public var gutter: Double
        public var labelAlign: Alignment

        /// The masthead and the headings start at the page margin, and only
        /// the entries sit past the rail — the shape of a timeline, where
        /// the rail belongs to the entries and not to the page.
        public var headAtMargin: Bool

        /// A hairline across the body above every section.
        public var ruled: Bool

        public init(
            labelWidth: Double = 0, gutter: Double = 0, labelAlign: Alignment = .right,
            headAtMargin: Bool = false, ruled: Bool = false
        ) {
            self.labelWidth = labelWidth
            self.gutter = gutter
            self.labelAlign = labelAlign
            self.headAtMargin = headAtMargin
            self.ruled = ruled
        }
    }
}

// MARK: - A second column

extension Blueprint {

    /// A second column, carrying the sections it names.
    ///
    /// The one thing in this vocabulary a tracking system reads wrong: the
    /// parser extracts the text in order and does not know the column is a
    /// column, so the rail comes out interleaved with the experience — a
    /// phone number in the middle of an employment history. A blueprint
    /// with a side is therefore not ``isSingleColumn``, and `check` reports
    /// it as the blocker it is. It exists for the document a person will
    /// open, and says so.
    public struct Side: Codable, Sendable, Equatable {

        /// The column's width in points, from the page edge when filled.
        public var width: Double
        public var edge: Edge

        /// The sections it carries. The rest go in the main column, as does
        /// any of these that would not fit on page one.
        public var sections: [Section]

        /// A tint behind it, running the page's full height. `rail` is the
        /// theme's accent lightened to a wash. Nil is no tint.
        public var fill: Paint?

        /// A hairline between the columns.
        public var divider: Bool

        /// How far the words sit in from the filled edge.
        public var inset: Double

        /// The space between the columns.
        public var gutter: Double

        /// Where the masthead goes: inside the column, stacked to its width
        /// with the contact details one per line; or above both columns,
        /// set by ``Masthead``.
        public var head: Head

        public var heading: Heading
        public var entries: Entries

        public enum Edge: String, Codable, Sendable, CaseIterable { case left, right }
        public enum Head: String, Codable, Sendable, CaseIterable { case inside, above }

        public init(
            width: Double = 190,
            edge: Edge = .left,
            sections: [Section] = [.skills, .languages, .education, .certifications, .interests],
            fill: Paint? = .rail,
            divider: Bool = false,
            inset: Double = 27,
            gutter: Double = 30,
            head: Head = .inside,
            heading: Heading = Heading(style: .plain, size: 7.4, colour: .accent),
            entries: Entries = Entries(dates: .beneath, roleSize: 9.6, bodySize: 8.7,
                                       detailSize: 8.6, dateSize: 8, entryGap: 10)
        ) {
            self.width = width
            self.edge = edge
            self.sections = sections
            self.fill = fill
            self.divider = divider
            self.inset = inset
            self.gutter = gutter
            self.head = head
            self.heading = heading
            self.entries = entries
        }
    }
}
