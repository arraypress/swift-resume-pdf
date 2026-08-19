//
//  Fixtures.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Test images, made rather than committed.
//
//  The photograph tests used to read a JPEG out of a scratch directory on one
//  machine and `XCTSkipUnless` their way past its absence everywhere else — so
//  on a fresh clone, and on CI, every photograph test silently passed by not
//  running. A skipped test is a test you do not have.
//
//  These are drawn with ImageIO, which is already a dependency of the image
//  path being tested, and written once per run.
//

import CoreGraphics
import Foundation
import ImageIO
import ResumePDF
import UniformTypeIdentifiers
import XCTest

enum Fixtures {

    /// A JPEG portrait.
    static let photoPath = write("portrait.jpg", as: UTType.jpeg, alpha: false)

    /// A PNG portrait, with an alpha channel that must survive the soft mask.
    static let pngPhotoPath = write("portrait.png", as: UTType.png, alpha: true)

    /// A JPEG portrait carrying an EXIF orientation, the way a phone shoots
    /// one. The writer embeds JPEG bytes verbatim, so the flag is never
    /// applied — which is exactly what the checks are supposed to notice.
    static let rotatedPhotoPath = write("portrait-rotated.jpg", as: UTType.jpeg, alpha: false,
                                        orientation: 6)

    // MARK: Drawing

    /// A 120×160 portrait: two bands and a disc, enough to tell right side up
    /// from upside down and cropped from squashed by eye.
    private static func draw(alpha: Bool) -> CGImage? {
        let width = 120, height = 160
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue
        ) else { return nil }

        context.setFillColor(CGColor(red: 0.86, green: 0.88, blue: 0.92, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.setFillColor(CGColor(red: 0.15, green: 0.23, blue: 0.37, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: 40))

        context.setFillColor(CGColor(red: 0.93, green: 0.78, blue: 0.66, alpha: 1))
        context.fillEllipse(in: CGRect(x: 30, y: 70, width: 60, height: 60))

        return context.makeImage()
    }

    private static func write(
        _ name: String, as type: UTType, alpha: Bool, orientation: Int? = nil
    ) -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("resume-pdf-fixtures", isDirectory: true)
            .appendingPathComponent(name)

        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )

        guard let image = draw(alpha: alpha),
              let destination = CGImageDestinationCreateWithURL(
                  url as CFURL, type.identifier as CFString, 1, nil
              )
        else { return "" }

        let properties = orientation.map { [kCGImagePropertyOrientation: $0] as CFDictionary }
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { return "" }

        return url.path
    }

    // MARK: Reading pages back

    /// The page content streams of a rendered PDF, in page order.
    ///
    /// Only readable when the document was drawn *without* an embedded
    /// family: base-14 text is written as escaped literals, where a family's
    /// runs are glyph hex nothing can grep. The layout tests build their
    /// sheets with an empty ``FontFamily`` for exactly this reason — with no
    /// faces, no images and no attachments, the only streams in the file are
    /// the pages, and they come out in page order.
    static func pageStreams(_ data: Data) -> [String] {
        guard let text = String(data: data, encoding: .isoLatin1) else { return [] }

        var streams: [String] = []
        var search = text.startIndex
        while let open = text.range(of: "stream\n", range: search..<text.endIndex) {
            guard let close = text.range(of: "endstream", range: open.upperBound..<text.endIndex)
            else { break }

            var body = String(text[open.upperBound..<close.lowerBound])
            if body.hasSuffix("\n") { body.removeLast() }
            streams.append(body)
            search = close.upperBound
        }
        return streams
    }
}

// MARK: - A résumé that does not fit

extension Resume {

    /// A résumé long enough to cross pages.
    ///
    /// ``sample`` is deliberately awkward but it is short, and every layout
    /// bug the audit found lived past the bottom of page one — the overflow
    /// tests share this so none of them proves anything about a page that
    /// was never full.
    static var long: Resume {
        Resume(
            profile: sample.profile,
            summary: sample.summary,
            experience: [
                Position(
                    role: "Senior Infrastructure Engineer",
                    organisation: "Stripe",
                    location: "London",
                    dates: .since("Mar 2022"),
                    highlights: [
                        "Carried the pager for the payments API through three peak seasons.",
                        "Rebuilt the ledger write path: p99 commit latency from 340ms to 45ms.",
                    ],
                    skills: ["Go", "Postgres", "Kubernetes"]
                ),
            ],
            education: (1...12).map { index in
                Education(
                    qualification: "Postgraduate Certificate in Distributed Systems, cohort \(index)",
                    institution: "University of Somewhere \(index)",
                    dates: DateRange("20\(String(format: "%02d", 8 + index % 10))"),
                    highlights: ["Dissertation: a fairly long title that wraps onto a second line."]
                )
            },
            skills: (1...4).map { group in
                SkillGroup("Discipline \(group)", (1...15).map { Skill("Skill \(group).\($0)", 0.7) })
            },
            certifications: (1...10).map {
                Credential(name: "Certification with a longer name than most, number \($0)",
                           issuer: "An Issuing Body", date: "20\(String(format: "%02d", 10 + $0))")
            },
            languages: (1...60).map { Language("Language \($0)", "C1") },
            order: Section.conventional
        )
    }
}
