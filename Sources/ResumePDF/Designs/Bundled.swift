//
//  Bundled.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A design is a JSON file the package carries, and the Swift only names it.
//
//  Reading one from a file, writing it back out formatted to be edited, and
//  finding the ones in the package's resources are the same for a résumé
//  design and a letter design; only the folder differs. So they are here
//  once, and ``Blueprint`` and ``LetterBlueprint`` each say which folder.
//

import DocumentTheme
import Foundation
import RecipeKit

/// A design written as data, and carried by the package as a JSON file.
public protocol BundledBlueprint: Codable, Equatable, Sendable {

    /// What this design is called — and what its file is called.
    var name: String { get }

    /// The bundled designs as JSON, by name, in the order they are listed
    /// (compiled in — see `Support/*CatalogText.swift`).
    static var catalogue: [(name: String, json: String)] { get }

    /// The files, read — once. A design is asked for on every render and
    /// every check, and a decode per ask is a decode too many.
    static var starting: [Self] { get }
}

extension BundledBlueprint {

    /// The bundled designs' names, in the order they are listed.
    public static var bundledNames: [String] { catalogue.map(\.name) }

    /// Reads a design from a JSON file, strictly: a key a design does not
    /// have is refused by its path, with the one it was probably meant to be.
    public init(contentsOf url: URL) throws {
        self = try JSONDecoder().decode(Self.self, from: try Data(contentsOf: url))
    }

    /// Writes it back out, formatted to be edited by hand.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    /// The design called `name`, from the ones already read.
    ///
    /// The designs are part of the package, so one that is missing is a
    /// build fault rather than a condition to handle — and
    /// ``catalogueProblems`` is the test for it.
    static func bundled(_ name: String) -> Self {
        guard let found = starting.first(where: { $0.name == name }) else {
            preconditionFailure("The bundled design \(name) is not in the package")
        }
        return found
    }

    /// Every design in ``catalogue``, read. One that will not read is a build
    /// fault, and ``catalogueProblems`` says which.
    static func readBundled() -> [Self] {
        catalogue.map { entry in
            do { return try JSONDecoder().decode(Self.self, from: Data(entry.json.utf8)) } catch {
                preconditionFailure("The bundled design \(entry.name) does not read: \(Decoding.describe(error))")
            }
        }
    }

    /// Every problem with the bundled designs: one that does not read
    /// strictly, or a name that is not kebab-case, is listed twice, or is
    /// not the name the design gives itself. A test asserts there are none,
    /// so a bad entry fails the build's tests rather than a run.
    public static var catalogueProblems: [String] {
        var seen = Set<String>()
        return catalogue.flatMap { entry -> [String] in
            var problems = StyleCatalogs.nameProblems(entry.name, seen: &seen)
            do {
                let design = try JSONDecoder().decode(Self.self, from: Data(entry.json.utf8))
                if design.name != entry.name { problems.append("\(entry.name): calls itself \(design.name)") }
            } catch {
                problems.append("\(entry.name): \(Decoding.describe(error))")
            }
            return problems
        }
    }
}
