//
//  SchemaTests.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The schemas are kept honest here. A small validator — types, enums,
//  properties, `$ref`, `oneOf` — is enough to prove that every file the
//  package carries and every sample it ships fits the schema that claims
//  to describe it, so a key added to the model without the schema
//  following is caught in this file rather than in somebody's editor.
//

import XCTest
@testable import ResumePDF

final class SchemaTests: XCTestCase {

    // MARK: A validator, small enough to trust

    private struct Mismatch: Error, CustomStringConvertible {
        let path: String
        let reason: String
        var description: String { "\(path): \(reason)" }
    }

    private func schema(_ which: Schema) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: which.data) as? [String: Any])
    }

    private func validate(_ value: Any, against node: [String: Any], root: [String: Any], path: String = "$") throws {
        if let ref = node["$ref"] as? String {
            let name = ref.replacingOccurrences(of: "#/$defs/", with: "")
            let defs = try XCTUnwrap(root["$defs"] as? [String: Any])
            let target = try XCTUnwrap(defs[name] as? [String: Any], "unknown $ref \(ref)")
            return try validate(value, against: target, root: root, path: path)
        }
        for key in ["oneOf", "anyOf"] {
            if let branches = node[key] as? [[String: Any]] {
                var failures: [String] = []
                for branch in branches {
                    do { try validate(value, against: branch, root: root, path: path); return }
                    catch let mismatch as Mismatch { failures.append(mismatch.reason) }
                }
                throw Mismatch(path: path, reason: "matched no branch of \(key): \(failures)")
            }
        }
        // JSON's true and false come back as NSNumber like every other
        // number, and 0 and 1 bridge to Bool — so a boolean is told apart by
        // its CoreFoundation type, not by a cast.
        let isBoolean = (value as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
        if let type = node["type"] as? String {
            let ok: Bool
            switch type {
            case "string": ok = value is String
            case "number": ok = value is NSNumber && !isBoolean
            case "integer": ok = value is NSNumber && !isBoolean
            case "boolean": ok = isBoolean
            case "array": ok = value is [Any]
            case "object": ok = value is [String: Any]
            case "null": ok = value is NSNull
            default: ok = false
            }
            if !ok { throw Mismatch(path: path, reason: "is not \(type)") }
        }
        if let allowed = node["enum"] as? [String], let text = value as? String, !allowed.contains(text) {
            throw Mismatch(path: path, reason: "\"\(text)\" is not one of \(allowed)")
        }
        if let pattern = node["pattern"] as? String, let text = value as? String,
           text.range(of: pattern, options: .regularExpression) == nil {
            throw Mismatch(path: path, reason: "\"\(text)\" does not match \(pattern)")
        }
        if let object = value as? [String: Any] {
            let properties = node["properties"] as? [String: Any] ?? [:]
            if let required = node["required"] as? [String] {
                for key in required where object[key] == nil { throw Mismatch(path: path, reason: "missing \(key)") }
            }
            for (key, child) in object {
                if let property = properties[key] as? [String: Any] {
                    try validate(child, against: property, root: root, path: "\(path).\(key)")
                } else if let names = node["propertyNames"] as? [String: Any] {
                    try validate(key, against: names, root: root, path: "\(path).\(key)")
                    if let extra = node["additionalProperties"] as? [String: Any] {
                        try validate(child, against: extra, root: root, path: "\(path).\(key)")
                    }
                } else if let extra = node["additionalProperties"] as? [String: Any] {
                    try validate(child, against: extra, root: root, path: "\(path).\(key)")
                } else if node["additionalProperties"] as? Bool == false {
                    throw Mismatch(path: path, reason: "unknown key \(key)")
                }
            }
        }
        if let array = value as? [Any], let items = node["items"] as? [String: Any] {
            for (index, child) in array.enumerated() {
                try validate(child, against: items, root: root, path: "\(path)[\(index)]")
            }
        }
    }

    private func check(_ data: Data, against which: Schema, _ label: String) throws {
        let value = try JSONSerialization.jsonObject(with: data)
        let root = try schema(which)
        do { try validate(value, against: root, root: root) }
        catch let mismatch as Mismatch { XCTFail("\(label) against \(which.filename): \(mismatch)") }
    }

    private func files(in folder: String) throws -> [URL] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: folder, withExtension: nil))
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
    }

    // MARK: The schemas themselves

    func testEverySchemaIsAJSONSchemaDocument() throws {
        for which in Schema.allCases {
            let root = try schema(which)
            XCTAssertEqual(root["$schema"] as? String, "https://json-schema.org/draft/2020-12/schema", which.rawValue)
            XCTAssertNotNil(root["title"], which.rawValue)
            XCTAssertNotNil(root["properties"], which.rawValue)
        }
    }

    // MARK: What the package carries fits its own schemas

    func testEveryBundledDesignFitsTheBlueprintSchema() throws {
        for file in try files(in: "Designs") {
            try check(try Data(contentsOf: file), against: .blueprint, file.lastPathComponent)
        }
    }

    func testEveryBundledLetterDesignFitsItsSchema() throws {
        for file in try files(in: "Letters") {
            try check(try Data(contentsOf: file), against: .letterBlueprint, file.lastPathComponent)
        }
    }

    func testEveryThemePresetFitsTheThemeSchema() throws {
        let files = try files(in: "Themes")
        XCTAssertEqual(files.count, Theme.presetNames.count)
        for file in files {
            try check(try Data(contentsOf: file), against: .theme, file.lastPathComponent)
            XCTAssertNotNil(Theme.named(file.deletingPathExtension().lastPathComponent),
                            "\(file.lastPathComponent) is a file but not a preset")
        }
        XCTAssertEqual(Theme.named("Navy"), .navy)
        XCTAssertEqual(Theme.plain, Theme(), "the plain preset is the default")
        XCTAssertEqual(Theme.classic.typeface, .sourceSerif, "a typeface reads back from its name")
        XCTAssertNil(Theme.named("neon"))
    }

    // MARK: What the library writes fits them too

    func testTheSamplesFitTheDocumentSchemas() throws {
        let encoder = JSONEncoder()
        try check(try encoder.encode(Resume.sample), against: .resume, "Resume.sample")
        try check(try encoder.encode(Resume.academicSample), against: .resume, "Resume.academicSample")
        try check(try encoder.encode(CoverLetter.sample), against: .letter, "CoverLetter.sample")

        // A custom section and every content kind, spelled out.
        let custom = Resume(
            profile: Profile(name: "A"),
            custom: [CustomSection("Patents", [
                .prose("x"), .list(["a"]), .positions([Position(role: "r")]),
                .education([Education(qualification: "q")]), .projects([Project(name: "p")]),
                .publications([Publication(title: "t")]), .credentials([Credential(name: "c")]),
                .awards([Award(name: "a")]), .grants([Grant(title: "g")]),
                .skills([SkillGroup("s", [Skill("Go", 0.5)])]), .languages([Language("l", "L")]),
            ])],
            order: [.custom("Patents"), .summary],
            labels: .german
        )
        try check(try encoder.encode(custom), against: .resume, "a custom section")
    }

    func testTheShorthandsTheDecoderTakesAreInTheSchema() throws {
        // A date as a string, a link as a string, a skill as a string, labels
        // as a code, and the keys a tool reads beside the résumé.
        let spec = """
            { "profile": { "name": "A", "links": ["https://x.y"] },
              "experience": [{ "role": "r", "dates": "2023", "skills": ["Go"] }],
              "skills": [{ "name": "g", "items": ["Go", { "name": "Rust", "level": 0.5 }] }],
              "labels": "de", "design": "ledger", "extends": "../base.json",
              "theme": { "accent": "#1F3A5F", "typeface": "serif", "density": "compact" } }
            """
        try check(Data(spec.utf8), against: .resume, "the shorthand spec")
        XCTAssertNoThrow(try JSONDecoder().decode(Resume.self, from: Data(spec.utf8)), "and the decoder agrees")
    }

    func testTheSchemaRefusesATypo() throws {
        let root = try schema(.resume)
        let typo = try JSONSerialization.jsonObject(with: Data(#"{"profile": {"name": "A"}, "experiance": []}"#.utf8))
        XCTAssertThrowsError(try validate(typo, against: root, root: root))

        let design = try schema(.blueprint)
        let bad = try JSONSerialization.jsonObject(with: Data(#"{"heading": {"style": "stripe"}}"#.utf8))
        XCTAssertThrowsError(try validate(bad, against: design, root: design))
    }
}
