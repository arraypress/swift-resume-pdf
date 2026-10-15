//
//  ThemeCatalogText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The preset themes, as data. The shape is DocumentTheme's, shared with
//  press; the choices are this library's.
//

enum ThemeCatalogText {

    /// Every file, by name, in the order they are listed.
    static let all: [(name: String, json: String)] = [
        ("plain", plain),
        ("navy", navy),
        ("classic", classic),
        ("american", american),
        ("midnight", midnight),
        ("paper", paper),
    ]

    static let plain = ##"""
    {
      "accent" : "#111111",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "A4",
      "scheme" : "light"
    }

    """##

    static let navy = ##"""
    {
      "accent" : "#1F3A5F",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "A4",
      "scheme" : "light"
    }

    """##

    static let classic = ##"""
    {
      "accent" : "#1A1A1A",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "A4",
      "scheme" : "light",
      "typeface" : "sourceSerif"
    }

    """##

    static let american = ##"""
    {
      "accent" : "#111111",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "Letter",
      "scheme" : "light"
    }

    """##

    static let midnight = ##"""
    {
      "accent" : "#E8A33D",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "A4",
      "scheme" : "dark"
    }

    """##

    static let paper = ##"""
    {
      "accent" : "#7A4A2B",
      "density" : "normal",
      "justified" : false,
      "pageSize" : "A4",
      "scheme" : "light",
      "tint" : "#F6F1E8"
    }

    """##

}
