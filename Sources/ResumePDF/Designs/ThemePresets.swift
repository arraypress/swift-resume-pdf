//
//  ThemePresets.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The preset themes this library carries. The shape is DocumentTheme's,
//  shared with press; the choices are this library's, as data in
//  `ThemeCatalogText`.
//
//  Most of what looks like a dozen résumé designs is four arrangements in a
//  dozen colourways — the same body on white, on pale paper, on near-black —
//  which is why the colourway is a theme rather than a design.
//

import DocumentTheme
import Foundation
import RecipeKit

/// The bundled preset themes, by name.
public enum ThemePresets {

    /// Their names, in the order they are listed.
    public static let names = ThemeCatalogText.all.map(\.name)

    /// Every preset, read once.
    public static let all: [Theme] = ThemeCatalogText.all.map { read($0.name, $0.json) }

    /// Restrained and monochrome. The safest thing to send anybody.
    public static var plain: Theme { named("plain")! }

    /// A quiet ink blue.
    public static var navy: Theme { named("navy")! }

    /// Set in the serif, for academia and law.
    public static var classic: Theme { named("classic")! }

    /// US Letter, because a résumé printed on A4 in Chicago comes out with a
    /// margin the printer had to invent.
    public static var american: Theme { named("american")! }

    /// Near-black, with a warm accent that survives it.
    public static var midnight: Theme { named("midnight")! }

    /// A warm paper tint. Reads as considered; costs a lot of toner.
    public static var paper: Theme { named("paper")! }

    /// A preset by name, however it was typed; nil for a name that is not one.
    public static func named(_ name: String) -> Theme? {
        names.firstIndex(of: name.lowercased()).map { all[$0] }
    }

    /// Every problem with the bundled presets: one that does not read
    /// strictly, a name that is not kebab-case or is listed twice. A test
    /// asserts there are none.
    public static var problems: [String] {
        var seen = Set<String>()
        return ThemeCatalogText.all.flatMap { entry -> [String] in
            var found = StyleCatalogs.nameProblems(entry.name, seen: &seen)
            do { _ = try JSONDecoder().decode(Theme.self, from: Data(entry.json.utf8)) } catch {
                found.append("\(entry.name): \(Decoding.describe(error))")
            }
            return found
        }
    }

    private static func read(_ name: String, _ json: String) -> Theme {
        do { return try JSONDecoder().decode(Theme.self, from: Data(json.utf8)) } catch {
            preconditionFailure("The bundled theme \(name) does not read: \(Decoding.describe(error))")
        }
    }
}
