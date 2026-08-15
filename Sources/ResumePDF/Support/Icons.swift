//
//  Icons.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  Small marks for section headings.
//
//  Drawn as vector outlines rather than carried as images: a path is a few
//  hundred bytes, stays sharp at any zoom, and takes the ink colour of
//  whatever is drawing it — so an icon set works in dark mode without a second
//  copy of every file.
//
//  Stroked, not filled. Line icons are outlines that were never meant to
//  enclose anything, and filling one produces a blob.
//
//  All of them are drawn in a 24-unit box, so a caller asks for a size in
//  points and gets it.
//

import Foundation
import TextPDF

/// A mark that can sit beside a section heading.
public enum Icon: String, Sendable, CaseIterable, Codable {

    case profile
    case experience
    case education
    case skills
    case projects
    case certifications
    case publications
    case awards
    case languages
    case interests
    case references
    case volunteering
    case email
    case phone
    case location
    case link
    case calendar

    /// The box the paths are drawn in.
    static let box = 24.0

    /// The path data, as an SVG `d` attribute.
    var path: String {
        switch self {
        case .profile:
            return "M15.5 8 C15.5 9.93 13.93 11.5 12 11.5 C10.07 11.5 8.5 9.93 8.5 8 "
                + "C8.5 6.07 10.07 4.5 12 4.5 C13.93 4.5 15.5 6.07 15.5 8 Z "
                + "M4.5 20 C4.5 16.4 7.9 13.5 12 13.5 C16.1 13.5 19.5 16.4 19.5 20"

        case .experience:
            return "M3.5 8 H20.5 V19 H3.5 Z "
                + "M9 8 V6.2 C9 5.5 9.5 5 10.2 5 H13.8 C14.5 5 15 5.5 15 6.2 V8"

        case .education:
            return "M12 4 L22 9 L12 14 L2 9 Z M6.5 11.2 V16.2 C8 17.6 9.9 18.3 12 18.3 "
                + "C14.1 18.3 16 17.6 17.5 16.2 V11.2"

        case .skills:
            return "M12 3.2 L14.2 9.3 L20.6 9.5 L15.6 13.4 L17.4 19.6 L12 15.9 "
                + "L6.6 19.6 L8.4 13.4 L3.4 9.5 L9.8 9.3 Z"

        case .projects:
            return "M3 7.2 C3 6.5 3.5 6 4.2 6 H9.4 L11.4 8.6 H19.8 C20.5 8.6 21 9.1 21 9.8 "
                + "V17.8 C21 18.5 20.5 19 19.8 19 H4.2 C3.5 19 3 18.5 3 17.8 Z"

        case .certifications:
            return "M16.5 9.3 C16.5 11.8 14.5 13.8 12 13.8 C9.5 13.8 7.5 11.8 7.5 9.3 "
                + "C7.5 6.8 9.5 4.8 12 4.8 C14.5 4.8 16.5 6.8 16.5 9.3 Z "
                + "M9.6 13.3 L8.6 20 L12 18.1 L15.4 20 L14.4 13.3"

        case .publications:
            return "M4 5.2 H9.6 C10.9 5.2 12 6.3 12 7.6 V19 C12 18 11 17.4 9.6 17.4 H4 Z "
                + "M20 5.2 H14.4 C13.1 5.2 12 6.3 12 7.6 V19 C12 18 13 17.4 14.4 17.4 H20 Z"

        case .awards:
            return "M8 4.2 H16 V10 C16 12.2 14.2 14 12 14 C9.8 14 8 12.2 8 10 Z "
                + "M8 5.6 H5.4 C5.4 8.6 6.4 10.2 8.4 10.7 "
                + "M16 5.6 H18.6 C18.6 8.6 17.6 10.2 15.6 10.7 "
                + "M12 14 V17.2 M9 20 H15 L14.4 17.2 H9.6 Z"

        case .languages:
            return "M20 12 C20 16.42 16.42 20 12 20 C7.58 20 4 16.42 4 12 "
                + "C4 7.58 7.58 4 12 4 C16.42 4 20 7.58 20 12 Z "
                + "M12 4 C14.4 6.6 15.4 9.2 15.4 12 C15.4 14.8 14.4 17.4 12 20 "
                + "C9.6 17.4 8.6 14.8 8.6 12 C8.6 9.2 9.6 6.6 12 4 Z "
                + "M4.6 9.4 H19.4 M4.6 14.6 H19.4"

        case .interests:
            return "M12 20 C12 20 3.6 14.4 3.6 9.1 C3.6 6.5 5.6 4.5 8.1 4.5 "
                + "C9.8 4.5 11.3 5.5 12 6.9 C12.7 5.5 14.2 4.5 15.9 4.5 "
                + "C18.4 4.5 20.4 6.5 20.4 9.1 C20.4 14.4 12 20 12 20 Z"

        case .references:
            return "M10.5 6.5 C7.2 7.6 5.5 10 5.5 13.2 V18 H10.8 V12.6 H8.2 "
                + "C8.4 10.4 9.2 9.1 10.9 8.3 Z "
                + "M20 6.5 C16.7 7.6 15 10 15 13.2 V18 H20.3 V12.6 H17.7 "
                + "C17.9 10.4 18.7 9.1 20.4 8.3 Z"

        case .volunteering:
            return "M9.2 10.4 C11.1 10.4 12.6 8.9 12.6 7 C12.6 5.1 11.1 3.6 9.2 3.6 "
                + "C7.3 3.6 5.8 5.1 5.8 7 C5.8 8.9 7.3 10.4 9.2 10.4 Z "
                + "M2.5 20 C2.5 16.3 5.5 13.4 9.2 13.4 C12.9 13.4 15.9 16.3 15.9 20 "
                + "M16.4 6 C18 6 19.3 7.3 19.3 8.9 C19.3 10.5 18 11.8 16.4 11.8 "
                + "M17.6 14.2 C20 14.9 21.5 17 21.5 19.4"

        case .email:
            return "M3 6.5 H21 V17.5 H3 Z M3.4 7 L12 13.2 L20.6 7"

        case .phone:
            return "M7.2 3.5 H10 L11.4 7.6 L9.4 9 C10.4 11.4 12.6 13.6 15 14.6 "
                + "L16.4 12.6 L20.5 14 V16.8 C20.5 18.4 19.2 19.7 17.6 19.6 "
                + "C10.2 19 5 13.8 4.4 6.4 C4.3 4.8 5.6 3.5 7.2 3.5 Z"

        case .location:
            return "M12 21 C12 21 19 14.4 19 9.4 C19 5.6 15.9 2.5 12 2.5 "
                + "C8.1 2.5 5 5.6 5 9.4 C5 14.4 12 21 12 21 Z "
                + "M14.4 9.4 C14.4 10.7 13.3 11.8 12 11.8 C10.7 11.8 9.6 10.7 9.6 9.4 "
                + "C9.6 8.1 10.7 7 12 7 C13.3 7 14.4 8.1 14.4 9.4 Z"

        case .link:
            return "M10 14 C11.6 15.6 14.2 15.6 15.8 14 L19 10.8 "
                + "C20.6 9.2 20.6 6.6 19 5 C17.4 3.4 14.8 3.4 13.2 5 L11.8 6.4 "
                + "M14 10 C12.4 8.4 9.8 8.4 8.2 10 L5 13.2 "
                + "C3.4 14.8 3.4 17.4 5 19 C6.6 20.6 9.2 20.6 10.8 19 L12.2 17.6"

        case .calendar:
            return "M4 6.5 H20 V20 H4 Z M4 10.4 H20 M8 4 V8 M16 4 V8"
        }
    }

    /// The icon a section conventionally takes.
    static func of(_ section: Section) -> Icon {
        switch section {
        case .summary: return .profile
        case .experience: return .experience
        case .education: return .education
        case .skills: return .skills
        case .projects: return .projects
        case .certifications: return .certifications
        case .publications: return .publications
        case .awards: return .awards
        case .languages: return .languages
        case .interests: return .interests
        case .references: return .references
        case .volunteering: return .volunteering
        }
    }
}

extension Sheet {

    /// Draws an icon with its top-left at `x`, `y`.
    ///
    /// The stroke thickens with the icon rather than staying constant: a
    /// hairline that reads correctly at seven points disappears at fourteen,
    /// and the mark stops matching the weight of the text beside it.
    func icon(_ mark: Icon, x: Double, y iconY: Double, size: Double, color: Color? = nil) {
        pdf.svgPath(
            mark.path,
            x: x, y: iconY,
            scale: size / Icon.box,
            color: color ?? muted,
            svgHeight: Icon.box,
            strokeWidth: max(1.15, size / 13)
        )
    }
}
