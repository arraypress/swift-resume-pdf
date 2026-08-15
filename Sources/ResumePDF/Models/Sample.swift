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
                outage. Happiest reducing a system nobody wants to touch into something \
                three people can change safely.
                """,
            experience: [
                Position(
                    role: "Senior Infrastructure Engineer",
                    organisation: "Stripe",
                    location: "London",
                    dates: .since("Mar 2022"),
                    highlights: [
                        "Rebuilt the double-entry ledger's write path, taking p99 commit latency from 340ms to 45ms while keeping the audit guarantees the finance team relies on.",
                        "Led the migration of 40 services off a shared Postgres primary, retiring the last single point of failure in the payments path.",
                        "Wrote the incident review process now used across the org; median time to a published review fell from nine days to two.",
                    ],
                    skills: ["Go", "Postgres", "Kubernetes", "Terraform"]
                ),
                Position(
                    role: "Platform Engineer",
                    organisation: "Monzo",
                    location: "London",
                    dates: DateRange("Jun 2019", "Feb 2022"),
                    summary: "Core banking platform, 200 engineers, 5m customers.",
                    highlights: [
                        "Built the deployment tooling that took the bank from 20 to 200 deploys a day without adding an approval step.",
                        "On-call lead for the ledger. Cut paging volume 60% by fixing the three alerts responsible for most of it rather than tuning thresholds.",
                    ],
                    skills: ["Go", "Cassandra", "AWS"]
                ),
                Position(
                    role: "Backend Engineer",
                    organisation: "Deliveroo",
                    location: "London",
                    dates: DateRange("Sep 2016", "May 2019"),
                    highlights: [
                        "Rider dispatch. Owned the assignment service through a period when order volume grew eight-fold.",
                    ]
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
                    summary: "A property-based fuzzer for double-entry ledgers. Used in production at two banks.",
                    skills: ["Go"]
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
