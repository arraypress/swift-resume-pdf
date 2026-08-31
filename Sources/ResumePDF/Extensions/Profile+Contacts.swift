//
//  Profile+Contacts.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The contact line assembled — what is shown, what it links to, and in
//  what order. The one genuinely tricky rule, turning a printed phone
//  number into a dial string, lives in Support/ContactRules.
//

import Foundation

extension Profile {

    /// The contact line, in the order a reader scans it.
    ///
    /// Email first because it is what they will use. Everything empty is
    /// dropped rather than left as a gap or a stray separator.
    public func contactLine() -> [String] {
        [email, phone, location].filter { !$0.isBlank }
    }

    /// The contact line, with somewhere to go where there is somewhere.
    ///
    /// A résumé is read from a screen far more often than from paper, and an
    /// address nobody can click is one somebody has to retype — which is the
    /// difference between a recruiter opening your GitHub and meaning to.
    ///
    /// The location has no URL. It is the one thing here that is not a way of
    /// reaching you, and putting it on a map is answering a question nobody
    /// asked.
    public func contactEntries() -> [(text: String, url: String)] {
        markedContacts().map { ($0.text, $0.url) }
    }

    /// The same, each with the mark that says what it is — for the panels
    /// that set an icon beside every entry.
    func markedContacts() -> [(icon: Icon, text: String, url: String)] {
        var entries: [(icon: Icon, text: String, url: String)] = []

        if !email.isBlank {
            entries.append((.email, email, "mailto:\(email.trimmingCharacters(in: .whitespaces))"))
        }
        if !phone.isBlank {
            entries.append((.phone, phone, ContactRules.dialURL(phone)))
        }
        if !location.isBlank {
            entries.append((.location, location, ""))
        }
        return entries + links.map { (.link, $0.label, $0.absolute) }
    }

    /// The regional particulars that are actually set, as label and value.
    public func particulars() -> [(label: String, value: String)] {
        [
            ("Date of birth", dateOfBirth),
            ("Place of birth", placeOfBirth),
            ("Nationality", nationality),
            ("Marital status", maritalStatus),
        ].filter { !$0.1.isBlank }
    }
}
