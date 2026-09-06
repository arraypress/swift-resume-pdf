//
//  VCard.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A contact record as vCard 3.0 — the thing a phone saves when it scans the
//  code on a card, rather than a URL it has to be told to open.
//
//  Assembled here as pure functions rather than in ``Card``, so the escaping
//  is testable without building a document. 3.0 rather than 4.0 because it is
//  what every phone camera on both platforms reads today; 4.0 is the better
//  specification and the worse choice.
//

import Foundation

/// A contact record, as the text a code carries.
enum VCard {

    /// The record for a profile, with the fields it actually has.
    ///
    /// Empty fields are dropped rather than written blank: a `TEL:` with
    /// nothing after it is a contact whose phone number is the empty string,
    /// which is worse than one with no phone number.
    static func text(
        name: String,
        title: String = "",
        organisation: String = "",
        phone: String = "",
        email: String = "",
        location: String = "",
        urls: [String] = []
    ) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append("N:\(escaped(name));;;;")
        lines.append("FN:\(escaped(name))")
        if !organisation.isBlank { lines.append("ORG:\(escaped(organisation))") }
        if !title.isBlank { lines.append("TITLE:\(escaped(title))") }
        // TYPE is what makes a phone file the number under "work" rather than
        // asking, which is the difference between one tap and four.
        if !phone.isBlank { lines.append("TEL;TYPE=WORK,VOICE:\(escaped(phone))") }
        if !email.isBlank { lines.append("EMAIL;TYPE=WORK,INTERNET:\(escaped(email))") }
        if !location.isBlank {
            // ADR is seven semicolon-separated parts and a city belongs in
            // the fourth. A location written as "Columbus, Ohio" is not a
            // postal address and is not pretended to be one — it goes in the
            // locality field and the rest stay empty.
            lines.append("ADR;TYPE=WORK:;;;\(escaped(location));;;")
        }
        for url in urls where !url.isBlank { lines.append("URL:\(escaped(url))") }
        lines.append("END:VCARD")

        // CRLF, which the specification requires and some Android readers
        // enforce.
        return lines.joined(separator: "\r\n")
    }

    /// vCard escaping: `\` `;` `,` take a backslash; a newline becomes `\n`.
    ///
    /// The trap is that `"\r\n"` is ONE Character in Swift — a grapheme
    /// cluster — so a Windows newline never matches `"\n"` alone and would
    /// sail through unescaped, ending the record early on whatever read it.
    /// This was a real fault in the fleet's QR payloads before it was one
    /// here.
    static func escaped(_ value: String) -> String {
        var out = ""
        for character in value {
            switch character {
            case "\\", ";", ",":
                out.append("\\")
                out.append(character)
            case "\n", "\r\n":
                out.append("\\n")
            case "\r":
                continue
            default:
                out.append(character)
            }
        }
        return out
    }
}
