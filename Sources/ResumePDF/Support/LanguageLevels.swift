//
//  LanguageLevels.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  What a written language level is worth on a five-point scale — so a
//  design can draw dots or a bar from the words somebody actually wrote,
//  and draw nothing from words it does not know rather than guessing.
//

import Foundation

/// The words and CEFR grades a level is written in, and where each sits.
enum LanguageLevels {

    /// A fraction of the scale, or nil when the level is not a known word.
    ///
    /// Nil is the important answer: a level the table does not know draws
    /// no dots, and the text stands alone — a wrong number of dots is a
    /// claim the candidate never made.
    static func fraction(for level: String) -> Double? {
        let key = level.trimmingCharacters(in: .whitespaces).lowercased()
        guard !key.isEmpty else { return nil }
        if let exact = table[key] { return exact }
        // "Native speaker", "Fluent (business)", "C1 Advanced" — the grade is
        // usually the first word, so the first word is tried on its own.
        let first = key.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).first.map(String.init) ?? ""
        return table[first]
    }

    private static let table: [String: Double] = [
        // Five: the language as one's own.
        "native": 1.0, "mother tongue": 1.0, "bilingual": 1.0, "c2": 1.0, "mastery": 1.0,
        "muttersprache": 1.0, "langue maternelle": 1.0,
        // Four: works in it all day.
        "fluent": 0.8, "proficient": 0.8, "advanced": 0.8, "c1": 0.8,
        "full professional": 0.8, "professional": 0.8, "fließend": 0.8, "courant": 0.8,
        // Three: gets by, and then some.
        "upper intermediate": 0.6, "upper-intermediate": 0.6, "b2": 0.6,
        "intermediate": 0.6, "b1": 0.6, "conversational": 0.6, "limited working": 0.6,
        "gut": 0.6, "intermédiaire": 0.6,
        // Two and one.
        "elementary": 0.4, "a2": 0.4, "basic": 0.4, "grundkenntnisse": 0.4,
        "beginner": 0.2, "a1": 0.2, "notions": 0.2,
    ]
}
