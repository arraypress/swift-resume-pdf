//
//  BlueprintHeading.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  How a section announces itself: the nine treatments the designs use.

import Foundation
import TextPDF

// MARK: - Headings

extension Blueprint {

    /// How a section announces itself.
    public struct Heading: Codable, Sendable, Equatable {

        public var style: Style
        public var size: Double
        public var colour: Paint

        /// A small mark beside the heading, from the built-in set.
        public var icon: Bool

        public init(
            style: Style = .ruled,
            size: Double = 7.6,
            colour: Paint = .muted,
            icon: Bool = false
        ) {
            self.style = style
            self.size = size
            self.colour = colour
            self.icon = icon
        }

        /// The treatments, which are the ones the built-in designs use.
        public enum Style: String, Codable, Sendable, CaseIterable {

            /// A rule across the column, under the words.
            case ruled

            /// Nothing but the words.
            case plain

            /// A short bar in the accent colour, beside them.
            case accentBar

            /// Centred, with a rule either side.
            case centred

            /// A rounded tab behind them.
            case tab

            /// A highlighter swipe behind them, ending part-way.
            case marker

            /// Hung in the margin beside the text, which needs a `column`
            /// with room for it.
            case margin

            /// A label with a rule running out from it to the right margin.
            /// Set in the monospace, which is the point of it.
            case terminal

            /// The label with a short accent stub under it: the band's echo,
            /// for a page whose one strong horizontal is a masthead band.
            case underlined
        }

        func draw(
            _ title: String, section: Section, on sheet: Sheet,
            x: Double, width: Double, labelWidth: Double, labelAlign: Alignment
        ) {
            let tint = colour.colour(on: sheet)

            switch style {
            case .ruled, .plain, .accentBar, .centred:
                // The mark sits at the column's edge and the label after it,
                // so the pair lives inside the column with the words beneath
                // — hung in whatever margin lay to the left, it lined up with
                // nothing. Centred on the label's capitals, and measured from
                // where the heading will be drawn: after the break it would
                // make, not before, or the mark lands a line above its words
                // at the foot of a page.
                let mark = size + 3
                let inset = icon ? mark + 8 : 0
                if icon {
                    sheet.pdf.breakIfNeeded(Sheet.headingLookahead(size: size, leading: sheet.leading(size)))
                }
                let top = sheet.cursor
                sheet.sectionHeading(title, x: x + inset, width: width - inset,
                                     style: style.builtIn, color: tint, size: size)
                if icon {
                    let baseline = top - Sheet.headingDrop(style.builtIn)
                    let middle = baseline + size * 0.36   // half a capital's height up from the baseline
                    sheet.icon(Icon.of(section), x: x, y: middle - mark / 2, size: mark, color: sheet.accent)
                }

            case .tab:
                drawTab(title, section: section, on: sheet, x: x)

            case .marker:
                drawMarker(title, on: sheet, x: x)

            case .margin:
                drawMargin(title, section: section, on: sheet,
                           x: x, labelWidth: labelWidth, labelAlign: labelAlign)

            case .terminal:
                drawTerminal(title, on: sheet, x: x, width: width)

            case .underlined:
                drawUnderlined(title, on: sheet, x: x)
            }
        }

        /// A section label with a short accent underline.
        ///
        /// A stub of ink under the label, not a rule across the column: a
        /// masthead band has already drawn the page's one strong horizontal,
        /// and a second full-width line would compete with it.
        private func drawUnderlined(_ title: String, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()

            // Kept with the first entry of what follows — see `sectionHeading`.
            pdf.breakIfNeeded(sheet.leading(size) + 64)
            let top = pdf.cursor()

            pdf.textAt(label, x: x, y: top - 8, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: size * 0.14)
            pdf.rect(x: x, y: top - 14.6, width: 22, height: 2.2, color: sheet.accent)

            pdf.move(to: top - 16)
            sheet.gap(11)
        }

        /// A prompt, a mono label, and a rule running out from it to the margin.
        private func drawTerminal(_ title: String, on sheet: Sheet, x: Double, width: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()
            let tracking = size * 0.1
            let face = sheet.monoMedium ?? sheet.medium

            pdf.breakIfNeeded(sheet.leading(size) + 62)
            let baseline = pdf.cursor()

            // Drawn, not typed — see `Sheet.prompt`.
            sheet.prompt(x: x, y: baseline - size * 0.62, size: size,
                         color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent)
            let labelX = x + size * 1.3

            pdf.textAt(label, x: labelX, y: baseline - size, size: size,
                       color: colour.colour(on: sheet), face: face, tracking: tracking)

            // The rule starts where the label ends rather than under it, so
            // the two read as one object. Measured with the face that drew it,
            // which is the only reason the gap is right.
            let measured = pdf.width(of: label, size: size, face: face, tracking: tracking)
            let from = labelX + measured + 12
            if from < x + width - 20 {
                pdf.line(from: from, baseline - size * 0.6, to: x + width, baseline - size * 0.6,
                         color: sheet.hairline, thickness: 0.7)
            }

            pdf.move(to: baseline - size * 1.45)
            sheet.gap(11)
        }

        /// A rounded tab, with the mark inside it.
        private func drawTab(_ title: String, section: Section, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let height = size * 2.6
            let badge = height - 1
            let label = title.uppercased()
            let tracking = size * 0.14

            pdf.breakIfNeeded(height + 66)

            let top = pdf.cursor()
            let bottom = top - height
            let textWidth = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)

            // The badge sits inside the tab's rounded end, concentric with it
            // — see Bulletin.
            let textX = x + height + 6
            pdf.roundedRect(x: x, y: bottom, width: textX - x + textWidth + 13,
                            height: height, radius: height / 2, color: sheet.wash)

            if icon {
                // Filled where the accent can carry a reversed mark, outlined
                // where it cannot — the same choice the panel makes, for the
                // same reason.
                let centreX = x + height / 2
                let centreY = bottom + height / 2
                let mark = badge * 0.55
                let filled = sheet.theme.accentIsDark && !sheet.theme.isMonochrome

                if filled {
                    pdf.circle(x: centreX, y: centreY, radius: badge / 2, color: sheet.accent)
                } else {
                    pdf.ring(x: centreX, y: centreY, radius: badge / 2 - 0.5,
                             thickness: 1.1, color: sheet.accent)
                }

                sheet.icon(Icon.of(section), x: centreX - mark / 2, y: centreY - mark / 2,
                           size: mark, color: filled ? sheet.theme.page : sheet.accent)
            }

            pdf.textAt(label, x: textX, y: bottom + height * 0.35, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: tracking)

            pdf.move(to: bottom - 10)
        }

        /// A highlighter swipe across the words, a little past each end.
        private func drawMarker(_ title: String, on sheet: Sheet, x: Double) {
            let pdf = sheet.pdf
            let label = title.uppercased()
            let tracking = size * 0.05

            pdf.breakIfNeeded(size * 3 + 52)

            let top = pdf.cursor()
            let measured = pdf.width(of: label, size: size, face: sheet.semibold, tracking: tracking)
            let swipe = sheet.theme.isMonochrome
                ? sheet.theme.wash.darkened(by: 0.06)
                : sheet.accent.lightened(by: 0.62)

            pdf.rect(x: x - 4, y: top - size * 1.12, width: measured + 8,
                     height: size * 1.05, color: swipe)
            pdf.textAt(label, x: x, y: top - size * 0.92, size: size,
                       color: colour.colour(on: sheet), face: sheet.semibold, tracking: tracking)

            pdf.move(to: top - size * 1.9)
        }

        /// The name hung in the margin, level with the text it labels.
        private func drawMargin(
            _ title: String, section: Section, on sheet: Sheet,
            x: Double, labelWidth: Double, labelAlign: Alignment
        ) {
            let pdf = sheet.pdf
            pdf.breakIfNeeded(size * 6)

            let top = pdf.cursor()
            let boxWidth = max(20, labelWidth - (icon ? 20 : 0))

            if icon {
                sheet.icon(Icon.of(section), x: sheet.left + labelWidth - 13,
                           y: top - 12, size: 13, color: sheet.accent)
            }

            pdf.cell(title, x: sheet.left, boxWidth: boxWidth, size: size + 1,
                     color: colour.colour(on: sheet), align: labelAlign.textAlign,
                     face: sheet.medium)

            // The cursor does not move: the label sits beside the entries
            // rather than above them, which is the whole point of hanging it.
            pdf.move(to: top)
        }
    }
}

extension Blueprint.Heading.Style {

    /// The four that map onto the built-in heading treatments.
    var builtIn: HeadingStyle {
        switch self {
        case .plain: return .plain
        case .accentBar: return .accentBar
        case .centred: return .centred
        case .ruled, .tab, .marker, .margin, .terminal, .underlined: return .ruled
        }
    }
}
