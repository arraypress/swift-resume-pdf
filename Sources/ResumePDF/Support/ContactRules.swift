//
//  ContactRules.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A printed phone number turned into something a phone can dial, as pure
//  functions the tests pin without building a Profile.
//

import Foundation

enum ContactRules {

    /// tel: wants the number and nothing else — no spaces, no brackets.
    /// The "(0)" written inside an international number is the national
    /// trunk digit: dialled after a country code it reaches a wrong
    /// number, so it comes out of the dial string and stays in the text.
    static func dialable(_ phone: String) -> String {
        phone
            .replacingOccurrences(of: "(0)", with: "")
            .filter { $0.isNumber || $0 == "+" }
    }

    /// The tel: URL, or nothing for a string too short to be a number.
    static func dialURL(_ phone: String) -> String {
        let digits = dialable(phone)
        return digits.count > 5 ? "tel:\(digits)" : ""
    }
}
