//
//  Recipient+Lines.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The recipient block as it is set — blanks dropped, order kept.
//

import Foundation

extension Recipient {

    /// The block as it is set, one string per line.
    public func lines() -> [String] {
        ([name, role, organisation] + address)
            .filter { !$0.isBlank }
    }
}
