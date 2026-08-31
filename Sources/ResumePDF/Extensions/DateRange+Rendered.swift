//
//  DateRange+Rendered.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  A range as one printed string — the rule that an open end says
//  "Present" and a missing start says only where it got to.
//

import Foundation

extension DateRange {

    /// The range as one string, using `dash` between the two.
    public func rendered(present: String = "Present", dash: String = "–") -> String {
        let from = start.trimmingCharacters(in: .whitespaces)
        let trimmedEnd = end.trimmingCharacters(in: .whitespaces)

        guard !trimmedEnd.isEmpty else { return from }

        let to = isCurrent ? present : trimmedEnd
        return from.isEmpty ? to : "\(from) \(dash) \(to)"
    }
}
