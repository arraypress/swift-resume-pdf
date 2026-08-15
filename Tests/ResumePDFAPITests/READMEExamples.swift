//
//  READMEExamples.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Every Swift example in the README, compiled.
//
//  Two of them had rotted before this file existed: `order: .conventional`,
//  which named a static on `Section` that a leading dot cannot reach from
//  `[Section]`, and a `CustomSection(body:items:)` initialiser that no longer
//  existed. Both read perfectly well. Nothing that runs would have caught
//  either, because documentation is the one part of a library that is never
//  executed — and it is the part everyone reads first.
//
//  So the examples live here, where the compiler sees them, and
//  `READMEDriftTests` checks that what is here is still what the README says.
//

import Foundation
import ResumePDF
import TextPDF

// MARK: - Building your own

struct Broadside: Design {
    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.line(resume.profile.name, size: 30, face: sheet.semibold)
        sheet.rule(color: sheet.accent, thickness: 2)

        let style = Blocks.Style(x: sheet.left, width: sheet.width)
        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section))
            Blocks.render(section, of: resume, on: sheet, style: style)
        }
    }
}

// MARK: - The rest

/// Never called. Compiled.
func readmeExamples(
    url: URL, profile: Profile, roles: [Position], funding: [Grant],
    resume: Resume, regularURL: URL, semiboldURL: URL, italicURL: URL
) throws {
    Theme(accent: "#1F3A5F")                        // an ink blue
    Theme(accent: "#E8A33D", scheme: .dark)         // reversed out
    Theme(accent: "#7A4A2B", tint: "#F6F1E8")       // on warm paper
    Theme(density: .compact)                        // six more lines per page
    Theme(justified: true)                          // flush both edges

    Resume(profile: profile, experience: roles, order: .conventional)   // a résumé
    Resume(profile: profile, grants: funding, order: .academic)         // a CV

    let mine = Typeface.custom(
        name: "Söhne",
        regular: regularURL,
        semibold: semiboldURL,
        italic: italicURL
    )
    try resume.save(to: url, theme: Theme(typeface: mine))

    try resume.save(to: url, design: Broadside())

    Resume(
        profile: profile,
        experience: roles,
        custom: [
            CustomSection("Patents", [
                .prose("Two granted, one pending."),
                .list(["GB2601234 — Ledger write ordering"])
            ])
        ],
        order: [.summary, .experience, .custom("Patents"), .education]
    )

    Profile(name: "Alex Moreau", email: "alex@moreau.dev", qr: "https://moreau.dev/cv")

    try resume.render(design: .ledger, archival: true)   // PDF/A-3

    let theme = try resume.fitted(to: 1, design: .ledger)

    let letter = CoverLetter(
        profile: resume.profile,          // the same person, so the two agree
        recipient: Recipient(name: "Ms Adaeze Okonkwo", organisation: "Northwind Payments"),
        date: "14 August 2026",
        subject: "Re: Staff Infrastructure Engineer (ref. NW-2291)",
        body: ["I am writing about…"],
        highlights: [Highlight("Ledger reliability", "Rebuilt a write path handling £4.2bn a year.")]
    )

    try letter.save(to: url, design: .panel)

    let report = try resume.check(design: .ledger, region: .unitedStates)

    DateRange("2023")                  // "2023" — a single date
    DateRange.since("Mar 2022")        // "Mar 2022 – Present"
    DateRange("Jun 2019", "Feb 2022")  // "Jun 2019 – Feb 2022"

    Resume(profile: profile, experience: roles, labels: .german)

    Theme(density: .compact)

    _ = (theme, report)
}

/// The opening example, which builds a whole résumé.
func readmeOpeningExample(url: URL) throws {
    let resume = Resume(
        profile: Profile(
            name: "Alex Moreau",
            headline: "Senior Infrastructure Engineer",
            location: "London, UK",
            email: "alex@moreau.dev",
            links: [Link("https://github.com/alexmoreau")]
        ),
        summary: "Infrastructure engineer with eleven years on payment and ledger systems.",
        experience: [
            Position(
                role: "Senior Infrastructure Engineer",
                organisation: "Stripe",
                location: "London",
                dates: .since("Mar 2022"),
                highlights: ["Took p99 commit latency from 340ms to 45ms."]
            )
        ]
    )

    try resume.save(to: url, design: .ledger)     // 54 KB
}

/// The blueprint example, which reuses the README's name for its own thing.
func readmeBlueprintExample(url: URL, out: URL, resume: Resume) throws {
    let mine = try Blueprint(contentsOf: url)
    try resume.save(to: out, design: mine)
}
