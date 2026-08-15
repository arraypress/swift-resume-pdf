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
import UniformTypeIdentifiers
import XCTest

enum Fixtures {

    /// A JPEG portrait.
    static let photoPath = write("portrait.jpg", as: UTType.jpeg, alpha: false)

    /// A PNG portrait, with an alpha channel that must survive the soft mask.
    static let pngPhotoPath = write("portrait.png", as: UTType.png, alpha: true)

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

    private static func write(_ name: String, as type: UTType, alpha: Bool) -> String {
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

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return "" }

        return url.path
    }
}
