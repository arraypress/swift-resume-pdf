//
//  Margin.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Section names hung in the left margin, content in one column beside them.
//
//  The oldest trick in book typography and still the best one for a document
//  that is scanned rather than read: the labels form a single vertical line
//  the eye runs down to find a section, and because they sit outside the text
//  column they never interrupt it. Nothing is centred, nothing is boxed, and
//  the page has one edge instead of three.
//
//  Still one column as far as a parser is concerned. The label is drawn
//  immediately before the block it names — the same order a person reads them
//  in — so the text comes out as heading followed by content rather than as
//  two streams to untangle.
//

import Foundation
import TextPDF

struct Margin: Design {

    /// Wide enough for "Certifications" at the label size.
    private let labelWidth = 104.0
    private let gutter = 22.0

    func render(_ resume: Resume, on sheet: Sheet) {
        let bodyX = sheet.left + labelWidth + gutter
        let bodyWidth = sheet.width - labelWidth - gutter

        masthead(resume, on: sheet, bodyX: bodyX, bodyWidth: bodyWidth)

        var style = Blocks.Style(x: bodyX, width: bodyWidth)
        style.entryGap = 14
        style.skills = .list

        for (index, section) in resume.populated().enumerated() {
            if index > 0 { sheet.gap(15) }

            // Ruled above rather than below, so the label and its block sit
            // inside the same compartment.
            sheet.pdf.breakIfNeeded(sheet.leading(style.roleSize) * 4)
            sheet.rule(x: bodyX, width: bodyWidth, thickness: 0.6)
            sheet.gap(11)

            label(resume.heading(for: section), on: sheet)
            Blocks.render(section, of: resume, on: sheet, style: style)
        }

        sheet.footer(name: resume.profile.name)
    }

    /// The section name, right-aligned against the gutter.
    ///
    /// Drawn without advancing: the content that follows starts on the same
    /// line, which is the whole point of hanging it out here.
    private func label(_ title: String, on sheet: Sheet) {
        sheet.pdf.cell(
            title, x: sheet.left, boxWidth: labelWidth,
            size: 8.6, color: sheet.muted, align: .right, face: sheet.medium
        )
    }

    private func masthead(_ resume: Resume, on sheet: Sheet, bodyX: Double, bodyWidth: Double) {
        let pdf = sheet.pdf
        let profile = resume.profile
        let top = pdf.height() - sheet.theme.density.margin

        // Aligned with the text column rather than the page edge, so the name
        // sits on the same vertical as everything under it.
        pdf.textAt(profile.name, x: bodyX, y: top - 20, size: 23,
                   color: sheet.theme.isMonochrome ? sheet.ink : sheet.accent,
                   face: sheet.semibold, tracking: -0.3)

        var y = top - 38
        if !profile.headline.isEmpty {
            pdf.textAt(profile.headline, x: bodyX, y: y, size: 10.4,
                       color: sheet.muted, face: sheet.regular)
            y -= 16
        }
        pdf.move(to: y - 8)

        let contact = profile.contactLine() + profile.links.map(\.label)
        if !contact.isEmpty {
            sheet.rule(x: bodyX, width: bodyWidth, thickness: 0.6)
            sheet.gap(11)
            label("Contact", on: sheet)
            sheet.contactFlow(contact, x: bodyX, width: bodyWidth, size: 8.7)
        }

        let particulars = profile.particulars()
        if !particulars.isEmpty {
            sheet.gap(13)
            sheet.rule(x: bodyX, width: bodyWidth, thickness: 0.6)
            sheet.gap(11)
            label("Details", on: sheet)
            sheet.contactFlow(particulars.map { "\($0.label): \($0.value)" },
                              x: bodyX, width: bodyWidth, size: 8.5)
        }
        sheet.gap(6)
    }
}
