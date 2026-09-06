//
//  BlueprintOrnament.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What is drawn behind: bands, cards, a rail, tabs — and the rectangles
//  recorded during layout and painted afterwards.

import Foundation
import TextPDF

// MARK: - What is drawn behind

extension Blueprint {

    /// Shading behind the text.
    ///
    /// Recorded while the page is laid out and painted in the background pass,
    /// because the height of a band is not known until the words that sit on
    /// it have been placed.
    public enum Ornament: String, Codable, Sendable, CaseIterable {

        case none

        /// Every other section on a tinted band.
        case bands

        /// The whole section on one rounded panel.
        case cards

        /// Every entry on a panel of its own. Suits several short roles;
        /// unkind to one long one.
        case entryCards

        /// Dates hung in a rail down the left, with a tick out to each entry.
        ///
        /// Sections that are not lists of dated things fall through to the
        /// ordinary treatment rather than being given an empty rail.
        case rail

        /// A bar of accent down the left of every section — the column
        /// inset by the bar's width, which is the column's `labelWidth`.
        case tabs

        static let cardPadding = 13.0

        /// The room a band keeps above its heading and below its last line.
        /// Without it the tint started on the label and stopped under the
        /// words, and read as a highlighter smear rather than a panel.
        static let bandPadding = 12.0

        /// Whether this section, by its position, gets a band.
        func bands(_ index: Int) -> Bool { self == .bands && index.isMultiple(of: 2) }

        /// Whether the entries sit inside something and need room from its edge.
        var insets: Bool { self == .cards || self == .entryCards }

        func prepare(on sheet: Sheet) -> Shading? {
            guard self != .none, self != .rail, self != .tabs else { return nil }

            let shading = Shading()
            let tint = sheet.wash
            let rounded = insets

            // A card gets a hairline edge — a larger panel under an inset
            // one, because the writer has no stroked rounded rectangle.
            // Without it the wash reads as page smudge rather than as an
            // object with a boundary. A band stays edgeless: it runs the
            // full bleed, and a boundary is exactly what it does not want.
            let edge = sheet.theme.scheme == .dark
                ? tint.lightened(by: 0.18)
                : Color.grey(225)

            sheet.background { doc, page, _ in
                for rect in shading.rects(onPage: page) {
                    if rounded {
                        doc.roundedRect(x: rect.x, y: rect.bottom, width: rect.width,
                                        height: rect.top - rect.bottom, radius: 7, color: edge)
                        doc.roundedRect(x: rect.x + 0.8, y: rect.bottom + 0.8,
                                        width: rect.width - 1.6,
                                        height: rect.top - rect.bottom - 1.6,
                                        radius: 6.2, color: tint)
                    } else {
                        doc.rect(x: 0, y: rect.bottom, width: doc.width(),
                                 height: rect.top - rect.bottom, color: tint)
                    }
                }
            }
            return shading
        }

        /// Runs `body`, recording what it covered so it can be painted under.
        /// - Parameter sectionTop: Where the section began, before its
        ///   heading — on this page. A band encloses the heading too, with
        ///   ``bandPadding`` above it; a card starts under the heading.
        func wrap(
            index: Int, on sheet: Sheet, shading: Shading?,
            x: Double, width: Double, sectionTop: Double?, _ body: () -> Void
        ) {
            guard let shading, self != .none, self == .cards || index.isMultiple(of: 2) else {
                body()
                return
            }

            let pdf = sheet.pdf
            let page = pdf.pageCount()
            let top: Double
            if self == .bands {
                // From above the heading, so the label sits inside the tint
                // with room over it rather than on its edge.
                top = (sectionTop ?? pdf.cursor()) + Ornament.bandPadding
            } else {
                // From the cursor down, with the words inset — a panel that
                // reached up into the heading's gap touched the label above it.
                top = pdf.cursor()
            }
            pdf.gap(13)

            // Drawn with a palette derived from the shading, so a chip's own
            // wash steps away from the wash it sits on rather than vanishing
            // into it.
            sheet.drawing(on: .against(sheet.wash, accent: sheet.theme.accentColor)) {
                body()
            }

            // Only shaded when the section stayed on one page: a rectangle
            // whose corners are on different sheets of paper is not a shape.
            guard pdf.pageCount() == page else { return }
            let bottom = pdf.cursor() - Ornament.bandPadding
            shading.add(page: page, x: x, width: width, top: top, bottom: bottom)
            // The next section measures its gap from the shape's edge, not
            // from the last line inside it.
            pdf.move(to: bottom)
        }
    }

    /// Rectangles recorded during layout, drawn afterwards.
    public final class Shading: @unchecked Sendable {

        struct Rect {
            let page: Int
            let x: Double
            let width: Double
            let top: Double
            let bottom: Double
        }

        private var recorded: [Rect] = []

        func add(page: Int, x: Double, width: Double, top: Double, bottom: Double) {
            guard top > bottom else { return }
            recorded.append(Rect(page: page, x: x, width: width, top: top, bottom: bottom))
        }

        func rects(onPage page: Int) -> [Rect] {
            recorded.filter { $0.page == page }
        }
    }
}
