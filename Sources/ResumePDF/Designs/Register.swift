//
//  Register.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Alternate sections on a tinted band, with the label in the left margin.
//
//  The banding does what a rule does, with less ink and more certainty: a
//  reader never has to work out whether a block belongs to the heading above
//  it or the one below, because the block and its heading share a background.
//
//  ## Drawing behind text that has not been laid out yet
//
//  A band has to be painted before the words that sit on it, and its height is
//  not known until they have been. Rather than measure twice, the bands are
//  recorded as the page is laid out and drawn in the background pass, which
//  happens after everything is placed and before anything is composited. The
//  cost is that a band is one page's worth: a section spanning a break is
//  banded on the page it started on and left plain on the next, which reads
//  correctly and is not worth a second layout pass to avoid.
//

import Foundation
import TextPDF

struct Register: Design {

    private let labelWidth = 96.0
    private let gutter = 20.0

    func render(_ resume: Resume, on sheet: Sheet) {
        let pdf = sheet.pdf
        let bodyX = sheet.left + labelWidth + gutter
        let bodyWidth = sheet.width - labelWidth - gutter

        masthead(resume, on: sheet, bodyX: bodyX, bodyWidth: bodyWidth)

        var style = Blocks.Style(x: bodyX, width: bodyWidth)
        style.entryGap = 14

        // Collected during layout, painted in the background pass.
        let bands = Bands()
        let tint = sheet.wash
        sheet.background { doc, page, _ in
            for band in bands.rects(onPage: page) {
                doc.rect(x: 0, y: band.bottom, width: doc.width(),
                         height: band.top - band.bottom, color: tint)
            }
        }

        for (index, section) in resume.populated().enumerated() {
            sheet.gap(index == 0 ? 4 : 15)
            pdf.breakIfNeeded(sheet.leading(style.roleSize) * 4)

            let page = pdf.pageCount()
            let top = pdf.cursor() + 13

            label(resume.heading(for: section), icon: Icon.of(section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)

            // Only banded when the section stayed on one page. A rectangle
            // whose corners are on different sheets of paper is not a shape.
            if index.isMultiple(of: 2), pdf.pageCount() == page {
                bands.add(page: page, top: top, bottom: pdf.cursor() - 12)
            }
        }

        sheet.footer(name: resume.profile.name)
    }

    /// The section name and its mark, hung in the margin.
    private func label(_ title: String, icon: Icon, on sheet: Sheet) {
        let pdf = sheet.pdf
        let top = pdf.cursor()

        sheet.icon(icon, x: sheet.left + labelWidth - 13, y: top - 12, size: 13, color: sheet.accent)
        pdf.cell(title, x: sheet.left, boxWidth: labelWidth - 20, size: 8.6,
                 color: sheet.muted, align: .right, face: sheet.medium)
    }

    private func masthead(_ resume: Resume, on sheet: Sheet, bodyX: Double, bodyWidth: Double) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        pdf.textAt(profile.name, x: bodyX, y: top - 20, size: 24,
                   color: sheet.ink, align: .center, boxWidth: bodyWidth,
                   face: sheet.semibold, tracking: -0.3)

        var y = top - 40
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: bodyX, y: y, size: 10.6,
                       color: sheet.theme.isMonochrome ? sheet.muted : sheet.accent,
                       align: .center, boxWidth: bodyWidth, face: sheet.regular)
            y -= 17
        }

        pdf.move(to: y - 2)
        sheet.contactFlow(profile.contactLine() + profile.links.map(\.label),
                          x: bodyX, width: bodyWidth, size: 8.7, align: .center)

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              x: bodyX, width: bodyWidth, size: 8.4, align: .center)
        }
        sheet.gap(8)
    }
}

/// Bands recorded during layout, drawn afterwards.
private final class Bands {

    struct Rect {
        let page: Int
        let top: Double
        let bottom: Double
    }

    private var recorded: [Rect] = []

    func add(page: Int, top: Double, bottom: Double) {
        guard top > bottom else { return }
        recorded.append(Rect(page: page, top: top, bottom: bottom))
    }

    func rects(onPage page: Int) -> [Rect] {
        recorded.filter { $0.page == page }
    }
}
