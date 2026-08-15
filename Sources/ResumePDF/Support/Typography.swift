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
///
/// A struct rather than an enum so callers are not limited to what happens to
/// be bundled. Somebody with a brand face, or who simply wants EB Garamond,
/// should not have to fork the package to use it — and a résumé tool that
/// dictates the typeface is dictating most of the design.
public struct Typeface: Sendable, Equatable, Codable {

    /// For diagnostics, and for the CLI to name.
    public let name: String

    /// Files making up the family. Empty for a bundled one.
    let files: [Face]

    /// Which bundled family this is, if it is one.
    let bundled: String?

    struct Face: Sendable, Equatable, Codable {
        let path: String
        let weight: Int
        let italic: Bool
    }

    // MARK: Bundled

    /// Inter — a neutral grotesque drawn for screens, with a tall x-height
    /// that stays legible at the sizes a dense résumé needs.
    public static let inter = Typeface(name: "Inter", files: [], bundled: "inter")

    /// Source Serif 4 — a transitional serif. Reads as considered rather than
    /// current, which suits academia, law, and anywhere a sans would look like
    /// it was trying too hard.
    public static let sourceSerif = Typeface(name: "Source Serif 4", files: [], bundled: "sourceSerif")

    /// The bundled families, for a caller offering a choice.
    public static let bundledFamilies: [Typeface] = [.inter, .sourceSerif]

    // MARK: Your own

    /// A family loaded from files on disk.
    ///
    /// Static TrueType instances — a variable font would embed as its default
    /// weight throughout, and ``EmbeddedFont`` refuses one rather than let
    /// that happen quietly.
    ///
    /// Only the weights given are available; a design asking for one that is
    /// missing gets the nearest that is, so a family of two files renders
    /// everything.
    public static func custom(
        name: String,
        regular: URL,
        medium: URL? = nil,
        semibold: URL? = nil,
        bold: URL? = nil,
        italic: URL? = nil
    ) -> Typeface {
        var faces = [Face(path: regular.path, weight: 400, italic: false)]
        if let medium { faces.append(Face(path: medium.path, weight: 500, italic: false)) }
        if let semibold { faces.append(Face(path: semibold.path, weight: 600, italic: false)) }
        if let bold { faces.append(Face(path: bold.path, weight: 700, italic: false)) }
        if let italic { faces.append(Face(path: italic.path, weight: 400, italic: true)) }

        return Typeface(name: name, files: faces, bundled: nil)
    }

    public var displayName: String { name }

    /// The bundled files making up a family, by weight and slope.
    var bundledFaces: [(file: String, weight: FontFamily.Weight, italic: Bool)] {
        switch bundled {
        case "sourceSerif":
            return [
                ("SourceSerif4-Regular", .regular, false),
                ("SourceSerif4-Semibold", .semibold, false),
                ("SourceSerif4-Bold", .bold, false),
                ("SourceSerif4-It", .regular, true),
            ]
        default:
            return [
                ("Inter-Regular", .regular, false),
                ("Inter-Medium", .medium, false),
                ("Inter-SemiBold", .semibold, false),
                ("Inter-Bold", .bold, false),
                ("Inter-Italic", .regular, true),
            ]
        }
    }

    /// The monospaced face every family can reach for.
    ///
    /// One family rather than one per typeface: a mono is set beside text
    /// rather than instead of it, and JetBrains Mono sits against both of the
    /// bundled families without arguing. It is loaded only when a design asks.
    static let monoFaces: [(file: String, weight: FontFamily.Weight, italic: Bool)] = [
        ("JetBrainsMono-Regular", .regular, false),
        ("JetBrainsMono-Medium", .medium, false),
        ("JetBrainsMono-Bold", .bold, false),
    ]
}

/// Loads the bundled families.
public enum Typography {

    /// JetBrains Mono, for the parts of a résumé that are data rather than
    /// prose — dates, versions, keys, anything meant to be compared down a
    /// column rather than read along a line.
    ///
    /// Body text is not one of those. A page of monospaced prose at nine
    /// points is markedly harder to read than the same words proportionally
    /// set, and the designs here use it on labels and figures rather than on
    /// the sentences somebody is being asked to read.
    public static func mono() throws -> FontFamily {
        var family = FontFamily(name: "JetBrains Mono")
        for face in Typeface.monoFaces {
            guard let url = Bundle.module.url(
                forResource: face.file, withExtension: "ttf", subdirectory: "Fonts"
            ) else {
                throw ResumeError.missingFont("\(face.file).ttf")
            }
            family.add(try EmbeddedFont.load(url), weight: face.weight, italic: face.italic)
        }
        return family
    }

    /// A fresh family, loaded from the package's resources.
    ///
    /// Fresh each call, deliberately. An ``EmbeddedFont`` accumulates the glyphs
    /// it has been asked to draw so it can subset itself afterwards, so a
    /// cached one shared between two documents would carry the first
    /// document's characters into the second's font file. Parsing costs a
    /// couple of milliseconds against a render measured in tens.
    public static func family(_ typeface: Typeface) throws -> FontFamily {
        var family = FontFamily(name: typeface.displayName)

        // A family of your own, loaded from wherever you put it.
        guard typeface.files.isEmpty else {
            for face in typeface.files {
                let weight = FontFamily.Weight(rawValue: face.weight) ?? .regular
                family.add(
                    try EmbeddedFont.load(URL(fileURLWithPath: face.path)),
                    weight: weight, italic: face.italic
                )
            }
            return family
        }

        for face in typeface.bundledFaces {
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
