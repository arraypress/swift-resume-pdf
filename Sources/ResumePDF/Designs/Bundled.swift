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

import Foundation

/// A design written as data, and carried by the package as a JSON file.
public protocol BundledBlueprint: Codable, Equatable, Sendable {

    /// What this design is called — and what its file is called.
    var name: String { get }

    /// The folder in the package's resources its files are in.
    static var subdirectory: String { get }

    /// The files there, in the order they are listed.
    static var bundledNames: [String] { get }

    /// The files, read — once. A design is asked for on every render and
    /// every check, and a decode per ask is a decode too many.
    static var starting: [Self] { get }
}

extension BundledBlueprint {

    /// Reads a design from a JSON file.
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
    /// The files are part of the package, so one that is missing is a
    /// build fault rather than a condition to handle — and there is a test
    /// that reads every one of them.
    static func bundled(_ name: String) -> Self {
        guard let found = starting.first(where: { $0.name == name }) else {
            preconditionFailure("The bundled design \(name).json is not in the package")
        }
        return found
    }

    /// Every file ``bundledNames`` lists, read from the package's resources.
    /// One that will not read, or that calls itself something other than
    /// its file's name, is the same build fault.
    static func readBundled() -> [Self] {
        bundledNames.map { name in
            guard let url = Bundle.module.url(forResource: name, withExtension: "json",
                                              subdirectory: subdirectory) else {
                preconditionFailure("The bundled design \(name).json is not in \(subdirectory)")
            }
            do {
                let read = try Self(contentsOf: url)
                precondition(read.name == name, "\(subdirectory)/\(name).json calls itself \(read.name)")
                return read
            } catch {
                preconditionFailure("The bundled design \(name).json does not read: \(error)")
            }
        }
    }
}
