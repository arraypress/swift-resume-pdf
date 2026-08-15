//
//  Sample.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A worked example, for seeing what a design does before writing your own.
//
//  Deliberately awkward in places — a long job title, a two-line bullet, a
//  name with an accent in it, a role with no end date. A sample where
//  everything is short makes every design look fine.
//

import Foundation

extension Resume {

    /// A complete résumé, for previews and tests.
    public static var sample: Resume {
        Resume(
            profile: Profile(
                name: "Alex Moreau",
                headline: "Senior Infrastructure Engineer",
                location: "London, UK",
                email: "alex@moreau.dev",
                phone: "+44 7700 900123",
                links: [
                    Link("https://github.com/alexmoreau"),
                    Link("https://alexmoreau.dev"),
                ]
            ),
            summary: """
                Infrastructure engineer with eleven years on payment and ledger systems, \
                most of it on the reliability side of teams that could not afford an \
                outage.
                """,
            experience: [
                Position(
                    role: "Senior Infrastructure Engineer",
                    organisation: "Stripe",
                    location: "London",
                    dates: .since("Mar 2022"),
                    highlights: [
                        "Rebuilt the ledger write path: p99 commit latency from 340ms to 45ms.",
                        "Led 40 services off a shared Postgres primary, retiring the last SPOF in payments.",
                    ],
                    skills: ["Go", "Postgres", "Kubernetes", "Terraform"]
                ),
                Position(
                    role: "Platform Engineer",
                    organisation: "Monzo",
                    location: "London",
                    dates: DateRange("Jun 2019", "Feb 2022"),
                    highlights: [
                        "Took the bank from 20 to 200 deploys a day, with no new approval step.",
                        "Cut paging 60% by fixing three alerts rather than raising thresholds.",
                    ],
                    skills: ["Go", "Cassandra", "AWS"]
                ),
                Position(
                    role: "Backend Engineer",
                    organisation: "Deliveroo",
                    location: "London",
                    dates: DateRange("Sep 2016", "May 2019"),
                    summary: "Rider dispatch, through a period when order volume grew eight-fold."
                ),
            ],
            education: [
                Education(
                    qualification: "BSc Computer Science",
                    institution: "University of Bristol",
                    dates: DateRange("2013", "2016"),
                    grade: "First Class Honours"
                ),
            ],
            skills: [
                SkillGroup("Languages", ["Go", "Swift", "Python", "SQL"]),
                SkillGroup("Infrastructure", ["Kubernetes", "Terraform", "AWS", "Postgres"]),
                SkillGroup("Practice", ["Incident response", "Capacity planning", "Mentoring"]),
            ],
            projects: [
                Project(
                    name: "ledgerfuzz",
                    role: "Author",
                    link: Link("https://github.com/alexmoreau/ledgerfuzz"),
                    dates: DateRange("2023"),
                    summary: "A property-based fuzzer for double-entry ledgers. In production at two banks."
                ),
            ],
            certifications: [
                Credential(name: "CKA — Certified Kubernetes Administrator", issuer: "CNCF", date: "2021"),
            ],
            awards: [],
            languages: [
                Language("English", "Native"),
                Language("French", "C1"),
            ],
            order: Section.conventional
        )
    }

    /// An academic CV, which is a different document rather than a longer one.
    public static var academicSample: Resume {
        Resume(
            profile: Profile(
                name: "Dr Ingrid Sørensen",
                headline: "Reader in Computational Linguistics",
                location: "Edinburgh, UK",
                email: "i.sorensen@ed.ac.uk",
                links: [Link("https://ed.ac.uk/informatics/sorensen")]
            ),
            summary: """
                Computational linguist working on low-resource morphology, with a \
                particular interest in languages whose speakers are not served by the \
                methods that work for English.
                """,
            experience: [
                Position(
                    role: "Reader in Computational Linguistics",
                    organisation: "University of Edinburgh",
                    dates: .since("2021"),
                    highlights: ["Principal investigator, EPSRC grant EP/X01234/1 (£1.2m, 2022–2026)."]
                ),
                Position(
                    role: "Lecturer",
                    organisation: "University of Copenhagen",
                    dates: DateRange("2016", "2021")
                ),
            ],
            education: [
                Education(
                    qualification: "PhD Linguistics",
                    institution: "University of Copenhagen",
                    dates: DateRange("2012", "2016"),
                    highlights: ["Thesis: Morphological segmentation without supervision in agglutinative languages."]
                ),
            ],
            skills: [SkillGroup("Methods", ["Bayesian inference", "Finite-state morphology"])],
            publications: [
                Publication(
                    title: "Unsupervised morphological segmentation for agglutinative languages",
                    venue: "Computational Linguistics 49(2)",
                    date: "2023",
                    authors: "Sørensen, I., Okonkwo, A., Baptiste, M."
                ),
                Publication(
                    title: "What morphological complexity costs a language model",
                    venue: "Proceedings of ACL",
                    date: "2022",
                    authors: "Sørensen, I., Baptiste, M."
                ),
            ],
            awards: [
                Award(name: "Best Long Paper", issuer: "ACL", date: "2022"),
            ],
            languages: [
                Language("Danish", "Native"),
                Language("English", "Native"),
                Language("German", "B2"),
            ],
            order: Section.academic
        )
    }
}

// MARK: - Letters

extension CoverLetter {

    /// A worked letter, for previews and tests.
    ///
    /// Written the way a good one is: addressed to a person, specific about
    /// the reader rather than about the writer, and short enough to be read.
    public static var sample: CoverLetter {
        CoverLetter(
            profile: Resume.sample.profile,
            recipient: Recipient(
                name: "Ms Adaeze Okonkwo",
                role: "Head of Infrastructure",
                organisation: "Northwind Payments",
                address: ["12 Finsbury Circus", "London EC2M 7EA"]
            ),
            date: "14 August 2026",
            subject: "Re: Staff Infrastructure Engineer (ref. NW-2291)",
            body: [
                """
                I am writing about the Staff Infrastructure Engineer role. I have spent \
                eleven years on payment and ledger systems, four of them at Stripe on the \
                team responsible for the double-entry ledger, and Northwind is one of the \
                few places doing that work at a scale where it is genuinely hard.
                """,
                """
                Your engineering blog's account of moving settlement off a shared primary \
                described a problem I spent most of 2023 on. We took the ledger's p99 \
                commit latency from 340ms to 45ms without weakening the audit guarantees \
                the finance team depends on, and retired the last single point of failure \
                in the payments path across forty services.
                """,
            ],
            highlights: [
                Highlight("Ledger reliability", "Rebuilt a write path handling £4.2bn a year, with no customer-visible incident during the migration."),
                Highlight("On-call that people can live with", "Cut paging volume 60% at Monzo by fixing the three alerts responsible for most of it rather than by raising thresholds."),
                Highlight("Writing things down", "Wrote the incident review process now used across Stripe; median time to a published review fell from nine days to two."),
            ],
            closing: "",
            postscript: ""
        )
    }
}
