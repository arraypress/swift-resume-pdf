//
//  ResumeError.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//

import Foundation

public enum ResumeError: Error, LocalizedError, Equatable {

    case unknownDesign(String)

    /// The document was asked to claim PDF/A-3 and cannot.
    ///
    /// Thrown rather than reported, because the request was explicit: a file
    /// written anyway would carry a claim it fails, and the person who asked
    /// for `archival:` is exactly the person sending it somewhere that will
    /// validate it.
    case notArchival([String])

    public var errorDescription: String? {
        switch self {
        case .unknownDesign(let name):
            return "There is no design called '\(name)'. One of: "
                + DesignKind.allCases.map(\.rawValue).joined(separator: ", ")
        case .notArchival(let issues):
            return "The document cannot claim PDF/A-3. " + issues.joined(separator: " ")
        }
    }
}
