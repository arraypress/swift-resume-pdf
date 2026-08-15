//
//  Typography.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The typefaces the designs are set in, carried in the package.
//
//  Bundled rather than asked for, because a résumé tool whose output looks
//  like a 1998 memo unless the user goes and finds a font is a résumé tool
//  nobody uses twice. Both families are SIL Open Font Licence 1.1, which
//  permits redistribution inside a larger work; the licences travel with them
//  in Resources/Fonts.
//
//  Static instances, not variable ones. A variable font carries a single set
//  of outlines plus the deltas that make a weight, and subsetting keeps the
//  outlines and drops the deltas — so the whole document would come out
//  regular. TextPDF refuses them outright for that reason.
//

import Foundation
import TextPDF

/// A typeface the designs can be set in.
public enum Typeface: String, Sendable, CaseIterable, Codable {

    /// Inter — a neutral grotesque drawn for screens, with a tall x-height
    /// that stays legible at the sizes a dense résumé needs.
    case inter

    /// Source Serif 4 — a transitional serif. Reads as considered rather than
    /// current, which suits academia, law, and anywhere a sans would look like
    /// it was trying too hard.
    case sourceSerif

    public var displayName: String {
        switch self {
        case .inter: return "Inter"
        case .sourceSerif: return "Source Serif 4"
        }
    }

    /// The files making up the family, by weight and slope.
    var faces: [(file: String, weight: FontFamily.Weight, italic: Bool)] {
        switch self {
        case .inter:
            return [
                ("Inter-Regular", .regular, false),
                ("Inter-Medium", .medium, false),
                ("Inter-SemiBold", .semibold, false),
                ("Inter-Bold", .bold, false),
                ("Inter-Italic", .regular, true),
            ]
        case .sourceSerif:
            return [
                ("SourceSerif4-Regular", .regular, false),
                ("SourceSerif4-Semibold", .semibold, false),
                ("SourceSerif4-Bold", .bold, false),
                ("SourceSerif4-It", .regular, true),
            ]
        }
    }
}

/// Loads the bundled families.
public enum Typography {

    /// A fresh family, loaded from the package's resources.
    ///
    /// Fresh each call, deliberately. An ``EmbeddedFont`` accumulates the glyphs
    /// it has been asked to draw so it can subset itself afterwards, so a
    /// cached one shared between two documents would carry the first
    /// document's characters into the second's font file. Parsing costs a
    /// couple of milliseconds against a render measured in tens.
    public static func family(_ typeface: Typeface) throws -> FontFamily {
        var family = FontFamily(name: typeface.displayName)

        for face in typeface.faces {
            guard let url = Bundle.module.url(
                forResource: face.file, withExtension: "ttf", subdirectory: "Fonts"
            ) else {
                throw ResumeError.missingFont("\(face.file).ttf")
            }
            family.add(try EmbeddedFont.load(url), weight: face.weight, italic: face.italic)
        }
        return family
    }
}

// MARK: - Errors

public enum ResumeError: Error, LocalizedError, Equatable {

    case missingFont(String)
    case unknownDesign(String)

    public var errorDescription: String? {
        switch self {
        case .missingFont(let name):
            return "\(name) is missing from the package resources. The build did not copy Resources/Fonts."
        case .unknownDesign(let name):
            return "There is no design called '\(name)'. One of: "
                + DesignKind.allCases.map(\.rawValue).joined(separator: ", ")
        }
    }
}
